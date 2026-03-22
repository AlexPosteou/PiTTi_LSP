;;;;;;;   Alle Dateien Laden

	(princ "Beginn des Ladens********************")
	(load "aca_lib1")
	(load "aca_lib2")
	(load "Werkzeugkästchen")
	(acad_init)
	(princ "\nEnde des Ladens *******************\n")

;;;;;;;   Projektordner aus der Datei C\\BieberCAD\\Projektpfad.txt auslesen bzw. Projektordner auswählen und die Datei ausfüllen

	(setq PPfad_file (open (findfile "Projektpfad.txt") "r"))
	(setq PPfad_aus (read-line PPfad_file))
	(close PPfad_file)
	
	; falls kein Projektordner ausgewählt wurde

	(if (or (= PPfad_aus NIL) (= PPfad_aus ""))(progn
		(setq PP_aus (dos_listbox "Auswahl vom Projektpfad" "Der Projektpfad wurde nicht ausgewählt. Jetzt auswählen?" '("Ja" "Nein")))
		(if (= PP_aus "Ja") 
			(Projektpfad_aus)
			(alert "Spätestens bei der Erstellung eines neuen Planes, müssen Sie den Projektpfad auswählen. Er bleibt auch beim Schließen von AutoCAD erhalten. Sie können ihn jede Zeit ändern.")
		) 
	))
	; falls der Ordner ausgewählt wurde und es keine Verbindung zu dem Ordner gibt
	
	(if (and (/= PPfad_aus NIL) (= (dos_dirp PPfad_aus) NIL) )(progn
		(alert "Es besteht keine Verbindung zum vorher ausgewählten Projektpfad. Die müssen den Projektpfad neu auswählen.")
		(setq PPfad_aus (dos_getdir "Projektpfad auswählen" ""))
		(setq PPfad_file (open (findfile "Projektpfad.txt") "w"))
		(if (/= PPfad_aus NIL)
			(progn
			(write-line PPfad_aus PPfad_file)
			(alert (strcat "Der neue Projektpfad ist " PPfad_aus "." ))
			)
			(progn
			(write-line PPfad_aus PPfad_file)
			(alert "Der vorher ausgewählte Projektpfad wurde wegen fehlender Verbindung gelöscht.")
			)
		) ; end if
		(close PPfad_file)
	))

;;;;;;;   Plotstilltabelle aus der Datei C\\BieberCAD\\Plotstilltabelle.txt auslesen

	(setq Plot_file (open (findfile "Plotstiltabelle.txt") "r"))
	(setq plotstiltabelle (read-line Plot_file))
	(close Plot_file)

;;;;;;;   Drucker aus der Datei C\\BieberCAD\\Drucker.txt auslesen bzw. Drucker auswählen und die Datei ausfüllen


;;;;;;;   Plotter aus der Datei C\\BieberCAD\\Plotter.txt auslesen bzw. Plotter auswählen und die Datei ausfüllen


;;;;;;;   Bemassungsstile definieren und DOT_I als aktuell einstellen

	(def_bemstile)
	(command "bemstil" "H" "DOT_I")

;;;;;;;   Optionen
	
	; Ofang für meinen Laptop
	(if (= (getvar "LOGINNAME") "G750JW-T4019H") (setvar "OSMODE" 33))
	; Nummernblock laden
	;(command "abilad" "Nummernblock.cuix")

;;;;;;;   BemassungsBlock DOT soll auf Layer 0 und VONBLOCK gesetzt werden.

	(defun-q PITTISTARTUP ( )
	
	(princ (load "DOT_0.lsp" "\nDOT_0.lsp nicht geladen!"))
	;(load "DOT_0.lsp")
	(c:dot_0)
	)

	(setq S::STARTUP (append S::STARTUP PITTISTARTUP))



;;;; 2019 Werkzeugkästchen nochmals laden, interner Fehler AutoCAD 2019

(vlax-for FOR-ITEM (vla-get-menugroups (vlax-get-acad-object))
(vlax-for FOR-TOOLBAR  (vla-get-toolbars FOR-ITEM)    

	(if (= (vla-get-name FOR-TOOLBAR) "B_Linien") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_linien_aus "1")
		)
	) 
	
	(if (= (vla-get-name FOR-TOOLBAR) "B_Mach wie") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_machwie_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_AutoCAD Standard") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_autocadstandard_aus "1")
		)
	)
	(if (= (vla-get-name FOR-TOOLBAR) "B_Objektfang") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_objektfang_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Layer") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_layer_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Text") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_text_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Schnitt") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_schnitt_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Schraffur") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_schraffur_aus "1")
		)
	)
 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Fang") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_fang_aus "1")
		)
	) 

	(if (= (vla-get-name FOR-TOOLBAR) "B_Objektmanipulation") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_objektmanipulation_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Projekt, Plan, Plotten") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_ppp_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Bibliotheken") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_bibliotheken_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Tripla") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_tripla_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Details") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_details_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Ablesen") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_ablesen_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Bemaßung") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_bemassung_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Block") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_block_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Positionsplan") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_positionsplan_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Bewehrung Info") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_bewinfo_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Rundstahl") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_rundstahl_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Matten") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_matten_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_HBT Anschluesse") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_hbtanschluesse_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_APS") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_aps_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Einbauteile") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_einbauteile_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Waende, Fundamente") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_waendefund_aus "1")
		)
	) 
	(if (= (vla-get-name FOR-TOOLBAR) "B_Verschiedenes") 

		(if (= (vla-get-visible FOR-TOOLBAR) :vlax-true) 
		(setq menu_verschiedenes_aus "1")
		)
	) 

))


(if (= menu_linien_aus "1") (progn (command "_.toolbar" "B_Linien" "_hide")(command "_.toolbar" "B_Linien" "_show")))
(if (= menu_machwie_aus "1") (progn (command "_.toolbar" "B_Mach wie" "_hide")(command "_.toolbar" "B_Mach wie" "_show")))
(if (= menu_autocadstandard_aus "1") (progn (command "_.toolbar" "B_AutoCAD Standard" "_hide")(command "_.toolbar" "B_AutoCAD Standard" "_show")))
(if (= menu_objektfang_aus "1") (progn (command "_.toolbar" "B_Objektfang" "_hide")(command "_.toolbar" "B_Objektfang" "_show")))
(if (= menu_layer_aus "1") (progn (command "_.toolbar" "B_Layer" "_hide")(command "_.toolbar" "B_Layer" "_show")))
(if (= menu_text_aus "1") (progn (command "_.toolbar" "B_Text" "_hide")(command "_.toolbar" "B_Text" "_show")))
(if (= menu_schnitt_aus "1") (progn (command "_.toolbar" "B_Schnitt" "_hide")(command "_.toolbar" "B_Schnitt" "_show")))
(if (= menu_schraffur_aus "1") (progn (command "_.toolbar" "B_Schraffur" "_hide")(command "_.toolbar" "B_Schraffur" "_show")))
(if (= menu_fang_aus "1") (progn (command "_.toolbar" "B_Fang" "_hide")(command "_.toolbar" "B_Fang" "_show")))
(if (= menu_objektmanipulation_aus "1") (progn (command "_.toolbar" "B_Objektmanipulation" "_hide")(command "_.toolbar" "B_Objektmanipulation" "_show")))
(if (= menu_ppp_aus "1") (progn (command "_.toolbar" "B_Projekt, Plan, Plotten" "_hide")(command "_.toolbar" "B_Projekt, Plan, Plotten" "_show")))
(if (= menu_bibliotheken_aus "1") (progn (command "_.toolbar" "B_Bibliotheken" "_hide")(command "_.toolbar" "B_Bibliotheken" "_show")))
(if (= menu_tripla_aus "1") (progn (command "_.toolbar" "B_Tripla" "_hide")(command "_.toolbar" "B_Tripla" "_show")))
(if (= menu_details_aus "1") (progn (command "_.toolbar" "B_Details" "_hide")(command "_.toolbar" "B_Details" "_show")))
(if (= menu_ablesen_aus "1") (progn (command "_.toolbar" "B_Ablesen" "_hide")(command "_.toolbar" "B_Ablesen" "_show")))
(if (= menu_bemassung_aus "1") (progn (command "_.toolbar" "B_Bemaßung" "_hide")(command "_.toolbar" "B_Bemaßung" "_show")))
(if (= menu_block_aus "1") (progn (command "_.toolbar" "B_Block" "_hide")(command "_.toolbar" "B_Block" "_show")))
(if (= menu_positionsplan_aus "1") (progn (command "_.toolbar" "B_Positionsplan" "_hide")(command "_.toolbar" "B_Positionsplan" "_show")))
(if (= menu_bewinfo_aus "1") (progn (command "_.toolbar" "B_Bewehrung Info" "_hide")(command "_.toolbar" "B_Bewehrung Info" "_show")))
(if (= menu_rundstahl_aus "1") (progn (command "_.toolbar" "B_Rundstahl" "_hide")(command "_.toolbar" "B_Rundstahl" "_show")))
(if (= menu_matten_aus "1") (progn (command "_.toolbar" "B_Matten" "_hide")(command "_.toolbar" "B_Matten" "_show")))
(if (= menu_hbtanschluesse_aus "1") (progn (command "_.toolbar" "B_HBT_Anschluesse" "_hide")(command "_.toolbar" "B_HBT_Anschluesse" "_show")))
(if (= menu_aps_aus "1") (progn (command "_.toolbar" "B_APS" "_hide")(command "_.toolbar" "B_APS" "_show")))
(if (= menu_einbauteile_aus "1") (progn (command "_.toolbar" "B_Einbauteile" "_hide")(command "_.toolbar" "B_Einbauteile" "_show")))
(if (= menu_waendefund_aus "1") (progn (command "_.toolbar" "B_Waende, Fundamente" "_hide")(command "_.toolbar" "B_Waende, Fundamente" "_show")))
(if (= menu_verschiedenes_aus "1") (progn (command "_.toolbar" "B_Verschiedenes" "_hide")(command "_.toolbar" "B_Verschiedenes" "_show")))


(princ)



