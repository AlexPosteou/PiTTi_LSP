;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; STAB.LSP
;; Kombinierte Funktion:
;;  - Segmentlaenge in [cm] → in TEXT schreiben
;;  - Gesamtlaenge in [m]   → in Attribut LANG
;;                            eines Blocks schreiben
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(princ "STAB.LSP geladen. Befehl: STAB")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun poly_lad (ename / punkte en ed)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (setq punkte '())
  (cond
    ((= (cdr (assoc 0 (entget ename))) "LWPOLYLINE")
      (foreach pair (entget ename)
        (if (= (car pair) 10)
          (setq punkte (append punkte (list (cdr pair))))
        )
      )
    )
    ((= (cdr (assoc 0 (entget ename))) "POLYLINE")
      (setq en (entnext ename))
      (while (and en (= (cdr (assoc 0 (entget en))) "VERTEX"))
        (setq punkte (append punkte (list (cdr (assoc 10 (entget en))))))
        (setq en (entnext en))
      )
    )
  )
  punkte
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun poly_laenge (ename / i punkte laenge p1 p2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (setq punkte (poly_lad ename)
        laenge 0.0
        i      0)
  (while (< i (1- (length punkte)))
    (setq p1 (nth i punkte)
          p2 (nth (1+ i) punkte))
    (setq laenge (+ laenge (distance p1 p2)))
    (setq i (1+ i))
  )
  laenge
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun naechstes_segment (klickpunkt punkte
                          / i p1 p2 dx dy lenq t_param
                            tx ty lotx loty dist
                            best_i best_dist)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  (setq best_i    0
        best_dist 1e99
        i         0)
  (while (< i (1- (length punkte)))
    (setq p1  (nth i punkte)
          p2  (nth (1+ i) punkte)
          dx  (- (car p2)  (car p1))
          dy  (- (cadr p2) (cadr p1))
          lenq (+ (* dx dx) (* dy dy)))
    (if (> lenq 0.0)
      (progn
        (setq t_param (/ (+ (* (- (car klickpunkt)  (car p1)) dx)
                            (* (- (cadr klickpunkt) (cadr p1)) dy))
                         lenq))
        (setq t_param (max 0.0 (min 1.0 t_param)))
        (setq lotx (+ (car p1)  (* t_param dx))
              loty (+ (cadr p1) (* t_param dy)))
        (setq dist (distance klickpunkt (list lotx loty)))
        (if (< dist best_dist)
          (setq best_dist dist
                best_i    i)
        )
      )
    )
    (setq i (1+ i))
  )
  best_i
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun C:STAB ( / se_poly poly_ename klickpunkt
                  punkte seg_idx p1 p2
                  seg_laenge seg_str
                  ges_laenge ges_str
                  se_txt txt_ename txtlst
                  se_blk blk_ename en ed)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; --- 1. Polylinie anklicken ---
  (setq se_poly (entsel "\nPolylinie anklicken..."))
  (if (null se_poly)
    (progn (alert "Nichts gewaehlt!") (exit))
  )
  (setq poly_ename  (car se_poly)
        klickpunkt  (cadr se_poly))

  (if (not (member (cdr (assoc 0 (entget poly_ename)))
                   '("LWPOLYLINE" "POLYLINE")))
    (progn (alert "Gewaeohltes Objekt ist keine Polylinie!") (exit))
  )

  ;; --- 2. Punkte laden ---
  (setq punkte (poly_lad poly_ename))
  (if (< (length punkte) 2)
    (progn (alert "Polylinie hat zu wenige Punkte!") (exit))
  )

  ;; --- 3. Naechstes Segment ermitteln ---
  (setq seg_idx (naechstes_segment klickpunkt punkte))
  (setq p1 (nth seg_idx punkte)
        p2 (nth (1+ seg_idx) punkte))

  ;; --- 4. Segmentlaenge in cm ---
  (setq seg_laenge (* (distance p1 p2) 100.0))  ; in cm umrechnen
  (setq seg_str    (rtos seg_laenge 2 0))       ; keine Nachkommastellen
  (princ (strcat "\nSegmentlaenge = " seg_str " cm"))

  ;; --- 5. Gesamtlaenge in m ---
  (setq ges_laenge (/ (poly_laenge poly_ename) 1.0)) ; in m umrechnen
  (setq ges_str    (rtos ges_laenge 2 2))    ; 2 Nachkommastellen

  (princ (strcat "\nGesamtlaenge  = " ges_str " m"))
  
  ;; --- 6. TEXT anklicken und Segmentlaenge eintragen ---
  ;;        Klick ins Leere = kein Text vorhanden → Schritt überspringen
  (setq se_txt (entsel "\nTEXT fuer Segmentlaenge anklicken (Leerklick = ueberspringen)..."))
  (cond
    ((null se_txt)
      ;; Leerklick → still ignorieren, weiter mit Schritt 7
      (princ "\nKein TEXT gewaehlt – Segmentlaenge wird uebersprungen.")
    )
    ((not (= (cdr (assoc 0 (entget (car se_txt)))) "TEXT"))
      ;; Objekt gewählt, aber falscher Typ → Abbruch wie bisher
      (alert "Gewaeohltes Objekt ist kein TEXT!")
      (exit)
    )
    (T
      ;; Gültiger TEXT → Wert eintragen
      (setq txt_ename (car se_txt))
      (setq txtlst (entget txt_ename))
      (setq txtlst (subst (cons 1 seg_str)
                          (assoc 1 txtlst)
                          txtlst))
      (entmod txtlst)
      (entupd txt_ename)
      (princ (strcat "\nTEXT gesetzt: " seg_str " cm"))
    )
  )

  ;; --- 7. Block anklicken und Attribut LANG setzen ---
  (setq se_blk (entsel "\nBlock RND_AUSZ anklicken..."))
  (if (null se_blk)
    (progn (alert "Nichts gewaehlt!") (exit))
  )
  (setq blk_ename (car se_blk))
  (if (not (= (cdr (assoc 0 (entget blk_ename))) "INSERT"))
    (progn (alert "Gewaeohltes Objekt ist kein Block!") (exit))
  )

  ;; Attribute des Blocks durchsuchen
  (setq en (entnext blk_ename))
  (while (and en (= (cdr (assoc 0 (entget en))) "ATTRIB"))
    (setq ed (entget en))
    (if (= (strcase (cdr (assoc 2 ed))) "LANG")
      (progn
        (setq ed (subst (cons 1 ges_str)
                        (assoc 1 ed)
                        ed))
        (entmod ed)
        (entupd en)
        (princ (strcat "\nAttribut LANG gesetzt: " ges_str " m"))
      )
    )
    (setq en (entnext en))
  )

  (princ "\nFertig.")
  (princ)
)

(princ)
