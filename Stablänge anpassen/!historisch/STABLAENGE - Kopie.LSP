;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; STABLAENGE.LSP
;; Ermittelt die Gesamtlaenge einer Polylinie in [m]
;; und traegt den Wert optional in Attribut LANG
;; eines Blocks RND_AUSZ ein.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(princ "STABLAENGE.LSP geladen.  Befehle: STABL  STABLT")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun poly_laenge (ename / i ii punkte laenge p1 p2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Berechnet die Gesamtlaenge einer 2D-Polylinie
;; ueber alle Stuetzpunkte.
;;
  (setq punkte (poly_lad ename))
  (setq laenge 0.0
        i      0
        ii     (length punkte))
  (while (< i (- ii 1))
    (setq p1 (nth i punkte)
          p2 (nth (+ i 1) punkte))
    (setq laenge (+ laenge (distance p1 p2)))
    (setq i (+ i 1))
  )
  laenge
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun C:STABL ( / se ename objname laenge_m laenge_str
                   se_blk blk_ename attlst att val)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
  (setvar "cmdecho" 0)

  ;; --- Polylinie waehlen ---
  (setq se (entsel "\nPolylinie waehlen..."))
  (if (null se)
    (progn (alert "Nichts gewaehlt!") (exit))
  )

  (setq ename   (car se))
  (setq objname (cdr (assoc 0 (entget ename))))

  ;; --- Nur LWPOLYLINE oder POLYLINE erlaubt ---
  (if (not (or (= objname "LWPOLYLINE")
               (= objname "POLYLINE")))
    (progn (alert "Gewaeohltes Objekt ist keine Polylinie!") (exit))
  )

  ;; --- Laenge berechnen ---
  (if (= objname "LWPOLYLINE")
    (setq laenge_m
      (/ (vla-get-Length (vlax-ename->vla-object ename)) 1.0))   ; ← Faktor 1.0 weil Plan in [m] gezeichnet
    (setq laenge_m
      (/ (poly_laenge ename) 1.0))                               ; ← Faktor 1.0 weil Plan in [m] gezeichnet
  )

  ;; --- Anzeige ---
  (setq laenge_str (rtos laenge_m 2 2))
  (princ (strcat "\nGesamtlaenge = " laenge_str " m"))

  ;; --- Block RND_AUSZ waehlen und Attribut LANG setzen ---
  (setq se_blk (entsel "\nBlock RND_AUSZ waehlen..."))

  (if se_blk (progn
    (setq blk_ename (car se_blk))

    ;; Pruefen ob es ein INSERT (Block) ist
    (if (not (= (cdr (assoc 0 (entget blk_ename))) "INSERT"))
      (progn (alert "Gewaeohltes Objekt ist kein Block!") (exit))
    )

    ;; Pruefen ob Blockname RND_AUSZ
    (if (not (= (cdr (assoc 2 (entget blk_ename))) "RND_AUSZ"))
      (progn (alert "Block ist nicht vom Typ RND_AUSZ!") (exit))
    )

    ;; Attribute durchsuchen und LANG finden
    (setq att (entnext blk_ename))
    (while (and att (= (cdr (assoc 0 (entget att))) "ATTRIB"))
      (if (= (cdr (assoc 2 (entget att))) "LANG")
        (progn
          ;; Attributwert setzen
          (setq attlst (entget att))
          (setq attlst (subst
                         (cons 1 laenge_str)
                         (assoc 1 attlst)
                         attlst))
          (entmod attlst)
          (entupd blk_ename)
          (princ (strcat "\nAttribut LANG gesetzt: " laenge_str " m"))
        )
      )
      (setq att (entnext att))
    )
  ))

  (princ)
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun C:STABLT ( / se ename objname klickpunkt punkte
                    seg laenge_cm laenge_str
                    se_txt txt_ename txtlst)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Segment einer Polylinie anklicken,
;; Laenge in [cm] ermitteln,
;; bestehenden TEXT-Wert ersetzen.
;;
  (setvar "cmdecho" 0)

  ;; --- Polylinie waehlen ---
  (setq se (entsel "\nPolylinie - Segment anklicken..."))
  (if (null se)
    (progn (alert "Nichts gewaehlt!") (exit))
  )

  (setq ename      (car se)
        klickpunkt (cadr se)
        objname    (cdr (assoc 0 (entget ename))))

  ;; --- Nur LWPOLYLINE oder POLYLINE erlaubt ---
  (if (not (or (= objname "LWPOLYLINE")
               (= objname "POLYLINE")))
    (progn (alert "Gewaeohltes Objekt ist keine Polylinie!") (exit))
  )

  ;; --- Stuetzpunkte laden ---
  (setq punkte (poly_lad ename))

  (if (< (length punkte) 2)
    (progn (alert "Polylinie hat zu wenige Punkte!") (exit))
  )

  ;; --- Naechstes Segment zum Klickpunkt finden ---
  (setq seg (naechstes_segment punkte klickpunkt))

  ;; --- Segmentlaenge berechnen und in cm umrechnen ---
  (setq laenge_cm  (* (distance (car seg) (cadr seg)) 100.0))
  (setq laenge_str (rtos laenge_cm 2 2))

  (princ (strcat "\nSegmentlaenge = " laenge_str " cm"))

  ;; --- TEXT-Objekt waehlen ---
  (setq se_txt (entsel "\nZu ersetzenden TEXT anklicken..."))
  (if (null se_txt)
    (progn (alert "Nichts gewaehlt!") (exit))
  )

  (setq txt_ename (car se_txt))

  ;; --- Pruefen ob TEXT ---
  (if (not (= (cdr (assoc 0 (entget txt_ename))) "TEXT"))
    (progn (alert "Gewaeohltes Objekt ist kein TEXT!") (exit))
  )

  ;; --- Textwert ersetzen ---
  (setq txtlst (entget txt_ename))
  (setq txtlst (subst
                 (cons 1 laenge_str)
                 (assoc 1 txtlst)
                 txtlst))
  (entmod txtlst)
  (entupd txt_ename)

  (princ (strcat "\nTEXT ersetzt durch: " laenge_str " cm"))
  (princ)
)