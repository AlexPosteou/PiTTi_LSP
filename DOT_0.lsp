;Setzt den Inhalt des BemaßungsDot-Blocks auf Layer 0 und VONBLOCK
;Ausführung erfolgt beim Start jeder Zeichnung über die acaddoc.LSP

(defun c:dot_0 ()
(command "-BEDIT")
(command "DOT")
(command "")
(command "_CHPROP" "ALLE" "" "LA" "0" "F" "VONBLOCK" "LTY" "VONBLOCK" "")
(command "BSPEICH")
(command "BSCHL")
)