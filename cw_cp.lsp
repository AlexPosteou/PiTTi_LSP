;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; CP - Copy Text
;
; Funktion kopiert Textinhalte von Quelltexten nach Zieltexten. Texte
; können dabei vollständig ersetzt, voran- oder nachgestellt werden.
; Ein integrierter Texteditor erlaubt das Ändern der Texte während des
; Kopierens.
; Alle Kopierschritte lassen sich vollständig rückgängig machen.
;
; Aufruf: cp
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


;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; MAIN
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

(defun c:cp (/ exitflag en ent enX txt txt_alt txt_neu)

;Initialisieren
  (setq	exitflag nil
	      cpundo nil
	     cpModus 1
  )

;Quelltext auswählen
  (while (= exitflag nil)
    (setq enX (nentsel "\nQuelltext wählen"))
    (if	(= nil enX)
			(setq exitflag T)
			(progn
				(setq en (car enx))
				(setq ent (entget en))
				(if (member (cdr (assoc 0 ent)) '("TEXT" "MTEXT" "RTEXT" "ATTRIB"))
					(setq exitflag T)
				)
			);progn
    );end if
  );while

;NIL ausschließen
  (if (= enX nil) ;#1
    (print)
    (progn ;#2
		;**Hauptprogramm**
		(setq exitflag nil)
		(setq txt (cdr (assoc 1 ent)))

		;Sind MText Steuercodes vorhanden?
		(if (wcmatch txt "*\\*")
			(princ "\n--> Der Quelltext enthält Formatierungsregeln. Diese können sich beim  Kopieren störend auswirken!")
		)

		;Benutzerausgabe
		(princ "\n\nModus: Ersetzen")

		;Auswahl steuern
		(while (= exitflag nil) ;#3
			(initget "Präfix Suffix Ersetzen Text Zurück")
			(setq aw (nentsel "\nZielobjekt wählen [Präfix/Suffix/Ersetzen/Text bearbeiten/Zurück] "))

			(if (member aw '("Präfix" "Suffix" "Ersetzen")) ;#4
				(progn
					(setq cpModus (cond
									((= aw "Präfix") 3)
									((= aw "Suffix") 2)
									((= aw "Ersetzen") 1)
									(T nil)
								);cond
					);setq
					(princ (strcat "\nModus: "
						(cond
						((= cpmodus 3) "Präfix")
						((= cpmodus 2) "Suffix")
						((= cpmodus 1) "Ersetzen")
						);cond
						);strcat
					);print
				);progn
				(progn ;Else #5
					(if	(= aw "Zurück") ;#6
						(if (= cpundo nil)
							(princ "\nAlle Änderungen wurden bereits zurückgenommen")
							(progn
								(setq	enx	(car (reverse cpundo))
								        en2	(car enx)
								        txt_neu (cadr enx)
								        ent2 (entget en2)
										ent2 (subst (cons 1 txt_neu) (assoc 1 ent2) ent2)
								)
								(entmod ent2)
								(entupd en2)
								(setq cpundo (reverse (cdr (reverse cpundo))))
							);progn
						);end if
						(progn ;#7
							(if (= aw "Text") ;#8
								(setq txt (cp_dlgchange txt)) ; Dialogfeld zum Ändern von Texten aufrufen
								(progn ;#9
									(if	(= aw nil) ;#10
										(setq exitflag T)
										(progn ;#11
											(setq en2 (car aw))
											(setq ent2 (entget en2))
											(setq text_before (cdr (assoc 1 ent2)))
											(if (member (cdr (assoc 0 ent2)) '("TEXT" "MTEXT" "RTEXT" "ATTRIB")) ;#12
												(progn ;Gewähltes Element ist ein gültiges Textfeld
													(if (= (cp_check_en ent2) "OK") ;#13
														(progn ;Das Objekt darf geändert werden
															(setq txt_alt (cdr (assoc 1 ent2)))
															(setq txt_neu (cond ((= cpmodus 3) (strcat txt txt_alt))
																		((= cpmodus 2) (strcat txt_alt txt))
																		((= cpmodus 1) txt))
															)
															(setq ent2 (subst (cons 1 txt_neu) (assoc 1 ent2) ent2))
															(entmod ent2)
															(entupd en2)
															(setq cpUndo (append cpUndo (list (list en2 txt_alt))))
														);progn
														(progn
															(princ "\nDas Element kann nicht geändert werden weil es ein Block/Vermassung/XREF ist")
														);progn
													);End if #13
												);progn
												(princ "\nGewähltes Objekt ist kein Textobjekt")
											) ;End if #12
										);progn #11
									);end if #10
								);progn #9
							);end if #8
						);progn #7
					);end if #6
				);progn #5
			);end if #4
		);while #3
    );progn #2
  );end if #1
  (print)
)


;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; CP_CHECK_EN
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

(defun cp_check_en (ent1_tmp / en2_tmp en2_obj_tmp lay_tmp result_tmp)

  ;Initialisieren
  (setq	lay_tmp (cdr (assoc 7 ent1_tmp))
	      en2_tmp (cdr (assoc 330 ent1_tmp))
	      en2_obj_tmp (vlax-ename->vla-object en2_tmp)
	      result_tmp "OK - LEER"
  )

  ;Eingabe prüfen
  (if (wcmatch lay_tmp "*|*")
		(setq result_tmp "XREF")
    (progn
			(if (= (cdr (assoc 0 ent1_tmp)) "ATTRIB")
				(setq result_tmp "OK")
				(if (= (vlax-get-property en2_obj_tmp 'IsLayout) :vlax-true)
					(setq result_tmp "OK")
					(setq result_tmp "Block oder Vermassung")
				);end if
			); End if
		); End progn
	); End if

  ;Ausgabe
  result_tmp
)


;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; CP_DLGCHANGE
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

(defun cp_dlgchange (tmpText / DLGflag tmpText2)
					;Dialog laden
  (setq dlgid (load_dialog "cw_cp.dcl"))
  (if (not (new_dialog "cp_dlg" dlgid))
    (progn
      (princ
	"\nDie Dialogdatei 'ccw_p.dcl' konnte nicht gefunden werden!"
      )
      (setq tmptext2 tmptext)
    )
    (progn
					;Dialog konfigurieren
      (set_tile "dlgText" tmpText)
      (action_tile
	"accept"
	"(setq DLGflag 1 tmpText2 (get_tile \"dlgText\")) (done_dialog)"
      )
      (action_tile
	"cancel"
	"(setq DLGflag 0 tmptext2 tmptext) (done_dialog)"
      )
      (mode_tile "dlgText" 2)

					;Dialog anzeigen
      (start_dialog)

					;Dialog beenden und entladen
      (unload_dialog dlgid)
    )
  )					;Wert zurückgeben
  tmptext2
)

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; ENDE
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

;(princ "\nTextCopy - (c) Dipl.-Ing. V. Kleppel, www.cadwerk.com")
;(princ "\nAufruf: cp")
;(print)
