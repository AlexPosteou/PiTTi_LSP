(defun c:blockrenamee ()
  (setq blockname (car (nentsel "\nSelect block: ")))
  (setq newnamer (getstring "\nNew block name: "))
  (command "_.rename" "BL" blockname newnamer)
)

(princ)
