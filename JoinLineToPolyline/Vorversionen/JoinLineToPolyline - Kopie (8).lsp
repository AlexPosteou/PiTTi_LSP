;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein
;; Version 3.2 - Layer wird gefroren + Linien aus Liste entfernt

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
          
          ;; Layer "0_kurze Linie" erstellen falls nicht vorhanden und einfrieren
          (create-and-freeze-layer "0_kurze Linie")
          
          ;; Finde alle übereinanderliegenden Linien
          (setq all-lines (find-and-remove-overlapping-lines all-lines))
          
          (if (> dup-count 0)
            (princ (strcat "\n  " (itoa dup-count) " kürzere, übereinanderliegende Linie(n) auf gefrorenen Layer '0_kurze Linie' verschoben."))
          )
        )
      )
      
      ;; SCHRITT 4: Verbinde Linien zu geschlossenen Polylinien
      (if all-lines
        (progn
          (princ "\nSchritt 4: Verbinde Linien zu Polylinien...")
          (princ (strcat "\n  " (itoa (length all-lines)) " Linien werden verarbeitet."))
          
          ;; Verarbeite alle Linien
          (foreach line-data all-lines
            (if (not (member (car line-data) processed-lines))
              (progn
                (setq chain (build-chain (car line-data) all-lines))
                (if (is-closed-chain chain all-lines)
                  (progn
                    (create-polyline-from-chain chain all-lines)
                    (setq count (1+ count))
                    (setq closed-chains (cons chain closed-chains))
                  )
                )
              )
            )
          )
          
          (princ (strcat "\n" (itoa count) " geschlossene Polylinie(n) wurden erstellt."))
        )
        (princ "\nKeine Linien zum Verarbeiten übrig.")
      )
      
      (princ "\n========================================================")
    )
    (princ "\nKeine Objekte ausgewählt.")
  )
  (princ)
)

;; Hilfsfunktion: Normalisiere Z-Koordinate auf 0
(defun normalize-z-coordinate (ent / entlist pt-start pt-end)
  (setq entlist (entget ent))
  (setq pt-start (cdr (assoc 10 entlist)))
  (setq pt-end (cdr (assoc 11 entlist)))
  
  ;; Setze Z auf 0.0
  (setq pt-start (list (car pt-start) (cadr pt-start) 0.0))
  (setq pt-end (list (car pt-end) (cadr pt-end) 0.0))
  
  ;; Update Entity
  (setq entlist (subst (cons 10 pt-start) (assoc 10 entlist) entlist))
  (setq entlist (subst (cons 11 pt-end) (assoc 11 entlist) entlist))
  (entmod entlist)
)

;; Hilfsfunktion: Layer erstellen und einfrieren
(defun create-and-freeze-layer (layer-name / layer-table layer-entry)
  (setq layer-table (tblsearch "LAYER" layer-name))
  
  (if (not layer-table)
    (progn
      ;; Layer existiert nicht - erstellen
      (command "._-LAYER" "_M" layer-name "_C" "7" layer-name "_F" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde erstellt und gefroren."))
    )
    (progn
      ;; Layer existiert - nur einfrieren
      (command "._-LAYER" "_F" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde gefroren."))
    )
  )
)

;; Hilfsfunktion: Prüfe ob Punkt auf Linie liegt
(defun point-on-line (pt p1 p2 / tol)
  (setq tol 0.0001)
  ;; Prüfe ob Punkt zwischen p1 und p2 liegt
  (and
    ;; Punkt liegt auf der Geraden (Kreuzprodukt = 0)
    (< (abs (- (* (- (car pt) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr pt) (cadr p1)) (- (car p2) (car p1))))) tol)
    ;; Punkt liegt zwischen p1 und p2
    (or
      (and (<= (car p1) (car pt) (car p2)) (<= (cadr p1) (cadr pt) (cadr p2)))
      (and (<= (car p2) (car pt) (car p1)) (<= (cadr p2) (cadr pt) (cadr p1)))
      (and (<= (car p1) (car pt) (car p2)) (<= (cadr p2) (cadr pt) (cadr p1)))
      (and (<= (car p2) (car pt) (car p1)) (<= (cadr p1) (cadr pt) (cadr p2)))
    )
  )
)

;; Hilfsfunktion: Prüfe ob zwei Linien kollinear sind (auf derselben Geraden liegen)
(defun lines-collinear (p1 p2 p3 p4 / tol)
  (setq tol 0.0001)
  ;; Alle 4 Punkte müssen auf derselben Geraden liegen
  (and
    (< (abs (- (* (- (car p3) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr p3) (cadr p1)) (- (car p2) (car p1))))) tol)
    (< (abs (- (* (- (car p4) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr p4) (cadr p1)) (- (car p2) (car p1))))) tol)
  )
)

;; Hilfsfunktion: Finde überlappende Linien und entferne kürzere aus Liste
(defun find-and-remove-overlapping-lines (line-list / i j current-data test-data result removed)
  (setq result line-list)
  (setq removed '())
  (setq dup-count 0)
  
  (setq i 0)
  (while (< i (length result))
    (setq current-data (nth i result))
    (setq current-ent (car current-data))
    (setq current-p1 (cadr current-data))
    (setq current-p2 (caddr current-data))
    (setq current-len (cadddr current-data))
    
    (setq j (1+ i))
    (while (< j (length result))
      (setq test-data (nth j result))
      (setq test-ent (car test-data))
      (setq test-p1 (cadr test-data))
      (setq test-p2 (caddr test-data))
      (setq test-len (cadddr test-data))
      
      ;; Prüfe ob Linien kollinear sind und sich überlappen
      (if (and (lines-collinear current-p1 current-p2 test-p1 test-p2)
               (or (point-on-line test-p1 current-p1 current-p2)
                   (point-on-line test-p2 current-p1 current-p2)
                   (point-on-line current-p1 test-p1 test-p2)
                   (point-on-line current-p2 test-p1 test-p2)))
        (progn
          ;; Linien überlappen - kürzere auf Layer verschieben
          (if (< test-len current-len)
            (progn
              ;; test-Linie ist kürzer
              (move-to-layer test-ent "0_kurze Linie")
              (setq result (remove-nth j result))
              (setq removed (cons test-ent removed))
              (setq dup-count (1+ dup-count))
              (setq j (1- j))  ;; Index korrigieren da Element entfernt wurde
            )
            (progn
              ;; current-Linie ist kürzer oder gleich lang
              (move-to-layer current-ent "0_kurze Linie")
              (setq result (remove-nth i result))
              (setq removed (cons current-ent removed))
              (setq dup-count (1+ dup-count))
              (setq i (1- i))  ;; Index korrigieren und äußere Schleife neu starten
              (setq j (length result))  ;; Innere Schleife beenden
            )
          )
        )
      )
      (setq j (1+ j))
    )
    (setq i (1+ i))
  )
  
  result
)

;; Hilfsfunktion: Entferne n-tes Element aus Liste
(defun remove-nth (n lst / i result)
  (setq i 0)
  (setq result '())
  (foreach item lst
    (if (/= i n)
      (setq result (append result (list item)))
    )
    (setq i (1+ i))
  )
  result
)

;; Hilfsfunktion: Verschiebe Linie auf anderen Layer
(defun move-to-layer (ent layer-name / entlist)
  (setq entlist (entget ent))
  (setq entlist (subst (cons 8 layer-name) (assoc 8 entlist) entlist))
  (entmod entlist)
)

;; Hilfsfunktion: Hole Linien-Daten aus Liste
(defun get-line-data (ent line-list / result)
  (setq result nil)
  (foreach line-data line-list
    (if (equal (car line-data) ent)
      (setq result line-data)
    )
  )
  result
)

;; Hilfsfunktion: Baue Linienkette von Startpunkt aus
(defun build-chain (start-ent all-lines / chain last-pt found test-ent used-ents start-data)
  (setq chain (list start-ent))
  (setq used-ents (list start-ent))
  (setq processed-lines (cons start-ent processed-lines))
  
  ;; Hole Start- und Endpunkt der ersten Linie
  (setq start-data (get-line-data start-ent all-lines))
  (setq last-pt (caddr start-data))  ;; Beginne am Endpunkt
  
  ;; Suche weitere anschließende Linien
  (setq found T)
  (while found
    (setq found nil)
    (foreach line-data all-lines
      (if (not found)
        (progn
          (setq test-ent (car line-data))
          (if (and (not (member test-ent used-ents))
                   (not (member test-ent processed-lines)))
            (progn
              (setq next-data (get-line-data test-ent all-lines))
              (setq next-start (cadr next-data))
              (setq next-end (caddr next-data))
              
              ;; Prüfe welcher Endpunkt von test-ent an last-pt anschließt
              (cond
                ;; Fall 1: next-start verbindet sich mit last-pt
                ((equal last-pt next-start 0.0001)
                 (setq chain (append chain (list test-ent)))
                 (setq last-pt next-end)
                 (setq used-ents (cons test-ent used-ents))
                 (setq processed-lines (cons test-ent processed-lines))
                 (setq found T)
                )
                ;; Fall 2: next-end verbindet sich mit last-pt
                ((equal last-pt next-end 0.0001)
                 (setq chain (append chain (list test-ent)))
                 (setq last-pt next-start)
                 (setq used-ents (cons test-ent used-ents))
                 (setq processed-lines (cons test-ent processed-lines))
                 (setq found T)
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

;; Hilfsfunktion: Prüfe ob Kette geschlossen ist
(defun is-closed-chain (chain all-lines / first-data last-data first-start last-end)
  (if (>= (length chain) 3)
    (progn
      (setq first-data (get-line-data (car chain) all-lines))
      (setq last-data (get-line-data (last chain) all-lines))
      (setq first-start (cadr first-data))
      (setq last-end (caddr last-data))
      
      ;; Prüfe ob letzte und erste Linie sich verbinden
      (or
        (equal first-start last-end 0.0001)
        (equal first-start (cadr last-data) 0.0001)
      )
    )
    nil
  )
)

;; Hilfsfunktion: Erstelle Polylinie aus Linienkette
(defun create-polyline-from-chain (chain all-lines / pt-list last-pt first-data)
  (setq pt-list '())
  
  ;; Starte mit der ersten Linie
  (setq first-data (get-line-data (car chain) all-lines))
  (setq pt-list (list (cadr first-data) (caddr first-data)))
  (setq last-pt (caddr first-data))
  
  ;; Füge alle weiteren Punkte hinzu
  (foreach line-ent (cdr chain)
    (setq next-data (get-line-data line-ent all-lines))
    (setq next-start (cadr next-data))
    (setq next-end (caddr next-data))
    
    (cond
      ((equal last-pt next-start 0.0001)
       (setq pt-list (append pt-list (list next-end)))
       (setq last-pt next-end)
      )
      ((equal last-pt next-end 0.0001)
       (setq pt-list (append pt-list (list next-start)))
       (setq last-pt next-start)
      )
    )
  )
  
  ;; Entferne Duplikate
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
