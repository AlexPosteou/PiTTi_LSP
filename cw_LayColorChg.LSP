;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; ColorChg
;
; Ändern die Farbeinstellung eines Layers durch Auswahl eins
; AutoCAD-Objektes auf dem entsprechenden Layer
;
; Aufruf: cliste
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; (c) Dipl.-Ing.  Volker Kleppel
; http://www.cadwerk.com
; vkleppel@gmx.de
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Version: 2.1                      Datum: 20.05.2018
; AutoCAD12   [ ]  AutoCAD14   [ ]  AutoCAD2000(i) [ ]
; AutoCAD2002 [ ]  AutoCAD2004 [x]  AutoCAD2005    [x]
; AutoCAD2006 [x]  AutoCAD2007 [x]  AutoCAD2008    [x]
; AutoCAD2009 [x]  AutoCAD2010 [x]  AutoCAD2011    [x]
; AutoCAD2012 [x]  AutoCAD2013 [x]  AutoCAD2014    [x]
; AutoCAD2015 [x]  AutoCAD2016 [x]  AutoCAD2017    [x]
; AutoCAD2018 [x]  AutoCAD2019 [x]
; Freeware    [x]  Shareware   [ ]
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

(defun c:laycolorchg (/ en ent entLayer entColor entLayerEntity temp1 temp2 cc62 cc420 cc430)

  (vl-load-com)

  (setq enx (entsel "\nElement wählen"))
  (if (/= enx nil)
    (progn
      (setq en		   (car enx)
	    ent		   (entget en)
	    entLayer	   (cdr (assoc 8 ent))
	    entColor	   (cdr (assoc 62 ent))
	    entLayerEntity (entget (tblobjname "layer" entLayer) '("*"))
	    cc62	   (assoc 62 entLayerEntity)
	    cc420	   (assoc 420 entLayerEntity)
	    cc430	   (assoc 430 entLayerEntity)
      )
      
      (if (or (= entColor nil) (= entColor 256))
	(progn
	  (princ (strcat "\nFarbe ändern von '" entlayer "'"))
	  (princ (strcat "\nFarbe aktuell: " (ccListGetProperty entLayerEntity)))
	  (if (= cc430 nil)
	    (if	(= cc420 nil)
	      (setq dump (acad_truecolordlg cc62 nil))
	      (setq dump (acad_truecolordlg cc420 nil))
	    )
	    (setq dump (acad_truecolordlg cc430 nil))
	  )
	  (if (/= dump nil)
	    (progn
	      (setq entLayerEntity (vl-remove cc62 entLayerEntity)
                    entLayerEntity (vl-remove cc420 entLayerEntity)
		    entLayerEntity (vl-remove cc430 entLayerEntity)
		    entlayerentity (append entlayerentity dump)
		    )
	      (princ (strcat "\nFarbe neu    : " (ccListGetProperty entLayerEntity)))
	      (setq cc62  (cdr (assoc 62 dump))
		    cc420 (cdr (assoc 420 dump))
		    cc430 (cdr (assoc 430 dump))
	      )
	      (if (= cc430 nil)
	        (if (= cc420 nil)
	          (command "layer" "fa" cc62 entLayer "")
	          (command "layer" "fa" "T" (ccGetRGB cc420) entlayer "")
	        ); if
	        (command "layer" "fa" "F" (nth 0 (ccGetColorBook2 cc430)) (nth 1 (ccGetColorBook2 cc430)) entlayer "")
	      )	      
	   )
	    (princ "\nAbbruch")
	  ); if
	); progn
	(princ "\nDas Element verwendet nicht die Farbe aus dem Layer!")
      ); if
    );progn
    (princ "\n")
  );if
  (print)
)

(defun ccListGetProperty (entList / ccTemp cc420 cc430 ccRGB ccBook)
  (defun clistefarbe (colorinfo)
    (cond ((= colorinfo 1) "rot (1)")
	  ((= colorinfo 2) "gelb (2)")
	  ((= colorinfo 3) "grün (3)")
	  ((= colorinfo 4) "cyan (4)")
	  ((= colorinfo 5) "blau (5)")
	  ((= colorinfo 6) "magenta (6)")
	  ((= colorinfo 7) "weiß (7)")
	  ((= colorinfo 8) "dunkelgrau (8)")
	  ((= colorinfo 9) "hellgrau (9)")
	  ((> colorinfo 9) (strcat "Farbe " (itoa colorinfo)))
	  (T nil)
    )
  )

  (setq ccTemp (clistefarbe (cdr (assoc 62 entList))))

  (if (setq cc420 (cdr (assoc 420 entList))) (setq ccRGB (ccGetRGB cc420)))
  (if (setq cc430 (cdr (assoc 430 entList))) (setq ccBook (ccGetColorBook cc430)))

  (if cc420 (setq ccTemp (strcat ccRGB "(RGB)")))
  (if cc430 (setq ccTemp ccBook))

  ccTemp
)

(defun ccGetRGB	(ccRGB / ccRed ccGreen ccBlue ccTemp)
  (setq	ccBlue	(logand ccRGB 255)
	ccGreen	(/ (logand ccRGB 65280) 256)
	ccRed	(/ (logand ccRGB 16711680) 65536)
	ccTemp	(strcat	(rtos ccRed 2 0) "," (rtos ccGreen 2 0) "," (rtos ccBlue 2 0))
  )

  ccTemp
)

(defun ccGetColorBook (ccColorBook / ccTemp ccI ccBookName ccColorName)
  (setq	ccI	    (vl-string-search "$" ccColorBook)
	ccBookName  (substr ccColorBook 1 ccI)
	ccColorName (substr ccColorBook (+ cci 2))
	ccTemp	    (strcat ccBookName " | " ccColorName)
  )

  ccTemp
)

(defun ccGetColorBook2
       (ccColorBook / ccTemp ccI ccBookName ccColorName)
  (setq	ccI	    (vl-string-search "$" ccColorBook)
	ccBookName  (substr ccColorBook 1 ccI)
	ccColorName (substr ccColorBook (+ cci 2))
	ccTemp	    (list ccBookName ccColorName)
  )

  ccTemp
)

;(princ "\nColorChg - (c) Dipl.-Ing. V. Kleppel, www.cadwerk.com")
;(princ "\nAufruf: ColorChg")
;(print)