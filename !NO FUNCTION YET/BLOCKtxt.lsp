; places name of block as text via pick
(defun C:blocktxt(/
;den verwendete Variablen lokale Gültigkeit zuweisen
sel seldaten blname pt1 TextStyleDaten texthöhe
)
  (setvar "cmdecho" 0); Unterdrückt die Ausgabe von Ausgaben in der Befehlszeile(von (command ..)
  ; die Objektwahl wird in eine Schleife gepackt, um sicher zu stellen, dass ein Objekt gewählt wurde und dieses auch dem Elementtype (in diesem Fall INSERT) entspricht
  (while (not sel)
    (setq sel (entsel (entsel"\nSelect Block:")))
    (if (not (and sel
  (car sel)
  (setq seldaten (entget (car sel)))
  (= "INSERT" (cdr(assoc 0 seldaten)))
  )
    )
      (setq sel nil)
      )
    )
  ; da sicher gestellt ist, dass ein Element gewählt wurde und dieses dem Elementtyp INSERT entspricht, kann es ohne Prüfung dessen weiter gehen
  (setq blname (cdr(assoc 2 seldaten)))
  (setq pt1 (getpoint"\nSelect point for block title:"))
  ; aktueller Textstil wird ausgewertet, um zu schauen, ob diesem eine Feste Höhe zugewiesen wurde
  ; Ist das der Fall, wird die Texthöhe in der Befehlszeile nicht abgefragt, weshalb die (command ..)-Anweisung unterschiedlich zu gestalten ist
  (setq TextStyleDaten (entget(TBLOBJNAME "STYLE"(getvar"TEXTSTYLE"))))
  (if (/= 0.0 (cdr (assoc 40 TextStyleDaten)))
    (progn;Textstil hat keine Höhe zugewiesen
      (initget 6)
      (setq texthöhe (getreal "\nTexthöhe: "))
      (command "text" pt1 (if texthöhe texthöhe "") 0 blname)
      )
    (progn;Textstil hat Höhe zugewiesen
      (command "text" pt1 0 blname)
      )
    )
  )