;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; CloneBlock
;
; CLONEBLOCK erstellt eine Kopie eines bestehendes Blocks unter neuem
; Blocknamen. Die Routine vereinfacht das Arbeiten mit Varianten mehrerer
; Blöcke. Blocknamen werden dabei automatisch vorgeschlagen oder können
; durch den Zeichner frei gewählt werden.
;
; Aufruf: cloneblock
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; (c) Dipl.-Ing.  Volker Kleppel
; http://www.cadwerk.com
; vkleppel@gmx.de
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Version: 1.1                      Datum: 28.03.2005
; AutoCAD12   [ ]  AutoCAD14   [x]  AutoCAD2000(i) [x]   
; AutoCAD2002 [x]  AutoCAD2004 [x]  AutoCAD2005    [x]
; AutoCAD2006 [x]  AutoCAD2007 [x]  AutoCAD2008    [x]
; Freeware    [x]  Shareware   [ ]
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

(defun C:BlockClone (/ enx en ent pkt nm nm2 nm3 i exitflag entyp cb_sysvar)

  (while (not exitflag)
    (setq enX (entsel))
    (setq en (car enx))
    (setq ent (entget en))

    (setq entyp (cdr (assoc 0 ent)))
    (setq pkt (trans (cdr (assoc 10 ent)) 0 1))
    (setq nm (cdr (assoc 2 ent)))

    (if	(= entyp "INSERT")
      (setq exitflag T)
      (princ "\nDas gewählte Element ist kein Block")
    )
  )

  (redraw en 3)

  (setq i 1)

  (while (> (length
	      (tblsearch "BLOCK" (setq nm2 (strcat nm (rtos i 2 0))))
	    )
	    0
	 )
    (setq i (1+ i))
  )

  (setq
    nm3	(getstring (strcat "\nNeuen Blockname eingeben: <" nm2 ">"))
  )
  (if (= nm3 "")
    (setq nm3 nm2)
  )
  (if (> (length (tblsearch "BLOCK" nm3)) 0)
    (progn
      (alert "Der angegebene Blockname existiert bereits")
      (redraw en 4)
    )
    (progn
      (command "_explode" en "")
      (command "_block" nm3 pkt "_p" "")

      (setq cb_sysvar (cb_std_sysvar '(("CLAYER" (cdr (assoc 8 ent))))))
      (command "_insert" nm3 pkt "" "" "")
      (cb_std_sysvar cb_sysvar)
      (princ "\n")
      (princ (strcat "\nBlock geklont von '" nm "' --> '" nm3 "'")
      )
    )
  )
  (print)
)

 ;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
 ; Ändert bzw. stellt Systemvariablen wieder her, die als Liste 'L'
 ; übergeben werden
 ;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

(defun CB_STD_sysvar (l)
     (mapcar '(lambda (x / var val vlist)
		   (setq var   (if (listp x)
				    (car x)
				    x
			       ) ;_ Ende von if
			 val   (if (listp x)
				    (eval (cadr x))
				    nil
			       ) ;_ Ende von if
			 vlist (list var (getvar var))
		   ) ;_ Ende von setq
		   (if val
			(setvar var val)
		   ) ;_ Ende von if
		   vlist
	      ) ;_ Ende von lambda
	     l
     ) ;_ Ende von mapcar
) ;_ Ende von defun


;(princ "\nCloneBlock - (c) Dipl.-Ing. V. Kleppel, www.cadwerk.com")
;(princ "\nAufruf: cloneblock")
;(print)
