;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Rotate Text
;
; Funktion richtet Text in einem bestimmten Winkel aus, den man entweder
; über Tastatur eingeben oder mit zwei Punkten auf dem Bildschirm zeigen
; kann. Somit ist es sehr einfach, Beschriftungen anhand von Kanten auszu-
; richten.
;
; Aufruf: rotatetext
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; (c) Dipl.-Ing.  Volker Kleppel
; http://www.cadwerk.com
; vkleppel@gmx.de
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Version: 1.2                      Datum: 1.8.1999
; AutoCAD12   [ ]  AutoCAD14   [x]  AutoCAD2000(i) [x]   
; AutoCAD2002 [x]  AutoCAD2004 [x]  AutoCAD2005    [x]
; AutoCAD2006 [x]  AutoCAD2007 [x]  AutoCAD2008    [x]
; Freeware    [x]  Shareware   [ ]
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

(defun c:rotatetext ( / en ent enX winkel exitflag)

	(setq winkel (getangle "\nBasiswinkel angeben"))
	(setq exitflag nil)

	(if (/= winkel nil)
		(progn
		'Drehung des BKS berücksichtigen
		(setq winkel (+ winkel (angle (trans '(0 0 0) 1 0) (trans '(1 0 0) 1 0))))
		(while (not exitflag)
			(setq enX (entsel "\nTextelement wählen "))
			(if (not enX)
				(setq exitflag T)
				(progn
					(setq en (car enX))
					(setq ent (entget en))
					(if (or (= (cdr (assoc 0 ent)) "TEXT") (= (cdr (assoc 0 ent)) "MTEXT"))
						(progn
							(setq ent (subst (cons 50 winkel) (assoc 50 ent) ent))
							(entmod ent)
							(entupd en)
						)
						(princ "\nGewähltes Element ist kein Textelement!")
					)
				)
			)
		)
		)
	)
)

(princ "\nRotateText - (c) Dipl.-Ing. V. Kleppel, www.cadwerk.com")
(princ "\nAufruf: rotatetext")
(print)