;;; ============================================================
;;; ISPARAL.LSP
;;; Prueft ob zwei Objekte (LINE / LWPOLYLINE / POLYLINE)
;;; exakt parallel verlaufen
;;; Aufruf: ISPARAL
;;; ============================================================

(defun isparal ( / obj1 obj2 ent1 ent2 dirs1 dirs2)

  ;; --- Normierung eines 2D-Vektors ---
  (defun normalize-vec (v / len)
    (setq len (sqrt (+ (* (car v) (car v))
                       (* (cadr v) (cadr v)))))
    (if (> len 1e-10)
      (list (/ (car v) len)
            (/ (cadr v) len))
      nil
    )
  )

  ;; --- Kreuzprodukt Z-Komponente (2D) ---
  (defun cross2d (a b)
    (- (* (car a) (cadr b))
       (* (cadr a) (car b)))
  )

  ;; --- Zwei normierte Vektoren parallel? ---
  (defun vecs-parallel? (a b)
    (< (abs (cross2d a b)) 1e-8)
  )

  ;; --- Richtungsvektoren aus LINE ---
  (defun dirs-from-line (ent / dxf p1 p2 v nv)
    (setq dxf (entget ent))
    (setq p1  (cdr (assoc 10 dxf))
          p2  (cdr (assoc 11 dxf))
          v   (list (- (car p2)  (car p1))
                    (- (cadr p2) (cadr p1)))
          nv  (normalize-vec v))
    (if nv (list nv) nil)
  )

  ;; --- Richtungsvektoren aus LWPOLYLINE ---
  (defun dirs-from-lwpoly (ent / dxf pts closed i p1 p2 v nv dirs)
    (setq dxf    (entget ent)
          pts    '()
          dirs   '()
          closed (logand (cdr (assoc 70 dxf)) 1))
    (foreach pair dxf
      (if (= (car pair) 10)
        (setq pts (append pts (list (cdr pair))))
      )
    )
    (setq i 0)
    (while (< i (1- (length pts)))
      (setq p1 (nth i pts)
            p2 (nth (1+ i) pts)
            v  (list (- (car p2)  (car p1))
                     (- (cadr p2) (cadr p1)))
            nv (normalize-vec v))
      (if nv (setq dirs (append dirs (list nv))))
      (setq i (1+ i))
    )
    (if (= closed 1)
      (progn
        (setq p1 (last pts)
              p2 (car pts)
              v  (list (- (car p2)  (car p1))
                       (- (cadr p2) (cadr p1)))
              nv (normalize-vec v))
        (if nv (setq dirs (append dirs (list nv))))
      )
    )
    dirs
  )

  ;; --- Richtungsvektoren aus alter POLYLINE (via VERTEX) ---
  (defun dirs-from-polyline (ent / pts closed dxf flags p1 p2 v nv dirs sub subtype)
    (setq pts    '()
          dirs   '()
          dxf    (entget ent)
          flags  (cdr (assoc 70 dxf))
          closed (if flags (logand flags 1) 0))
    ;; VERTEX-Entities sammeln
    (setq sub (entnext ent))
    (while (and sub
                (not (= (cdr (assoc 0 (entget sub))) "SEQEND")))
      (setq subtype (cdr (assoc 0 (entget sub))))
      (if (= subtype "VERTEX")
        (progn
          ;; Nur echte 2D/3D-Linienpunkte (keine Mesh/Face-Vertices)
          ;; Bit 16 (face vertex) und Bit 64 (spline frame) ausfiltern
          (setq vflags (cdr (assoc 70 (entget sub))))
          (if (null vflags) (setq vflags 0))
          (if (= (logand vflags 80) 0)   ; keine Spline-Kontrollpunkte (Bit 16+64)
            (setq pts (append pts
                        (list (cdr (assoc 10 (entget sub))))))
          )
        )
      )
      (setq sub (entnext sub))
    )
    ;; Segmente berechnen
    (setq i 0)
    (while (< i (1- (length pts)))
      (setq p1 (nth i pts)
            p2 (nth (1+ i) pts)
            v  (list (- (car p2)  (car p1))
                     (- (cadr p2) (cadr p1)))
            nv (normalize-vec v))
      (if nv (setq dirs (append dirs (list nv))))
      (setq i (1+ i))
    )
    (if (= closed 1)
      (progn
        (setq p1 (last pts)
              p2 (car pts)
              v  (list (- (car p2)  (car p1))
                       (- (cadr p2) (cadr p1)))
              nv (normalize-vec v))
        (if nv (setq dirs (append dirs (list nv))))
      )
    )
    dirs
  )

  ;; --- Dispatcher: Richtungen je nach Objekttyp ---
  (defun get-directions (ent / etype)
    (setq etype (cdr (assoc 0 (entget ent))))
    (cond
      ((= etype "LINE")        (dirs-from-line     ent))
      ((= etype "LWPOLYLINE")  (dirs-from-lwpoly   ent))
      ((= etype "POLYLINE")    (dirs-from-polyline ent))
      (T
        (princ (strcat "\nObjekttyp '" etype "' wird nicht unterstuetzt."))
        nil
      )
    )
  )

  ;; --- Alle Vektoren beider Listen parallel? ---
  (defun all-parallel? (list1 list2 / ref d ok)
    (setq ref (car list1)
          ok  T)
    (foreach d (append list1 list2)
      (if (not (vecs-parallel? ref d))
        (setq ok nil)
      )
    )
    ok
  )

  ;; ============================================================
  ;; HAUPTPROGRAMM
  ;; ============================================================
  (princ "\n--- ISPARAL: Parallelpruefung ---")
  (princ "\nErstes Objekt waehlen (LINE / LWPOLYLINE / POLYLINE): ")
  (setq obj1 (entsel))

  (if (null obj1)
    (princ "\nKein Objekt gewaehlt. Abbruch.")
    (progn
      (setq ent1 (car obj1))
      (princ "\nZweites Objekt waehlen (LINE / LWPOLYLINE / POLYLINE): ")
      (setq obj2 (entsel))

      (if (null obj2)
        (princ "\nKein Objekt gewaehlt. Abbruch.")
        (progn
          (setq ent2  (car obj2)
                dirs1 (get-directions ent1)
                dirs2 (get-directions ent2))

          (cond
            ((or (null dirs1) (null dirs2))
              (princ "\nFEHLER: Richtungsvektoren konnten nicht ermittelt werden.")
            )
            ((all-parallel? dirs1 dirs2)
              (princ "\nERGEBNIS: Die Objekte verlaufen PARALLEL.")
            )
            (T
              (princ "\nERGEBNIS: Die Objekte sind NICHT parallel.")
            )
          )
        )
      )
    )
  )
  (princ)
)

(defun C:ISPARAL () (isparal))

(princ "\nISPARAL.LSP geladen  |  Befehl: ISPARAL")
(princ)
