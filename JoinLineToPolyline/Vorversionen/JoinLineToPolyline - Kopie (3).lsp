;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein
;; Version 2.0 - Funktioniert unabhängig von der Zeichenreihenfolge

(defun c:joinpoly (/ ss i ent entlist all-lines processed-lines closed-chains count)
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
      
      ;; Alle Linien in eine Liste einlesen
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq entlist (entget ent))
        (setq all-lines (cons (list ent 
                                    (cdr (assoc 10 entlist))  ; Startpunkt
                                    (cdr (assoc 11 entlist))  ; Endpunkt
                              ) all-lines))
        (setq i (1+ i))
      )
      
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
      
      (princ (strcat "\n" (itoa count) " geschlossene Polylinie(n) wurden erstellt."))
    )
    (princ "\nKeine Linien ausgewählt.")
  )
  (princ)
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
                                    sorted-chain current-ent pt-list next-ent 
                                    current-end found entlist pline-data)
  
  ;; Sortiere die Kette in richtiger Reihenfolge
  (setq sorted-chain (list (car chain)))
  (setq current-ent (car chain))
  
  (repeat (1- (length chain))
    (setq current-data (get-line-data current-ent all-lines))
    (setq current-start (cadr current-data))
    (setq current-end (caddr current-data))
    
    ;; Bestimme welcher Endpunkt als nächstes verwendet wird
    (if (= (length sorted-chain) 1)
      (setq search-pt current-end)
      (setq search-pt current-end)
    )
    
    ;; Finde nächste verbundene Linie
    (setq found nil)
    (foreach test-ent chain
      (if (and (not (member test-ent sorted-chain))
               (not found))
        (progn
          (setq test-data (get-line-data test-ent all-lines))
          (setq test-start (cadr test-data))
          (setq test-end (caddr test-data))
          
          (if (or (equal current-end test-start 0.0001)
                  (equal current-end test-end 0.0001))
            (progn
              (setq sorted-chain (append sorted-chain (list test-ent)))
              (setq current-ent test-ent)
              (setq found T)
            )
          )
          
          (if (and (not found)
                   (or (equal current-start test-start 0.0001)
                       (equal current-start test-end 0.0001)))
            (progn
              (setq sorted-chain (append sorted-chain (list test-ent)))
              (setq current-ent test-ent)
              (setq found T)
            )
          )
        )
      )
    )
  )
  
  ;; Sammle Punkte in richtiger Reihenfolge
  (setq pt-list '())
  (setq current-ent (car sorted-chain))
  (setq current-data (get-line-data current-ent all-lines))
  (setq pt-list (list (cadr current-data)))
  (setq last-pt (cadr current-data))
  
  (foreach line-ent sorted-chain
    (setq line-data (get-line-data line-ent all-lines))
    (setq start-pt (cadr line-data))
    (setq end-pt (caddr line-data))
    
    (if (equal last-pt start-pt 0.0001)
      (progn
        (setq pt-list (append pt-list (list end-pt)))
        (setq last-pt end-pt)
      )
      (progn
        (setq pt-list (append pt-list (list start-pt)))
        (setq last-pt start-pt)
      )
    )
  )
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")
  
  ;; Färbe die Polylinie mit Farbe 171
  (setq pline-data (entget (entlast)))
  (setq pline-data (subst (cons 62 171) (assoc 62 pline-data) pline-data))
  (if (not (assoc 62 pline-data))
    (setq pline-data (append pline-data (list (cons 62 171))))
  )
  (entmod pline-data)
  
  ;; Lösche originale Linien
  (foreach line-ent chain
    (entdel line-ent)
  )
)

(princ "\nJOINPOLY geladen. Tippen Sie 'joinpoly' zum Starten.")
(princ)
