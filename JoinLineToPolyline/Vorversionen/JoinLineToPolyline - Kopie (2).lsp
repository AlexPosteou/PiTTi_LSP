;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein

(defun c:joinpoly (/ ss i ent entlist processed-lines all-lines)
  (princ "\nJOINPOLY - Verbindet Linien zu geschlossenen Polylinien")
  (princ "\n========================================================")
  
  ;; Objekte auswählen
  (setq ss (ssget '((0 . "LINE"))))
  
  (if ss
    (progn
      (princ (strcat "\n" (itoa (sslength ss)) " Linien gefunden."))
      (setq all-lines '())
      (setq processed-lines '())
      
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
            (setq chain (build-chain (car line-data) all-lines processed-lines))
            (if (> (length chain) 1)
              (progn
                ;; Prüfen ob geschlossen
                (if (is-closed chain)
                  (progn
                    ;; Polylinie erstellen
                    (create-polyline-from-chain chain)
                    ;; Markiere alle verarbeiteten Linien
                    (foreach line-ent chain
                      (setq processed-lines (cons line-ent processed-lines))
                    )
                  )
                )
              )
            )
          )
        )
      )
      
      (princ "\nFertig! Geschlossene Polylinien wurden erstellt.")
    )
    (princ "\nKeine Linien ausgewählt.")
  )
  (princ)
)

;; Funktion: Baue Kette von verbundenen Linien
(defun build-chain (start-ent all-lines processed / chain current-ent found pt-start pt-end)
  (setq chain (list start-ent))
  (setq current-ent start-ent)
  (setq found T)
  
  (while found
    (setq found nil)
    (setq pt-end (get-endpoint current-ent))
    
    (foreach line-data all-lines
      (if (and (not (member (car line-data) chain))
               (not (member (car line-data) processed)))
        (progn
          (setq test-ent (car line-data))
          (setq test-start (cadr line-data))
          (setq test-end (caddr line-data))
          
          ;; Prüfe ob Endpunkt mit Start- oder Endpunkt der Testlinie übereinstimmt
          (if (or (equal pt-end test-start 0.0001)
                  (equal pt-end test-end 0.0001))
            (progn
              (setq chain (append chain (list test-ent)))
              (setq current-ent test-ent)
              (setq found T)
            )
          )
        )
      )
    )
  )
  chain
)

;; Funktion: Hole Endpunkt einer Linie
(defun get-endpoint (ent / entlist)
  (setq entlist (entget ent))
  (cdr (assoc 11 entlist))
)

;; Funktion: Prüfe ob Kette geschlossen ist
(defun is-closed (chain / first-start last-end)
  (if (> (length chain) 2)
    (progn
      (setq first-start (cdr (assoc 10 (entget (car chain)))))
      (setq last-end (cdr (assoc 11 (entget (last chain)))))
      (equal first-start last-end 0.0001)
    )
    nil
  )
)

;; Funktion: Erstelle Polylinie aus Kette und färbe sie
(defun create-polyline-from-chain (chain / pt-list ent entlist pt pline-data)
  (setq pt-list '())
  
  ;; Sammle alle Punkte
  (foreach line-ent chain
    (setq entlist (entget line-ent))
    (setq pt (cdr (assoc 10 entlist)))
    (setq pt-list (append pt-list (list pt)))
  )
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")  ; Schließen
  
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
