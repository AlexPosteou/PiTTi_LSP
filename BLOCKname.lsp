; places name of block as text via pick

(defun C:blockname()

(setvar "cmdecho" 0)

(setq pt(cadr(entsel"\nSelect Block:")))

(setq e1(ssget pt))

(setq e2 (entget (ssname e1 0)))
 
(setq blname (cdr(assoc 2 e2)))
 
(setq pt1 (getpoint"\nSelect point for block title:"))
 
(command "text" pt1 "" 0 blname)
 
)