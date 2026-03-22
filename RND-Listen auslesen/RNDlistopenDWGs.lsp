(defun c:openclose ()
  (setq dir "C:\\SWAP\\RND")
  (setq file-list (vl-directory-files dir "*.dwg" 1))
  (foreach dwg file-list
    (setq full-path (strcat dir "\\" dwg))
    (setq opendwg (vla-open (vla-get-documents (vlax-get-acad-object)) full-path :vlax-false))
    (if opendwg
      (progn

	(princ (strcat dir "\\" dwg "\n"))
;        (command "_.purge" "all" "*" "n")
        (vla-close opendwg :vlax-false)
      )
    )
  )
  (princ "\nAlle Zeichnungen wurden bearbeitet und geschlossen.")

	(command "_.close" "n")
)
