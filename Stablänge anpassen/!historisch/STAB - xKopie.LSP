;;; ─────────────────────────────────────────────────────────────
;;; STAB.LSP  –  Segment-Länge aus Polylinie → TEXT + Block-Attr
;;; Unterstützt: LWPOLYLINE und POLYLINE
;;; ─────────────────────────────────────────────────────────────

(defun pt2d ( p )
  (list (car p) (cadr p))
)

;; Hilfsfunktion: Stützpunkte aus alter POLYLINE lesen
(defun poly_lad ( ename / verts ent edata vflags )
  (setq verts '()
        ent   (entnext ename))
  (while (and ent
              (equal (cdr (assoc 0 (entget ent))) "VERTEX"))
    (setq edata  (entget ent)
          vflags (cdr (assoc 70 edata)))
    (if (null vflags) (setq vflags 0))
    (if (= (logand vflags 16) 0)
      (setq verts (append verts
                    (list (cdr (assoc 10 edata)))))
    )
    (setq ent (entnext ent))
  )
  verts
)

;; Hilfsfunktion: 2D-Abstand zwischen zwei Punkten
(defun dist2d ( p1 p2 )
  (sqrt (+ (expt (- (car p2) (car p1)) 2)
           (expt (- (cadr p2) (cadr p1)) 2)))
)

;; Hauptfunktion
(defun C:STAB ( / ent_pl_res ent_pl pick_pt pl_data pl_type
                  verts n i
                  p1 p2 mid_pt seg_angle seg_len total_len
                  min_dist seg_idx
                  ent_txt_res ent_txt txt_data txt_pt
                  new_pt new_val total_val
                  ent_blk_res ent_blk att att_data )

  ;; ─────────────────────────────────────────
  ;; 1. POLYLINIE auswählen
  ;; ─────────────────────────────────────────
  (setq ent_pl_res (entsel "\nPolylinie anklicken: "))
  (if (null ent_pl_res)
    (progn (prompt "\nAbbruch.") (exit))
  )
  (setq ent_pl  (car ent_pl_res)
        pick_pt (cadr ent_pl_res)
        pl_data (entget ent_pl)
        pl_type (cdr (assoc 0 pl_data))
  )

  ;; Typ prüfen
  (if (not (member pl_type '("LWPOLYLINE" "POLYLINE")))
    (progn (prompt "\nKein Polylinien-Objekt gewaehlt!") (exit))
  )

  ;; ─────────────────────────────────────────
  ;; 2. Stützpunkte sammeln
  ;; ─────────────────────────────────────────
  (if (equal pl_type "LWPOLYLINE")
    (progn
      (setq verts '())
      (foreach pair pl_data
        (if (= (car pair) 10)
          (setq verts (append verts (list (cdr pair))))
        )
      )
    )
    (setq verts (poly_lad ent_pl))
  )

  (setq n (length verts))
  (if (< n 2)
    (progn (prompt "\nZu wenige Stuetzpunkte!") (exit))
  )

  ;; ─────────────────────────────────────────
  ;; 3. Nächstes Segment zum Klickpunkt finden
  ;;    (nur horizontale / vertikale Segmente)
  ;; ─────────────────────────────────────────
  (setq min_dist 1e38
        seg_idx  0
        i        0)

  (while (< i (1- n))
     (setq p1 (pt2d (nth i verts))
           p2 (pt2d (nth (1+ i) verts))
     )

    ;; Mittelpunkt des Segments
    (setq mid_pt (list (/ (+ (car p1) (car p2)) 2.0)
                   (/ (+ (cadr p1) (cadr p2)) 2.0)))

    ;; Winkel des Segments
    (setq seg_angle (angle p1 p2))

    ;; Nur orthogonale Segmente berücksichtigen
    (if (or (< (abs (sin seg_angle)) 0.1)   ; horizontal
            (< (abs (cos seg_angle)) 0.1))  ; vertikal
      (progn
        (setq d (dist2d (list (car pick_pt) (cadr pick_pt))
                        (list (car mid_pt)  (cadr mid_pt))))
        (if (< d min_dist)
          (setq min_dist d
                seg_idx  i)
        )
      )
    )
    (setq i (1+ i))
  )

  ;; Gewähltes Segment
  (setq p1      (nth seg_idx verts)
        p2      (nth (1+ seg_idx) verts)
        seg_len (dist2d p1 p2)
        mid_pt  (list (/ (+ (car p1) (car p2)) 2.0)
                      (/ (+ (cadr p1) (cadr p2)) 2.0)
                      0.0)
        seg_angle (angle p1 p2)
  )

  
  ;; ─────────────────────────────────────────
  ;; 4. Gesamtlänge aller Segmente berechnen
  ;; ─────────────────────────────────────────
  (setq total_len 0.0
        i         0)
  (while (< i (1- n))
    (setq total_len (+ total_len
                       (dist2d (nth i verts) (nth (1+ i) verts))))
    (setq i (1+ i))
  )

  ;; ─────────────────────────────────────────
  ;; 5. TEXT auswählen
  ;; ─────────────────────────────────────────
  (setq ent_txt_res (entsel "\nText anklicken: "))
  (if (null ent_txt_res)
    (progn (prompt "\nAbbruch.") (exit))
  )
  (setq ent_txt  (car ent_txt_res)
        txt_data (entget ent_txt)
  )

  (if (not (equal (cdr (assoc 0 txt_data)) "TEXT"))
    (progn (prompt "\nKein TEXT-Objekt gewaehlt!") (exit))
  )

  ;; ─────────────────────────────────────────
  ;; 6. Neuen Einfügepunkt berechnen
  ;;    Horizontal → Y vom Text behalten, X = Mittelpunkt
  ;;    Vertikal   → X vom Text behalten, Y = Mittelpunkt
  ;; ─────────────────────────────────────────
  (setq txt_pt (cdr (assoc 10 txt_data)))

  (if (< (abs (sin seg_angle)) 0.1)
    ;; Horizontales Segment → X anpassen
    (setq new_pt (list (car mid_pt)
                       (cadr txt_pt)
                       (caddr txt_pt)))
    ;; Vertikales Segment → Y anpassen
    (setq new_pt (list (car txt_pt)
                       (cadr mid_pt)
                       (caddr txt_pt)))
  )

  ;; ─────────────────────────────────────────
  ;; 7. TEXT aktualisieren (Wert + Position)
  ;; ─────────────────────────────────────────
  (setq new_val (rtos (* seg_len 100.0) 2 0))

  (setq txt_data (subst (cons 10 new_pt)
                        (assoc 10 txt_data)
                        txt_data))
  (setq txt_data (subst (cons 1 new_val)
                        (assoc 1 txt_data)
                        txt_data))
  (entmod txt_data)
  (entupd ent_txt)

  ;; ─────────────────────────────────────────
  ;; 8. BLOCK auswählen + Attribut LANG setzen
  ;; ─────────────────────────────────────────
  (setq ent_blk_res (entsel "\nBlock anklicken: "))
  (if (null ent_blk_res)
    (progn (prompt "\nAbbruch.") (exit))
  )
  (setq ent_blk   (car ent_blk_res)
      total_val (rtos total_len 2 2))

  (setq att (entnext ent_blk))
  (while (and att
              (equal (cdr (assoc 0 (entget att))) "ATTRIB"))
    (setq att_data (entget att))
    (if (equal (strcase (cdr (assoc 2 att_data))) "LANG")
      (progn
        (setq att_data (subst (cons 1 total_val)
                              (assoc 1 att_data)
                              att_data))
        (entmod att_data)
        (entupd att)
      )
    )
    (setq att (entnext att))
  )

  ;; ─────────────────────────────────────────
  ;; 9. Rückmeldung
  ;; ─────────────────────────────────────────
  ;; NEU (wenn Segment in cm, Gesamt in m):
  (prompt (strcat "\nFertig!"
                  "  Segment: " new_val " cm"
                  "  |  Gesamt: " total_val " m"))
  (princ)
)
