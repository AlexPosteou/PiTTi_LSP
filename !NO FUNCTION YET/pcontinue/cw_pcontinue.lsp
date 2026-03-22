;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Polyline Continue
;
; Funktion ermöglicht es, eine beliebige Polylinie, Linie oder
; Bogen fortzuführen. Am Ende des Befehls existiert nur eine einzelne
; Linie.
;
; Aufruf: pcontinue
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; (c) Dipl.-Ing.  Volker Kleppel
; http://www.cadwerk.com
; vkleppel@gmx.de
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; Version: 2.1                      Datum: 26.2.1999
; AutoCAD12   [ ]  AutoCAD14   [x]  AutoCAD2000(i) [x]   
; AutoCAD2002 [x]  AutoCAD2004 [x]  AutoCAD2005    [x]
; AutoCAD2006 [x]  AutoCAD2007 [x]  AutoCAD2008    [x]
; Freeware    [x]  Shareware   [ ]
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

(defun c:pcontinue ( / en en1 ent enX i flag startpunkt winkel radius p1 p2 pt p dump iDump)

	(setq iDump "Element") 
	(if (= iDump "Element")
	(progn
	(setq enX (entsel "\nLinie, Polylinie oder Bogen anpicken:"))
	(setq dump (getvar "osmode"))
	(setvar "osmode" 0)
	(setq en  (car enX)
	      ent (entget en)
	     flag (cdr (assoc 0 ent))
	       pt (osnap (cadr enX) "end")
	)
	(setvar "osmode" dump)

	(if (not (member flag '("ARC" "LINE" "LWPOLYLINE")))
		(princ "\nElement ist keine Linie, Polylinie oder Bogen!")
		(progn ;else
			(if (and (= flag "LWPOLYLINE") (= (cdr (assoc 70 ent)) 1))
				(princ "\nDie gewählte Polylinie ist geschlossen!")
				(progn ;ELSE
					(cond
						((= flag "LINE")
							(setq p pt)
						)
						((= flag "ARC")
							(setq p pt)
						)
						((= flag "LWPOLYLINE")
							(setq i (length ent) exitflag nil)
							(setq exitflag nil)
							(while (not exitflag)
								(if (= (car (nth (1- i) ent)) 10)
									(setq p1 (cdr (nth (1- i) ent)) exitflag T)
									(setq i (1- i))
								)
							)
							(setq i 1)
							(setq exitflag nil)
							(while (not exitflag)
								(if (= (car (nth (1- i) ent)) 10)
									(setq p2 (cdr (nth (1- i) ent)) exitflag T)
									(setq i (1+ i))
								)
							)
							(setq p1 (trans p1 0 1) p2 (trans p2 0 1))
							(if (< (distance pt p1) (distance pt p2)) (setq p p1) (setq p p2))
						)
						(t nil)
					)
					(Command "_.pline" p)
					(while (/= (getvar "CMDNAMES") "")
						(command pause)
					)
					(setq en2 (entlast))
					(setq dump (getvar "cmdecho"))
					(setvar "cmdecho" 0)
					(if (= flag "LWPOLYLINE")
					  (command "_.pedit" en "_j" en2 "" "")
					  (command "_.pedit" en "_y" "_j" en2 "" "")
					 )
					(setvar "cmdecho" dump)
				)
			)
		)
	)
	)
	(progn ;ELSE
	(if (/= idump nil)
	(progn
	(if (/= (type iDump) 'LIST)
	(princ (strcat "\nDer Befehl '" iDump "' existiert nicht!"))
	(progn
	(command "cmdecho" 1)
	(Command "_.pline" iDump)
		(while (/= (getvar "CMDNAMES") "")
			(command pause)
		)
	)
	)
	)
	)
	)
	)
	(print)
)

(princ "\nPContinue - (c) Dipl.-Ing. V. Kleppel, www.cadwerk.com")
(princ "\nAufruf: pcontinue")
(print)