;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Enth�lt allgemeine Prozeduren
;;
;;

(princ "SUB_LIB1**")



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun SUB_DAT ( / )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Setzt Vorwerte f�r Prozeduren bei sub_lib....
;;

 (setq
           schatt1_b      0.3
           schatt1_h      0.3

           schraff_abst1  0.2
           schraff_abst2  0.1
           schraff_lay1   "BETON"

           schnitt_nam    ""

           stre_fac       1.0

           arr_abst1      0.15
           arr_n1         4

 )
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun BOG_GRAD (w /)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Rechnet Bogenma�e in Grad um.
 (/ (* w 180.0) PI)
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun GRAD_BOG (w /)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Rechnet Grad in Bogenma�e um.
 (* (/ w 180.0) PI)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun C:DIST1 (/ p1 p2 )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Abstand zwischen Parallelen
;; mit Vorsicht zu verwenden, weil keine Pr�fung der Parallelit�t
;; stattfindet.

 (setvar "cmdecho" 0)

 (setq hilf_was "dist1")
 (dis_zei 10)

 (modes '("osmode"))
 (setvar "osmode" 512)
 (setq p1 (getpoint "\n1.Linie..."))

 (if p1 (setvar "lastpoint" p1))

 (setq p2 (osnap (getpoint "\nParallele...") "_perpend"))

 (if (and p1 p2) (progn
   (princ "\nAbstand = ")
   (princ (distance (trans p1 1 0) (trans p2 1 0)))
  )
   (princ "\nNicht getroffen !")
 )
 (moder)
 (prin1)
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun dxy (/ punkt dx dy)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Sprung um DELTAX und DELTAY
;;
 (modes '("osmode"))
 (setvar "osmode" (+ 1 32))
 (setq punkt (getpoint "\nReferenzpunkt..."))
 (moder)

 (setq dx (getdist punkt "\nDX  [0.0] ? "))
 (if (not dx) (setq dx 0.0))
 (setq dy (getdist punkt "\nDY  [0.0] ?  "))
 (if (not dy) (setq dy 0.0))

 (list (+ (car punkt) dx) (+ (car (cdr punkt)) dy))
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun C:LADE (/
     ja
 )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
 (setvar "cmdecho" 0)

 (setq hilf_was "lade")
 (dis_zei 10)

 (if (or (= "" alg_fil) (null alg_fil))
  (setq alg_fil (getstring "Lisp-File (ohne Extension) ? "))
  (progn
   (princ "File [")
   (princ alg_fil)
   (princ "] ? ")
   (setq fil (getstring))
   (if (/="" fil) (setq alg_fil fil))
 ))

 (setq ja (load alg_fil))
 (prin1)
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun SEX (/ sa se pa pe pa1 pe1 punkt dx dy)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Schnittpunkt zweier Linien

 (setq se (entsel "\n1. Linie ? "))

 (setq pa (osnap (car (cdr se)) "_endp"))
 (setq pe (osnap (car (cdr se)) "_midp"))

 (setq sa (entsel "\n2. Linie ? "))

 (setq pa1 (osnap (car (cdr sa)) "_endp"))
 (setq pe1 (osnap (car (cdr sa)) "_midp"))

 (setq punkt (inters pa pe pa1 pe1 nil))

 (setq dx (getdist "\nDX  [0.0] ? "))
 (setq dy (getdist "\nDY  [0.0] ? "))
 (list (+ (car punkt) (if (not dx) 0.0 dx)) 
  (+ (car (cdr punkt)) (if (not dy) 0.0 dy))
 )
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun LEX (/ pa pe dl punkt se)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Verl�ngert eine Linie am angepickten Ende

 (setq se (entsel "\nEndpunkt einer Linie ? "))
 (setq pe (osnap (car (cdr se)) "_endp"))

 (setq pa (osnap (car (cdr se)) "_midp"))

 (initget (+ 1 2 32))
 (setq dl (getdist "\nWelche Verl�ngerung ? "))

 (setq punkt (polar pe (angle pa pe) dl))
)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Prueft Parallelitaet winkelbasiert MIT Antiparallel-Toleranz
(defun angles-parallel? (p1a p1b p2a p2b / w1 w2 diff)
  (setq w1   (angle p1a p1b)
        w2   (angle p2a p2b)
        diff (abs (- w1 w2)))
  ;; Normierung auf 0..PI (antiparallel = parallel)
  (if (> diff PI) (setq diff (abs (- diff (* 2 PI))))  )
  (if (> diff (/ PI 2.0)) (setq diff (abs (- diff PI))) )
  ;; Toleranzvergleich
  (< diff 1e-8)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun MIDP1 (/)

;;; die erste Linie/Polylinie
	(setq se1 (entsel "\nErste Linie..."))



(if se1 (progn
	(setq seobj1 (car se1))
	(setq pkt1 (trans (osnap (cadr se1) "_nearest") 1 0)  )

	(if (= (vla-get-ObjectName (vlax-ename->vla-object seobj1)) "AcDb2dPolyline") (progn

		(setq poly1 (poly_lad seobj1))
		(setq poly1_n ())
		(setq i 0 ii (length poly1))
		(while (< i (- ii 1))
			(setq poly1_n        (append poly1_n    (list (list (nth i poly1) (nth (+ i 1) poly1)) )  )    )
			(setq i (+ i 1))
		)
		(setq a 0 aa (length poly1_n))
		(while (< a aa)
			(setq lin_pkt (nth a poly1_n))
			(setq lin_pkt1-1 (nth 0 lin_pkt)) ; Anfangspunkt
			(setq lin_pkt1-2 (nth 1 lin_pkt)) ; Endpunkt
			(if 	(equal (distance lin_pkt1-1 lin_pkt1-2) 
				(+  (distance lin_pkt1-1 pkt1) (distance lin_pkt1-2 pkt1) )  0.001
			)
			(setq b a a aa)
 			(setq a (+ a 1))
			) ; end if
		) ; end while
	)) ; end if, end progn

	(if (= (vla-get-ObjectName (vlax-ename->vla-object seobj1)) "AcDbLine") (progn
		(setq lin_pkt1-1 (vlax-safearray->list (vlax-variant-value (vla-get-StartPoint (vlax-ename->vla-object seobj1)))))
		(setq lin_pkt1-2 (vlax-safearray->list (vlax-variant-value (vla-get-EndPoint (vlax-ename->vla-object seobj1)))))
	)) ; end progn, end if
))

;;; die zweite Linie/Polylinie
	(setq se2 (entsel "\nZweite Linie..."))

(if se2 (progn
	(setq seobj2 (car se2))
	(setq pkt2 (trans (osnap (cadr se2) "_nearest") 1 0)  )

	(if (= (vla-get-ObjectName (vlax-ename->vla-object seobj2)) "AcDb2dPolyline") (progn

		(setq poly2 (poly_lad seobj2))
		(setq poly2_n ())
		(setq i 0 ii (length poly2))
		(while (< i (- ii 1))
			(setq poly2_n        (append poly2_n    (list (list (nth i poly2) (nth (+ i 1) poly2)) )  )    )
			(setq i (+ i 1))
		)
		(setq a 0 aa (length poly2_n))
		(while (< a aa)
			(setq lin_pkt (nth a poly2_n))
			(setq lin_pkt2-1 (nth 0 lin_pkt)) ; Anfangspunkt
			(setq lin_pkt2-2 (nth 1 lin_pkt)) ; Endpunkt
			(if 	(equal (distance lin_pkt2-1 lin_pkt2-2) 
				(+  (distance lin_pkt2-1 pkt2) (distance lin_pkt2-2 pkt2) ) 0.001
				)
				(setq b a a aa)
 				(setq a (+ a 1))
			) ; end if
		) ; end while
	)) ; end progn, end if
	
	(if (= (vla-get-ObjectName (vlax-ename->vla-object seobj2)) "AcDbLine") (progn
		(setq lin_pkt2-1 (vlax-safearray->list (vlax-variant-value (vla-get-StartPoint (vlax-ename->vla-object seobj2)))))
		(setq lin_pkt2-2 (vlax-safearray->list (vlax-variant-value (vla-get-EndPoint (vlax-ename->vla-object seobj2)))))
	)) ; end progn, end if
	
))

(if (and (/= se1 nil) (/= se2 nil) ) 
	(if (= (inters lin_pkt1-1 lin_pkt1-2 lin_pkt2-1 lin_pkt2-2) nil ) ; Linien d�rfen nicht kreuzen
		(progn 
			; Pr�fen ob die Linie Anfangspunkt1-Anfangspunkt2 kreuzt mit der Linie Endpunkt1-Endpunkt2
			(if (= (inters lin_pkt1-1 lin_pkt2-2 lin_pkt2-1 lin_pkt1-2) nil)  
			(setq lin_pkt2-1- lin_pkt2-2 lin_pkt2-2 lin_pkt1-1 lin_pkt2-1 lin_pkt2-1-)
			) ; end if
			
			(if (angles-parallel? lin_pkt1-1 lin_pkt1-2 lin_pkt2-1 lin_pkt2-2)
  ; Linien sind parallel
				(setq midp (trans (mid lin_pkt1-1 lin_pkt2-1) 0 1 ))
				(alert "Linien/Polyliniensegmente sind nicht parallel!")			
			)
		) ; end progn
		(alert "Linien/Polyliniensegmente kreuzen!")
	) ; end if
	(progn (alert "Linien/Polylinien wurden falsch gepickt!") (exit))
) ; end if

)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun mid (p1 p2)
  (list
    (/ (+ (car p1) (car p2)) 2.0)
    (/ (+ (cadr p1) (cadr p2)) 2.0)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun MIDP2 (/ p1 p2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Mittelpunkt zwischen Punkten
;;
 (modes '("osmode"))
 (setvar "osmode" (+ 1 32))
 (setq p1 (getpoint "\n1. Punkt..."))
 (setq p2 (getpoint "\n2. Punkt..."))
 (moder)

 (polar p1 (angle p1 p2) (* (distance p1 p2) 0.5))
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun POLXY (/ se p1 p2 dv dn)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Gedrehtes Koordinatensystem
;; Sprung um DVECTOR und DNORMAL

 (setq se (entsel "\nEndpunkt einer Geraden..."))
 (setq p1 (osnap (car (cdr se)) "_endp"))
 (setq p2 (osnap (car (cdr se)) "_midp"))

 (setq dv (getdist "\nVerl�ngerung [0] ..."))
 (if (not dv) (setq dv 0.0))

 (setq dn (getdist "\nNormale [0] ..."))
 (if (not dn) (setq dn 0.0))

 (polar (polar p1 (angle p2 p1) dv) (+ (* pi 0.5) (angle p2 p1)) dn)
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun MODES (a /)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
 (setq MLST '())

 (repeat (length a)
  (setq MLST (append MLST (list (list (car a) (getvar (car a))))))
  (setq a (cdr a))
 )
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun MODER ()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
 (repeat (length MLST)
  (setvar (caar MLST) (cadar MLST))
  (setq MLST (cdr MLST))
 )
 (setq *error* nil)
 (terpri)
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun myerror_set (was / )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setzt den eigenen Error-handler, der unter 'was' ver-
;; zeichnet ist.
;;
;; old_err ist global.
;;
 (if (= was 1) (setq old_err *error* *error* myerror_handler_break1))
;(if (= was 2) (setq old_err *error* *error* myerror_handler_break2))
)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun myerror_0 (/ )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setzt den Error-handler von ACAD
;;
 (setq *error* old_err)
)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun myerror_handler_break1 (msg)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Es k�nnen beliebige weitere handler vereinbart werden.
;;
 (if (= msg "Funktion abgebrochen") (progn
  (command "_undo" "_end")
  (command "_u")
 ))
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun C:COL ( /
       i p1 p2 pa
 )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Stellt alle Farben als PLINE dar.
;;

 (setq hilf_was "col")
 (dis_zei 10)

 (setq i 0)

 (setq pa (getpoint "wo..."))

 (command "_pline" "0,0" "b" 0.04  "" "")

 (while (< i 255)
  (setq dxy 0)
  (setq i (+ i 1))
  (command "_color" i)
  (princ "\n") (princ i)
  (setq p1 (polar pa 1.5709 (* 0.05 i)))
  (if (= (rem i 10) 0) (setq dxy 0.5))
  (setq p2 (polar p1 0 (+ dxy 1.0)))
; (princ p1)
; (princ p2)
  (command "_pline" p1 p2 "")
 )
 (command "_regen")
 
 (princ)
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun atoi1 (tx /
       i ii tx1 wert
 )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pr�ft, ob eine ganze Zahl vorliegt.
;; Wenn nein, dann wird "" zur�ckgegeben.

 (setq ii (strlen tx) i 0 wert 0)

 (while (< i ii)
  (setq tx1 (substr tx (1+ i) 1))
  (cond
   ((= tx1 "0") T)
   ((= tx1 "1") T)
   ((= tx1 "2") T)
   ((= tx1 "3") T)
   ((= tx1 "4") T)
   ((= tx1 "5") T)
   ((= tx1 "6") T)
   ((= tx1 "7") T)
   ((= tx1 "8") T)
   ((= tx1 "9") T)
   (T      (setq wert (1+ wert) i ii))
  )
  (setq i (1+ i))
 )
 (if (= wert 0)
  (setq tx tx)
  (setq tx "")
 )
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun atof1 (tx /
     i ii t1 tx1 wert wert1 
 )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pr�ft, ob eine REAL-Zahl vorliegt. Diese wird als STRING
;; �bergeben, zur�ck kommt eine REAL-Zahl oder nil.
;;
;; Es sind nur folgende Zeichen erlaubt:
;; 0 bis 9, +, -, ein '.'. Es mu� ein '.' vorhanden sein, sonst
;; mu� mit atoi1 gepr�ft werden.
;;
;; Die Zahl mu� bereits beidseits getrimmt sein.
;;

 (setq t1 (substr tx 1 1))
 (if (or (= t1 "+") (= t1 "-")) (setq tx (substr tx 2)))

 (setq ii (strlen tx) i 0 wert 0 wert1 -1)

 (while (< i ii)
  (setq tx1 (substr tx (1+ i) 1))
  (cond
   ((= tx1 "0") T)
   ((= tx1 "1") T)
   ((= tx1 "2") T)
   ((= tx1 "3") T)
   ((= tx1 "4") T)
   ((= tx1 "5") T)
   ((= tx1 "6") T)
   ((= tx1 "7") T)
   ((= tx1 "8") T)
   ((= tx1 "9") T)
   ((= tx1 ".") T)
   (T      (setq wert (1+ wert) i ii))
  )

  (if (= tx1 ".") (setq wert1 (1+ wert1)))
  (setq i (1+ i))
 )

 (if (= t1 "-") (setq tx (strcat "-" tx)))

 (if (and (= wert 0) (= wert1 0))
  (setq tx (atof tx))
  (setq tx nil)
 )
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun zahl_str (wert art n /
        tmp
 ) 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Macht einen REAL- oder INT-Wert zu einem String.
;; art ist "R", wenn REAL bleiben soll
;;         "I", wenn ganzzahlig und ev. gerundet zur�ckkommt
;;
;; n ist Zahl der Stellen, falls REAL.
;;
 (if (= (type wert) 'INT) (progn
  (setq tmp (itoa wert))
 ))

 (if (= (type wert) 'REAL) (progn
  (if (= art "R") (setq tmp (rtos wert 2 n)))
  (if (= art "I") (setq tmp (itoa (fix (+ wert 0.499)))))
 ))

 tmp
) 




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun asso (lis tx /
     k kk tmp wert
 )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Schaut nach, ob tx in lis enthalten ist.
;;
 (setq kk (length lis) k 0 wert '() dummy "0")
 (while (< k kk)
  (setq tmp (list (nth k lis) dummy))
  (setq wert (append wert (list tmp)))
  (setq k (1+ k))
 )

 (assoc tx wert)
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun get_ass (n ent / wert)
;; Bringt den Inhalt eines Codes zur�ck.
;;
;; Beispiel:       (get_ass 8 <12F4B>)    >>>>>> "OBJEKT"
;;
 (setq wert (cdr (assoc n (entget ent))))
)





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun C:WAHL_SATZ1 ( /
 )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Ein Auswahlsatz wird zusammengestellt, der in einer
;; Lisp-Variablen abgelegt wird. Auch bei UNDO steht dieser
;; Satz zur Verf�gung.
;;

 (setq hilf_was "satz1")
 (dis_zei 10)

 (prompt "Auswahlsatz bilden....\n")
 (prompt "Wird durch UNDO nicht gel�scht !\n")

 (setq sub_satz1 (ssget))

 (princ)
)





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun ss_rahm_setz (lay col ltp bre /
     al_lay xy1 xy2 xy3 xy4
 )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Damit wird ein Rahmen gew�hlt. Nur die Objekte werden eingesammelt,
;; die innerhalb dieses Rahmens liegen.
;;

 (prompt "\nEs wird ein rechteckiger Rahmen gezeichnet.\n")

 (command "orthomode" 0)

 (setq xy1 (in_getp nil "Linken unteren Punkt w�hlen...."))
 (setq xy3 (in_getp xy1 "Rechten oberen Punkt w�hlen...."))

 (command "_color" col)
 (command "_linetype" "_set" ltp "")
 (setq al_lay (getvar "CLAYER"))
 (command "_layer" "_m" lay "")

 (setq xy2 (list (car xy1) (cadr xy3)))
 (setq xy4 (list (car xy3) (cadr xy1)))

 (command "_pline" xy1 "_w" bre bre xy2)
 (command xy3)
 (command xy4)
 (command "_c")

 (setvar "plinewid" 0)
 (command "_layer""_set" al_lay "")
)





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun ss_rahm_red (satz rahm /
    art ee ent i ii neu plis x
    xmax xmin xy xy1 xy2 xy3 xy4 y ymax ymin
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Ein allgemeiner Auswahlsatz, der Objekte der gesamtem Zeichnung
;; umfa�t, wird auf einen Satz reduziert, dessen Definitionspunkte
;; innerhalb eines rechteckigen Rahmens liegen, der durch 'ss_rahm_setz'
;; erzeugt wurde.
;;
;; Dieser Rahmen mu� eine POLYLINE sein. Farbe, Layer und Linientype
;; sind ohne Bedeutung.
;;

 (if satz (progn
  (setq neu (ssadd))
  (setq plis (poly_lad rahm))

  (setq xy1 (car plis) xy2 (cadr plis) xy3 (caddr plis) xy4 (cadddr plis))
  (setq xmin (min (car xy1) (car xy2) (car xy3) (car xy4)))
  (setq xmax (max (car xy1) (car xy2) (car xy3) (car xy4)))
  (setq ymin (min (cadr xy1) (cadr xy2) (cadr xy3) (cadr xy4)))
  (setq ymax (max (cadr xy1) (cadr xy2) (cadr xy3) (cadr xy4)))

  (setq ii (sslength satz) i 0)

  (while (< i ii)
   (setq ent (ssname satz i) ee (entget ent))
   (setq art (cdr (assoc 0 ee)))

   (if (= art "POLYLINE")
    (setq xy (cdr (assoc 10 (entget (entnext ent)))))
    (setq xy (cdr (assoc 10 ee)))
   )

   (setq x (car xy) y (cadr xy))
   (if (and (> x xmin) (< x xmax) (> y ymin) (< y ymax)) (progn
    (setq neu (ssadd ent neu))
   ))
   (setq i (1+ i))
  )

  (if (= (sslength neu) 0) (setq neu nil))
 ))

 neu
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun re_setz (xy1 xy3 lay col lpt bre /
     al_lay xy2 xy4
 )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Zeigt am Bildschirm einen dicken Rahmen.
;;
 (command "_color" col)
 (command "_linetype" "_set" ltp "")
 (setq al_lay (getvar "CLAYER"))
 (command "_layer" "_m" lay "")

 (setq xy2 (list (car xy1) (cadr xy3)))
 (setq xy4 (list (car xy3) (cadr xy1)))

 (command "_pline" xy1 "_w" bre bre xy2)
 (command xy3)
 (command xy4)
 (command "_c")

 (setvar "plinewid" 0)
 (command "_layer""_set" al_lay "")
)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun runden (la nach art dif /
      fac
 )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Rundet L�ngen in m auf 'nach' Nachkommastellen
;; F�r art="Auf" wird immer aufgerundet,
;;     art="Ab"  wird immer abgerundet,
;;               sondt wird normal gerundet.
;; dif ist eine Zugabe zur L�nge
;;
 (setq art (strcase art) fac (expt 10 nach))

 (cond
  ((= art "AB")  (setq la (+ la dif) la (* la fac)
                      la (fix la) la (/ (float la) fac)))
  ((= art "AUF") (setq la (* la fac) la (fix (1+ la))
                      la (/ (float la) fac)))
  (T (setq la (* la fac) la (+ la 0.49999999999999)
                      la (fix la) la (/ (float la) fac)))
 )

 la
)


