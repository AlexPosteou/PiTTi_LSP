(defun C:BlockIT (/ einfuegepunkt blockname elemente)

(setq einfuegepunkt (getpoint "Einfügepunkt auswählen"))
(setq blockname (substr (rtos (getvar "MILLISECS")) 1 6 ))
(setq elemente (ssget))
(command "block" blockname einfuegepunkt elemente "")
(command "einfüge" blockname einfuegepunkt "" "" "")
(princ)
)


(defun C:BlockITCopy (/ einfuegepunkt blockname elemente lastblk lastblk_obj)

(setq einfuegepunkt (getpoint "Einfügepunkt auswählen"))
(setq blockname (substr (rtos (getvar "MILLISECS")) 1 6 ))
(setq elemente (ssget))
(command "block" blockname einfuegepunkt elemente "")
(command "einfüge" blockname einfuegepunkt "" "" "")
(setq lastblk (entlast))
(setq lastblk_obj (vlax-ename->vla-object lastblk))
(command "ursprung" lastblk)
(command "einfüge" blockname pause "" "" "")
(princ)
)
