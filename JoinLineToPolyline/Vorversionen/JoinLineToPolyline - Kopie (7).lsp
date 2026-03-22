;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein
;; Version 3.1 - Erkennt auch teilweise überlappende Linien

(defun c:joinpoly (/ ss i ent entlist all-lines processed-lines closed-chains count short-count dup-count)
  (princ "\nJOINPOLY - Verbindet Linien zu geschlossenen Polylinien")
  (princ "\n========================================================")
  
  ;; Objekte auswählen
  (setq ss (ssget '((0 . "LINE"))))
  
  (if ss
    (progn
      (princ (strcat "\n" (itoa (sslength ss)) " Linien gefunden."))
      (setq all-lines '())
      (setq processed-lines '())
      (setq closed-chains '())
      (setq count 0)
      (setq short-count 0)
      (setq dup-count 0)
      
      ;; SCHRITT 1: Z-Koordinaten auf 0 setzen
      (princ "\nSchritt 1: Normalisiere Z-Koordinaten...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (normalize-z-coordinate ent)
        (setq i (1+ i))
      )
      
      ;; SCHRITT 2: Alle Linien einlesen und kurze Linien löschen
      (princ "\nSchritt 2: Entferne kurze Linien...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq entlist (entget ent))
        (setq pt-start (cdr (assoc 10 entlist)))
        (setq pt-end (cdr (assoc 11 entlist)))
        (setq line-length (distance pt-start pt-end))
        
        ;; Prüfe Linienlänge
        (if (< line-length 0.005)
          (progn
            ;; Linie ist zu kurz - löschen
            (entdel ent)
            (setq short-count (1+ short-count))
          )
          (progn
            ;; Linie ist lang genug - in Liste aufnehmen
            (setq all-lines (cons (list ent pt-start pt-end line-length) all-lines))
          )
        )
        (setq i (1+ i))
      )
      
      (if (> short-count 0)
        (princ (strcat "\n  " (itoa short-count) " kurze Linie(n) (< 0.005) wurden gelöscht."))
      )
      
      ;; SCHRITT 3: Übereinanderliegende und überlappende Linien finden
      (if all-lines
        (progn
          (princ "\nSchritt 3: Suche nach übereinanderliegenden/überlappenden Linien...")
          
          ;; Layer "0_kurze Linie" erstellen falls nicht vorhanden
          (create-layer-if-not-exists "0_kurze Linie")
          
          ;; Übereinanderliegende Linien behandeln
          (setq result (handle-overlapping-lines all-lines))
          (setq all-lines (car result))
          (setq dup-count (cadr result))
          
          (if (> dup-count 0)
            (princ (strcat "\n  " (itoa dup-count) " kürzere, übereinanderliegende Linie(n) auf Layer '0_kurze Linie' verschoben."))
          )
          
          ;; SCHRITT 4: Verarbeitung - Suche nach verbundenen Linienzügen
          (princ "\nSchritt 4: Verbinde Linien zu Polylinien...")
          (princ (strcat "\n  " (itoa (length all-lines)) " Linien werden verarbeitet."))
          
          ;; Verarbeitung: Suche nach verbundenen Linienzügen
          (foreach line-data all-lines
            (if (not (member (car line-data) processed-lines))
              (progn
                (setq chain (build-chain-bidirectional (car line-data) all-lines))
                (if (and chain (> (length chain) 2))
                  (progn
                    ;; Prüfen ob geschlossen
                    (if (is-closed-chain chain all-lines)
                      (progn
                        ;; Speichere geschlossene Kette
                        (setq closed-chains (cons chain closed-chains))
                        ;; Markiere alle verarbeiteten Linien
                        (foreach line-ent chain
                          (setq processed-lines (cons line-ent processed-lines))
                        )
                        (setq count (1+ count))
                      )
                    )
                  )
                )
              )
            )
          )
          
          ;; Erstelle Polylinien aus geschlossenen Ketten
          (foreach chain closed-chains
            (create-polyline-from-chain chain all-lines)
          )
          
          (princ (strcat "\n\n" (itoa count) " geschlossene Polylinie(n) wurden erstellt."))
          (princ "\n========================================================")
        )
        (princ "\nKeine gültigen Linien zum Verarbeiten übrig.")
      )
    )
    (princ "\nKeine Linien ausgewählt.")
  )
  (princ)
)

;; Funktion: Setze Z-Koordinaten auf 0
(defun normalize-z-coordinate (ent / entlist pt-start pt-end)
  (setq entlist (entget ent))
  (setq pt-start (cdr (assoc 10 entlist)))
  (setq pt-end (cdr (assoc 11 entlist)))
  
  ;; Setze Z auf 0
  (setq pt-start (list (car pt-start) (cadr pt-start) 0.0))
  (setq pt-end (list (car pt-end) (cadr pt-end) 0.0))
  
  ;; Aktualisiere Entity
  (setq entlist (subst (cons 10 pt-start) (assoc 10 entlist) entlist))
  (setq entlist (subst (cons 11 pt-end) (assoc 11 entlist) entlist))
  (entmod entlist)
)

;; Funktion: Erstelle Layer falls nicht vorhanden
(defun create-layer-if-not-exists (layer-name / layer-table)
  (if (not (tblsearch "LAYER" layer-name))
    (progn
      (command "_.LAYER" "_M" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde erstellt."))
    )
  )
)

;; Funktion: Behandle übereinanderliegende und überlappende Linien
(defun handle-overlapping-lines (all-lines / 
                                  clean-lines checked-ents 
                                  current-ent current-data
                                  duplicates longest-ent
                                  dup-count)
  (setq clean-lines '())
  (setq checked-ents '())
  (setq dup-count 0)
  
  ;; Durchlaufe alle Linien
  (foreach line-data all-lines
    (setq current-ent (car line-data))
    
    ;; Nur verarbeiten wenn noch nicht geprüft
    (if (not (member current-ent checked-ents))
      (progn
        ;; Finde alle Duplikate (übereinanderliegende/überlappende Linien)
        (setq duplicates (find-overlapping-lines line-data all-lines))
        
        ;; Markiere alle als geprüft
        (foreach dup-data duplicates
          (setq checked-ents (cons (car dup-data) checked-ents))
        )
        
        ;; Wenn Duplikate gefunden wurden
        (if (> (length duplicates) 1)
          (progn
            ;; Finde die längste Linie
            (setq longest-ent (find-longest-line duplicates))
            
            ;; Verschiebe alle kürzeren auf Layer "0_kurze Linie"
            (foreach dup-data duplicates
              (if (not (equal (car dup-data) longest-ent))
                (progn
                  (move-to-layer (car dup-data) "0_kurze Linie")
                  (setq dup-count (1+ dup-count))
                )
              )
            )
            
            ;; Füge nur die längste zur clean-lines hinzu
            (foreach dup-data duplicates
              (if (equal (car dup-data) longest-ent)
                (setq clean-lines (cons dup-data clean-lines))
              )
            )
          )
          ;; Keine Duplikate - normal hinzufügen
          (setq clean-lines (cons line-data clean-lines))
        )
      )
    )
  )
  
  (list clean-lines dup-count)
)

;; Funktion: Prüfe ob zwei Punkte auf einer Linie liegen
(defun point-on-line (pt line-start line-end / 
                       dist-total dist1 dist2)
  ;; Berechne Distanzen
  (setq dist-total (distance line-start line-end))
  (setq dist1 (distance line-start pt))
  (setq dist2 (distance pt line-end))
  
  ;; Punkt liegt auf Linie wenn dist1 + dist2 ≈ dist-total
  (< (abs (- (+ dist1 dist2) dist-total)) 0.0001)
)

;; Funktion: Prüfe ob Linien kollinear (auf derselben Geraden) sind
(defun lines-collinear (start1 end1 start2 end2 / )
  ;; Prüfe ob alle 4 Punkte auf derselben Linie liegen
  (and 
    (point-on-line start2 start1 end1)
    (point-on-line end2 start1 end1)
  )
)

;; Funktion: Finde übereinanderliegende/überlappende Linien
(defun find-overlapping-lines (line-data all-lines / 
                                overlapping current-start current-end
                                test-start test-end)
  (setq overlapping '())
  (setq current-start (cadr line-data))
  (setq current-end (caddr line-data))
  
  ;; Durchsuche alle Linien
  (foreach test-data all-lines
    (setq test-start (cadr test-data))
    (setq test-end (caddr test-data))
    
    ;; Prüfe ob Linien übereinander/überlappend liegen
    (if (or 
          ;; Fall 1: Identische Linie (gleiche Richtung)
          (and (equal current-start test-start 0.0001)
               (equal current-end test-end 0.0001))
          ;; Fall 2: Identische Linie (umgekehrte Richtung)
          (and (equal current-start test-end 0.0001)
               (equal current-end test-start 0.0001))
          ;; Fall 3: Linien liegen auf derselben Geraden (kollinear)
          (lines-collinear current-start current-end test-start test-end)
          ;; Fall 4: Linien liegen auf derselben Geraden (umgekehrte Richtung)
          (lines-collinear current-start current-end test-end test-start)
        )
      (setq overlapping (cons test-data overlapping))
    )
  )
  
  overlapping
)

;; Funktion: Finde längste Linie aus Liste
(defun find-longest-line (line-list / longest-ent max-length)
  (setq longest-ent nil)
  (setq max-length 0.0)
  
  (foreach line-data line-list
    (if (> (cadddr line-data) max-length)
      (progn
        (setq max-length (cadddr line-data))
        (setq longest-ent (car line-data))
      )
    )
  )
  
  longest-ent
)

;; Funktion: Verschiebe Entity auf anderen Layer
(defun move-to-layer (ent layer-name / entlist)
  (setq entlist (entget ent))
  (setq entlist (subst (cons 8 layer-name) (assoc 8 entlist) entlist))
  (entmod entlist)
)

;; Funktion: Baue Kette bidirektional (in beide Richtungen)
(defun build-chain-bidirectional (start-ent all-lines / chain used-ents changed)
  (setq chain (list start-ent))
  (setq used-ents (list start-ent))
  (setq changed T)
  
  ;; Wiederhole solange neue Linien gefunden werden
  (while changed
    (setq changed nil)
    
    ;; Durchsuche alle Linien in der aktuellen Kette
    (foreach current-ent chain
      (setq current-data (get-line-data current-ent all-lines))
      (if current-data
        (progn
          (setq current-start (cadr current-data))
          (setq current-end (caddr current-data))
          
          ;; Suche nach angrenzenden Linien
          (foreach line-data all-lines
            (if (not (member (car line-data) used-ents))
              (progn
                (setq test-ent (car line-data))
                (setq test-start (cadr line-data))
                (setq test-end (caddr line-data))
                
                ;; Prüfe alle möglichen Verbindungen
                (if (or (equal current-start test-start 0.0001)
                        (equal current-start test-end 0.0001)
                        (equal current-end test-start 0.0001)
                        (equal current-end test-end 0.0001))
                  (progn
                    (setq chain (append chain (list test-ent)))
                    (setq used-ents (cons test-ent used-ents))
                    (setq changed T)
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  chain
)

;; Funktion: Hole Linien-Daten aus der Liste
(defun get-line-data (ent all-lines / result)
  (setq result nil)
  (foreach line-data all-lines
    (if (equal (car line-data) ent)
      (setq result line-data)
    )
  )
  result
)

;; Funktion: Prüfe ob Kette geschlossen ist
(defun is-closed-chain (chain all-lines / endpoints pt count)
  (setq endpoints '())
  
  ;; Sammle alle Endpunkte
  (foreach ent chain
    (setq line-data (get-line-data ent all-lines))
    (if line-data
      (progn
        (setq endpoints (cons (cadr line-data) endpoints))  ; Startpunkt
        (setq endpoints (cons (caddr line-data) endpoints)) ; Endpunkt
      )
    )
  )
  
  ;; Prüfe ob alle Punkte genau 2x vorkommen (= geschlossen)
  (setq all-closed T)
  (foreach pt endpoints
    (setq count 0)
    (foreach test-pt endpoints
      (if (equal pt test-pt 0.0001)
        (setq count (1+ count))
      )
    )
    ;; Wenn ein Punkt nicht genau 2x vorkommt, ist die Kette nicht geschlossen
    (if (/= count 2)
      (setq all-closed nil)
    )
  )
  all-closed
)

;; Funktion: Erstelle Polylinie aus Kette und färbe sie
(defun create-polyline-from-chain (chain all-lines / 
                                    pt-list current-ent current-data 
                                    current-start current-end next-ent 
                                    next-data next-start next-end
                                    used-ents found last-pt
                                    pline-data)
  
  ;; Starte mit der ersten Linie
  (setq used-ents '())
  (setq current-ent (car chain))
  (setq used-ents (cons current-ent used-ents))
  (setq current-data (get-line-data current-ent all-lines))
  (setq current-start (cadr current-data))
  (setq current-end (caddr current-data))
  
  ;; Initialisiere Punktliste mit dem Startpunkt
  (setq pt-list (list current-start))
  (setq last-pt current-end)
  
  ;; Durchlaufe die restlichen Linien
  (repeat (1- (length chain))
    (setq found nil)
    
    ;; Finde die nächste verbundene Linie
    (foreach test-ent chain
      (if (and (not (member test-ent used-ents))
               (not found))
        (progn
          (setq next-data (get-line-data test-ent all-lines))
          (setq next-start (cadr next-data))
          (setq next-end (caddr next-data))
          
          ;; Prüfe welcher Endpunkt von test-ent an last-pt anschließt
          (cond
            ;; Fall 1: next-start verbindet sich mit last-pt
            ((equal last-pt next-start 0.0001)
             (setq pt-list (append pt-list (list next-start)))
             (setq last-pt next-end)
             (setq used-ents (cons test-ent used-ents))
             (setq found T)
            )
            ;; Fall 2: next-end verbindet sich mit last-pt
            ((equal last-pt next-end 0.0001)
             (setq pt-list (append pt-list (list next-end)))
             (setq last-pt next-start)
             (setq used-ents (cons test-ent used-ents))
             (setq found T)
            )
          )
        )
      )
    )
  )
  
  ;; Entferne Duplikate (sicherheitshalber)
  (setq pt-list (remove-duplicate-points pt-list))
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")
  
  ;; Färbe die Polylinie mit Farbe 171
  (setq pline-data (entget (entlast)))
  (if (assoc 62 pline-data)
    (setq pline-data (subst (cons 62 171) (assoc 62 pline-data) pline-data))
    (setq pline-data (append pline-data (list (cons 62 171))))
  )
  (entmod pline-data)
  
  ;; Lösche originale Linien
  (foreach line-ent chain
    (entdel line-ent)
  )
)

;; Hilfsfunktion: Entferne doppelte Punkte aus Liste
(defun remove-duplicate-points (pt-list / result)
  (setq result '())
  (foreach pt pt-list
    (if (not (member-point pt result))
      (setq result (append result (list pt)))
    )
  )
  result
)

;; Hilfsfunktion: Prüfe ob Punkt bereits in Liste
(defun member-point (pt pt-list / found)
  (setq found nil)
  (foreach test-pt pt-list
    (if (equal pt test-pt 0.0001)
      (setq found T)
    )
  )
  found
)

(princ "\nJOINPOLY geladen. Tippen Sie 'joinpoly' zum Starten.")
(princ)
