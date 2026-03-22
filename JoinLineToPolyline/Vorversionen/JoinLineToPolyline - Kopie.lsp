(defun c:joinpoly (/ ss i ent obj pline pts)
  (prompt "\nWählen Sie Linien aus, die zu Polylinien verbunden werden sollen...")
  (setq ss (ssget '((0 . "LINE")))) ; Nur Linien auswählen
  (if ss
    (progn
      (repeat (setq i (sslength ss))
        (setq ent (ssname ss (setq i (1- i))))
        (setq obj (vlax-ename->vla-object ent))
        (setq pts (cons (vlax-get obj 'StartPoint) pts))
        (setq pts (cons (vlax-get obj 'EndPoint) pts))
      )
      ; Überprüfen, ob die Punkte eine geschlossene Kontur bilden
      (if (and pts (equal (car pts) (last pts) 1e-6))
        (progn
          (setq pline (vla-addLightweightPolyline
                        (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object)))
                        (apply 'append (mapcar '(lambda (p) (list (car p) (cadr p))) pts))
                      ))
          (vla-put-Closed pline :vlax-true) ; Polylinie schließen
          (command "_.ERASE" ss "") ; Original-Linien löschen
          (prompt "\nLinien wurden zu einer geschlossenen Polylinie verbunden.")
        )
        (prompt "\nDie ausgewählten Linien bilden keine geschlossene Kontur!")
      )
    )
    (prompt "\nKeine Linien ausgewählt!")
  )
  (princ)
)
