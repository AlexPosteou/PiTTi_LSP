(defun c:adjust-block-inner-properties (/ blk ss ent)
  ;Name des Blocks
  (setq blk "ABC")
  
  ;Alle Objekte des Blocks auswählen
  (setq ss (ssget "_X" (list '(0 . "INSERT")(cons 2 blk))))
  
  ;Loop durch alle Objekte des Blocks
  (setq i 0)
  (while (< i (sslength ss))
    (setq ent (ssname ss i))
    
    ;Layer=0
    ;(command "-LAYER" "SE" "0" ent "")
  
    ;Farbe = byblock
    (command "_-COLOR" "1" ent "")
  
    ;Linientyp = byblock
    ;(command "-LTYPE" "S" "BYBLOCK" ent "")
  
    ;Inkrementiere den Zähler
    (setq i (1+ i))
  )
  
  ;Benachrichtigung
  (princ (strcat "\nProperties adjusted for all inner objects of block: " blk))
  
  (princ)
)
