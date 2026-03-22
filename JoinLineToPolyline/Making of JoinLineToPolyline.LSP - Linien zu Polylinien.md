# Gibt es in AutoCAD einen Befehl, mit dem es möglich ist, bei einer frei gewählten Menge von Linien (die Auswahl erfolgt mit dem Befehl Kreuzen oder Fenster) die jenigen Linenzüge in geschlossene Polylinien wandelt, falls sich deren Enden exakt berühren?

<img src="JoinLineToPolyline.LSP - Linien zu Polylinien_01.jpg" alt="AutoLisp3.jpg" width="158" height="158">

<img width="20" height="20" src="JoinLineToPolyline.LSP - Linien zu Polylinien_02.png" class="jop-noMdConv"> via Mammouth

# Ja, in AutoCAD gibt es mehrere Möglichkeiten:

## 1\. **PEDIT** (Polylinie bearbeiten) - Klassische Methode

```
Befehl: PEDIT
- Wählen Sie mehrere Linien aus
- Option: J (für Verbinden/Join)
- Bestätigen Sie die Umwandlung in Polylinien
```

**Wichtig:** PEDIT verbindet nur Linien, deren Endpunkte **exakt** übereinstimmen.

## 2\. **VERBINDEN** (JOIN) - Moderne Alternative

```
Befehl: VERBINDEN (oder JOIN)
- Objekte wählen (mit Fenster/Kreuzen)
- Enter
```

Dieser Befehl ist einfacher und funktioniert auch mit Linien, Bögen und Polylinien.

## 3\. **Tipps für bessere Ergebnisse:**

- **Toleranz einstellen:** Bei PEDIT können Sie mit der Option **V** (Verknüpfungstyp) eine kleine Toleranz definieren, falls Endpunkte minimal voneinander abweichen
    
- **OVERKILL** vorher ausführen: Entfernt doppelte/überlappende Geometrien
    
- **Systemvariable PEDITACCEPT:** Setzen Sie diese auf `1`, um die Bestätigungsabfrage zu überspringen:
    
    ```
    PEDITACCEPT = 1
    ```
    

## Empfehlung:

Für Ihre Anforderung ist **VERBINDEN (JOIN)** am besten geeignet, da es automatisch geschlossene Polylinien erstellt, wenn die Endpunkte sich berühren.

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Kannst du mir eine AutoCAD-LISP-Datei (JoinLineToPolyline.lsp) erstellen? Diese enthält das Kommando "joinpoly", was folgendes bewirkt: 1. Aufforderung Objekte zu wählen 2. In der Auswahl sucht das Programm nach Linien. 3. Alle Linien, deren Anfangs- oder Endpunkte sich exakt berühren, werden zu einer geschlossenen Polylinie verbunden. 4. Alle in Polylinien konvertierte Objekte erhalten die Farbe 171.

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Hier ist die LISP-Datei für Ihre Anforderungen:

```
;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein

(defun c:joinpoly (/ ss i ent entlist processed-lines all-lines)
  (princ "\nJOINPOLY - Verbindet Linien zu geschlossenen Polylinien")
  (princ "\n========================================================")
  
  ;; Objekte auswählen
  (setq ss (ssget '((0 . "LINE"))))
  
  (if ss
    (progn
      (princ (strcat "\n" (itoa (sslength ss)) " Linien gefunden."))
      (setq all-lines '())
      (setq processed-lines '())
      
      ;; Alle Linien in eine Liste einlesen
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq entlist (entget ent))
        (setq all-lines (cons (list ent 
                                    (cdr (assoc 10 entlist))  ; Startpunkt
                                    (cdr (assoc 11 entlist))  ; Endpunkt
                              ) all-lines))
        (setq i (1+ i))
      )
      
      ;; Verarbeitung: Suche nach verbundenen Linienzügen
      (foreach line-data all-lines
        (if (not (member (car line-data) processed-lines))
          (progn
            (setq chain (build-chain (car line-data) all-lines processed-lines))
            (if (> (length chain) 1)
              (progn
                ;; Prüfen ob geschlossen
                (if (is-closed chain)
                  (progn
                    ;; Polylinie erstellen
                    (create-polyline-from-chain chain)
                    ;; Markiere alle verarbeiteten Linien
                    (foreach line-ent chain
                      (setq processed-lines (cons line-ent processed-lines))
                    )
                  )
                )
              )
            )
          )
        )
      )
      
      (princ "\nFertig! Geschlossene Polylinien wurden erstellt.")
    )
    (princ "\nKeine Linien ausgewählt.")
  )
  (princ)
)

;; Funktion: Baue Kette von verbundenen Linien
(defun build-chain (start-ent all-lines processed / chain current-ent found pt-start pt-end)
  (setq chain (list start-ent))
  (setq current-ent start-ent)
  (setq found T)
  
  (while found
    (setq found nil)
    (setq pt-end (get-endpoint current-ent))
    
    (foreach line-data all-lines
      (if (and (not (member (car line-data) chain))
               (not (member (car line-data) processed)))
        (progn
          (setq test-ent (car line-data))
          (setq test-start (cadr line-data))
          (setq test-end (caddr line-data))
          
          ;; Prüfe ob Endpunkt mit Start- oder Endpunkt der Testlinie übereinstimmt
          (if (or (equal pt-end test-start 0.0001)
                  (equal pt-end test-end 0.0001))
            (progn
              (setq chain (append chain (list test-ent)))
              (setq current-ent test-ent)
              (setq found T)
            )
          )
        )
      )
    )
  )
  chain
)

;; Funktion: Hole Endpunkt einer Linie
(defun get-endpoint (ent / entlist)
  (setq entlist (entget ent))
  (cdr (assoc 11 entlist))
)

;; Funktion: Prüfe ob Kette geschlossen ist
(defun is-closed (chain / first-start last-end)
  (if (> (length chain) 2)
    (progn
      (setq first-start (cdr (assoc 10 (entget (car chain)))))
      (setq last-end (cdr (assoc 11 (entget (last chain)))))
      (equal first-start last-end 0.0001)
    )
    nil
  )
)

;; Funktion: Erstelle Polylinie aus Kette und färbe sie
(defun create-polyline-from-chain (chain / pt-list ent entlist pt pline-data)
  (setq pt-list '())
  
  ;; Sammle alle Punkte
  (foreach line-ent chain
    (setq entlist (entget line-ent))
    (setq pt (cdr (assoc 10 entlist)))
    (setq pt-list (append pt-list (list pt)))
  )
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")  ; Schließen
  
  ;; Färbe die Polylinie mit Farbe 171
  (setq pline-data (entget (entlast)))
  (setq pline-data (subst (cons 62 171) (assoc 62 pline-data) pline-data))
  (if (not (assoc 62 pline-data))
    (setq pline-data (append pline-data (list (cons 62 171))))
  )
  (entmod pline-data)
  
  ;; Lösche originale Linien
  (foreach line-ent chain
    (entdel line-ent)
  )
)

(princ "\nJOINPOLY geladen. Tippen Sie 'joinpoly' zum Starten.")
(princ)
```

## Installation und Verwendung:

1.  **Speichern:** Speichern Sie den Code als `JoinLineToPolyline.lsp`
    
2.  **Laden in AutoCAD:**
    
    - Tippen Sie `APPLOAD`
    - Wählen Sie die LSP-Datei aus
    - Oder ziehen Sie die Datei in AutoCAD
3.  **Ausführen:**
    
    ```
    Befehl: joinpoly
    ```
    

## Funktionen:

✅ Wählt nur Linien aus  
✅ Findet verbundene Linien (Endpunkte müssen exakt übereinstimmen)  
✅ Erstellt geschlossene Polylinien  
✅ Färbt Polylinien mit Farbe 171  
✅ Löscht originale Linien

**Hinweis:** Die Toleranz für "exakt berühren" ist auf 0.0001 Einheiten gesetzt. Sie können dies im Code bei `(equal ... 0.0001)` anpassen.

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Deine Lisp-Routine funktioniert nur dann, wenn die Linien-Objekte in einem Zug gezeichnet wurden. Kannst du es auch so einrichten, es auch dann funktioniert, wenn dies nicht der Fall war?

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Ja, das Problem ist, dass die aktuelle Routine nur linear nach vorne sucht. Hier ist die verbesserte Version, die Linien in beliebiger Reihenfolge findet:

```
;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein
;; Version 2.0 - Funktioniert unabhängig von der Zeichenreihenfolge

(defun c:joinpoly (/ ss i ent entlist all-lines processed-lines closed-chains count)
  (princ "\nJOINPOLY - Verbindet Linien zu geschlossenen Polylinien")
  (princ "\n========================================================")
  
  ;; Objekte auswählen
  (setq ss (ssget '((0 . "LINE"))))
  
  (if ss
    (progn
      (princ (strcat "\n" (itoa (sslength ss)) " Linien gefunden."))
      (setq all-lines '())
      (setq processed-lines '())
      (setq closed-chains '())
      (setq count 0)
      
      ;; Alle Linien in eine Liste einlesen
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq entlist (entget ent))
        (setq all-lines (cons (list ent 
                                    (cdr (assoc 10 entlist))  ; Startpunkt
                                    (cdr (assoc 11 entlist))  ; Endpunkt
                              ) all-lines))
        (setq i (1+ i))
      )
      
      ;; Verarbeitung: Suche nach verbundenen Linienzügen
      (foreach line-data all-lines
        (if (not (member (car line-data) processed-lines))
          (progn
            (setq chain (build-chain-bidirectional (car line-data) all-lines))
            (if (and chain (> (length chain) 2))
              (progn
                ;; Prüfen ob geschlossen
                (if (is-closed-chain chain all-lines)
                  (progn
                    ;; Speichere geschlossene Kette
                    (setq closed-chains (cons chain closed-chains))
                    ;; Markiere alle verarbeiteten Linien
                    (foreach line-ent chain
                      (setq processed-lines (cons line-ent processed-lines))
                    )
                    (setq count (1+ count))
                  )
                )
              )
            )
          )
        )
      )
      
      ;; Erstelle Polylinien aus geschlossenen Ketten
      (foreach chain closed-chains
        (create-polyline-from-chain chain all-lines)
      )
      
      (princ (strcat "\n" (itoa count) " geschlossene Polylinie(n) wurden erstellt."))
    )
    (princ "\nKeine Linien ausgewählt.")
  )
  (princ)
)

;; Funktion: Baue Kette bidirektional (in beide Richtungen)
(defun build-chain-bidirectional (start-ent all-lines / chain used-ents changed)
  (setq chain (list start-ent))
  (setq used-ents (list start-ent))
  (setq changed T)
  
  ;; Wiederhole solange neue Linien gefunden werden
  (while changed
    (setq changed nil)
    
    ;; Durchsuche alle Linien in der aktuellen Kette
    (foreach current-ent chain
      (setq current-data (get-line-data current-ent all-lines))
      (if current-data
        (progn
          (setq current-start (cadr current-data))
          (setq current-end (caddr current-data))
          
          ;; Suche nach angrenzenden Linien
          (foreach line-data all-lines
            (if (not (member (car line-data) used-ents))
              (progn
                (setq test-ent (car line-data))
                (setq test-start (cadr line-data))
                (setq test-end (caddr line-data))
                
                ;; Prüfe alle möglichen Verbindungen
                (if (or (equal current-start test-start 0.0001)
                        (equal current-start test-end 0.0001)
                        (equal current-end test-start 0.0001)
                        (equal current-end test-end 0.0001))
                  (progn
                    (setq chain (append chain (list test-ent)))
                    (setq used-ents (cons test-ent used-ents))
                    (setq changed T)
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  chain
)

;; Funktion: Hole Linien-Daten aus der Liste
(defun get-line-data (ent all-lines / result)
  (setq result nil)
  (foreach line-data all-lines
    (if (equal (car line-data) ent)
      (setq result line-data)
    )
  )
  result
)

;; Funktion: Prüfe ob Kette geschlossen ist
(defun is-closed-chain (chain all-lines / endpoints pt count)
  (setq endpoints '())
  
  ;; Sammle alle Endpunkte
  (foreach ent chain
    (setq line-data (get-line-data ent all-lines))
    (if line-data
      (progn
        (setq endpoints (cons (cadr line-data) endpoints))  ; Startpunkt
        (setq endpoints (cons (caddr line-data) endpoints)) ; Endpunkt
      )
    )
  )
  
  ;; Prüfe ob alle Punkte genau 2x vorkommen (= geschlossen)
  (setq all-closed T)
  (foreach pt endpoints
    (setq count 0)
    (foreach test-pt endpoints
      (if (equal pt test-pt 0.0001)
        (setq count (1+ count))
      )
    )
    ;; Wenn ein Punkt nicht genau 2x vorkommt, ist die Kette nicht geschlossen
    (if (/= count 2)
      (setq all-closed nil)
    )
  )
  all-closed
)

;; Funktion: Erstelle Polylinie aus Kette und färbe sie
(defun create-polyline-from-chain (chain all-lines / 
                                    sorted-chain current-ent pt-list next-ent 
                                    current-end found entlist pline-data)
  
  ;; Sortiere die Kette in richtiger Reihenfolge
  (setq sorted-chain (list (car chain)))
  (setq current-ent (car chain))
  
  (repeat (1- (length chain))
    (setq current-data (get-line-data current-ent all-lines))
    (setq current-start (cadr current-data))
    (setq current-end (caddr current-data))
    
    ;; Bestimme welcher Endpunkt als nächstes verwendet wird
    (if (= (length sorted-chain) 1)
      (setq search-pt current-end)
      (setq search-pt current-end)
    )
    
    ;; Finde nächste verbundene Linie
    (setq found nil)
    (foreach test-ent chain
      (if (and (not (member test-ent sorted-chain))
               (not found))
        (progn
          (setq test-data (get-line-data test-ent all-lines))
          (setq test-start (cadr test-data))
          (setq test-end (caddr test-data))
          
          (if (or (equal current-end test-start 0.0001)
                  (equal current-end test-end 0.0001))
            (progn
              (setq sorted-chain (append sorted-chain (list test-ent)))
              (setq current-ent test-ent)
              (setq found T)
            )
          )
          
          (if (and (not found)
                   (or (equal current-start test-start 0.0001)
                       (equal current-start test-end 0.0001)))
            (progn
              (setq sorted-chain (append sorted-chain (list test-ent)))
              (setq current-ent test-ent)
              (setq found T)
            )
          )
        )
      )
    )
  )
  
  ;; Sammle Punkte in richtiger Reihenfolge
  (setq pt-list '())
  (setq current-ent (car sorted-chain))
  (setq current-data (get-line-data current-ent all-lines))
  (setq pt-list (list (cadr current-data)))
  (setq last-pt (cadr current-data))
  
  (foreach line-ent sorted-chain
    (setq line-data (get-line-data line-ent all-lines))
    (setq start-pt (cadr line-data))
    (setq end-pt (caddr line-data))
    
    (if (equal last-pt start-pt 0.0001)
      (progn
        (setq pt-list (append pt-list (list end-pt)))
        (setq last-pt end-pt)
      )
      (progn
        (setq pt-list (append pt-list (list start-pt)))
        (setq last-pt start-pt)
      )
    )
  )
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")
  
  ;; Färbe die Polylinie mit Farbe 171
  (setq pline-data (entget (entlast)))
  (setq pline-data (subst (cons 62 171) (assoc 62 pline-data) pline-data))
  (if (not (assoc 62 pline-data))
    (setq pline-data (append pline-data (list (cons 62 171))))
  )
  (entmod pline-data)
  
  ;; Lösche originale Linien
  (foreach line-ent chain
    (entdel line-ent)
  )
)

(princ "\nJOINPOLY geladen. Tippen Sie 'joinpoly' zum Starten.")
(princ)
```

## Hauptverbesserungen:

✅ **Bidirektionale Suche** - findet Linien in beliebiger Reihenfolge  
✅ **Intelligente Kettenbildung** - sammelt alle verbundenen Linien unabhängig von der Zeichenreihenfolge  
✅ **Verbesserte Geschlossenheitsprüfung** - prüft ob alle Endpunkte genau 2x vorkommen  
✅ **Korrekte Sortierung** - ordnet die Linien vor der Polylinienerstellung in die richtige Reihenfolge

Die Routine funktioniert jetzt auch wenn die Linien in völlig zufälliger Reihenfolge gezeichnet wurden!

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Kannst du das Lisp-Programm so erweitern, dass direkt nach der Auswahl alle Objekte gelöscht werden, die kürzer als 0.005 sind?

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Ja, hier ist die erweiterte Version mit automatischer Löschung von kurzen Linien:

```
;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein
;; Version 2.1 - Löscht kurze Linien automatisch

(defun c:joinpoly (/ ss i ent entlist all-lines processed-lines closed-chains count short-count)
  (princ "\nJOINPOLY - Verbindet Linien zu geschlossenen Polylinien")
  (princ "\n========================================================")
  
  ;; Objekte auswählen
  (setq ss (ssget '((0 . "LINE"))))
  
  (if ss
    (progn
      (princ (strcat "\n" (itoa (sslength ss)) " Linien gefunden."))
      (setq all-lines '())
      (setq processed-lines '())
      (setq closed-chains '())
      (setq count 0)
      (setq short-count 0)
      
      ;; Alle Linien in eine Liste einlesen und kurze Linien sofort löschen
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq entlist (entget ent))
        (setq pt-start (cdr (assoc 10 entlist)))
        (setq pt-end (cdr (assoc 11 entlist)))
        (setq line-length (distance pt-start pt-end))
        
        ;; Prüfe Linienlänge
        (if (< line-length 0.005)
          (progn
            ;; Linie ist zu kurz - löschen
            (entdel ent)
            (setq short-count (1+ short-count))
          )
          (progn
            ;; Linie ist lang genug - in Liste aufnehmen
            (setq all-lines (cons (list ent pt-start pt-end) all-lines))
          )
        )
        (setq i (1+ i))
      )
      
      (if (> short-count 0)
        (princ (strcat "\n" (itoa short-count) " kurze Linie(n) (< 0.005) wurden gelöscht."))
      )
      
      (if all-lines
        (progn
          (princ (strcat "\n" (itoa (length all-lines)) " Linien werden verarbeitet."))
          
          ;; Verarbeitung: Suche nach verbundenen Linienzügen
          (foreach line-data all-lines
            (if (not (member (car line-data) processed-lines))
              (progn
                (setq chain (build-chain-bidirectional (car line-data) all-lines))
                (if (and chain (> (length chain) 2))
                  (progn
                    ;; Prüfen ob geschlossen
                    (if (is-closed-chain chain all-lines)
                      (progn
                        ;; Speichere geschlossene Kette
                        (setq closed-chains (cons chain closed-chains))
                        ;; Markiere alle verarbeiteten Linien
                        (foreach line-ent chain
                          (setq processed-lines (cons line-ent processed-lines))
                        )
                        (setq count (1+ count))
                      )
                    )
                  )
                )
              )
            )
          )
          
          ;; Erstelle Polylinien aus geschlossenen Ketten
          (foreach chain closed-chains
            (create-polyline-from-chain chain all-lines)
          )
          
          (princ (strcat "\n" (itoa count) " geschlossene Polylinie(n) wurden erstellt."))
        )
        (princ "\nKeine gültigen Linien zum Verarbeiten übrig.")
      )
    )
    (princ "\nKeine Linien ausgewählt.")
  )
  (princ)
)

;; Funktion: Baue Kette bidirektional (in beide Richtungen)
(defun build-chain-bidirectional (start-ent all-lines / chain used-ents changed)
  (setq chain (list start-ent))
  (setq used-ents (list start-ent))
  (setq changed T)
  
  ;; Wiederhole solange neue Linien gefunden werden
  (while changed
    (setq changed nil)
    
    ;; Durchsuche alle Linien in der aktuellen Kette
    (foreach current-ent chain
      (setq current-data (get-line-data current-ent all-lines))
      (if current-data
        (progn
          (setq current-start (cadr current-data))
          (setq current-end (caddr current-data))
          
          ;; Suche nach angrenzenden Linien
          (foreach line-data all-lines
            (if (not (member (car line-data) used-ents))
              (progn
                (setq test-ent (car line-data))
                (setq test-start (cadr line-data))
                (setq test-end (caddr line-data))
                
                ;; Prüfe alle möglichen Verbindungen
                (if (or (equal current-start test-start 0.0001)
                        (equal current-start test-end 0.0001)
                        (equal current-end test-start 0.0001)
                        (equal current-end test-end 0.0001))
                  (progn
                    (setq chain (append chain (list test-ent)))
                    (setq used-ents (cons test-ent used-ents))
                    (setq changed T)
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  chain
)

;; Funktion: Hole Linien-Daten aus der Liste
(defun get-line-data (ent all-lines / result)
  (setq result nil)
  (foreach line-data all-lines
    (if (equal (car line-data) ent)
      (setq result line-data)
    )
  )
  result
)

;; Funktion: Prüfe ob Kette geschlossen ist
(defun is-closed-chain (chain all-lines / endpoints pt count)
  (setq endpoints '())
  
  ;; Sammle alle Endpunkte
  (foreach ent chain
    (setq line-data (get-line-data ent all-lines))
    (if line-data
      (progn
        (setq endpoints (cons (cadr line-data) endpoints))  ; Startpunkt
        (setq endpoints (cons (caddr line-data) endpoints)) ; Endpunkt
      )
    )
  )
  
  ;; Prüfe ob alle Punkte genau 2x vorkommen (= geschlossen)
  (setq all-closed T)
  (foreach pt endpoints
    (setq count 0)
    (foreach test-pt endpoints
      (if (equal pt test-pt 0.0001)
        (setq count (1+ count))
      )
    )
    ;; Wenn ein Punkt nicht genau 2x vorkommt, ist die Kette nicht geschlossen
    (if (/= count 2)
      (setq all-closed nil)
    )
  )
  all-closed
)

;; Funktion: Erstelle Polylinie aus Kette und färbe sie
(defun create-polyline-from-chain (chain all-lines / 
                                    sorted-chain current-ent pt-list next-ent 
                                    current-end found entlist pline-data)
  
  ;; Sortiere die Kette in richtiger Reihenfolge
  (setq sorted-chain (list (car chain)))
  (setq current-ent (car chain))
  
  (repeat (1- (length chain))
    (setq current-data (get-line-data current-ent all-lines))
    (setq current-start (cadr current-data))
    (setq current-end (caddr current-data))
    
    ;; Bestimme welcher Endpunkt als nächstes verwendet wird
    (if (= (length sorted-chain) 1)
      (setq search-pt current-end)
      (setq search-pt current-end)
    )
    
    ;; Finde nächste verbundene Linie
    (setq found nil)
    (foreach test-ent chain
      (if (and (not (member test-ent sorted-chain))
               (not found))
        (progn
          (setq test-data (get-line-data test-ent all-lines))
          (setq test-start (cadr test-data))
          (setq test-end (caddr test-data))
          
          (if (or (equal current-end test-start 0.0001)
                  (equal current-end test-end 0.0001))
            (progn
              (setq sorted-chain (append sorted-chain (list test-ent)))
              (setq current-ent test-ent)
              (setq found T)
            )
          )
          
          (if (and (not found)
                   (or (equal current-start test-start 0.0001)
                       (equal current-start test-end 0.0001)))
            (progn
              (setq sorted-chain (append sorted-chain (list test-ent)))
              (setq current-ent test-ent)
              (setq found T)
            )
          )
        )
      )
    )
  )
  
  ;; Sammle Punkte in richtiger Reihenfolge
  (setq pt-list '())
  (setq current-ent (car sorted-chain))
  (setq current-data (get-line-data current-ent all-lines))
  (setq pt-list (list (cadr current-data)))
  (setq last-pt (cadr current-data))
  
  (foreach line-ent sorted-chain
    (setq line-data (get-line-data line-ent all-lines))
    (setq start-pt (cadr line-data))
    (setq end-pt (caddr line-data))
    
    (if (equal last-pt start-pt 0.0001)
      (progn
        (setq pt-list (append pt-list (list end-pt)))
        (setq last-pt end-pt)
      )
      (progn
        (setq pt-list (append pt-list (list start-pt)))
        (setq last-pt start-pt)
      )
    )
  )
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")
  
  ;; Färbe die Polylinie mit Farbe 171
  (setq pline-data (entget (entlast)))
  (setq pline-data (subst (cons 62 171) (assoc 62 pline-data) pline-data))
  (if (not (assoc 62 pline-data))
    (setq pline-data (append pline-data (list (cons 62 171))))
  )
  (entmod pline-data)
  
  ;; Lösche originale Linien
  (foreach line-ent chain
    (entdel line-ent)
  )
)

(princ "\nJOINPOLY geladen. Tippen Sie 'joinpoly' zum Starten.")
(princ)
```

## Neue Funktionen:

✅ **Automatische Löschung kurzer Linien** - alle Linien < 0.005 werden sofort nach der Auswahl gelöscht  
✅ **Zähler für gelöschte Linien** - zeigt an, wie viele kurze Linien entfernt wurden  
✅ **Längenmessung** - verwendet die `distance` Funktion für präzise Berechnung

## Ausgabe-Beispiel:

```
JOINPOLY - Verbindet Linien zu geschlossenen Polylinien
========================================================
150 Linien gefunden.
12 kurze Linie(n) (< 0.005) wurden gelöscht.
138 Linien werden verarbeitet.
3 geschlossene Polylinie(n) wurden erstellt.
```

Falls Sie den Schwellenwert ändern möchten, ändern Sie einfach die `0.005` in Zeile 36 zu einem anderen Wert.

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Es gibt noch ein Problem, daß ich mir nicht erklären kann: Ich habe ein Viereck aus 4 Linien (sh. Original.txt). Dann wandelt das Kommando "joinpoly" diese um und ich erhalte ein Dreieck mit 3 geschlossenen Polylinien (sh. Ergebnis.txt) ## Schuld scheint die Linie mit der Referenz = 1802dec zu sein. Wenn ich diese Linie gegen eine neue austausche, erhalte ich ein geschlossenes Polyline-Viereck (sh. Original2.txt und Ergebnis2.txt.) Ich kann aber nicht erkennen, was an der Line mit der Referenz = 1802dec falsch sein sollte. # Dieses Problem besteht in vielen weiteren Strukturen, die eigentlich eine geschlossene Polylinie ergeben könnten. # Das Dienstprogramm \_audit findet keinen Fehler. Hast du eine Idee?

TXT

Ergebnis2.txt

TXT

Ergebnis.txt

TXT

Original.txt

TXT

Original2.txt

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Das Problem liegt an **doppelten/identischen Punkten** in der Polylinie! Schauen Sie sich die Kontrollpunkte an:

**In Ergebnis.txt:**

- Punkt 1: X=259.3435, Y=103.1633 ✓
- Punkt 2: X=259.5935, Y=103.1633 ✓
- **Punkt 3: X=259.3435, Y=103.1633** ← **DUPLIKAT von Punkt 1!**
- Punkt 4: X=259.3435, Y=102.0494 ✓
- Punkt 5: X=259.5935, Y=103.1633 ← sollte Y=102.0494 sein

Der Algorithmus fügt denselben Punkt mehrfach hinzu, weil die Sortierlogik fehlerhaft ist. Hier ist die korrigierte Version:

```
;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein
;; Version 2.2 - Behebt Duplikatpunkte-Problem

(defun c:joinpoly (/ ss i ent entlist all-lines processed-lines closed-chains count short-count)
  (princ "\nJOINPOLY - Verbindet Linien zu geschlossenen Polylinien")
  (princ "\n========================================================")
  
  ;; Objekte auswählen
  (setq ss (ssget '((0 . "LINE"))))
  
  (if ss
    (progn
      (princ (strcat "\n" (itoa (sslength ss)) " Linien gefunden."))
      (setq all-lines '())
      (setq processed-lines '())
      (setq closed-chains '())
      (setq count 0)
      (setq short-count 0)
      
      ;; Alle Linien in eine Liste einlesen und kurze Linien sofort löschen
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq entlist (entget ent))
        (setq pt-start (cdr (assoc 10 entlist)))
        (setq pt-end (cdr (assoc 11 entlist)))
        (setq line-length (distance pt-start pt-end))
        
        ;; Prüfe Linienlänge
        (if (< line-length 0.005)
          (progn
            ;; Linie ist zu kurz - löschen
            (entdel ent)
            (setq short-count (1+ short-count))
          )
          (progn
            ;; Linie ist lang genug - in Liste aufnehmen
            (setq all-lines (cons (list ent pt-start pt-end) all-lines))
          )
        )
        (setq i (1+ i))
      )
      
      (if (> short-count 0)
        (princ (strcat "\n" (itoa short-count) " kurze Linie(n) (< 0.005) wurden gelöscht."))
      )
      
      (if all-lines
        (progn
          (princ (strcat "\n" (itoa (length all-lines)) " Linien werden verarbeitet."))
          
          ;; Verarbeitung: Suche nach verbundenen Linienzügen
          (foreach line-data all-lines
            (if (not (member (car line-data) processed-lines))
              (progn
                (setq chain (build-chain-bidirectional (car line-data) all-lines))
                (if (and chain (> (length chain) 2))
                  (progn
                    ;; Prüfen ob geschlossen
                    (if (is-closed-chain chain all-lines)
                      (progn
                        ;; Speichere geschlossene Kette
                        (setq closed-chains (cons chain closed-chains))
                        ;; Markiere alle verarbeiteten Linien
                        (foreach line-ent chain
                          (setq processed-lines (cons line-ent processed-lines))
                        )
                        (setq count (1+ count))
                      )
                    )
                  )
                )
              )
            )
          )
          
          ;; Erstelle Polylinien aus geschlossenen Ketten
          (foreach chain closed-chains
            (create-polyline-from-chain chain all-lines)
          )
          
          (princ (strcat "\n" (itoa count) " geschlossene Polylinie(n) wurden erstellt."))
        )
        (princ "\nKeine gültigen Linien zum Verarbeiten übrig.")
      )
    )
    (princ "\nKeine Linien ausgewählt.")
  )
  (princ)
)

;; Funktion: Baue Kette bidirektional (in beide Richtungen)
(defun build-chain-bidirectional (start-ent all-lines / chain used-ents changed)
  (setq chain (list start-ent))
  (setq used-ents (list start-ent))
  (setq changed T)
  
  ;; Wiederhole solange neue Linien gefunden werden
  (while changed
    (setq changed nil)
    
    ;; Durchsuche alle Linien in der aktuellen Kette
    (foreach current-ent chain
      (setq current-data (get-line-data current-ent all-lines))
      (if current-data
        (progn
          (setq current-start (cadr current-data))
          (setq current-end (caddr current-data))
          
          ;; Suche nach angrenzenden Linien
          (foreach line-data all-lines
            (if (not (member (car line-data) used-ents))
              (progn
                (setq test-ent (car line-data))
                (setq test-start (cadr line-data))
                (setq test-end (caddr line-data))
                
                ;; Prüfe alle möglichen Verbindungen
                (if (or (equal current-start test-start 0.0001)
                        (equal current-start test-end 0.0001)
                        (equal current-end test-start 0.0001)
                        (equal current-end test-end 0.0001))
                  (progn
                    (setq chain (append chain (list test-ent)))
                    (setq used-ents (cons test-ent used-ents))
                    (setq changed T)
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  chain
)

;; Funktion: Hole Linien-Daten aus der Liste
(defun get-line-data (ent all-lines / result)
  (setq result nil)
  (foreach line-data all-lines
    (if (equal (car line-data) ent)
      (setq result line-data)
    )
  )
  result
)

;; Funktion: Prüfe ob Kette geschlossen ist
(defun is-closed-chain (chain all-lines / endpoints pt count)
  (setq endpoints '())
  
  ;; Sammle alle Endpunkte
  (foreach ent chain
    (setq line-data (get-line-data ent all-lines))
    (if line-data
      (progn
        (setq endpoints (cons (cadr line-data) endpoints))  ; Startpunkt
        (setq endpoints (cons (caddr line-data) endpoints)) ; Endpunkt
      )
    )
  )
  
  ;; Prüfe ob alle Punkte genau 2x vorkommen (= geschlossen)
  (setq all-closed T)
  (foreach pt endpoints
    (setq count 0)
    (foreach test-pt endpoints
      (if (equal pt test-pt 0.0001)
        (setq count (1+ count))
      )
    )
    ;; Wenn ein Punkt nicht genau 2x vorkommt, ist die Kette nicht geschlossen
    (if (/= count 2)
      (setq all-closed nil)
    )
  )
  all-closed
)

;; Funktion: Erstelle Polylinie aus Kette und färbe sie (KOMPLETT NEU)
(defun create-polyline-from-chain (chain all-lines / 
                                    pt-list current-ent current-data 
                                    current-start current-end next-ent 
                                    next-data next-start next-end
                                    used-ents found last-pt
                                    pline-data)
  
  ;; Starte mit der ersten Linie
  (setq used-ents '())
  (setq current-ent (car chain))
  (setq used-ents (cons current-ent used-ents))
  (setq current-data (get-line-data current-ent all-lines))
  (setq current-start (cadr current-data))
  (setq current-end (caddr current-data))
  
  ;; Initialisiere Punktliste mit dem Startpunkt
  (setq pt-list (list current-start))
  (setq last-pt current-end)
  
  ;; Durchlaufe die restlichen Linien
  (repeat (1- (length chain))
    (setq found nil)
    
    ;; Finde die nächste verbundene Linie
    (foreach test-ent chain
      (if (and (not (member test-ent used-ents))
               (not found))
        (progn
          (setq next-data (get-line-data test-ent all-lines))
          (setq next-start (cadr next-data))
          (setq next-end (caddr next-data))
          
          ;; Prüfe welcher Endpunkt von test-ent an last-pt anschließt
          (cond
            ;; Fall 1: next-start verbindet sich mit last-pt
            ((equal last-pt next-start 0.0001)
             (setq pt-list (append pt-list (list next-start)))
             (setq last-pt next-end)
             (setq used-ents (cons test-ent used-ents))
             (setq found T)
            )
            ;; Fall 2: next-end verbindet sich mit last-pt
            ((equal last-pt next-end 0.0001)
             (setq pt-list (append pt-list (list next-end)))
             (setq last-pt next-start)
             (setq used-ents (cons test-ent used-ents))
             (setq found T)
            )
          )
        )
      )
    )
  )
  
  ;; Entferne Duplikate (sicherheitshalber)
  (setq pt-list (remove-duplicate-points pt-list))
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")
  
  ;; Färbe die Polylinie mit Farbe 171
  (setq pline-data (entget (entlast)))
  (if (assoc 62 pline-data)
    (setq pline-data (subst (cons 62 171) (assoc 62 pline-data) pline-data))
    (setq pline-data (append pline-data (list (cons 62 171))))
  )
  (entmod pline-data)
  
  ;; Lösche originale Linien
  (foreach line-ent chain
    (entdel line-ent)
  )
)

;; Hilfsfunktion: Entferne doppelte Punkte aus Liste
(defun remove-duplicate-points (pt-list / result)
  (setq result '())
  (foreach pt pt-list
    (if (not (member-point pt result))
      (setq result (append result (list pt)))
    )
  )
  result
)

;; Hilfsfunktion: Prüfe ob Punkt bereits in Liste
(defun member-point (pt pt-list / found)
  (setq found nil)
  (foreach test-pt pt-list
    (if (equal pt test-pt 0.0001)
      (setq found T)
    )
  )
  found
)

(princ "\nJOINPOLY geladen. Tippen Sie 'joinpoly' zum Starten.")
(princ)
```

## Hauptänderungen:

✅ **Komplett überarbeitete `create-polyline-from-chain` Funktion** - vermeidet Duplikate durch korrekte Verfolgung des letzten Punktes

✅ **Neue Hilfsfunktionen:**

- `remove-duplicate-points` - entfernt identische Punkte
- `member-point` - prüft ob Punkt bereits existiert

✅ **Verbesserte Logik** - fügt nur noch neue, eindeutige Punkte hinzu

Das Problem war, dass die alte Funktion Punkte mehrfach hinzufügte, wenn sich Linien berührten. Die neue Version verfolgt genau, welcher Endpunkt als nächstes kommt und vermeidet Duplikate vollständig.

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Das hat funktioniert! Jetzt noch eine wichtige Verbesserung: Das Lisp-Programm scheitert, wenn zwei oder mehrere Linien aufeinander liegen. Könnten wir nach der erfogten Auswahl und dem Löschen der extrem kurzen Linien noch folgendes tun: 1. Start Z und Ende Z aller Linien auf 0,0000 legen 2. Übereinander liegende Linien finden 3. in diesem Fall soll nur die jeweils längste Linie in der Auswahl bleiben. 4. die kürzeren Linien sollen auf einen (zu erstellenden) Layer "0_kurze Linie" gelegt werden. 5. die bisherige Routine starten.

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Hier ist die erweiterte Version mit Behandlung von übereinanderliegenden Linien:

```
;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein
;; Version 3.0 - Mit Z-Normalisierung und Duplikat-Linien-Behandlung

(defun c:joinpoly (/ ss i ent entlist all-lines processed-lines closed-chains count short-count dup-count)
  (princ "\nJOINPOLY - Verbindet Linien zu geschlossenen Polylinien")
  (princ "\n========================================================")
  
  ;; Objekte auswählen
  (setq ss (ssget '((0 . "LINE"))))
  
  (if ss
    (progn
      (princ (strcat "\n" (itoa (sslength ss)) " Linien gefunden."))
      (setq all-lines '())
      (setq processed-lines '())
      (setq closed-chains '())
      (setq count 0)
      (setq short-count 0)
      (setq dup-count 0)
      
      ;; SCHRITT 1: Z-Koordinaten auf 0 setzen
      (princ "\nSchritt 1: Normalisiere Z-Koordinaten...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (normalize-z-coordinate ent)
        (setq i (1+ i))
      )
      
      ;; SCHRITT 2: Alle Linien einlesen und kurze Linien löschen
      (princ "\nSchritt 2: Entferne kurze Linien...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq entlist (entget ent))
        (setq pt-start (cdr (assoc 10 entlist)))
        (setq pt-end (cdr (assoc 11 entlist)))
        (setq line-length (distance pt-start pt-end))
        
        ;; Prüfe Linienlänge
        (if (< line-length 0.005)
          (progn
            ;; Linie ist zu kurz - löschen
            (entdel ent)
            (setq short-count (1+ short-count))
          )
          (progn
            ;; Linie ist lang genug - in Liste aufnehmen
            (setq all-lines (cons (list ent pt-start pt-end line-length) all-lines))
          )
        )
        (setq i (1+ i))
      )
      
      (if (> short-count 0)
        (princ (strcat "\n  " (itoa short-count) " kurze Linie(n) (< 0.005) wurden gelöscht."))
      )
      
      ;; SCHRITT 3: Übereinanderliegende Linien finden und behandeln
      (if all-lines
        (progn
          (princ "\nSchritt 3: Suche nach übereinanderliegenden Linien...")
          
          ;; Layer "0_kurze Linie" erstellen falls nicht vorhanden
          (create-layer-if-not-exists "0_kurze Linie")
          
          ;; Übereinanderliegende Linien behandeln
          (setq result (handle-overlapping-lines all-lines))
          (setq all-lines (car result))
          (setq dup-count (cadr result))
          
          (if (> dup-count 0)
            (princ (strcat "\n  " (itoa dup-count) " kürzere, übereinanderliegende Linie(n) auf Layer '0_kurze Linie' verschoben."))
          )
          
          ;; SCHRITT 4: Verarbeitung - Suche nach verbundenen Linienzügen
          (princ "\nSchritt 4: Verbinde Linien zu Polylinien...")
          (princ (strcat "\n  " (itoa (length all-lines)) " Linien werden verarbeitet."))
          
          ;; Verarbeitung: Suche nach verbundenen Linienzügen
          (foreach line-data all-lines
            (if (not (member (car line-data) processed-lines))
              (progn
                (setq chain (build-chain-bidirectional (car line-data) all-lines))
                (if (and chain (> (length chain) 2))
                  (progn
                    ;; Prüfen ob geschlossen
                    (if (is-closed-chain chain all-lines)
                      (progn
                        ;; Speichere geschlossene Kette
                        (setq closed-chains (cons chain closed-chains))
                        ;; Markiere alle verarbeiteten Linien
                        (foreach line-ent chain
                          (setq processed-lines (cons line-ent processed-lines))
                        )
                        (setq count (1+ count))
                      )
                    )
                  )
                )
              )
            )
          )
          
          ;; Erstelle Polylinien aus geschlossenen Ketten
          (foreach chain closed-chains
            (create-polyline-from-chain chain all-lines)
          )
          
          (princ (strcat "\n\n" (itoa count) " geschlossene Polylinie(n) wurden erstellt."))
          (princ "\n========================================================")
        )
        (princ "\nKeine gültigen Linien zum Verarbeiten übrig.")
      )
    )
    (princ "\nKeine Linien ausgewählt.")
  )
  (princ)
)

;; Funktion: Setze Z-Koordinaten auf 0
(defun normalize-z-coordinate (ent / entlist pt-start pt-end)
  (setq entlist (entget ent))
  (setq pt-start (cdr (assoc 10 entlist)))
  (setq pt-end (cdr (assoc 11 entlist)))
  
  ;; Setze Z auf 0
  (setq pt-start (list (car pt-start) (cadr pt-start) 0.0))
  (setq pt-end (list (car pt-end) (cadr pt-end) 0.0))
  
  ;; Aktualisiere Entity
  (setq entlist (subst (cons 10 pt-start) (assoc 10 entlist) entlist))
  (setq entlist (subst (cons 11 pt-end) (assoc 11 entlist) entlist))
  (entmod entlist)
)

;; Funktion: Erstelle Layer falls nicht vorhanden
(defun create-layer-if-not-exists (layer-name / layer-table)
  (if (not (tblsearch "LAYER" layer-name))
    (progn
      (command "_.LAYER" "_M" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde erstellt."))
    )
  )
)

;; Funktion: Behandle übereinanderliegende Linien
(defun handle-overlapping-lines (all-lines / 
                                  clean-lines checked-ents 
                                  current-ent current-data
                                  duplicates longest-ent
                                  dup-count)
  (setq clean-lines '())
  (setq checked-ents '())
  (setq dup-count 0)
  
  ;; Durchlaufe alle Linien
  (foreach line-data all-lines
    (setq current-ent (car line-data))
    
    ;; Nur verarbeiten wenn noch nicht geprüft
    (if (not (member current-ent checked-ents))
      (progn
        ;; Finde alle Duplikate (übereinanderliegende Linien)
        (setq duplicates (find-overlapping-lines line-data all-lines))
        
        ;; Markiere alle als geprüft
        (foreach dup-data duplicates
          (setq checked-ents (cons (car dup-data) checked-ents))
        )
        
        ;; Wenn Duplikate gefunden wurden
        (if (> (length duplicates) 1)
          (progn
            ;; Finde die längste Linie
            (setq longest-ent (find-longest-line duplicates))
            
            ;; Verschiebe alle kürzeren auf Layer "0_kurze Linie"
            (foreach dup-data duplicates
              (if (not (equal (car dup-data) longest-ent))
                (progn
                  (move-to-layer (car dup-data) "0_kurze Linie")
                  (setq dup-count (1+ dup-count))
                )
              )
            )
            
            ;; Füge nur die längste zur clean-lines hinzu
            (foreach dup-data duplicates
              (if (equal (car dup-data) longest-ent)
                (setq clean-lines (cons dup-data clean-lines))
              )
            )
          )
          ;; Keine Duplikate - normal hinzufügen
          (setq clean-lines (cons line-data clean-lines))
        )
      )
    )
  )
  
  (list clean-lines dup-count)
)

;; Funktion: Finde übereinanderliegende Linien
(defun find-overlapping-lines (line-data all-lines / 
                                overlapping current-start current-end
                                test-start test-end)
  (setq overlapping '())
  (setq current-start (cadr line-data))
  (setq current-end (caddr line-data))
  
  ;; Durchsuche alle Linien
  (foreach test-data all-lines
    (setq test-start (cadr test-data))
    (setq test-end (caddr test-data))
    
    ;; Prüfe ob Linien übereinander liegen (beide Richtungen)
    (if (or 
          ;; Fall 1: Gleiche Richtung
          (and (equal current-start test-start 0.0001)
               (equal current-end test-end 0.0001))
          ;; Fall 2: Umgekehrte Richtung
          (and (equal current-start test-end 0.0001)
               (equal current-end test-start 0.0001))
        )
      (setq overlapping (cons test-data overlapping))
    )
  )
  
  overlapping
)

;; Funktion: Finde längste Linie aus Liste
(defun find-longest-line (line-list / longest-ent max-length)
  (setq longest-ent nil)
  (setq max-length 0.0)
  
  (foreach line-data line-list
    (if (> (cadddr line-data) max-length)
      (progn
        (setq max-length (cadddr line-data))
        (setq longest-ent (car line-data))
      )
    )
  )
  
  longest-ent
)

;; Funktion: Verschiebe Entity auf anderen Layer
(defun move-to-layer (ent layer-name / entlist)
  (setq entlist (entget ent))
  (setq entlist (subst (cons 8 layer-name) (assoc 8 entlist) entlist))
  (entmod entlist)
)

;; Funktion: Baue Kette bidirektional (in beide Richtungen)
(defun build-chain-bidirectional (start-ent all-lines / chain used-ents changed)
  (setq chain (list start-ent))
  (setq used-ents (list start-ent))
  (setq changed T)
  
  ;; Wiederhole solange neue Linien gefunden werden
  (while changed
    (setq changed nil)
    
    ;; Durchsuche alle Linien in der aktuellen Kette
    (foreach current-ent chain
      (setq current-data (get-line-data current-ent all-lines))
      (if current-data
        (progn
          (setq current-start (cadr current-data))
          (setq current-end (caddr current-data))
          
          ;; Suche nach angrenzenden Linien
          (foreach line-data all-lines
            (if (not (member (car line-data) used-ents))
              (progn
                (setq test-ent (car line-data))
                (setq test-start (cadr line-data))
                (setq test-end (caddr line-data))
                
                ;; Prüfe alle möglichen Verbindungen
                (if (or (equal current-start test-start 0.0001)
                        (equal current-start test-end 0.0001)
                        (equal current-end test-start 0.0001)
                        (equal current-end test-end 0.0001))
                  (progn
                    (setq chain (append chain (list test-ent)))
                    (setq used-ents (cons test-ent used-ents))
                    (setq changed T)
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  chain
)

;; Funktion: Hole Linien-Daten aus der Liste
(defun get-line-data (ent all-lines / result)
  (setq result nil)
  (foreach line-data all-lines
    (if (equal (car line-data) ent)
      (setq result line-data)
    )
  )
  result
)

;; Funktion: Prüfe ob Kette geschlossen ist
(defun is-closed-chain (chain all-lines / endpoints pt count)
  (setq endpoints '())
  
  ;; Sammle alle Endpunkte
  (foreach ent chain
    (setq line-data (get-line-data ent all-lines))
    (if line-data
      (progn
        (setq endpoints (cons (cadr line-data) endpoints))  ; Startpunkt
        (setq endpoints (cons (caddr line-data) endpoints)) ; Endpunkt
      )
    )
  )
  
  ;; Prüfe ob alle Punkte genau 2x vorkommen (= geschlossen)
  (setq all-closed T)
  (foreach pt endpoints
    (setq count 0)
    (foreach test-pt endpoints
      (if (equal pt test-pt 0.0001)
        (setq count (1+ count))
      )
    )
    ;; Wenn ein Punkt nicht genau 2x vorkommt, ist die Kette nicht geschlossen
    (if (/= count 2)
      (setq all-closed nil)
    )
  )
  all-closed
)

;; Funktion: Erstelle Polylinie aus Kette und färbe sie
(defun create-polyline-from-chain (chain all-lines / 
                                    pt-list current-ent current-data 
                                    current-start current-end next-ent 
                                    next-data next-start next-end
                                    used-ents found last-pt
                                    pline-data)
  
  ;; Starte mit der ersten Linie
  (setq used-ents '())
  (setq current-ent (car chain))
  (setq used-ents (cons current-ent used-ents))
  (setq current-data (get-line-data current-ent all-lines))
  (setq current-start (cadr current-data))
  (setq current-end (caddr current-data))
  
  ;; Initialisiere Punktliste mit dem Startpunkt
  (setq pt-list (list current-start))
  (setq last-pt current-end)
  
  ;; Durchlaufe die restlichen Linien
  (repeat (1- (length chain))
    (setq found nil)
    
    ;; Finde die nächste verbundene Linie
    (foreach test-ent chain
      (if (and (not (member test-ent used-ents))
               (not found))
        (progn
          (setq next-data (get-line-data test-ent all-lines))
          (setq next-start (cadr next-data))
          (setq next-end (caddr next-data))
          
          ;; Prüfe welcher Endpunkt von test-ent an last-pt anschließt
          (cond
            ;; Fall 1: next-start verbindet sich mit last-pt
            ((equal last-pt next-start 0.0001)
             (setq pt-list (append pt-list (list next-start)))
             (setq last-pt next-end)
             (setq used-ents (cons test-ent used-ents))
             (setq found T)
            )
            ;; Fall 2: next-end verbindet sich mit last-pt
            ((equal last-pt next-end 0.0001)
             (setq pt-list (append pt-list (list next-end)))
             (setq last-pt next-start)
             (setq used-ents (cons test-ent used-ents))
             (setq found T)
            )
          )
        )
      )
    )
  )
  
  ;; Entferne Duplikate (sicherheitshalber)
  (setq pt-list (remove-duplicate-points pt-list))
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")
  
  ;; Färbe die Polylinie mit Farbe 171
  (setq pline-data (entget (entlast)))
  (if (assoc 62 pline-data)
    (setq pline-data (subst (cons 62 171) (assoc 62 pline-data) pline-data))
    (setq pline-data (append pline-data (list (cons 62 171))))
  )
  (entmod pline-data)
  
  ;; Lösche originale Linien
  (foreach line-ent chain
    (entdel line-ent)
  )
)

;; Hilfsfunktion: Entferne doppelte Punkte aus Liste
(defun remove-duplicate-points (pt-list / result)
  (setq result '())
  (foreach pt pt-list
    (if (not (member-point pt result))
      (setq result (append result (list pt)))
    )
  )
  result
)

;; Hilfsfunktion: Prüfe ob Punkt bereits in Liste
(defun member-point (pt pt-list / found)
  (setq found nil)
  (foreach test-pt pt-list
    (if (equal pt test-pt 0.0001)
      (setq found T)
    )
  )
  found
)

(princ "\nJOINPOLY geladen. Tippen Sie 'joinpoly' zum Starten.")
(princ)
```

## Neue Features:

✅ **Z-Normalisierung** - Setzt alle Z-Koordinaten auf 0.0000  
✅ **Duplikat-Erkennung** - Findet übereinanderliegende Linien (auch umgekehrt)  
✅ **Längenvergleich** - Behält nur die längste Linie  
✅ **Layer-Verwaltung** - Erstellt automatisch Layer "0_kurze Linie"  
✅ **Übersichtliche Ausgabe** - Zeigt jeden Schritt mit Statistiken

## Beispiel-Ausgabe:

```
JOINPOLY - Verbindet Linien zu geschlossenen Polylinien
========================================================
150 Linien gefunden.
Schritt 1: Normalisiere Z-Koordinaten...
Schritt 2: Entferne kurze Linien...
  5 kurze Linie(n) (< 0.005) wurden gelöscht.
Schritt 3: Suche nach übereinanderliegenden Linien...
  Layer '0_kurze Linie' wurde erstellt.
  8 kürzere, übereinanderliegende Linie(n) auf Layer '0_kurze Linie' verschoben.
Schritt 4: Verbinde Linien zu Polylinien...
  137 Linien werden verarbeitet.

3 geschlossene Polylinie(n) wurden erstellt.
========================================================
```

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Schau mal bitte in die Datei "Doppellinie.txt": Die Linien mit den Refferenzen: Referenz = 180661c von Punkt, X= 204.4408 Y= 96.0515 Z= 0.0000 nach Punkt, X= 208.6408 Y= 96.0515 Z= 0.0000 und Referenz = 180661a von Punkt, X= 208.6408 Y= 96.0515 Z= 0.0000 nach Punkt, X= 204.6908 Y= 96.0515 Z= 0.0000 liegen auf Y übereinander! Daher findet keine Umwandlung in Polylinien statt.

TXT

Doppellinie.txt

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Sie haben recht! Das Problem ist, dass die aktuelle Duplikat-Erkennung nur **identische** Linien findet (gleiche Start- und Endpunkte), aber keine **teilweise überlappenden** Linien.

Hier ist die korrigierte Version, die auch überlappende Linien erkennt:

```
;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein
;; Version 3.1 - Erkennt auch teilweise überlappende Linien

(defun c:joinpoly (/ ss i ent entlist all-lines processed-lines closed-chains count short-count dup-count)
  (princ "\nJOINPOLY - Verbindet Linien zu geschlossenen Polylinien")
  (princ "\n========================================================")
  
  ;; Objekte auswählen
  (setq ss (ssget '((0 . "LINE"))))
  
  (if ss
    (progn
      (princ (strcat "\n" (itoa (sslength ss)) " Linien gefunden."))
      (setq all-lines '())
      (setq processed-lines '())
      (setq closed-chains '())
      (setq count 0)
      (setq short-count 0)
      (setq dup-count 0)
      
      ;; SCHRITT 1: Z-Koordinaten auf 0 setzen
      (princ "\nSchritt 1: Normalisiere Z-Koordinaten...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (normalize-z-coordinate ent)
        (setq i (1+ i))
      )
      
      ;; SCHRITT 2: Alle Linien einlesen und kurze Linien löschen
      (princ "\nSchritt 2: Entferne kurze Linien...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq entlist (entget ent))
        (setq pt-start (cdr (assoc 10 entlist)))
        (setq pt-end (cdr (assoc 11 entlist)))
        (setq line-length (distance pt-start pt-end))
        
        ;; Prüfe Linienlänge
        (if (< line-length 0.005)
          (progn
            ;; Linie ist zu kurz - löschen
            (entdel ent)
            (setq short-count (1+ short-count))
          )
          (progn
            ;; Linie ist lang genug - in Liste aufnehmen
            (setq all-lines (cons (list ent pt-start pt-end line-length) all-lines))
          )
        )
        (setq i (1+ i))
      )
      
      (if (> short-count 0)
        (princ (strcat "\n  " (itoa short-count) " kurze Linie(n) (< 0.005) wurden gelöscht."))
      )
      
      ;; SCHRITT 3: Übereinanderliegende und überlappende Linien finden
      (if all-lines
        (progn
          (princ "\nSchritt 3: Suche nach übereinanderliegenden/überlappenden Linien...")
          
          ;; Layer "0_kurze Linie" erstellen falls nicht vorhanden
          (create-layer-if-not-exists "0_kurze Linie")
          
          ;; Übereinanderliegende Linien behandeln
          (setq result (handle-overlapping-lines all-lines))
          (setq all-lines (car result))
          (setq dup-count (cadr result))
          
          (if (> dup-count 0)
            (princ (strcat "\n  " (itoa dup-count) " kürzere, übereinanderliegende Linie(n) auf Layer '0_kurze Linie' verschoben."))
          )
          
          ;; SCHRITT 4: Verarbeitung - Suche nach verbundenen Linienzügen
          (princ "\nSchritt 4: Verbinde Linien zu Polylinien...")
          (princ (strcat "\n  " (itoa (length all-lines)) " Linien werden verarbeitet."))
          
          ;; Verarbeitung: Suche nach verbundenen Linienzügen
          (foreach line-data all-lines
            (if (not (member (car line-data) processed-lines))
              (progn
                (setq chain (build-chain-bidirectional (car line-data) all-lines))
                (if (and chain (> (length chain) 2))
                  (progn
                    ;; Prüfen ob geschlossen
                    (if (is-closed-chain chain all-lines)
                      (progn
                        ;; Speichere geschlossene Kette
                        (setq closed-chains (cons chain closed-chains))
                        ;; Markiere alle verarbeiteten Linien
                        (foreach line-ent chain
                          (setq processed-lines (cons line-ent processed-lines))
                        )
                        (setq count (1+ count))
                      )
                    )
                  )
                )
              )
            )
          )
          
          ;; Erstelle Polylinien aus geschlossenen Ketten
          (foreach chain closed-chains
            (create-polyline-from-chain chain all-lines)
          )
          
          (princ (strcat "\n\n" (itoa count) " geschlossene Polylinie(n) wurden erstellt."))
          (princ "\n========================================================")
        )
        (princ "\nKeine gültigen Linien zum Verarbeiten übrig.")
      )
    )
    (princ "\nKeine Linien ausgewählt.")
  )
  (princ)
)

;; Funktion: Setze Z-Koordinaten auf 0
(defun normalize-z-coordinate (ent / entlist pt-start pt-end)
  (setq entlist (entget ent))
  (setq pt-start (cdr (assoc 10 entlist)))
  (setq pt-end (cdr (assoc 11 entlist)))
  
  ;; Setze Z auf 0
  (setq pt-start (list (car pt-start) (cadr pt-start) 0.0))
  (setq pt-end (list (car pt-end) (cadr pt-end) 0.0))
  
  ;; Aktualisiere Entity
  (setq entlist (subst (cons 10 pt-start) (assoc 10 entlist) entlist))
  (setq entlist (subst (cons 11 pt-end) (assoc 11 entlist) entlist))
  (entmod entlist)
)

;; Funktion: Erstelle Layer falls nicht vorhanden
(defun create-layer-if-not-exists (layer-name / layer-table)
  (if (not (tblsearch "LAYER" layer-name))
    (progn
      (command "_.LAYER" "_M" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde erstellt."))
    )
  )
)

;; Funktion: Behandle übereinanderliegende und überlappende Linien
(defun handle-overlapping-lines (all-lines / 
                                  clean-lines checked-ents 
                                  current-ent current-data
                                  duplicates longest-ent
                                  dup-count)
  (setq clean-lines '())
  (setq checked-ents '())
  (setq dup-count 0)
  
  ;; Durchlaufe alle Linien
  (foreach line-data all-lines
    (setq current-ent (car line-data))
    
    ;; Nur verarbeiten wenn noch nicht geprüft
    (if (not (member current-ent checked-ents))
      (progn
        ;; Finde alle Duplikate (übereinanderliegende/überlappende Linien)
        (setq duplicates (find-overlapping-lines line-data all-lines))
        
        ;; Markiere alle als geprüft
        (foreach dup-data duplicates
          (setq checked-ents (cons (car dup-data) checked-ents))
        )
        
        ;; Wenn Duplikate gefunden wurden
        (if (> (length duplicates) 1)
          (progn
            ;; Finde die längste Linie
            (setq longest-ent (find-longest-line duplicates))
            
            ;; Verschiebe alle kürzeren auf Layer "0_kurze Linie"
            (foreach dup-data duplicates
              (if (not (equal (car dup-data) longest-ent))
                (progn
                  (move-to-layer (car dup-data) "0_kurze Linie")
                  (setq dup-count (1+ dup-count))
                )
              )
            )
            
            ;; Füge nur die längste zur clean-lines hinzu
            (foreach dup-data duplicates
              (if (equal (car dup-data) longest-ent)
                (setq clean-lines (cons dup-data clean-lines))
              )
            )
          )
          ;; Keine Duplikate - normal hinzufügen
          (setq clean-lines (cons line-data clean-lines))
        )
      )
    )
  )
  
  (list clean-lines dup-count)
)

;; Funktion: Prüfe ob zwei Punkte auf einer Linie liegen
(defun point-on-line (pt line-start line-end / 
                       dist-total dist1 dist2)
  ;; Berechne Distanzen
  (setq dist-total (distance line-start line-end))
  (setq dist1 (distance line-start pt))
  (setq dist2 (distance pt line-end))
  
  ;; Punkt liegt auf Linie wenn dist1 + dist2 ≈ dist-total
  (< (abs (- (+ dist1 dist2) dist-total)) 0.0001)
)

;; Funktion: Prüfe ob Linien kollinear (auf derselben Geraden) sind
(defun lines-collinear (start1 end1 start2 end2 / )
  ;; Prüfe ob alle 4 Punkte auf derselben Linie liegen
  (and 
    (point-on-line start2 start1 end1)
    (point-on-line end2 start1 end1)
  )
)

;; Funktion: Finde übereinanderliegende/überlappende Linien
(defun find-overlapping-lines (line-data all-lines / 
                                overlapping current-start current-end
                                test-start test-end)
  (setq overlapping '())
  (setq current-start (cadr line-data))
  (setq current-end (caddr line-data))
  
  ;; Durchsuche alle Linien
  (foreach test-data all-lines
    (setq test-start (cadr test-data))
    (setq test-end (caddr test-data))
    
    ;; Prüfe ob Linien übereinander/überlappend liegen
    (if (or 
          ;; Fall 1: Identische Linie (gleiche Richtung)
          (and (equal current-start test-start 0.0001)
               (equal current-end test-end 0.0001))
          ;; Fall 2: Identische Linie (umgekehrte Richtung)
          (and (equal current-start test-end 0.0001)
               (equal current-end test-start 0.0001))
          ;; Fall 3: Linien liegen auf derselben Geraden (kollinear)
          (lines-collinear current-start current-end test-start test-end)
          ;; Fall 4: Linien liegen auf derselben Geraden (umgekehrte Richtung)
          (lines-collinear current-start current-end test-end test-start)
        )
      (setq overlapping (cons test-data overlapping))
    )
  )
  
  overlapping
)

;; Funktion: Finde längste Linie aus Liste
(defun find-longest-line (line-list / longest-ent max-length)
  (setq longest-ent nil)
  (setq max-length 0.0)
  
  (foreach line-data line-list
    (if (> (cadddr line-data) max-length)
      (progn
        (setq max-length (cadddr line-data))
        (setq longest-ent (car line-data))
      )
    )
  )
  
  longest-ent
)

;; Funktion: Verschiebe Entity auf anderen Layer
(defun move-to-layer (ent layer-name / entlist)
  (setq entlist (entget ent))
  (setq entlist (subst (cons 8 layer-name) (assoc 8 entlist) entlist))
  (entmod entlist)
)

;; Funktion: Baue Kette bidirektional (in beide Richtungen)
(defun build-chain-bidirectional (start-ent all-lines / chain used-ents changed)
  (setq chain (list start-ent))
  (setq used-ents (list start-ent))
  (setq changed T)
  
  ;; Wiederhole solange neue Linien gefunden werden
  (while changed
    (setq changed nil)
    
    ;; Durchsuche alle Linien in der aktuellen Kette
    (foreach current-ent chain
      (setq current-data (get-line-data current-ent all-lines))
      (if current-data
        (progn
          (setq current-start (cadr current-data))
          (setq current-end (caddr current-data))
          
          ;; Suche nach angrenzenden Linien
          (foreach line-data all-lines
            (if (not (member (car line-data) used-ents))
              (progn
                (setq test-ent (car line-data))
                (setq test-start (cadr line-data))
                (setq test-end (caddr line-data))
                
                ;; Prüfe alle möglichen Verbindungen
                (if (or (equal current-start test-start 0.0001)
                        (equal current-start test-end 0.0001)
                        (equal current-end test-start 0.0001)
                        (equal current-end test-end 0.0001))
                  (progn
                    (setq chain (append chain (list test-ent)))
                    (setq used-ents (cons test-ent used-ents))
                    (setq changed T)
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  chain
)

;; Funktion: Hole Linien-Daten aus der Liste
(defun get-line-data (ent all-lines / result)
  (setq result nil)
  (foreach line-data all-lines
    (if (equal (car line-data) ent)
      (setq result line-data)
    )
  )
  result
)

;; Funktion: Prüfe ob Kette geschlossen ist
(defun is-closed-chain (chain all-lines / endpoints pt count)
  (setq endpoints '())
  
  ;; Sammle alle Endpunkte
  (foreach ent chain
    (setq line-data (get-line-data ent all-lines))
    (if line-data
      (progn
        (setq endpoints (cons (cadr line-data) endpoints))  ; Startpunkt
        (setq endpoints (cons (caddr line-data) endpoints)) ; Endpunkt
      )
    )
  )
  
  ;; Prüfe ob alle Punkte genau 2x vorkommen (= geschlossen)
  (setq all-closed T)
  (foreach pt endpoints
    (setq count 0)
    (foreach test-pt endpoints
      (if (equal pt test-pt 0.0001)
        (setq count (1+ count))
      )
    )
    ;; Wenn ein Punkt nicht genau 2x vorkommt, ist die Kette nicht geschlossen
    (if (/= count 2)
      (setq all-closed nil)
    )
  )
  all-closed
)

;; Funktion: Erstelle Polylinie aus Kette und färbe sie
(defun create-polyline-from-chain (chain all-lines / 
                                    pt-list current-ent current-data 
                                    current-start current-end next-ent 
                                    next-data next-start next-end
                                    used-ents found last-pt
                                    pline-data)
  
  ;; Starte mit der ersten Linie
  (setq used-ents '())
  (setq current-ent (car chain))
  (setq used-ents (cons current-ent used-ents))
  (setq current-data (get-line-data current-ent all-lines))
  (setq current-start (cadr current-data))
  (setq current-end (caddr current-data))
  
  ;; Initialisiere Punktliste mit dem Startpunkt
  (setq pt-list (list current-start))
  (setq last-pt current-end)
  
  ;; Durchlaufe die restlichen Linien
  (repeat (1- (length chain))
    (setq found nil)
    
    ;; Finde die nächste verbundene Linie
    (foreach test-ent chain
      (if (and (not (member test-ent used-ents))
               (not found))
        (progn
          (setq next-data (get-line-data test-ent all-lines))
          (setq next-start (cadr next-data))
          (setq next-end (caddr next-data))
          
          ;; Prüfe welcher Endpunkt von test-ent an last-pt anschließt
          (cond
            ;; Fall 1: next-start verbindet sich mit last-pt
            ((equal last-pt next-start 0.0001)
             (setq pt-list (append pt-list (list next-start)))
             (setq last-pt next-end)
             (setq used-ents (cons test-ent used-ents))
             (setq found T)
            )
            ;; Fall 2: next-end verbindet sich mit last-pt
            ((equal last-pt next-end 0.0001)
             (setq pt-list (append pt-list (list next-end)))
             (setq last-pt next-start)
             (setq used-ents (cons test-ent used-ents))
             (setq found T)
            )
          )
        )
      )
    )
  )
  
  ;; Entferne Duplikate (sicherheitshalber)
  (setq pt-list (remove-duplicate-points pt-list))
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")
  
  ;; Färbe die Polylinie mit Farbe 171
  (setq pline-data (entget (entlast)))
  (if (assoc 62 pline-data)
    (setq pline-data (subst (cons 62 171) (assoc 62 pline-data) pline-data))
    (setq pline-data (append pline-data (list (cons 62 171))))
  )
  (entmod pline-data)
  
  ;; Lösche originale Linien
  (foreach line-ent chain
    (entdel line-ent)
  )
)

;; Hilfsfunktion: Entferne doppelte Punkte aus Liste
(defun remove-duplicate-points (pt-list / result)
  (setq result '())
  (foreach pt pt-list
    (if (not (member-point pt result))
      (setq result (append result (list pt)))
    )
  )
  result
)

;; Hilfsfunktion: Prüfe ob Punkt bereits in Liste
(defun member-point (pt pt-list / found)
  (setq found nil)
  (foreach test-pt pt-list
    (if (equal pt test-pt 0.0001)
      (setq found T)
    )
  )
  found
)

(princ "\nJOINPOLY geladen. Tippen Sie 'joinpoly' zum Starten.")
(princ)
```

## Hauptverbesserungen:

✅ **Neue Funktion `point-on-line`** - Prüft ob ein Punkt auf einer Linie liegt  
✅ **Neue Funktion `lines-collinear`** - Erkennt ob Linien auf derselben Geraden liegen  
✅ **Erweiterte `find-overlapping-lines`** - Findet auch **teilweise überlappende** Linien

In Ihrem Beispiel:

- Linie 1: X=204.4408 bis X=208.6408 (Länge 4.2)
- Linie 2: X=208.6408 bis X=204.6908 (Länge 3.95)

Diese liegen auf Y=96.0515 übereinander → die kürzere wird nun auf Layer "0_kurze Linie" verschoben!

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

In dem Lisp-Programm gibt es noch ein logisches Problem: Der Layer "0_kurze Linie" muss, bevor die doppelten Linien dahin verschoben werden, gefroren sein, da diese Linien für das Programm ansonsten weiterhin sichtbar bleiben und somit erfolgt keine Bildung einer Polylinie.

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Sorry, I was unable to process your message. Please try sending it again.

If the issue persist, consider using another model and returning later.

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

In dem Lisp-Programm gibt es noch ein logisches Problem: Der Layer "0_kurze Linie" muss, bevor die doppelten Linien dahin verschoben werden, gefroren sein, da diese Linien für das Programm ansonsten weiterhin sichtbar bleiben und somit erfolgt keine Bildung einer Polylinie.

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Absolut richtig! Die verschobenen Linien bleiben in der `all-lines` Liste und stören die Polylinien-Bildung. Hier ist die korrigierte Version:

```
;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein
;; Version 3.2 - Layer wird gefroren + Linien aus Liste entfernt

(defun c:joinpoly (/ ss i ent entlist all-lines processed-lines closed-chains count short-count dup-count)
  (princ "\nJOINPOLY - Verbindet Linien zu geschlossenen Polylinien")
  (princ "\n========================================================")
  
  ;; Objekte auswählen
  (setq ss (ssget '((0 . "LINE"))))
  
  (if ss
    (progn
      (princ (strcat "\n" (itoa (sslength ss)) " Linien gefunden."))
      (setq all-lines '())
      (setq processed-lines '())
      (setq closed-chains '())
      (setq count 0)
      (setq short-count 0)
      (setq dup-count 0)
      
      ;; SCHRITT 1: Z-Koordinaten auf 0 setzen
      (princ "\nSchritt 1: Normalisiere Z-Koordinaten...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (normalize-z-coordinate ent)
        (setq i (1+ i))
      )
      
      ;; SCHRITT 2: Alle Linien einlesen und kurze Linien löschen
      (princ "\nSchritt 2: Entferne kurze Linien...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq entlist (entget ent))
        (setq pt-start (cdr (assoc 10 entlist)))
        (setq pt-end (cdr (assoc 11 entlist)))
        (setq line-length (distance pt-start pt-end))
        
        ;; Prüfe Linienlänge
        (if (< line-length 0.005)
          (progn
            ;; Linie ist zu kurz - löschen
            (entdel ent)
            (setq short-count (1+ short-count))
          )
          (progn
            ;; Linie ist lang genug - in Liste aufnehmen
            (setq all-lines (cons (list ent pt-start pt-end line-length) all-lines))
          )
        )
        (setq i (1+ i))
      )
      
      (if (> short-count 0)
        (princ (strcat "\n  " (itoa short-count) " kurze Linie(n) (< 0.005) wurden gelöscht."))
      )
      
      ;; SCHRITT 3: Übereinanderliegende und überlappende Linien finden
      (if all-lines
        (progn
          (princ "\nSchritt 3: Suche nach übereinanderliegenden/überlappenden Linien...")
          
          ;; Layer "0_kurze Linie" erstellen falls nicht vorhanden und einfrieren
          (create-and-freeze-layer "0_kurze Linie")
          
          ;; Finde alle übereinanderliegenden Linien
          (setq all-lines (find-and-remove-overlapping-lines all-lines))
          
          (if (> dup-count 0)
            (princ (strcat "\n  " (itoa dup-count) " kürzere, übereinanderliegende Linie(n) auf gefrorenen Layer '0_kurze Linie' verschoben."))
          )
        )
      )
      
      ;; SCHRITT 4: Verbinde Linien zu geschlossenen Polylinien
      (if all-lines
        (progn
          (princ "\nSchritt 4: Verbinde Linien zu Polylinien...")
          (princ (strcat "\n  " (itoa (length all-lines)) " Linien werden verarbeitet."))
          
          ;; Verarbeite alle Linien
          (foreach line-data all-lines
            (if (not (member (car line-data) processed-lines))
              (progn
                (setq chain (build-chain (car line-data) all-lines))
                (if (is-closed-chain chain all-lines)
                  (progn
                    (create-polyline-from-chain chain all-lines)
                    (setq count (1+ count))
                    (setq closed-chains (cons chain closed-chains))
                  )
                )
              )
            )
          )
          
          (princ (strcat "\n" (itoa count) " geschlossene Polylinie(n) wurden erstellt."))
        )
        (princ "\nKeine Linien zum Verarbeiten übrig.")
      )
      
      (princ "\n========================================================")
    )
    (princ "\nKeine Objekte ausgewählt.")
  )
  (princ)
)

;; Hilfsfunktion: Normalisiere Z-Koordinate auf 0
(defun normalize-z-coordinate (ent / entlist pt-start pt-end)
  (setq entlist (entget ent))
  (setq pt-start (cdr (assoc 10 entlist)))
  (setq pt-end (cdr (assoc 11 entlist)))
  
  ;; Setze Z auf 0.0
  (setq pt-start (list (car pt-start) (cadr pt-start) 0.0))
  (setq pt-end (list (car pt-end) (cadr pt-end) 0.0))
  
  ;; Update Entity
  (setq entlist (subst (cons 10 pt-start) (assoc 10 entlist) entlist))
  (setq entlist (subst (cons 11 pt-end) (assoc 11 entlist) entlist))
  (entmod entlist)
)

;; Hilfsfunktion: Layer erstellen und einfrieren
(defun create-and-freeze-layer (layer-name / layer-table layer-entry)
  (setq layer-table (tblsearch "LAYER" layer-name))
  
  (if (not layer-table)
    (progn
      ;; Layer existiert nicht - erstellen
      (command "._-LAYER" "_M" layer-name "_C" "7" layer-name "_F" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde erstellt und gefroren."))
    )
    (progn
      ;; Layer existiert - nur einfrieren
      (command "._-LAYER" "_F" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde gefroren."))
    )
  )
)

;; Hilfsfunktion: Prüfe ob Punkt auf Linie liegt
(defun point-on-line (pt p1 p2 / tol)
  (setq tol 0.0001)
  ;; Prüfe ob Punkt zwischen p1 und p2 liegt
  (and
    ;; Punkt liegt auf der Geraden (Kreuzprodukt = 0)
    (< (abs (- (* (- (car pt) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr pt) (cadr p1)) (- (car p2) (car p1))))) tol)
    ;; Punkt liegt zwischen p1 und p2
    (or
      (and (<= (car p1) (car pt) (car p2)) (<= (cadr p1) (cadr pt) (cadr p2)))
      (and (<= (car p2) (car pt) (car p1)) (<= (cadr p2) (cadr pt) (cadr p1)))
      (and (<= (car p1) (car pt) (car p2)) (<= (cadr p2) (cadr pt) (cadr p1)))
      (and (<= (car p2) (car pt) (car p1)) (<= (cadr p1) (cadr pt) (cadr p2)))
    )
  )
)

;; Hilfsfunktion: Prüfe ob zwei Linien kollinear sind (auf derselben Geraden liegen)
(defun lines-collinear (p1 p2 p3 p4 / tol)
  (setq tol 0.0001)
  ;; Alle 4 Punkte müssen auf derselben Geraden liegen
  (and
    (< (abs (- (* (- (car p3) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr p3) (cadr p1)) (- (car p2) (car p1))))) tol)
    (< (abs (- (* (- (car p4) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr p4) (cadr p1)) (- (car p2) (car p1))))) tol)
  )
)

;; Hilfsfunktion: Finde überlappende Linien und entferne kürzere aus Liste
(defun find-and-remove-overlapping-lines (line-list / i j current-data test-data result removed)
  (setq result line-list)
  (setq removed '())
  (setq dup-count 0)
  
  (setq i 0)
  (while (< i (length result))
    (setq current-data (nth i result))
    (setq current-ent (car current-data))
    (setq current-p1 (cadr current-data))
    (setq current-p2 (caddr current-data))
    (setq current-len (cadddr current-data))
    
    (setq j (1+ i))
    (while (< j (length result))
      (setq test-data (nth j result))
      (setq test-ent (car test-data))
      (setq test-p1 (cadr test-data))
      (setq test-p2 (caddr test-data))
      (setq test-len (cadddr test-data))
      
      ;; Prüfe ob Linien kollinear sind und sich überlappen
      (if (and (lines-collinear current-p1 current-p2 test-p1 test-p2)
               (or (point-on-line test-p1 current-p1 current-p2)
                   (point-on-line test-p2 current-p1 current-p2)
                   (point-on-line current-p1 test-p1 test-p2)
                   (point-on-line current-p2 test-p1 test-p2)))
        (progn
          ;; Linien überlappen - kürzere auf Layer verschieben
          (if (< test-len current-len)
            (progn
              ;; test-Linie ist kürzer
              (move-to-layer test-ent "0_kurze Linie")
              (setq result (remove-nth j result))
              (setq removed (cons test-ent removed))
              (setq dup-count (1+ dup-count))
              (setq j (1- j))  ;; Index korrigieren da Element entfernt wurde
            )
            (progn
              ;; current-Linie ist kürzer oder gleich lang
              (move-to-layer current-ent "0_kurze Linie")
              (setq result (remove-nth i result))
              (setq removed (cons current-ent removed))
              (setq dup-count (1+ dup-count))
              (setq i (1- i))  ;; Index korrigieren und äußere Schleife neu starten
              (setq j (length result))  ;; Innere Schleife beenden
            )
          )
        )
      )
      (setq j (1+ j))
    )
    (setq i (1+ i))
  )
  
  result
)

;; Hilfsfunktion: Entferne n-tes Element aus Liste
(defun remove-nth (n lst / i result)
  (setq i 0)
  (setq result '())
  (foreach item lst
    (if (/= i n)
      (setq result (append result (list item)))
    )
    (setq i (1+ i))
  )
  result
)

;; Hilfsfunktion: Verschiebe Linie auf anderen Layer
(defun move-to-layer (ent layer-name / entlist)
  (setq entlist (entget ent))
  (setq entlist (subst (cons 8 layer-name) (assoc 8 entlist) entlist))
  (entmod entlist)
)

;; Hilfsfunktion: Hole Linien-Daten aus Liste
(defun get-line-data (ent line-list / result)
  (setq result nil)
  (foreach line-data line-list
    (if (equal (car line-data) ent)
      (setq result line-data)
    )
  )
  result
)

;; Hilfsfunktion: Baue Linienkette von Startpunkt aus
(defun build-chain (start-ent all-lines / chain last-pt found test-ent used-ents start-data)
  (setq chain (list start-ent))
  (setq used-ents (list start-ent))
  (setq processed-lines (cons start-ent processed-lines))
  
  ;; Hole Start- und Endpunkt der ersten Linie
  (setq start-data (get-line-data start-ent all-lines))
  (setq last-pt (caddr start-data))  ;; Beginne am Endpunkt
  
  ;; Suche weitere anschließende Linien
  (setq found T)
  (while found
    (setq found nil)
    (foreach line-data all-lines
      (if (not found)
        (progn
          (setq test-ent (car line-data))
          (if (and (not (member test-ent used-ents))
                   (not (member test-ent processed-lines)))
            (progn
              (setq next-data (get-line-data test-ent all-lines))
              (setq next-start (cadr next-data))
              (setq next-end (caddr next-data))
              
              ;; Prüfe welcher Endpunkt von test-ent an last-pt anschließt
              (cond
                ;; Fall 1: next-start verbindet sich mit last-pt
                ((equal last-pt next-start 0.0001)
                 (setq chain (append chain (list test-ent)))
                 (setq last-pt next-end)
                 (setq used-ents (cons test-ent used-ents))
                 (setq processed-lines (cons test-ent processed-lines))
                 (setq found T)
                )
                ;; Fall 2: next-end verbindet sich mit last-pt
                ((equal last-pt next-end 0.0001)
                 (setq chain (append chain (list test-ent)))
                 (setq last-pt next-start)
                 (setq used-ents (cons test-ent used-ents))
                 (setq processed-lines (cons test-ent processed-lines))
                 (setq found T)
                )
              )
            )
          )
        )
      )
    )
  )
  
  chain
)

;; Hilfsfunktion: Prüfe ob Kette geschlossen ist
(defun is-closed-chain (chain all-lines / first-data last-data first-start last-end)
  (if (>= (length chain) 3)
    (progn
      (setq first-data (get-line-data (car chain) all-lines))
      (setq last-data (get-line-data (last chain) all-lines))
      (setq first-start (cadr first-data))
      (setq last-end (caddr last-data))
      
      ;; Prüfe ob letzte und erste Linie sich verbinden
      (or
        (equal first-start last-end 0.0001)
        (equal first-start (cadr last-data) 0.0001)
      )
    )
    nil
  )
)

;; Hilfsfunktion: Erstelle Polylinie aus Linienkette
(defun create-polyline-from-chain (chain all-lines / pt-list last-pt first-data)
  (setq pt-list '())
  
  ;; Starte mit der ersten Linie
  (setq first-data (get-line-data (car chain) all-lines))
  (setq pt-list (list (cadr first-data) (caddr first-data)))
  (setq last-pt (caddr first-data))
  
  ;; Füge alle weiteren Punkte hinzu
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
  
  ;; Entferne Duplikate
  (setq pt-list (remove-duplicate-points pt-list))
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")
  
  ;; Färbe die Polylinie mit Farbe 171
  (setq pline-data (entget (entlast)))
  (if (assoc 62 pline-data)
    (setq pline-data (subst (cons 62 171) (assoc 62 pline-data) pline-data))
    (setq pline-data (append pline-data (list (cons 62 171))))
  )
  (entmod pline-data)
  
  ;; Lösche originale Linien
  (foreach line-ent chain
    (entdel line-ent)
  )
)

;; Hilfsfunktion: Entferne doppelte Punkte aus Liste
(defun remove-duplicate-points (pt-list / result)
  (setq result '())
  (foreach pt pt-list
    (if (not (member-point pt result))
      (setq result (append result (list pt)))
    )
  )
  result
)

;; Hilfsfunktion: Prüfe ob Punkt bereits in Liste
(defun member-point (pt pt-list / found)
  (setq found nil)
  (foreach test-pt pt-list
    (if (equal pt test-pt 0.0001)
      (setq found T)
    )
  )
  found
)

(princ "\nJOINPOLY geladen. Tippen Sie 'joinpoly' zum Starten.")
(princ)
```

## Wichtige Änderungen:

✅ **`create-and-freeze-layer`** - Erstellt Layer UND friert ihn sofort ein  
✅ **`find-and-remove-overlapping-lines`** - Entfernt verschobene Linien aus `all-lines` Liste  
✅ **Gefrorener Layer** - Verschobene Linien sind unsichtbar und beeinflussen die Polylinienerstellung nicht mehr

Jetzt sollte Ihr Beispiel funktionieren! Die kürzere Linie wird auf den gefrorenen Layer verschoben und stört nicht mehr.

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Es ist noch eine Korrektur erforderlich: Zwei Linien-Objekte können waagerecht oder senkrecht auf einer Linie liegen, und einen gemeinsamen Start- oder Endpunkt besitzen, sich aber dennoch nicht überlappen. In diesem Fall sollten sie zu einer Polylinie verbunden werden. Das heist, es muß in der Routine genau geprüft werden, ob sich Linien wirklich überlappen, also mehr als einen gemeinsamen Punkt besitzen. Kannst du das Problem in der LISP-Datei lösen?

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Absolut richtig! Zwei Linien die sich nur an einem Endpunkt berühren dürfen NICHT als überlappend betrachtet werden. Hier ist die korrigierte Version:

```
;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein
;; Version 3.3 - Korrekte Überlappungsprüfung

(defun c:joinpoly (/ ss i ent entlist all-lines processed-lines closed-chains count short-count dup-count)
  (princ "\nJOINPOLY - Verbindet Linien zu geschlossenen Polylinien")
  (princ "\n========================================================")
  
  ;; Objekte auswählen
  (setq ss (ssget '((0 . "LINE"))))
  
  (if ss
    (progn
      (princ (strcat "\n" (itoa (sslength ss)) " Linien gefunden."))
      (setq all-lines '())
      (setq processed-lines '())
      (setq closed-chains '())
      (setq count 0)
      (setq short-count 0)
      (setq dup-count 0)
      
      ;; SCHRITT 1: Z-Koordinaten auf 0 setzen
      (princ "\nSchritt 1: Normalisiere Z-Koordinaten...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (normalize-z-coordinate ent)
        (setq i (1+ i))
      )
      
      ;; SCHRITT 2: Alle Linien einlesen und kurze Linien löschen
      (princ "\nSchritt 2: Entferne kurze Linien...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq entlist (entget ent))
        (setq pt-start (cdr (assoc 10 entlist)))
        (setq pt-end (cdr (assoc 11 entlist)))
        (setq line-length (distance pt-start pt-end))
        
        ;; Prüfe Linienlänge
        (if (< line-length 0.005)
          (progn
            ;; Linie ist zu kurz - löschen
            (entdel ent)
            (setq short-count (1+ short-count))
          )
          (progn
            ;; Linie ist lang genug - in Liste aufnehmen
            (setq all-lines (cons (list ent pt-start pt-end line-length) all-lines))
          )
        )
        (setq i (1+ i))
      )
      
      (if (> short-count 0)
        (princ (strcat "\n  " (itoa short-count) " kurze Linie(n) (< 0.005) wurden gelöscht."))
      )
      
      ;; SCHRITT 3: Übereinanderliegende und überlappende Linien finden
      (if all-lines
        (progn
          (princ "\nSchritt 3: Suche nach übereinanderliegenden/überlappenden Linien...")
          
          ;; Layer "0_kurze Linie" erstellen falls nicht vorhanden und einfrieren
          (create-and-freeze-layer "0_kurze Linie")
          
          ;; Finde alle übereinanderliegenden Linien
          (setq all-lines (find-and-remove-overlapping-lines all-lines))
          
          (if (> dup-count 0)
            (princ (strcat "\n  " (itoa dup-count) " kürzere, übereinanderliegende Linie(n) auf gefrorenen Layer '0_kurze Linie' verschoben."))
          )
        )
      )
      
      ;; SCHRITT 4: Verbinde Linien zu geschlossenen Polylinien
      (if all-lines
        (progn
          (princ "\nSchritt 4: Verbinde Linien zu Polylinien...")
          (princ (strcat "\n  " (itoa (length all-lines)) " Linien werden verarbeitet."))
          
          ;; Verarbeite alle Linien
          (foreach line-data all-lines
            (if (not (member (car line-data) processed-lines))
              (progn
                (setq chain (build-chain (car line-data) all-lines))
                (if (is-closed-chain chain all-lines)
                  (progn
                    (create-polyline-from-chain chain all-lines)
                    (setq count (1+ count))
                    (setq closed-chains (cons chain closed-chains))
                  )
                )
              )
            )
          )
          
          (princ (strcat "\n" (itoa count) " geschlossene Polylinie(n) wurden erstellt."))
        )
        (princ "\nKeine Linien zum Verarbeiten übrig.")
      )
      
      (princ "\n========================================================")
    )
    (princ "\nKeine Objekte ausgewählt.")
  )
  (princ)
)

;; Hilfsfunktion: Normalisiere Z-Koordinate auf 0
(defun normalize-z-coordinate (ent / entlist pt-start pt-end)
  (setq entlist (entget ent))
  (setq pt-start (cdr (assoc 10 entlist)))
  (setq pt-end (cdr (assoc 11 entlist)))
  
  ;; Setze Z auf 0.0
  (setq pt-start (list (car pt-start) (cadr pt-start) 0.0))
  (setq pt-end (list (car pt-end) (cadr pt-end) 0.0))
  
  ;; Update Entity
  (setq entlist (subst (cons 10 pt-start) (assoc 10 entlist) entlist))
  (setq entlist (subst (cons 11 pt-end) (assoc 11 entlist) entlist))
  (entmod entlist)
)

;; Hilfsfunktion: Layer erstellen und einfrieren
(defun create-and-freeze-layer (layer-name / layer-table layer-entry)
  (setq layer-table (tblsearch "LAYER" layer-name))
  
  (if (not layer-table)
    (progn
      ;; Layer existiert nicht - erstellen
      (command "._-LAYER" "_M" layer-name "_C" "7" layer-name "_F" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde erstellt und gefroren."))
    )
    (progn
      ;; Layer existiert - nur einfrieren
      (command "._-LAYER" "_F" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde gefroren."))
    )
  )
)

;; Hilfsfunktion: Prüfe ob Punkt INNERHALB einer Linie liegt (nicht an den Enden!)
(defun point-inside-line (pt p1 p2 / tol minx maxx miny maxy on-line at-endpoint)
  (setq tol 0.0001)
  
  ;; Prüfe zuerst ob Punkt auf der Geraden liegt
  (setq on-line
    (< (abs (- (* (- (car pt) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr pt) (cadr p1)) (- (car p2) (car p1))))) tol)
  )
  
  ;; Prüfe ob Punkt an einem Endpunkt liegt
  (setq at-endpoint
    (or (equal pt p1 tol) (equal pt p2 tol))
  )
  
  ;; Punkt muss auf Linie liegen UND darf nicht an Endpunkt sein
  (if (and on-line (not at-endpoint))
    (progn
      ;; Prüfe ob Punkt zwischen p1 und p2 liegt
      (setq minx (min (car p1) (car p2)))
      (setq maxx (max (car p1) (car p2)))
      (setq miny (min (cadr p1) (cadr p2)))
      (setq maxy (max (cadr p1) (cadr p2)))
      
      (and
        (>= (car pt) (- minx tol))
        (<= (car pt) (+ maxx tol))
        (>= (cadr pt) (- miny tol))
        (<= (cadr pt) (+ maxy tol))
      )
    )
    nil
  )
)

;; Hilfsfunktion: Prüfe ob zwei Linien kollinear sind (auf derselben Geraden liegen)
(defun lines-collinear (p1 p2 p3 p4 / tol)
  (setq tol 0.0001)
  ;; Alle 4 Punkte müssen auf derselben Geraden liegen
  (and
    (< (abs (- (* (- (car p3) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr p3) (cadr p1)) (- (car p2) (car p1))))) tol)
    (< (abs (- (* (- (car p4) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr p4) (cadr p1)) (- (car p2) (car p1))))) tol)
  )
)

;; Hilfsfunktion: Prüfe ob sich zwei Linien WIRKLICH überlappen
(defun lines-truly-overlap (p1 p2 p3 p4 / tol touches-only)
  (setq tol 0.0001)
  
  ;; Prüfe ob Linien sich nur an Endpunkten berühren (das ist OK!)
  (setq touches-only
    (or
      (equal p1 p3 tol)  ;; Start1 = Start2
      (equal p1 p4 tol)  ;; Start1 = End2
      (equal p2 p3 tol)  ;; End1 = Start2
      (equal p2 p4 tol)  ;; End1 = End2
    )
  )
  
  ;; Wenn Linien kollinear sind UND sich nicht nur berühren = Überlappung
  (if (lines-collinear p1 p2 p3 p4)
    (progn
      ;; Prüfe ob ein Punkt der einen Linie INNERHALB der anderen liegt
      (setq overlap
        (or
          (point-inside-line p3 p1 p2)  ;; Start2 liegt in Linie1
          (point-inside-line p4 p1 p2)  ;; End2 liegt in Linie1
          (point-inside-line p1 p3 p4)  ;; Start1 liegt in Linie2
          (point-inside-line p2 p3 p4)  ;; End1 liegt in Linie2
        )
      )
      
      ;; Nur als Überlappung zählen wenn wirklich überlappend (nicht nur berührend)
      (and overlap (not touches-only))
    )
    nil
  )
)

;; Hilfsfunktion: Finde überlappende Linien und entferne kürzere aus Liste
(defun find-and-remove-overlapping-lines (line-list / i j current-data test-data result removed)
  (setq result line-list)
  (setq removed '())
  (setq dup-count 0)
  
  (setq i 0)
  (while (< i (length result))
    (setq current-data (nth i result))
    (setq current-ent (car current-data))
    (setq current-p1 (cadr current-data))
    (setq current-p2 (caddr current-data))
    (setq current-len (cadddr current-data))
    
    (setq j (1+ i))
    (while (< j (length result))
      (setq test-data (nth j result))
      (setq test-ent (car test-data))
      (setq test-p1 (cadr test-data))
      (setq test-p2 (caddr test-data))
      (setq test-len (cadddr test-data))
      
      ;; Prüfe ob Linien sich WIRKLICH überlappen (nicht nur berühren!)
      (if (lines-truly-overlap current-p1 current-p2 test-p1 test-p2)
        (progn
          ;; Linien überlappen - kürzere auf Layer verschieben
          (if (< test-len current-len)
            (progn
              ;; test-Linie ist kürzer
              (move-to-layer test-ent "0_kurze Linie")
              (setq result (remove-nth j result))
              (setq removed (cons test-ent removed))
              (setq dup-count (1+ dup-count))
              (setq j (1- j))  ;; Index korrigieren da Element entfernt wurde
            )
            (progn
              ;; current-Linie ist kürzer oder gleich lang
              (move-to-layer current-ent "0_kurze Linie")
              (setq result (remove-nth i result))
              (setq removed (cons current-ent removed))
              (setq dup-count (1+ dup-count))
              (setq i (1- i))  ;; Index korrigieren und äußere Schleife neu starten
              (setq j (length result))  ;; Innere Schleife beenden
            )
          )
        )
      )
      (setq j (1+ j))
    )
    (setq i (1+ i))
  )
  
  result
)

;; Hilfsfunktion: Entferne n-tes Element aus Liste
(defun remove-nth (n lst / i result)
  (setq i 0)
  (setq result '())
  (foreach item lst
    (if (/= i n)
      (setq result (append result (list item)))
    )
    (setq i (1+ i))
  )
  result
)

;; Hilfsfunktion: Verschiebe Linie auf anderen Layer
(defun move-to-layer (ent layer-name / entlist)
  (setq entlist (entget ent))
  (setq entlist (subst (cons 8 layer-name) (assoc 8 entlist) entlist))
  (entmod entlist)
)

;; Hilfsfunktion: Hole Linien-Daten aus Liste
(defun get-line-data (ent line-list / result)
  (setq result nil)
  (foreach line-data line-list
    (if (equal (car line-data) ent)
      (setq result line-data)
    )
  )
  result
)

;; Hilfsfunktion: Baue Linienkette von Startpunkt aus
(defun build-chain (start-ent all-lines / chain last-pt found test-ent used-ents start-data)
  (setq chain (list start-ent))
  (setq used-ents (list start-ent))
  (setq processed-lines (cons start-ent processed-lines))
  
  ;; Hole Start- und Endpunkt der ersten Linie
  (setq start-data (get-line-data start-ent all-lines))
  (setq last-pt (caddr start-data))  ;; Beginne am Endpunkt
  
  ;; Suche weitere anschließende Linien
  (setq found T)
  (while found
    (setq found nil)
    (foreach line-data all-lines
      (if (not found)
        (progn
          (setq test-ent (car line-data))
          (if (and (not (member test-ent used-ents))
                   (not (member test-ent processed-lines)))
            (progn
              (setq next-data (get-line-data test-ent all-lines))
              (setq next-start (cadr next-data))
              (setq next-end (caddr next-data))
              
              ;; Prüfe welcher Endpunkt von test-ent an last-pt anschließt
              (cond
                ;; Fall 1: next-start verbindet sich mit last-pt
                ((equal last-pt next-start 0.0001)
                 (setq chain (append chain (list test-ent)))
                 (setq last-pt next-end)
                 (setq used-ents (cons test-ent used-ents))
                 (setq processed-lines (cons test-ent processed-lines))
                 (setq found T)
                )
                ;; Fall 2: next-end verbindet sich mit last-pt
                ((equal last-pt next-end 0.0001)
                 (setq chain (append chain (list test-ent)))
                 (setq last-pt next-start)
                 (setq used-ents (cons test-ent used-ents))
                 (setq processed-lines (cons test-ent processed-lines))
                 (setq found T)
                )
              )
            )
          )
        )
      )
    )
  )
  
  chain
)

;; Hilfsfunktion: Prüfe ob Kette geschlossen ist
(defun is-closed-chain (chain all-lines / first-data last-data first-start last-end)
  (if (>= (length chain) 3)
    (progn
      (setq first-data (get-line-data (car chain) all-lines))
      (setq last-data (get-line-data (last chain) all-lines))
      (setq first-start (cadr first-data))
      (setq last-end (caddr last-data))
      
      ;; Prüfe ob letzte und erste Linie sich verbinden
      (or
        (equal first-start last-end 0.0001)
        (equal first-start (cadr last-data) 0.0001)
      )
    )
    nil
  )
)

;; Hilfsfunktion: Erstelle Polylinie aus Linienkette
(defun create-polyline-from-chain (chain all-lines / pt-list last-pt first-data)
  (setq pt-list '())
  
  ;; Starte mit der ersten Linie
  (setq first-data (get-line-data (car chain) all-lines))
  (setq pt-list (list (cadr first-data) (caddr first-data)))
  (setq last-pt (caddr first-data))
  
  ;; Füge alle weiteren Punkte hinzu
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
  
  ;; Entferne Duplikate
  (setq pt-list (remove-duplicate-points pt-list))
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")
  
  ;; Färbe die Polylinie mit Farbe 171
  (setq pline-data (entget (entlast)))
  (if (assoc 62 pline-data)
    (setq pline-data (subst (cons 62 171) (assoc 62 pline-data) pline-data))
    (setq pline-data (append pline-data (list (cons 62 171))))
  )
  (entmod pline-data)
  
  ;; Lösche originale Linien
  (foreach line-ent chain
    (entdel line-ent)
  )
)

;; Hilfsfunktion: Entferne doppelte Punkte aus Liste
(defun remove-duplicate-points (pt-list / result)
  (setq result '())
  (foreach pt pt-list
    (if (not (member-point pt result))
      (setq result (append result (list pt)))
    )
  )
  result
)

;; Hilfsfunktion: Prüfe ob Punkt bereits in Liste
(defun member-point (pt pt-list / found)
  (setq found nil)
  (foreach test-pt pt-list
    (if (equal pt test-pt 0.0001)
      (setq found T)
    )
  )
  found
)

(princ "\nJOINPOLY geladen. Tippen Sie 'joinpoly' zum Starten.")
(princ)
```

## Hauptverbesserungen:

✅ **`point-inside-line`** - Prüft ob Punkt INNERHALB der Linie liegt (nicht an Endpunkten)  
✅ **`lines-truly-overlap`** - Unterscheidet zwischen:

- **Berühren** an Endpunkten → OK, werden zu Polylinie verbunden
- **Überlappen** mit gemeinsamem Segment → kürzere wird entfernt

**Beispiel:**

- Linie A: (0,0) bis (4,0) und Linie B: (4,0) bis (8,0) → **Berühren sich** → werden verbunden ✓
- Linie A: (0,0) bis (4,0) und Linie B: (2,0) bis (6,0) → **Überlappen sich** → kürzere entfernen ✗

Jetzt sollte Ihr Fall korrekt funktionieren!

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Stopp, da ist etwas schief gelaufen: Das Lisp-Programm hat jetzt die Linien gefunden, die sich an einem Endpunkt berühren und in der gleichen Spur laufen, dafür aber nicht mehr die wirklich überlappenden Linien!

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Sie haben recht! Die Logik war umgekehrt. Hier ist die korrigierte Version:

```
;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein
;; Version 3.4 - KORRIGIERTE Überlappungsprüfung

(defun c:joinpoly (/ ss i ent entlist all-lines processed-lines closed-chains count short-count dup-count)
  (princ "\nJOINPOLY - Verbindet Linien zu geschlossenen Polylinien")
  (princ "\n========================================================")
  
  ;; Objekte auswählen
  (setq ss (ssget '((0 . "LINE"))))
  
  (if ss
    (progn
      (princ (strcat "\n" (itoa (sslength ss)) " Linien gefunden."))
      (setq all-lines '())
      (setq processed-lines '())
      (setq closed-chains '())
      (setq count 0)
      (setq short-count 0)
      (setq dup-count 0)
      
      ;; SCHRITT 1: Z-Koordinaten auf 0 setzen
      (princ "\nSchritt 1: Normalisiere Z-Koordinaten...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (normalize-z-coordinate ent)
        (setq i (1+ i))
      )
      
      ;; SCHRITT 2: Alle Linien einlesen und kurze Linien löschen
      (princ "\nSchritt 2: Entferne kurze Linien...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq entlist (entget ent))
        (setq pt-start (cdr (assoc 10 entlist)))
        (setq pt-end (cdr (assoc 11 entlist)))
        (setq line-length (distance pt-start pt-end))
        
        ;; Prüfe Linienlänge
        (if (< line-length 0.005)
          (progn
            ;; Linie ist zu kurz - löschen
            (entdel ent)
            (setq short-count (1+ short-count))
          )
          (progn
            ;; Linie ist lang genug - in Liste aufnehmen
            (setq all-lines (cons (list ent pt-start pt-end line-length) all-lines))
          )
        )
        (setq i (1+ i))
      )
      
      (if (> short-count 0)
        (princ (strcat "\n  " (itoa short-count) " kurze Linie(n) (< 0.005) wurden gelöscht."))
      )
      
      ;; SCHRITT 3: Übereinanderliegende und überlappende Linien finden
      (if all-lines
        (progn
          (princ "\nSchritt 3: Suche nach übereinanderliegenden/überlappenden Linien...")
          
          ;; Layer "0_kurze Linie" erstellen falls nicht vorhanden und einfrieren
          (create-and-freeze-layer "0_kurze Linie")
          
          ;; Finde alle übereinanderliegenden Linien
          (setq all-lines (find-and-remove-overlapping-lines all-lines))
          
          (if (> dup-count 0)
            (princ (strcat "\n  " (itoa dup-count) " kürzere, übereinanderliegende Linie(n) auf gefrorenen Layer '0_kurze Linie' verschoben."))
          )
        )
      )
      
      ;; SCHRITT 4: Verbinde Linien zu geschlossenen Polylinien
      (if all-lines
        (progn
          (princ "\nSchritt 4: Verbinde Linien zu Polylinien...")
          (princ (strcat "\n  " (itoa (length all-lines)) " Linien werden verarbeitet."))
          
          ;; Verarbeite alle Linien
          (foreach line-data all-lines
            (if (not (member (car line-data) processed-lines))
              (progn
                (setq chain (build-chain (car line-data) all-lines))
                (if (is-closed-chain chain all-lines)
                  (progn
                    (create-polyline-from-chain chain all-lines)
                    (setq count (1+ count))
                    (setq closed-chains (cons chain closed-chains))
                  )
                )
              )
            )
          )
          
          (princ (strcat "\n" (itoa count) " geschlossene Polylinie(n) wurden erstellt."))
        )
        (princ "\nKeine Linien zum Verarbeiten übrig.")
      )
      
      (princ "\n========================================================")
    )
    (princ "\nKeine Objekte ausgewählt.")
  )
  (princ)
)

;; Hilfsfunktion: Normalisiere Z-Koordinate auf 0
(defun normalize-z-coordinate (ent / entlist pt-start pt-end)
  (setq entlist (entget ent))
  (setq pt-start (cdr (assoc 10 entlist)))
  (setq pt-end (cdr (assoc 11 entlist)))
  
  ;; Setze Z auf 0.0
  (setq pt-start (list (car pt-start) (cadr pt-start) 0.0))
  (setq pt-end (list (car pt-end) (cadr pt-end) 0.0))
  
  ;; Update Entity
  (setq entlist (subst (cons 10 pt-start) (assoc 10 entlist) entlist))
  (setq entlist (subst (cons 11 pt-end) (assoc 11 entlist) entlist))
  (entmod entlist)
)

;; Hilfsfunktion: Layer erstellen und einfrieren
(defun create-and-freeze-layer (layer-name / layer-table layer-entry)
  (setq layer-table (tblsearch "LAYER" layer-name))
  
  (if (not layer-table)
    (progn
      ;; Layer existiert nicht - erstellen
      (command "._-LAYER" "_M" layer-name "_C" "7" layer-name "_F" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde erstellt und gefroren."))
    )
    (progn
      ;; Layer existiert - nur einfrieren
      (command "._-LAYER" "_F" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde gefroren."))
    )
  )
)

;; Hilfsfunktion: Prüfe ob Punkt INNERHALB einer Linie liegt (nicht an den Enden!)
(defun point-inside-line (pt p1 p2 / tol minx maxx miny maxy on-line at-endpoint)
  (setq tol 0.0001)
  
  ;; Prüfe zuerst ob Punkt auf der Geraden liegt
  (setq on-line
    (< (abs (- (* (- (car pt) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr pt) (cadr p1)) (- (car p2) (car p1))))) tol)
  )
  
  ;; Prüfe ob Punkt an einem Endpunkt liegt
  (setq at-endpoint
    (or (equal pt p1 tol) (equal pt p2 tol))
  )
  
  ;; Punkt muss auf Linie liegen UND darf nicht an Endpunkt sein
  (if (and on-line (not at-endpoint))
    (progn
      ;; Prüfe ob Punkt zwischen p1 und p2 liegt
      (setq minx (min (car p1) (car p2)))
      (setq maxx (max (car p1) (car p2)))
      (setq miny (min (cadr p1) (cadr p2)))
      (setq maxy (max (cadr p1) (cadr p2)))
      
      (and
        (>= (car pt) (- minx tol))
        (<= (car pt) (+ maxx tol))
        (>= (cadr pt) (- miny tol))
        (<= (cadr pt) (+ maxy tol))
      )
    )
    nil
  )
)

;; Hilfsfunktion: Prüfe ob zwei Linien kollinear sind (auf derselben Geraden liegen)
(defun lines-collinear (p1 p2 p3 p4 / tol)
  (setq tol 0.0001)
  ;; Alle 4 Punkte müssen auf derselben Geraden liegen
  (and
    (< (abs (- (* (- (car p3) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr p3) (cadr p1)) (- (car p2) (car p1))))) tol)
    (< (abs (- (* (- (car p4) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr p4) (cadr p1)) (- (car p2) (car p1))))) tol)
  )
)

;; Hilfsfunktion: Prüfe ob sich zwei Linien WIRKLICH überlappen
(defun lines-truly-overlap (p1 p2 p3 p4 / tol only-touch-at-ends has-internal-overlap)
  (setq tol 0.0001)
  
  ;; Erst prüfen ob überhaupt kollinear
  (if (not (lines-collinear p1 p2 p3 p4))
    nil  ;; Nicht auf gleicher Geraden = keine Überlappung
    (progn
      ;; Linien sind kollinear - jetzt unterscheiden zwischen:
      ;; 1. Nur berühren an Endpunkten (OK - sollen verbunden werden)
      ;; 2. Tatsächliche Überlappung (BAD - kürzere entfernen)
      
      ;; Prüfe ob nur Berührung an Endpunkten
      (setq only-touch-at-ends
        (and
          ;; Berühren sich
          (or
            (equal p1 p3 tol)  ;; Start1 = Start2
            (equal p1 p4 tol)  ;; Start1 = End2
            (equal p2 p3 tol)  ;; End1 = Start2
            (equal p2 p4 tol)  ;; End1 = End2
          )
          ;; ABER keine inneren Punkte überlappen
          (not
            (or
              (point-inside-line p3 p1 p2)  ;; Start2 liegt in Linie1
              (point-inside-line p4 p1 p2)  ;; End2 liegt in Linie1
              (point-inside-line p1 p3 p4)  ;; Start1 liegt in Linie2
              (point-inside-line p2 p3 p4)  ;; End1 liegt in Linie2
            )
          )
        )
      )
      
      ;; Prüfe ob innere Überlappung existiert
      (setq has-internal-overlap
        (or
          (point-inside-line p3 p1 p2)  ;; Start2 liegt INNERHALB Linie1
          (point-inside-line p4 p1 p2)  ;; End2 liegt INNERHALB Linie1
          (point-inside-line p1 p3 p4)  ;; Start1 liegt INNERHALB Linie2
          (point-inside-line p2 p3 p4)  ;; End1 liegt INNERHALB Linie2
        )
      )
      
      ;; Rückgabe: TRUE nur bei tatsächlicher Überlappung (nicht bei reiner Berührung)
      (and has-internal-overlap (not only-touch-at-ends))
    )
  )
)

;; Hilfsfunktion: Finde überlappende Linien und entferne kürzere aus Liste
(defun find-and-remove-overlapping-lines (line-list / i j current-data test-data result removed)
  (setq result line-list)
  (setq removed '())
  (setq dup-count 0)
  
  (setq i 0)
  (while (< i (length result))
    (setq current-data (nth i result))
    (setq current-ent (car current-data))
    (setq current-p1 (cadr current-data))
    (setq current-p2 (caddr current-data))
    (setq current-len (cadddr current-data))
    
    (setq j (1+ i))
    (while (< j (length result))
      (setq test-data (nth j result))
      (setq test-ent (car test-data))
      (setq test-p1 (cadr test-data))
      (setq test-p2 (caddr test-data))
      (setq test-len (cadddr test-data))
      
      ;; Prüfe ob Linien sich WIRKLICH überlappen (nicht nur berühren!)
      (if (lines-truly-overlap current-p1 current-p2 test-p1 test-p2)
        (progn
          (princ (strcat "\n  DEBUG: Überlappung gefunden zwischen Linie " (itoa (1+ i)) " und " (itoa (1+ j))))
          ;; Linien überlappen - kürzere auf Layer verschieben
          (if (< test-len current-len)
            (progn
              ;; test-Linie ist kürzer
              (princ (strcat " -> Verschiebe kürzere Linie " (itoa (1+ j))))
              (move-to-layer test-ent "0_kurze Linie")
              (setq result (remove-nth j result))
              (setq removed (cons test-ent removed))
              (setq dup-count (1+ dup-count))
              (setq j (1- j))  ;; Index korrigieren da Element entfernt wurde
            )
            (progn
              ;; current-Linie ist kürzer oder gleich lang
              (princ (strcat " -> Verschiebe kürzere Linie " (itoa (1+ i))))
              (move-to-layer current-ent "0_kurze Linie")
              (setq result (remove-nth i result))
              (setq removed (cons current-ent removed))
              (setq dup-count (1+ dup-count))
              (setq i (1- i))  ;; Index korrigieren und äußere Schleife neu starten
              (setq j (length result))  ;; Innere Schleife beenden
            )
          )
        )
      )
      (setq j (1+ j))
    )
    (setq i (1+ i))
  )
  
  result
)

;; Hilfsfunktion: Entferne n-tes Element aus Liste
(defun remove-nth (n lst / i result)
  (setq i 0)
  (setq result '())
  (foreach item lst
    (if (/= i n)
      (setq result (append result (list item)))
    )
    (setq i (1+ i))
  )
  result
)

;; Hilfsfunktion: Verschiebe Linie auf anderen Layer
(defun move-to-layer (ent layer-name / entlist)
  (setq entlist (entget ent))
  (setq entlist (subst (cons 8 layer-name) (assoc 8 entlist) entlist))
  (entmod entlist)
)

;; Hilfsfunktion: Hole Linien-Daten aus Liste
(defun get-line-data (ent line-list / result)
  (setq result nil)
  (foreach line-data line-list
    (if (equal (car line-data) ent)
      (setq result line-data)
    )
  )
  result
)

;; Hilfsfunktion: Baue Linienkette von Startpunkt aus
(defun build-chain (start-ent all-lines / chain last-pt found test-ent used-ents start-data)
  (setq chain (list start-ent))
  (setq used-ents (list start-ent))
  (setq processed-lines (cons start-ent processed-lines))
  
  ;; Hole Start- und Endpunkt der ersten Linie
  (setq start-data (get-line-data start-ent all-lines))
  (setq last-pt (caddr start-data))  ;; Beginne am Endpunkt
  
  ;; Suche weitere anschließende Linien
  (setq found T)
  (while found
    (setq found nil)
    (foreach line-data all-lines
      (if (not found)
        (progn
          (setq test-ent (car line-data))
          (if (and (not (member test-ent used-ents))
                   (not (member test-ent processed-lines)))
            (progn
              (setq next-data (get-line-data test-ent all-lines))
              (setq next-start (cadr next-data))
              (setq next-end (caddr next-data))
              
              ;; Prüfe welcher Endpunkt von test-ent an last-pt anschließt
              (cond
                ;; Fall 1: next-start verbindet sich mit last-pt
                ((equal last-pt next-start 0.0001)
                 (setq chain (append chain (list test-ent)))
                 (setq last-pt next-end)
                 (setq used-ents (cons test-ent used-ents))
                 (setq processed-lines (cons test-ent processed-lines))
                 (setq found T)
                )
                ;; Fall 2: next-end verbindet sich mit last-pt
                ((equal last-pt next-end 0.0001)
                 (setq chain (append chain (list test-ent)))
                 (setq last-pt next-start)
                 (setq used-ents (cons test-ent used-ents))
                 (setq processed-lines (cons test-ent processed-lines))
                 (setq found T)
                )
              )
            )
          )
        )
      )
    )
  )
  
  chain
)

;; Hilfsfunktion: Prüfe ob Kette geschlossen ist
(defun is-closed-chain (chain all-lines / first-data last-data first-start last-end)
  (if (>= (length chain) 3)
    (progn
      (setq first-data (get-line-data (car chain) all-lines))
      (setq last-data (get-line-data (last chain) all-lines))
      (setq first-start (cadr first-data))
      (setq last-end (caddr last-data))
      
      ;; Prüfe ob letzte und erste Linie sich verbinden
      (or
        (equal first-start last-end 0.0001)
        (equal first-start (cadr last-data) 0.0001)
      )
    )
    nil
  )
)

;; Hilfsfunktion: Erstelle Polylinie aus Linienkette
(defun create-polyline-from-chain (chain all-lines / pt-list last-pt first-data)
  (setq pt-list '())
  
  ;; Starte mit der ersten Linie
  (setq first-data (get-line-data (car chain) all-lines))
  (setq pt-list (list (cadr first-data) (caddr first-data)))
  (setq last-pt (caddr first-data))
  
  ;; Füge alle weiteren Punkte hinzu
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
  
  ;; Entferne Duplikate
  (setq pt-list (remove-duplicate-points pt-list))
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")
  
  ;; Färbe die Polylinie mit Farbe 171
  (setq pline-data (entget (entlast)))
  (if (assoc 62 pline-data)
    (setq pline-data (subst (cons 62 171) (assoc 62 pline-data) pline-data))
    (setq pline-data (append pline-data (list (cons 62 171))))
  )
  (entmod pline-data)
  
  ;; Lösche originale Linien
  (foreach line-ent chain
    (entdel line-ent)
  )
)

;; Hilfsfunktion: Entferne doppelte Punkte aus Liste
(defun remove-duplicate-points (pt-list / result)
  (setq result '())
  (foreach pt pt-list
    (if (not (member-point pt result))
      (setq result (append result (list pt)))
    )
  )
  result
)

;; Hilfsfunktion: Prüfe ob Punkt bereits in Liste
(defun member-point (pt pt-list / found)
  (setq found nil)
  (foreach test-pt pt-list
    (if (equal pt test-pt 0.0001)
      (setq found T)
    )
  )
  found
)

(princ "\nJOINPOLY geladen. Tippen Sie 'joinpoly' zum Starten.")
(princ)
```

## Wichtigste Änderung in `lines-truly-overlap`:

```
;; NUR als Überlappung zählen wenn:
;; 1. Innere Punkte überlappen UND
;; 2. NICHT nur Berührung an Endpunkten
(and has-internal-overlap (not only-touch-at-ends))
```

**Jetzt gilt:**

- ✅ Linien berühren sich nur an Endpunkten → KEINE Überlappung → werden verbunden
- ❌ Linien haben überlappende Segmente → Überlappung → kürzere wird entfernt

Ich habe auch DEBUG-Ausgaben hinzugefügt, damit Sie sehen, welche Linien als überlappend erkannt werden.

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Fast perfekt! Aber es gibt jetzt noch \*\*doppelte Linien mit exakt der gleichen Länge\*\*, die nicht auf den "0_kurze Linien"-Layer verschoben werden. Kannst du das korrigieren?

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Perfekt! Hier ist die korrigierte Version, die auch doppelte Linien mit gleicher Länge behandelt:

```
;; JoinLineToPolyline.lsp
;; Verbindet Linien zu geschlossenen Polylinien und färbt sie ein
;; Version 3.5 - Behandelt auch doppelte Linien mit gleicher Länge

(defun c:joinpoly (/ ss i ent entlist all-lines processed-lines closed-chains count short-count dup-count)
  (princ "\nJOINPOLY - Verbindet Linien zu geschlossenen Polylinien")
  (princ "\n========================================================")
  
  ;; Objekte auswählen
  (setq ss (ssget '((0 . "LINE"))))
  
  (if ss
    (progn
      (princ (strcat "\n" (itoa (sslength ss)) " Linien gefunden."))
      (setq all-lines '())
      (setq processed-lines '())
      (setq closed-chains '())
      (setq count 0)
      (setq short-count 0)
      (setq dup-count 0)
      
      ;; SCHRITT 1: Z-Koordinaten auf 0 setzen
      (princ "\nSchritt 1: Normalisiere Z-Koordinaten...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (normalize-z-coordinate ent)
        (setq i (1+ i))
      )
      
      ;; SCHRITT 2: Alle Linien einlesen und kurze Linien löschen
      (princ "\nSchritt 2: Entferne kurze Linien...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq entlist (entget ent))
        (setq pt-start (cdr (assoc 10 entlist)))
        (setq pt-end (cdr (assoc 11 entlist)))
        (setq line-length (distance pt-start pt-end))
        
        ;; Prüfe Linienlänge
        (if (< line-length 0.005)
          (progn
            ;; Linie ist zu kurz - löschen
            (entdel ent)
            (setq short-count (1+ short-count))
          )
          (progn
            ;; Linie ist lang genug - in Liste aufnehmen
            (setq all-lines (cons (list ent pt-start pt-end line-length) all-lines))
          )
        )
        (setq i (1+ i))
      )
      
      (if (> short-count 0)
        (princ (strcat "\n  " (itoa short-count) " kurze Linie(n) (< 0.005) wurden gelöscht."))
      )
      
      ;; SCHRITT 3: Übereinanderliegende und überlappende Linien finden
      (if all-lines
        (progn
          (princ "\nSchritt 3: Suche nach übereinanderliegenden/überlappenden Linien...")
          
          ;; Layer "0_kurze Linie" erstellen falls nicht vorhanden und einfrieren
          (create-and-freeze-layer "0_kurze Linie")
          
          ;; Finde alle übereinanderliegenden Linien
          (setq all-lines (find-and-remove-overlapping-lines all-lines))
          
          (if (> dup-count 0)
            (princ (strcat "\n  " (itoa dup-count) " kürzere/doppelte übereinanderliegende Linie(n) auf gefrorenen Layer '0_kurze Linie' verschoben."))
          )
        )
      )
      
      ;; SCHRITT 4: Verbinde Linien zu geschlossenen Polylinien
      (if all-lines
        (progn
          (princ "\nSchritt 4: Verbinde Linien zu Polylinien...")
          (princ (strcat "\n  " (itoa (length all-lines)) " Linien werden verarbeitet."))
          
          ;; Verarbeite alle Linien
          (foreach line-data all-lines
            (if (not (member (car line-data) processed-lines))
              (progn
                (setq chain (build-chain (car line-data) all-lines))
                (if (is-closed-chain chain all-lines)
                  (progn
                    (create-polyline-from-chain chain all-lines)
                    (setq count (1+ count))
                    (setq closed-chains (cons chain closed-chains))
                  )
                )
              )
            )
          )
          
          (princ (strcat "\n" (itoa count) " geschlossene Polylinie(n) wurden erstellt."))
        )
        (princ "\nKeine Linien zum Verarbeiten übrig.")
      )
      
      (princ "\n========================================================")
    )
    (princ "\nKeine Objekte ausgewählt.")
  )
  (princ)
)

;; Hilfsfunktion: Normalisiere Z-Koordinate auf 0
(defun normalize-z-coordinate (ent / entlist pt-start pt-end)
  (setq entlist (entget ent))
  (setq pt-start (cdr (assoc 10 entlist)))
  (setq pt-end (cdr (assoc 11 entlist)))
  
  ;; Setze Z auf 0.0
  (setq pt-start (list (car pt-start) (cadr pt-start) 0.0))
  (setq pt-end (list (car pt-end) (cadr pt-end) 0.0))
  
  ;; Update Entity
  (setq entlist (subst (cons 10 pt-start) (assoc 10 entlist) entlist))
  (setq entlist (subst (cons 11 pt-end) (assoc 11 entlist) entlist))
  (entmod entlist)
)

;; Hilfsfunktion: Layer erstellen und einfrieren
(defun create-and-freeze-layer (layer-name / layer-table layer-entry)
  (setq layer-table (tblsearch "LAYER" layer-name))
  
  (if (not layer-table)
    (progn
      ;; Layer existiert nicht - erstellen
      (command "._-LAYER" "_M" layer-name "_C" "7" layer-name "_F" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde erstellt und gefroren."))
    )
    (progn
      ;; Layer existiert - nur einfrieren
      (command "._-LAYER" "_F" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde gefroren."))
    )
  )
)

;; Hilfsfunktion: Prüfe ob Punkt INNERHALB einer Linie liegt (nicht an den Enden!)
(defun point-inside-line (pt p1 p2 / tol minx maxx miny maxy on-line at-endpoint)
  (setq tol 0.0001)
  
  ;; Prüfe zuerst ob Punkt auf der Geraden liegt
  (setq on-line
    (< (abs (- (* (- (car pt) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr pt) (cadr p1)) (- (car p2) (car p1))))) tol)
  )
  
  ;; Prüfe ob Punkt an einem Endpunkt liegt
  (setq at-endpoint
    (or (equal pt p1 tol) (equal pt p2 tol))
  )
  
  ;; Punkt muss auf Linie liegen UND darf nicht an Endpunkt sein
  (if (and on-line (not at-endpoint))
    (progn
      ;; Prüfe ob Punkt zwischen p1 und p2 liegt
      (setq minx (min (car p1) (car p2)))
      (setq maxx (max (car p1) (car p2)))
      (setq miny (min (cadr p1) (cadr p2)))
      (setq maxy (max (cadr p1) (cadr p2)))
      
      (and
        (>= (car pt) (- minx tol))
        (<= (car pt) (+ maxx tol))
        (>= (cadr pt) (- miny tol))
        (<= (cadr pt) (+ maxy tol))
      )
    )
    nil
  )
)

;; Hilfsfunktion: Prüfe ob zwei Linien kollinear sind (auf derselben Geraden liegen)
(defun lines-collinear (p1 p2 p3 p4 / tol)
  (setq tol 0.0001)
  ;; Alle 4 Punkte müssen auf derselben Geraden liegen
  (and
    (< (abs (- (* (- (car p3) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr p3) (cadr p1)) (- (car p2) (car p1))))) tol)
    (< (abs (- (* (- (car p4) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr p4) (cadr p1)) (- (car p2) (car p1))))) tol)
  )
)

;; Hilfsfunktion: Prüfe ob zwei Linien IDENTISCH sind (gleiche Endpunkte)
(defun lines-identical (p1 p2 p3 p4 / tol)
  (setq tol 0.0001)
  (or
    ;; Fall 1: p1=p3 UND p2=p4
    (and (equal p1 p3 tol) (equal p2 p4 tol))
    ;; Fall 2: p1=p4 UND p2=p3 (umgekehrte Richtung)
    (and (equal p1 p4 tol) (equal p2 p3 tol))
  )
)

;; Hilfsfunktion: Prüfe ob sich zwei Linien WIRKLICH überlappen
(defun lines-truly-overlap (p1 p2 p3 p4 / tol only-touch-at-ends has-internal-overlap are-identical)
  (setq tol 0.0001)
  
  ;; Erst prüfen ob überhaupt kollinear
  (if (not (lines-collinear p1 p2 p3 p4))
    nil  ;; Nicht auf gleicher Geraden = keine Überlappung
    (progn
      ;; Prüfe ob Linien identisch sind (doppelte Linie)
      (setq are-identical (lines-identical p1 p2 p3 p4))
      
      ;; Wenn identisch, dann ist das eine Überlappung!
      (if are-identical
        T  ;; Identische Linien = Überlappung
        (progn
          ;; Nicht identisch - prüfe auf Berührung vs. Überlappung
          
          ;; Prüfe ob nur Berührung an Endpunkten
          (setq only-touch-at-ends
            (and
              ;; Berühren sich
              (or
                (equal p1 p3 tol)  ;; Start1 = Start2
                (equal p1 p4 tol)  ;; Start1 = End2
                (equal p2 p3 tol)  ;; End1 = Start2
                (equal p2 p4 tol)  ;; End1 = End2
              )
              ;; ABER keine inneren Punkte überlappen
              (not
                (or
                  (point-inside-line p3 p1 p2)  ;; Start2 liegt in Linie1
                  (point-inside-line p4 p1 p2)  ;; End2 liegt in Linie1
                  (point-inside-line p1 p3 p4)  ;; Start1 liegt in Linie2
                  (point-inside-line p2 p3 p4)  ;; End1 liegt in Linie2
                )
              )
            )
          )
          
          ;; Prüfe ob innere Überlappung existiert
          (setq has-internal-overlap
            (or
              (point-inside-line p3 p1 p2)  ;; Start2 liegt INNERHALB Linie1
              (point-inside-line p4 p1 p2)  ;; End2 liegt INNERHALB Linie1
              (point-inside-line p1 p3 p4)  ;; Start1 liegt INNERHALB Linie2
              (point-inside-line p2 p3 p4)  ;; End1 liegt INNERHALB Linie2
            )
          )
          
          ;; Rückgabe: TRUE nur bei tatsächlicher Überlappung (nicht bei reiner Berührung)
          (and has-internal-overlap (not only-touch-at-ends))
        )
      )
    )
  )
)

;; Hilfsfunktion: Finde überlappende Linien und entferne kürzere aus Liste
(defun find-and-remove-overlapping-lines (line-list / i j current-data test-data result removed)
  (setq result line-list)
  (setq removed '())
  (setq dup-count 0)
  
  (setq i 0)
  (while (< i (length result))
    (setq current-data (nth i result))
    (setq current-ent (car current-data))
    (setq current-p1 (cadr current-data))
    (setq current-p2 (caddr current-data))
    (setq current-len (cadddr current-data))
    
    (setq j (1+ i))
    (while (< j (length result))
      (setq test-data (nth j result))
      (setq test-ent (car test-data))
      (setq test-p1 (cadr test-data))
      (setq test-p2 (caddr test-data))
      (setq test-len (cadddr test-data))
      
      ;; Prüfe ob Linien sich WIRKLICH überlappen (nicht nur berühren!)
      (if (lines-truly-overlap current-p1 current-p2 test-p1 test-p2)
        (progn
          (princ (strcat "\n  DEBUG: Überlappung gefunden zwischen Linie " (itoa (1+ i)) " und " (itoa (1+ j))))
          
          ;; Entscheide welche Linie verschoben wird
          (cond
            ;; Fall 1: test-Linie ist kürzer -> verschiebe test-Linie
            ((< test-len current-len)
             (princ (strcat " -> Verschiebe kürzere Linie " (itoa (1+ j))))
             (move-to-layer test-ent "0_kurze Linie")
             (setq result (remove-nth j result))
             (setq removed (cons test-ent removed))
             (setq dup-count (1+ dup-count))
             (setq j (1- j))  ;; Index korrigieren da Element entfernt wurde
            )
            ;; Fall 2: current-Linie ist kürzer -> verschiebe current-Linie
            ((> test-len current-len)
             (princ (strcat " -> Verschiebe kürzere Linie " (itoa (1+ i))))
             (move-to-layer current-ent "0_kurze Linie")
             (setq result (remove-nth i result))
             (setq removed (cons current-ent removed))
             (setq dup-count (1+ dup-count))
             (setq i (1- i))  ;; Index korrigieren und äußere Schleife neu starten
             (setq j (length result))  ;; Innere Schleife beenden
            )
            ;; Fall 3: GLEICHE Länge -> verschiebe die zweite (test-Linie)
            (T
             (princ (strcat " -> Verschiebe doppelte Linie " (itoa (1+ j)) " (gleiche Länge)"))
             (move-to-layer test-ent "0_kurze Linie")
             (setq result (remove-nth j result))
             (setq removed (cons test-ent removed))
             (setq dup-count (1+ dup-count))
             (setq j (1- j))  ;; Index korrigieren da Element entfernt wurde
            )
          )
        )
      )
      (setq j (1+ j))
    )
    (setq i (1+ i))
  )
  
  result
)

;; Hilfsfunktion: Entferne n-tes Element aus Liste
(defun remove-nth (n lst / i result)
  (setq i 0)
  (setq result '())
  (foreach item lst
    (if (/= i n)
      (setq result (append result (list item)))
    )
    (setq i (1+ i))
  )
  result
)

;; Hilfsfunktion: Verschiebe Linie auf anderen Layer
(defun move-to-layer (ent layer-name / entlist)
  (setq entlist (entget ent))
  (setq entlist (subst (cons 8 layer-name) (assoc 8 entlist) entlist))
  (entmod entlist)
)

;; Hilfsfunktion: Hole Linien-Daten aus Liste
(defun get-line-data (ent line-list / result)
  (setq result nil)
  (foreach line-data line-list
    (if (equal (car line-data) ent)
      (setq result line-data)
    )
  )
  result
)

;; Hilfsfunktion: Baue Linienkette von Startpunkt aus
(defun build-chain (start-ent all-lines / chain last-pt found test-ent used-ents start-data)
  (setq chain (list start-ent))
  (setq used-ents (list start-ent))
  (setq processed-lines (cons start-ent processed-lines))
  
  ;; Hole Start- und Endpunkt der ersten Linie
  (setq start-data (get-line-data start-ent all-lines))
  (setq last-pt (caddr start-data))  ;; Beginne am Endpunkt
  
  ;; Suche weitere anschließende Linien
  (setq found T)
  (while found
    (setq found nil)
    (foreach line-data all-lines
      (if (not found)
        (progn
          (setq test-ent (car line-data))
          (if (and (not (member test-ent used-ents))
                   (not (member test-ent processed-lines)))
            (progn
              (setq next-data (get-line-data test-ent all-lines))
              (setq next-start (cadr next-data))
              (setq next-end (caddr next-data))
              
              ;; Prüfe welcher Endpunkt von test-ent an last-pt anschließt
              (cond
                ;; Fall 1: next-start verbindet sich mit last-pt
                ((equal last-pt next-start 0.0001)
                 (setq chain (append chain (list test-ent)))
                 (setq last-pt next-end)
                 (setq used-ents (cons test-ent used-ents))
                 (setq processed-lines (cons test-ent processed-lines))
                 (setq found T)
                )
                ;; Fall 2: next-end verbindet sich mit last-pt
                ((equal last-pt next-end 0.0001)
                 (setq chain (append chain (list test-ent)))
                 (setq last-pt next-start)
                 (setq used-ents (cons test-ent used-ents))
                 (setq processed-lines (cons test-ent processed-lines))
                 (setq found T)
                )
              )
            )
          )
        )
      )
    )
  )
  
  chain
)

;; Hilfsfunktion: Prüfe ob Kette geschlossen ist
(defun is-closed-chain (chain all-lines / first-data last-data first-start last-end)
  (if (>= (length chain) 3)
    (progn
      (setq first-data (get-line-data (car chain) all-lines))
      (setq last-data (get-line-data (last chain) all-lines))
      (setq first-start (cadr first-data))
      (setq last-end (caddr last-data))
      
      ;; Prüfe ob letzte und erste Linie sich verbinden
      (or
        (equal first-start last-end 0.0001)
        (equal first-start (cadr last-data) 0.0001)
      )
    )
    nil
  )
)

;; Hilfsfunktion: Erstelle Polylinie aus Linienkette
(defun create-polyline-from-chain (chain all-lines / pt-list last-pt first-data)
  (setq pt-list '())
  
  ;; Starte mit der ersten Linie
  (setq first-data (get-line-data (car chain) all-lines))
  (setq pt-list (list (cadr first-data) (caddr first-data)))
  (setq last-pt (caddr first-data))
  
  ;; Füge alle weiteren Punkte hinzu
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
  
  ;; Entferne Duplikate
  (setq pt-list (remove-duplicate-points pt-list))
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")
  
  ;; Färbe die Polylinie mit Farbe 171
  (setq pline-data (entget (entlast)))
  (if (assoc 62 pline-data)
    (setq pline-data (subst (cons 62 171) (assoc 62 pline-data) pline-data))
    (setq pline-data (append pline-data (list (cons 62 171))))
  )
  (entmod pline-data)
  
  ;; Lösche originale Linien
  (foreach line-ent chain
    (entdel line-ent)
  )
)

;; Hilfsfunktion: Entferne doppelte Punkte aus Liste
(defun remove-duplicate-points (pt-list / result)
  (setq result '())
  (foreach pt pt-list
    (if (not (member-point pt result))
      (setq result (append result (list pt)))
    )
  )
  result
)

;; Hilfsfunktion: Prüfe ob Punkt bereits in Liste
(defun member-point (pt pt-list / found)
  (setq found nil)
  (foreach test-pt pt-list
    (if (equal pt test-pt 0.0001)
      (setq found T)
    )
  )
  found
)

(princ "\nJOINPOLY geladen. Tippen Sie 'joinpoly' zum Starten.")
(princ)
```

## Hauptänderungen:

✅ **Neue Funktion `lines-identical`** - Erkennt Linien mit exakt gleichen Endpunkten  
✅ **Erweiterte `lines-truly-overlap`** - Prüft zuerst auf identische Linien  
✅ **Aktualisierte `find-and-remove-overlapping-lines`** - Behandelt 3 Fälle:

- **Kürzere Linie** → verschieben
- **Längere Linie** → andere verschieben
- **Gleiche Länge** → zweite Linie verschieben (mit "(gleiche Länge)" im Debug)

Jetzt werden auch doppelte Linien mit exakt gleicher Länge korrekt erkannt und auf den Layer "0_kurze Linie" verschoben!

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Kannst du mir an den Anfang der Lisp-Datei noch Kommentarzeilen einfügen, die folgendes enthalten: - Wozu dient das Programm - Wie geht es dabei vor - Was sind die Voraussetzungen, damit es funktioniert - Einen Anwendungs-Hinweis

<img width="20" height="20" src="../_resources/claude_73a9a209984947e38b6a8830b7abb926.png" class="jop-noMdConv">

Hier ist die Lisp-Datei mit ausführlichen Kommentarzeilen am Anfang:

```
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

(defun c:joinpoly (/ ss i ent entlist all-lines processed-lines closed-chains count short-count dup-count)
  (princ "\nJOINPOLY - Verbindet Linien zu geschlossenen Polylinien")
  (princ "\n========================================================")
  
  ;; Objekte auswählen
  (setq ss (ssget '((0 . "LINE"))))
  
  (if ss
    (progn
      (princ (strcat "\n" (itoa (sslength ss)) " Linien gefunden."))
      (setq all-lines '())
      (setq processed-lines '())
      (setq closed-chains '())
      (setq count 0)
      (setq short-count 0)
      (setq dup-count 0)
      
      ;; SCHRITT 1: Z-Koordinaten auf 0 setzen
      (princ "\nSchritt 1: Normalisiere Z-Koordinaten...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (normalize-z-coordinate ent)
        (setq i (1+ i))
      )
      
      ;; SCHRITT 2: Alle Linien einlesen und kurze Linien löschen
      (princ "\nSchritt 2: Entferne kurze Linien...")
      (setq i 0)
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq entlist (entget ent))
        (setq pt-start (cdr (assoc 10 entlist)))
        (setq pt-end (cdr (assoc 11 entlist)))
        (setq line-length (distance pt-start pt-end))
        
        ;; Prüfe Linienlänge
        (if (< line-length 0.005)
          (progn
            ;; Linie ist zu kurz - löschen
            (entdel ent)
            (setq short-count (1+ short-count))
          )
          (progn
            ;; Linie ist lang genug - in Liste aufnehmen
            (setq all-lines (cons (list ent pt-start pt-end line-length) all-lines))
          )
        )
        (setq i (1+ i))
      )
      
      (if (> short-count 0)
        (princ (strcat "\n  " (itoa short-count) " kurze Linie(n) (< 0.005) wurden gelöscht."))
      )
      
      ;; SCHRITT 3: Übereinanderliegende und überlappende Linien finden
      (if all-lines
        (progn
          (princ "\nSchritt 3: Suche nach übereinanderliegenden/überlappenden Linien...")
          
          ;; Layer "0_kurze Linie" erstellen falls nicht vorhanden und einfrieren
          (create-and-freeze-layer "0_kurze Linie")
          
          ;; Finde alle übereinanderliegenden Linien
          (setq all-lines (find-and-remove-overlapping-lines all-lines))
          
          (if (> dup-count 0)
            (princ (strcat "\n  " (itoa dup-count) " kürzere/doppelte übereinanderliegende Linie(n) auf gefrorenen Layer '0_kurze Linie' verschoben."))
          )
        )
      )
      
      ;; SCHRITT 4: Verbinde Linien zu geschlossenen Polylinien
      (if all-lines
        (progn
          (princ "\nSchritt 4: Verbinde Linien zu Polylinien...")
          (princ (strcat "\n  " (itoa (length all-lines)) " Linien werden verarbeitet."))
          
          ;; Verarbeite alle Linien
          (foreach line-data all-lines
            (if (not (member (car line-data) processed-lines))
              (progn
                (setq chain (build-chain (car line-data) all-lines))
                (if (is-closed-chain chain all-lines)
                  (progn
                    (create-polyline-from-chain chain all-lines)
                    (setq count (1+ count))
                    (setq closed-chains (cons chain closed-chains))
                  )
                )
              )
            )
          )
          
          (princ (strcat "\n" (itoa count) " geschlossene Polylinie(n) wurden erstellt."))
        )
        (princ "\nKeine Linien zum Verarbeiten übrig.")
      )
      
      (princ "\n========================================================")
    )
    (princ "\nKeine Objekte ausgewählt.")
  )
  (princ)
)

;; Hilfsfunktion: Normalisiere Z-Koordinate auf 0
(defun normalize-z-coordinate (ent / entlist pt-start pt-end)
  (setq entlist (entget ent))
  (setq pt-start (cdr (assoc 10 entlist)))
  (setq pt-end (cdr (assoc 11 entlist)))
  
  ;; Setze Z auf 0.0
  (setq pt-start (list (car pt-start) (cadr pt-start) 0.0))
  (setq pt-end (list (car pt-end) (cadr pt-end) 0.0))
  
  ;; Update Entity
  (setq entlist (subst (cons 10 pt-start) (assoc 10 entlist) entlist))
  (setq entlist (subst (cons 11 pt-end) (assoc 11 entlist) entlist))
  (entmod entlist)
)

;; Hilfsfunktion: Layer erstellen und einfrieren
(defun create-and-freeze-layer (layer-name / layer-table layer-entry)
  (setq layer-table (tblsearch "LAYER" layer-name))
  
  (if (not layer-table)
    (progn
      ;; Layer existiert nicht - erstellen
      (command "._-LAYER" "_M" layer-name "_C" "7" layer-name "_F" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde erstellt und gefroren."))
    )
    (progn
      ;; Layer existiert - nur einfrieren
      (command "._-LAYER" "_F" layer-name "")
      (princ (strcat "\n  Layer '" layer-name "' wurde gefroren."))
    )
  )
)

;; Hilfsfunktion: Prüfe ob Punkt INNERHALB einer Linie liegt (nicht an den Enden!)
(defun point-inside-line (pt p1 p2 / tol minx maxx miny maxy on-line at-endpoint)
  (setq tol 0.0001)
  
  ;; Prüfe zuerst ob Punkt auf der Geraden liegt
  (setq on-line
    (< (abs (- (* (- (car pt) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr pt) (cadr p1)) (- (car p2) (car p1))))) tol)
  )
  
  ;; Prüfe ob Punkt an einem Endpunkt liegt
  (setq at-endpoint
    (or (equal pt p1 tol) (equal pt p2 tol))
  )
  
  ;; Punkt muss auf Linie liegen UND darf nicht an Endpunkt sein
  (if (and on-line (not at-endpoint))
    (progn
      ;; Prüfe ob Punkt zwischen p1 und p2 liegt
      (setq minx (min (car p1) (car p2)))
      (setq maxx (max (car p1) (car p2)))
      (setq miny (min (cadr p1) (cadr p2)))
      (setq maxy (max (cadr p1) (cadr p2)))
      
      (and
        (>= (car pt) (- minx tol))
        (<= (car pt) (+ maxx tol))
        (>= (cadr pt) (- miny tol))
        (<= (cadr pt) (+ maxy tol))
      )
    )
    nil
  )
)

;; Hilfsfunktion: Prüfe ob zwei Linien kollinear sind (auf derselben Geraden liegen)
(defun lines-collinear (p1 p2 p3 p4 / tol)
  (setq tol 0.0001)
  ;; Alle 4 Punkte müssen auf derselben Geraden liegen
  (and
    (< (abs (- (* (- (car p3) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr p3) (cadr p1)) (- (car p2) (car p1))))) tol)
    (< (abs (- (* (- (car p4) (car p1)) (- (cadr p2) (cadr p1)))
               (* (- (cadr p4) (cadr p1)) (- (car p2) (car p1))))) tol)
  )
)

;; Hilfsfunktion: Prüfe ob zwei Linien IDENTISCH sind (gleiche Endpunkte)
(defun lines-identical (p1 p2 p3 p4 / tol)
  (setq tol 0.0001)
  (or
    ;; Fall 1: p1=p3 UND p2=p4
    (and (equal p1 p3 tol) (equal p2 p4 tol))
    ;; Fall 2: p1=p4 UND p2=p3 (umgekehrte Richtung)
    (and (equal p1 p4 tol) (equal p2 p3 tol))
  )
)

;; Hilfsfunktion: Prüfe ob sich zwei Linien WIRKLICH überlappen
(defun lines-truly-overlap (p1 p2 p3 p4 / tol only-touch-at-ends has-internal-overlap are-identical)
  (setq tol 0.0001)
  
  ;; Erst prüfen ob überhaupt kollinear
  (if (not (lines-collinear p1 p2 p3 p4))
    nil  ;; Nicht auf gleicher Geraden = keine Überlappung
    (progn
      ;; Prüfe ob Linien identisch sind (doppelte Linie)
      (setq are-identical (lines-identical p1 p2 p3 p4))
      
      ;; Wenn identisch, dann ist das eine Überlappung!
      (if are-identical
        T  ;; Identische Linien = Überlappung
        (progn
          ;; Nicht identisch - prüfe auf Berührung vs. Überlappung
          
          ;; Prüfe ob nur Berührung an Endpunkten
          (setq only-touch-at-ends
            (and
              ;; Berühren sich
              (or
                (equal p1 p3 tol)  ;; Start1 = Start2
                (equal p1 p4 tol)  ;; Start1 = End2
                (equal p2 p3 tol)  ;; End1 = Start2
                (equal p2 p4 tol)  ;; End1 = End2
              )
              ;; ABER keine inneren Punkte überlappen
              (not
                (or
                  (point-inside-line p3 p1 p2)  ;; Start2 liegt in Linie1
                  (point-inside-line p4 p1 p2)  ;; End2 liegt in Linie1
                  (point-inside-line p1 p3 p4)  ;; Start1 liegt in Linie2
                  (point-inside-line p2 p3 p4)  ;; End1 liegt in Linie2
                )
              )
            )
          )
          
          ;; Prüfe ob innere Überlappung existiert
          (setq has-internal-overlap
            (or
              (point-inside-line p3 p1 p2)  ;; Start2 liegt INNERHALB Linie1
              (point-inside-line p4 p1 p2)  ;; End2 liegt INNERHALB Linie1
              (point-inside-line p1 p3 p4)  ;; Start1 liegt INNERHALB Linie2
              (point-inside-line p2 p3 p4)  ;; End1 liegt INNERHALB Linie2
            )
          )
          
          ;; Rückgabe: TRUE nur bei tatsächlicher Überlappung (nicht bei reiner Berührung)
          (and has-internal-overlap (not only-touch-at-ends))
        )
      )
    )
  )
)

;; Hilfsfunktion: Finde überlappende Linien und entferne kürzere aus Liste
(defun find-and-remove-overlapping-lines (line-list / i j current-data test-data result removed)
  (setq result line-list)
  (setq removed '())
  (setq dup-count 0)
  
  (setq i 0)
  (while (< i (length result))
    (setq current-data (nth i result))
    (setq current-ent (car current-data))
    (setq current-p1 (cadr current-data))
    (setq current-p2 (caddr current-data))
    (setq current-len (cadddr current-data))
    
    (setq j (1+ i))
    (while (< j (length result))
      (setq test-data (nth j result))
      (setq test-ent (car test-data))
      (setq test-p1 (cadr test-data))
      (setq test-p2 (caddr test-data))
      (setq test-len (cadddr test-data))
      
      ;; Prüfe ob Linien sich WIRKLICH überlappen (nicht nur berühren!)
      (if (lines-truly-overlap current-p1 current-p2 test-p1 test-p2)
        (progn
          (princ (strcat "\n  DEBUG: Überlappung gefunden zwischen Linie " (itoa (1+ i)) " und " (itoa (1+ j))))
          
          ;; Entscheide welche Linie verschoben wird
          (cond
            ;; Fall 1: test-Linie ist kürzer -> verschiebe test-Linie
            ((< test-len current-len)
             (princ (strcat " -> Verschiebe kürzere Linie " (itoa (1+ j))))
             (move-to-layer test-ent "0_kurze Linie")
             (setq result (remove-nth j result))
             (setq removed (cons test-ent removed))
             (setq dup-count (1+ dup-count))
             (setq j (1- j))  ;; Index korrigieren da Element entfernt wurde
            )
            ;; Fall 2: current-Linie ist kürzer -> verschiebe current-Linie
            ((> test-len current-len)
             (princ (strcat " -> Verschiebe kürzere Linie " (itoa (1+ i))))
             (move-to-layer current-ent "0_kurze Linie")
             (setq result (remove-nth i result))
             (setq removed (cons current-ent removed))
             (setq dup-count (1+ dup-count))
             (setq i (1- i))  ;; Index korrigieren und äußere Schleife neu starten
             (setq j (length result))  ;; Innere Schleife beenden
            )
            ;; Fall 3: GLEICHE Länge -> verschiebe die zweite (test-Linie)
            (T
             (princ (strcat " -> Verschiebe doppelte Linie " (itoa (1+ j)) " (gleiche Länge)"))
             (move-to-layer test-ent "0_kurze Linie")
             (setq result (remove-nth j result))
             (setq removed (cons test-ent removed))
             (setq dup-count (1+ dup-count))
             (setq j (1- j))  ;; Index korrigieren da Element entfernt wurde
            )
          )
        )
      )
      (setq j (1+ j))
    )
    (setq i (1+ i))
  )
  
  result
)

;; Hilfsfunktion: Entferne n-tes Element aus Liste
(defun remove-nth (n lst / i result)
  (setq i 0)
  (setq result '())
  (foreach item lst
    (if (/= i n)
      (setq result (append result (list item)))
    )
    (setq i (1+ i))
  )
  result
)

;; Hilfsfunktion: Verschiebe Linie auf anderen Layer
(defun move-to-layer (ent layer-name / entlist)
  (setq entlist (entget ent))
  (setq entlist (subst (cons 8 layer-name) (assoc 8 entlist) entlist))
  (entmod entlist)
)

;; Hilfsfunktion: Hole Linien-Daten aus Liste
(defun get-line-data (ent line-list / result)
  (setq result nil)
  (foreach line-data line-list
    (if (equal (car line-data) ent)
      (setq result line-data)
    )
  )
  result
)

;; Hilfsfunktion: Baue Linienkette von Startpunkt aus
(defun build-chain (start-ent all-lines / chain last-pt found test-ent used-ents start-data)
  (setq chain (list start-ent))
  (setq used-ents (list start-ent))
  (setq processed-lines (cons start-ent processed-lines))
  
  ;; Hole Start- und Endpunkt der ersten Linie
  (setq start-data (get-line-data start-ent all-lines))
  (setq last-pt (caddr start-data))  ;; Beginne am Endpunkt
  
  ;; Suche weitere anschließende Linien
  (setq found T)
  (while found
    (setq found nil)
    (foreach line-data all-lines
      (if (not found)
        (progn
          (setq test-ent (car line-data))
          (if (and (not (member test-ent used-ents))
                   (not (member test-ent processed-lines)))
            (progn
              (setq next-data (get-line-data test-ent all-lines))
              (setq next-start (cadr next-data))
              (setq next-end (caddr next-data))
              
              ;; Prüfe welcher Endpunkt von test-ent an last-pt anschließt
              (cond
                ;; Fall 1: next-start verbindet sich mit last-pt
                ((equal last-pt next-start 0.0001)
                 (setq chain (append chain (list test-ent)))
                 (setq last-pt next-end)
                 (setq used-ents (cons test-ent used-ents))
                 (setq processed-lines (cons test-ent processed-lines))
                 (setq found T)
                )
                ;; Fall 2: next-end verbindet sich mit last-pt
                ((equal last-pt next-end 0.0001)
                 (setq chain (append chain (list test-ent)))
                 (setq last-pt next-start)
                 (setq used-ents (cons test-ent used-ents))
                 (setq processed-lines (cons test-ent processed-lines))
                 (setq found T)
                )
              )
            )
          )
        )
      )
    )
  )
  
  chain
)

;; Hilfsfunktion: Prüfe ob Kette geschlossen ist
(defun is-closed-chain (chain all-lines / first-data last-data first-start last-end)
  (if (>= (length chain) 3)
    (progn
      (setq first-data (get-line-data (car chain) all-lines))
      (setq last-data (get-line-data (last chain) all-lines))
      (setq first-start (cadr first-data))
      (setq last-end (caddr last-data))
      
      ;; Prüfe ob letzte und erste Linie sich verbinden
      (or
        (equal first-start last-end 0.0001)
        (equal first-start (cadr last-data) 0.0001)
      )
    )
    nil
  )
)

;; Hilfsfunktion: Erstelle Polylinie aus Linienkette
(defun create-polyline-from-chain (chain all-lines / pt-list last-pt first-data pline-data)
  (setq pt-list '())
  
  ;; Starte mit der ersten Linie
  (setq first-data (get-line-data (car chain) all-lines))
  (setq pt-list (list (cadr first-data) (caddr first-data)))
  (setq last-pt (caddr first-data))
  
  ;; Füge alle weiteren Punkte hinzu
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
  
  ;; Entferne Duplikate
  (setq pt-list (remove-duplicate-points pt-list))
  
  ;; Erstelle Polylinie
  (command "_.PLINE")
  (foreach pt pt-list
    (command pt)
  )
  (command "_C")
  
  ;; Färbe die Polylinie mit Farbe 171
  (setq pline-data (entget (entlast)))
  (if (assoc 62 pline-data)
    (setq pline-data (subst (cons 62 171) (assoc 62 pline-data) pline-data))
    (setq pline-data (append pline-data (list (cons 62 171))))
  )
  (entmod pline-data)
  
  ;; Lösche originale Linien
  (foreach line-ent chain
    (entdel line-ent)
  )
)

;; Hilfsfunktion: Entferne doppelte Punkte aus Liste
(defun remove-duplicate-points (pt-list / result)
  (setq result '())
  (foreach pt pt-list
    (if (not (member-point pt result))
      (setq result (append result (list pt)))
    )
  )
  result
)

;; Hilfsfunktion: Prüfe ob Punkt bereits in Liste
(defun member-point (pt pt-list / found)
  (setq found nil)
  (foreach test-pt pt-list
    (if (equal pt test-pt 0.0001)
      (setq found T)
    )
  )
  found
)

(princ "\nJOINPOLY geladen. Tippen Sie 'joinpoly' zum Starten.")
(princ)
```

Die Kommentarzeilen am Anfang enthalten jetzt:

- ✅ **ZWECK** - Wofür das Programm gedacht ist
- ✅ **VORGEHENSWEISE** - Alle 6 Schritte detailliert erklärt
- ✅ **VORAUSSETZUNGEN** - Was erfüllt sein muss
- ✅ **ANWENDUNGS-HINWEIS** - Schritt-für-Schritt-Anleitung mit Tipps

[](#)![](https://mammouth.ai/app/a/default/c/moz-extension://fbfc4e15-e4f8-412f-a5e8-98f7572f56af/icon/icon_32.png)