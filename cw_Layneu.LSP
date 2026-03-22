;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; LAYNEU
;
; Die Funktion erstellt auf die Schnelle einen neuen Layer
; nach der Eingabe des Layernamens erscheint der AutoCAD-Farbauswahldialog
; zur Angabe einer ACL-, RGB oder Farbbuchfarbe
;
; Aufruf: layneu
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; (c) Dipl.-Ing.  Volker Kleppel
; http://www.cadwerk.com
; vkleppel@gmx.de
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Version: 1.2                   Datum: 20.05.2018
; AutoCAD12   [ ]  AutoCAD14   [x]  AutoCAD2000(i) [x]   
; AutoCAD2002 [ ]  AutoCAD2004 [x]  AutoCAD2005    [x]
; AutoCAD2006 [x]  AutoCAD2007 [x]  AutoCAD2008    [x]
; AutoCAD2009 [x]  AutoCAD2010 [x]  AutoCAD2011    [x]
; AutoCAD2012 [x]  AutoCAD2013 [x]  AutoCAD2014    [x]
; AutoCAD2015 [x]  AutoCAD2016 [x]  AutoCAD2017    [x]
; AutoCAD2018 [x]  AutoCAD2019 [x]
; Freeware    [x]  Shareware   [ ]
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

(defun c:layneu	(/ ln lc ex)
  (setq ln (getstring "\nName des Layers: "))
  (if (/= ln "")
    (if	(= nil (tblsearch "layer" ln))
      (progn
	(setq lc (acad_truecolordlg '(62 . 7) nil))
	(if (/= lc nil)
	  (progn
	    (setq ex
		     (list (cons 0 "LAYER")
			   (cons 100 "AcDbSymbolTableRecord")
			   (cons 100 "AcDbLayerTableRecord")
			   (cons 2 ln)
			   (cons 70 0)
		     )

		  ex (append ex lc)
	    )
	    (entmake ex)
	    (setvar "clayer" ln)
	  )
	  (princ "\nAbbruch")
	)
      )
      (princ "\nEinen Layer mit diesem Namen gibt es bereits!")
    )
    (princ "\nKeine Eingabe - Abbruch")
  )
  (print)
)

;(princ "\nRoutine zum Anlegen eines neuen Layers")
;(princ "\n(c) Dipl.-Ing. Volker Kleppel")
;(princ "\nStand 25.07.2011")
;(princ "\nAufruf: layneu")
;(print)
