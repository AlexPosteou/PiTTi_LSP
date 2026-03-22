;;; ============================================================
;;; RND_TEILUNG.LSP
;;  Befehl TLG
;;; Ermittelt die Anzahl von Teilungspunkten (z.B. Schrauben)
;;; entlang einer oder zwei Linien und schreibt das Ergebnis
;;; in das Attribut ANZ eines gewaehlten Blocks RND_LEI.
;;;
;;; Autor  : gemeinsam entwickelt
;;; Version: 1.1  (ASCII-bereinigt)
;;; ============================================================

;;; ============================================================
;;; SCRIPTNAME
;;;   RND_TEILUNG.LSP
;;;
;;; ZWECK
;;;   Berechnet automatisch die Anzahl von Teilungspunkten
;;;   (z.B. Schrauben oder Befestigungen) entlang einer oder
;;;   zweier Linien und schreibt das Ergebnis in das Attribut
;;;   "ANZ" eines Blocks vom Typ RND_LEI.
;;;
;;; FUNKTIONSWEISE
;;;   1. Benutzer waehlt einen Block RND_LEI.
;;;   2. Das Script liest aus dem Block das Attribut "ABSTD".
;;;   3. Der Wert wird aus dem Format "-XX" oder "-XX.X"
;;;      interpretiert (Zentimeter) und in Meter umgerechnet.
;;;   4. Benutzer waehlt eine erste Linie und eine zweite Linie.
;;;      - Wird dieselbe Linie zweimal gewaehlt, arbeitet das
;;;        Script im Einzellinienmodus.
;;;   5. Aus den Linienendpunkten wird die Gesamtlaenge bestimmt.
;;;      Dabei wird die groessere Ausdehnung in X- oder Y-
;;;      Richtung als massgebliche Strecke verwendet.
;;;   6. Die Anzahl der Teilungspunkte wird berechnet:
;;;
;;;         ANZ = ceil(GESAMTL / ABSTD) + 1
;;;
;;;      (Aufrunden auf die naechste ganze Zahl).
;;;   7. Das Ergebnis wird in das Blockattribut "ANZ"
;;;      geschrieben.
;;;
;;; VORAUSSETZUNGEN
;;;   - AutoCAD mit AutoLISP-Unterstuetzung
;;;   - Script muss geladen sein (z.B. ueber APPLOAD)
;;;   - Block "RND_LEI" muss existieren
;;;   - Der Block muss folgende Attribute enthalten:
;;;        ABSTD  (Abstand der Teilung in cm)
;;;        ANZ    (Ausgabe der berechneten Anzahl)
;;;   - Es koennen maximal zwei LINE-Objekte verarbeitet werden.
;;;
;;; ANWENDUNG
;;;   1. Script laden:
;;;        APPLOAD -> RND_TEILUNG.LSP
;;;
;;;   2. Befehl starten:   TLG
;;;       
;;;
;;;   3. Block RND_LEI anklicken
;;;   4. Erste Linie waehlen
;;;   5. Zweite Linie waehlen
;;;      (oder gleiche Linie erneut fuer Einzellinie)
;;;
;;;   Das Script berechnet die Anzahl der Teilungspunkte und
;;;   schreibt das Ergebnis automatisch in das Attribut "ANZ".
;;;
;;; HINWEISE
;;;   - ABSTD muss einen Wert > 0 enthalten.
;;;   - Nur LINE-Objekte werden akzeptiert.
;;;   - Statusmeldungen erscheinen in der Befehlszeile.
;;;
;;; Version : 1.1
;;; ============================================================

;;; ------------------------------------------------------------
;;; Hilfsfunktion: Attributwert eines Blocks lesen
;;; Uebergabe: Block-Entity, Attribut-Tag (String)
;;; Rueckgabe: Attributwert als String oder nil
;;; ------------------------------------------------------------
(defun RND:get-attrib-value (blk-ent tag / attrib-ent attrib-tag result)
  (setq result     nil)
  (setq attrib-ent (entnext blk-ent))
  (while (and attrib-ent
              (/= (cdr (assoc 0 (entget attrib-ent))) "SEQEND"))
    (setq attrib-tag (cdr (assoc 2 (entget attrib-ent))))
    (if (= (strcase attrib-tag) (strcase tag))
      (setq result (cdr (assoc 1 (entget attrib-ent))))
    )
    (setq attrib-ent (entnext attrib-ent))
  )
  result
)


;;; ------------------------------------------------------------
;;; Hilfsfunktion: Attributwert eines Blocks schreiben
;;; Uebergabe: Block-Entity, Attribut-Tag (String), neuer Wert (String)
;;; Rueckgabe: T bei Erfolg
;;; ------------------------------------------------------------
(defun RND:set-attrib-value (blk-ent tag new-val / attrib-ent attrib-data attrib-tag)
  (setq attrib-ent (entnext blk-ent))
  (while (and attrib-ent
              (/= (cdr (assoc 0 (entget attrib-ent))) "SEQEND"))
    (setq attrib-data (entget attrib-ent))
    (setq attrib-tag  (cdr (assoc 2 attrib-data)))
    (if (= (strcase attrib-tag) (strcase tag))
      (progn
        (setq attrib-data (subst (cons 1 new-val)
                                 (assoc 1 attrib-data)
                                 attrib-data))
        (entmod attrib-data)
        (entupd attrib-ent)
      )
    )
    (setq attrib-ent (entnext attrib-ent))
  )
  T
)


;;; ------------------------------------------------------------
;;; Hilfsfunktion: ABSTD-String parsen
;;; Erwartet Format "-XX" oder "-XX.X" (Bindestrich = Praefix, kein Vorzeichen)
;;; Rueckgabe: Dezimalzahl in Metern oder nil bei Fehler
;;; ------------------------------------------------------------
(defun RND:parse-abstd (abstd-str / num-str val)
  (if (= (substr abstd-str 1 1) "-")
    (setq num-str (substr abstd-str 2))
    (setq num-str abstd-str)
  )
  (setq val (atof num-str))
  (if (> val 0.0)
    (/ val 100.0)
    nil
  )
)


;;; ------------------------------------------------------------
;;; Hilfsfunktion: Anfangs- und Endpunkt einer Linie lesen
;;; Uebergabe: Entity einer LINE
;;; Rueckgabe: Liste mit zwei 2D-Punkten ((x1 y1) (x2 y2))
;;; ------------------------------------------------------------
(defun RND:get-line-pts (line-ent / elist pt-start pt-end)
  (setq elist    (entget line-ent))
  (setq pt-start (cdr (assoc 10 elist)))
  (setq pt-end   (cdr (assoc 11 elist)))
  (list (list (car pt-start) (cadr pt-start))
        (list (car pt-end)   (cadr pt-end)))
)


;;; ------------------------------------------------------------
;;; Hilfsfunktion: Ceiling (Aufrunden auf naechste Ganzzahl)
;;; Berechnung: ceil(x) fuer positive Dezimalzahlen
;;; ------------------------------------------------------------
(defun RND:ceil (x / ix)
  (setq ix (fix x))
  (if (> x (float ix))
    (1+ ix)
    ix
  )
)


;;; ============================================================
;;; HAUPTFUNKTION
;;; Aufruf in AutoCAD: RND_TEILUNG
;;; ============================================================
(defun C:TLG (/ blk-ent blk-name
                        abstd-str abstd-m
                        sel1 ent1 handle1 pts1
                        sel2 ent2 handle2 pts2
                        all-pts
                        x-coords y-coords
                        dx dy gesamtl
                        anz anz-str)

  (princ "\n--- RND_TEILUNG - Teilungsberechnung ---")

  ;; ----------------------------------------------------------
  ;; SCHRITT 1: Block RND_LEI waehlen
  ;; ----------------------------------------------------------
  (setq blk-ent (car (entsel "\nBlock [RND_LEI] anklicken: ")))

  (if (null blk-ent)
    (progn (princ "\nAbbruch: Kein Objekt gewaehlt.") (exit))
  )

  (if (/= (cdr (assoc 0 (entget blk-ent))) "INSERT")
    (progn (princ "\nAbbruch: Gewaehltes Objekt ist kein Block.") (exit))
  )

  (setq blk-name (cdr (assoc 2 (entget blk-ent))))
  (princ (strcat "\nBlock erkannt: " blk-name))

  ;; ----------------------------------------------------------
  ;; SCHRITT 2: Attribut ABSTD lesen und parsen
  ;; ----------------------------------------------------------
  (setq abstd-str (RND:get-attrib-value blk-ent "ABSTD"))

  (if (null abstd-str)
    (progn (princ "\nAbbruch: Attribut ABSTD nicht gefunden.") (exit))
  )

  (setq abstd-m (RND:parse-abstd abstd-str))

  (if (null abstd-m)
    (progn
      (princ (strcat "\nAbbruch: ABSTD-Wert ungueltig [" abstd-str "]."))
      (exit)
    )
  )

  (princ (strcat "\nABSTD gelesen : " abstd-str " cm"
                 "  =>  " (rtos abstd-m 2 4) " m"))

  ;; ----------------------------------------------------------
  ;; SCHRITT 3: Erste Linie waehlen
  ;; ----------------------------------------------------------
  (setq sel1 (entsel "\nErste Linie waehlen: "))

  (if (null sel1)
    (progn (princ "\nAbbruch: Keine Linie gewaehlt.") (exit))
  )

  (setq ent1    (car sel1))
  (setq handle1 (cdr (assoc 5 (entget ent1))))

  (if (/= (cdr (assoc 0 (entget ent1))) "LINE")
    (progn (princ "\nAbbruch: Gewaeltes Objekt ist keine Linie.") (exit))
  )

  (setq pts1 (RND:get-line-pts ent1))
  (princ (strcat "\nLinie 1 OK (Handle: " handle1 ")"))

  ;; ----------------------------------------------------------
  ;; SCHRITT 4: Zweite Linie waehlen
  ;;            Dieselbe Linie nochmals = Einzellinie-Modus
  ;; ----------------------------------------------------------
  (setq sel2 (entsel "\nZweite Linie waehlen (oder Linie 1 nochmals fuer Einzellinie): "))

  (if (null sel2)
    (progn (princ "\nAbbruch: Keine zweite Linie gewaehlt.") (exit))
  )

  (setq ent2    (car sel2))
  (setq handle2 (cdr (assoc 5 (entget ent2))))

  (if (/= (cdr (assoc 0 (entget ent2))) "LINE")
    (progn (princ "\nAbbruch: Gewaehltes Objekt ist keine Linie.") (exit))
  )

  ;; ----------------------------------------------------------
  ;; SCHRITT 5: GESAMTL berechnen
  ;; ----------------------------------------------------------
  (if (= handle1 handle2)
    (progn
      (princ "\nEinzellinie erkannt (gleicher Handle).")
      (setq all-pts pts1)
    )
    (progn
      (setq pts2 (RND:get-line-pts ent2))
      (princ (strcat "\nLinie 2 OK (Handle: " handle2 ")"))
      (setq all-pts (append pts1 pts2))
    )
  )

  ;; Ausdehnung in X und Y bestimmen
  ;; Groessere Ausdehnung = massgebliche Achse
  (setq x-coords (mapcar 'car  all-pts))
  (setq y-coords (mapcar 'cadr all-pts))

  (setq dx (- (apply 'max x-coords) (apply 'min x-coords)))
  (setq dy (- (apply 'max y-coords) (apply 'min y-coords)))

  (if (>= dx dy)
    (progn
      (setq gesamtl dx)
      (princ "\nAusdehnung: X-Richtung")
    )
    (progn
      (setq gesamtl dy)
      (princ "\nAusdehnung: Y-Richtung")
    )
  )

  (princ (strcat "\nGESAMTL = " (rtos gesamtl 2 4) " m"))

  ;; ----------------------------------------------------------
  ;; SCHRITT 6: ANZ berechnen
  ;; ceil(GESAMTL / ABSTD_m) + 1
  ;; ----------------------------------------------------------
  (setq anz     (+ (RND:ceil (/ gesamtl abstd-m)) 1))
  (setq anz-str (itoa anz))

  (princ (strcat "\nANZ = ceil("
                 (rtos gesamtl 2 4) " / "
                 (rtos abstd-m 2 4) ") + 1 = "
                 anz-str))

  ;; ----------------------------------------------------------
  ;; SCHRITT 7: Attribut ANZ im Block schreiben
  ;; ----------------------------------------------------------
  (RND:set-attrib-value blk-ent "ANZ" anz-str)

  (princ (strcat "\nErgebnis: Attribut ANZ = " anz-str
                 " in Block [" blk-name "] gesetzt."))
  (princ "\n--- Fertig ---\n")

  (princ)
)

;;; ------------------------------------------------------------
;;; Lademeldung
;;; ------------------------------------------------------------
(princ "\nRND_TEILUNG.LSP geladen. Befehl: RND_TEILUNG")
(princ)
