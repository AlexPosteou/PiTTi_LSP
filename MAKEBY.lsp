;; MAKEBY.LSP - Layer-Eigenschaften-Utility
;; Autor: Claude AI
;; Datum: 2025-08-04
;; 
;; Funktionen:
;; MKLY    - Setzt Farbe und Linientyp auf "Von Layer"
;; MKBL    - Setzt Farbe und Linientyp auf "Von Block" und verschiebt auf Layer 0
;; MKLYALL - Setzt alle Objekte eines Layers auf "Von Layer" (mit Bestätigung)

;; =================================================================
;; Funktion 1: MKLY - Eigenschaften auf "Von Layer" setzen
;; =================================================================
(defun c:mkly (/ ss i ent)
  (princ "\nObjekte für 'Von Layer' wählen...")
  (if (setq ss (ssget))
    (progn
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (if ent
          (progn
            ;; Farbe auf "Von Layer" (256)
            (entmod (subst (cons 62 256) 
                          (assoc 62 (entget ent)) 
                          (entget ent)))
            ;; Linientyp auf "Von Layer" ("BYLAYER")
            (entmod (subst (cons 6 "BYLAYER") 
                          (assoc 6 (entget ent)) 
                          (entget ent)))
          )
        )
        (setq i (1+ i))
      )
      (princ (strcat "\n" (itoa (sslength ss)) " Objekt(e) auf 'Von Layer' gesetzt."))
    )
    (princ "\nKeine Objekte gewählt.")
  )
  (princ)
)

;; =================================================================
;; Funktion 2: MKBL - Eigenschaften auf "Von Block" setzen
;; =================================================================
(defun c:mkbl (/ ss i ent layer0)
  (princ "\nObjekte für 'Von Block' wählen...")
  
  ;; Layer 0 vorbereiten (einschalten und tauen)
  (setq layer0 (tblobjname "LAYER" "0"))
  (if layer0
    (progn
      (entmod (subst (cons 62 7) (assoc 62 (entget layer0)) (entget layer0))) ; Farbe weiß
      (entmod (subst (cons 70 0) (assoc 70 (entget layer0)) (entget layer0))) ; Eingeschaltet und getaut
    )
  )
  
  (if (setq ss (ssget))
    (progn
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (if ent
          (progn
            ;; Auf Layer 0 verschieben
            (entmod (subst (cons 8 "0") 
                          (assoc 8 (entget ent)) 
                          (entget ent)))
            ;; Farbe auf "Von Block" (0)
            (entmod (subst (cons 62 0) 
                          (assoc 62 (entget ent)) 
                          (entget ent)))
            ;; Linientyp auf "Von Block" ("BYBLOCK")
            (entmod (subst (cons 6 "BYBLOCK") 
                          (assoc 6 (entget ent)) 
                          (entget ent)))
          )
        )
        (setq i (1+ i))
      )
      (princ (strcat "\n" (itoa (sslength ss)) " Objekt(e) auf Layer 0 verschoben und auf 'Von Block' gesetzt."))
    )
    (princ "\nKeine Objekte gewählt.")
  )
  (princ)
)

;; =================================================================
;; Funktion 3: MKLYALL - Alle Objekte eines Layers auf "Von Layer"
;; =================================================================
(defun c:mklyall (/ ent layername ss i answer)
  (princ "\nObjekt auf dem zu bearbeitenden Layer wählen...")
  
  (if (setq ent (car (entsel)))
    (progn
      (setq layername (cdr (assoc 8 (entget ent))))
      (princ (strcat "\nGewählter Layer: " layername))
      (princ (strcat "\nAlle Objekte auf Layer '" layername "' auf 'Von Layer' setzen?"))
      (setq answer (getstring "\n[Y/N] <N>: "))
      
      (if (or (= (strcase answer) "Y") (= (strcase answer) "YES"))
        (progn
          ;; Alle Objekte des Layers auswählen
          (setq ss (ssget "X" (list (cons 8 layername))))
          (if ss
            (progn
              (setq i 0)
              (repeat (sslength ss)
                (setq ent (ssname ss i))
                (if ent
                  (progn
                    ;; Farbe auf "Von Layer" (256)
                    (entmod (subst (cons 62 256) 
                                  (assoc 62 (entget ent)) 
                                  (entget ent)))
                    ;; Linientyp auf "Von Layer" ("BYLAYER")
                    (entmod (subst (cons 6 "BYLAYER") 
                                  (assoc 6 (entget ent)) 
                                  (entget ent)))
                  )
                )
                (setq i (1+ i))
              )
              (princ (strcat "\n" (itoa (sslength ss)) " Objekt(e) auf Layer '" layername "' wurden auf 'Von Layer' gesetzt."))
            )
            (princ (strcat "\nKeine Objekte auf Layer '" layername "' gefunden."))
          )
        )
        (princ "\nVorgang abgebrochen.")
      )
    )
    (princ "\nKein Objekt gewählt.")
  )
  (princ)
)

;; =================================================================
;; Hilfsmeldung beim Laden
;; =================================================================
(princ "\n*** MAKEBY.LSP geladen ***")
(princ "\nVerfügbare Befehle:")
(princ "\n  MKLY    - Farbe und Linientyp auf 'Von Layer'")
(princ "\n  MKBL    - Farbe und Linientyp auf 'Von Block', auf Layer 0")
(princ "\n  MKLYALL - Alle Objekte eines Layers auf 'Von Layer' (mit Bestätigung)")
(princ "\n")