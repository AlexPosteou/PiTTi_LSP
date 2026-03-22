;; ============================================================================
;; JoinLineToPolyline.lsp
;; ============================================================================
;;
;; ZWECK:
;; ------
;; Dieses Programm verbindet einzelne Linien-Objekte zu geschlossenen 
;; Polylinien und färbt diese ein. Es ist besonders nützlich beim Bereinigen
;; von importierten oder gescannten Zeichnungen, bei denen geschlossene 
;; Konturen aus vielen Einzellinien bestehen.
;;
;; VORGEHENSWEISE:
;; ---------------
;; 1. Normalisierung: Alle Z-Koordinaten der ausgewählten Linien werden 
;;    auf 0 gesetzt (2D-Ebene).
;;
;; 2. Bereinigung kurzer Linien: Linien mit einer Länge < 0.005 werden 
;;    automatisch gelöscht (typischerweise Zeichnungsfehler).
;;
;; 3. Erkennung überlappender Linien: Das Programm findet Linien, die 
;;    - vollständig übereinander liegen (doppelte Linien)
;;    - sich teilweise überlappen (auf gleicher Geraden)
;;    Die kürzere bzw. doppelte Linie wird auf den Layer "0_kurze Linie" 
;;    verschoben (dieser Layer wird automatisch eingefroren).
;;
;; 4. Kettenbildung: Linien, deren Anfangs- oder Endpunkte sich exakt 
;;    berühren (Toleranz 0.0001), werden zu Ketten verbunden.
;;
;; 5. Polylinienerstellung: Geschlossene Ketten (mindestens 3 Linien, 
;;    Start = Ende) werden zu Polylinien konvertiert und mit der 
;;    Farbe 171 eingefärbt.
;;
;; 6. Aufräumen: Die ursprünglichen Linien-Objekte werden nach erfolgreicher
;;    Konvertierung gelöscht.
;;
;; VORAUSSETZUNGEN:
;; ----------------
;; - AutoCAD oder kompatible CAD-Software mit LISP-Unterstützung
;; - Nur LINE-Objekte werden verarbeitet (keine Polylinien, Bögen, etc.)
;; - Linien müssen sich an gemeinsamen Endpunkten berühren (nicht überlappen)
;; - Für geschlossene Polylinien: mindestens 3 zusammenhängende Linien
;; - Die Endpunkte müssen mit einer Toleranz von 0.0001 übereinstimmen
;; - Z-Koordinaten sollten idealerweise bereits auf 0 sein (wird automatisch 
;;   korrigiert, aber unterschiedliche Z-Werte können zu Problemen führen)
;;
;; ANWENDUNGS-HINWEIS:
;; -------------------
;; 1. Laden Sie die Datei mit: (load "JoinLineToPolyline.lsp")
;; 2. Starten Sie das Programm durch Eingabe von: JOINPOLY
;; 3. Wählen Sie alle Linien aus, die verarbeitet werden sollen
;;    (am besten mit Fensterauswahl oder "Alle")
;; 4. Das Programm gibt während der Verarbeitung Statusmeldungen aus
;; 5. Prüfen Sie nach Abschluss:
;;    - Anzahl der erstellten Polylinien
;;    - Layer "0_kurze Linie" (aufgetaut) für verschobene Duplikate
;;    - Nicht verarbeitete Linien (offene Ketten)
;; 
;; TIPP: Führen Sie vor der Anwendung eine Sicherungskopie Ihrer Zeichnung
;;       durch, da das Programm Objekte löscht und verschiebt!
;;
;; Version: 3.5
;; Datum: 2024
;; ============================================================================

;; ========================================================================
;; VERSION 3.6 – Layer-sichere Polyline-Erstellung
;; ========================================================================

(defun create-polyline-from-chain (chain all-lines 
        / pt-list last-pt first-data pline-data 
          old-layer target-layer)

  ;; Aktuellen Layer sichern
  (setq old-layer (getvar "CLAYER"))

  ;; Ziel-Layer = Layer der ersten Linie der Kette
  (setq first-data (entget (car chain)))
  (setq target-layer (cdr (assoc 8 first-data)))

  ;; Sicherheitsmaßnahme:
  ;; Falls Ziel-Layer der "0_kurze Linie"-Layer ist,
  ;; dann verwende stattdessen den alten Layer
  (if (= target-layer "0_kurze Linie")
    (setq target-layer old-layer)
  )

  ;; Aktiven Layer setzen
  (setvar "CLAYER" target-layer)

  ;; ---------------------------
  ;; Punkte sammeln
  ;; ---------------------------

  (setq pt-list '())

  (setq first-data (get-line-data (car chain) all-lines))
  (setq pt-list (list (cadr first-data) (caddr first-data)))
  (setq last-pt (caddr first-data))

  (foreach line-ent (cdr chain)
    (setq next-data (get-line-data line-ent all-lines))
    (setq next-start (cadr next-data))
    (setq next-end (caddr next-data))

    (cond
      ((equal last-pt next-start 0.0001)
       (setq pt-list (append pt-list (list next-end)))
       (setq last-pt next-end)
      )
      ((equal last-pt next-end 0.0001)
       (setq pt-list (append pt-list (list next-start)))
       (setq last-pt next-start)
      )
    )
  )

  ;; Duplikate entfernen
  (setq pt-list (remove-duplicate-points pt-list))

  ;; ---------------------------
  ;; Polyline erzeugen
  ;; ---------------------------

  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")

  ;; ---------------------------
  ;; Farbe setzen
  ;; ---------------------------

  (setq pline-data (entget (entlast)))

  ;; Layer explizit setzen (Sicherheitsmaßnahme)
  (setq pline-data
        (subst (cons 8 target-layer)
               (assoc 8 pline-data)
               pline-data))

  ;; Farbe 171 setzen
  (if (assoc 62 pline-data)
    (setq pline-data
          (subst (cons 62 171)
                 (assoc 62 pline-data)
                 pline-data))
    (setq pline-data
          (append pline-data (list (cons 62 171))))
  )

  (entmod pline-data)

  ;; ---------------------------
  ;; Ursprüngliche Linien löschen
  ;; ---------------------------

  (foreach line-ent chain
    (entdel line-ent)
  )

  ;; Ursprünglichen Layer wiederherstellen
  (setvar "CLAYER" old-layer)
)
