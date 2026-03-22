# RND_LEI.LSP - Korrigiert die Stabanzahl für eine Leiter bei Änderung der Länge (und des Stababstandes)

---

### Scriptname
**RND_TEILUNG.LSP**

---

### Zweck des Scripts
Das AutoLISP‑Script dient zur **automatischen Berechnung der Anzahl von Teilungspunkten** (z. B. Schrauben, Befestigungen oder Montagepunkte) entlang einer oder zweier Linien in AutoCAD.

Das Ergebnis wird anschließend **in das Attribut `ANZ` eines ausgewählten Blocks vom Typ `RND_LEI` geschrieben**.  
Die Berechnung basiert auf dem im Block hinterlegten Attribut **`ABSTD`**, welches den Abstand der Teilungspunkte vorgibt.

---

### Funktionsweise

Das Script wird über den AutoCAD‑Befehl **`TLG`** gestartet und arbeitet in mehreren Schritten:

1. **Blockauswahl**
   - Der Benutzer wählt einen Block vom Typ **`RND_LEI`** aus.
   - Aus diesem Block wird das Attribut **`ABSTD`** gelesen.

2. **Auslesen des Abstandswertes**
   - Das Attribut `ABSTD` enthält einen Abstandswert im Format:
     
     ```
     -XX
     -XX.X
     ```
   - Der Bindestrich ist lediglich ein Präfix.
   - Der Wert wird als **Zentimeter interpretiert** und intern in **Meter umgerechnet**.

3. **Auswahl der Linien**
   - Der Benutzer wählt:
     - **eine erste Linie**
     - **eine zweite Linie**
   - Wird **dieselbe Linie zweimal ausgewählt**, arbeitet das Script im **Einzellinienmodus**.

4. **Bestimmung der Gesamtstrecke**
   - Das Script liest die Start‑ und Endpunkte der Linie(n).
   - Es berechnet die **Ausdehnung der Punkte in X‑ und Y‑Richtung**.
   - Die **größere Ausdehnung** wird als maßgebliche Gesamtlänge `GESAMTL` verwendet.

5. **Berechnung der Anzahl der Teilungspunkte**

   Die Anzahl der Punkte wird berechnet mit:

\[
ANZ = \lceil \frac{GESAMTL}{ABSTD} \rceil + 1
\]

Dabei bedeutet:

- `GESAMTL` = ermittelte Gesamtlänge der Linie(n) in Metern  
- `ABSTD` = Abstand der Teilungspunkte in Metern  
- `ceil()` = Aufrunden auf die nächste ganze Zahl  

Das **+1** stellt sicher, dass beide Endpunkte berücksichtigt werden.

6. **Schreiben des Ergebnisses**
   - Das berechnete Ergebnis wird als Text in das **Blockattribut `ANZ`** geschrieben.

---

### Voraussetzungen für die Anwendung

- **Software:** AutoCAD (mit AutoLISP‑Unterstützung)
- **Scriptdatei:** `RND_TEILUNG.LSP`
- Das Script muss:
  - manuell über **APPLOAD** geladen werden  
  - oder in einer Autoload‑Routine eingebunden sein

Erforderliche Objekte im Zeichnungsbestand:

- **Blockname:** `RND_LEI`
- Der Block muss folgende Attribute enthalten:

| Attribut | Bedeutung |
|---|---|
| `ABSTD` | Abstand der Teilungspunkte (cm, Format `-XX` oder `-XX.X`) |
| `ANZ` | Ergebnisfeld für die berechnete Anzahl |

Unterstützte Geometrie:

- **LINE‑Objekte**
- maximal **zwei Linien**
- Einzellinienmodus durch **doppelte Auswahl derselben Linie**

---

### Anwendungshinweise

1. Script laden:
```
APPLOAD → RND_TEILUNG.LSP
```

2. Befehl starten:
```
RND_TEILUNG
```

3. Ablauf:

- Block **RND_LEI** anklicken
- erste Linie auswählen
- zweite Linie auswählen  
  *(oder dieselbe Linie erneut für Einzellinienmodus)*

4. Ergebnis:

- Die berechnete Anzahl der Teilungspunkte wird automatisch in das **Attribut `ANZ`** des Blocks geschrieben.
- Statusmeldungen erscheinen in der **AutoCAD‑Befehlszeile**.

---

### Besonderheiten

- Der Abstandswert `ABSTD` muss **größer als 0** sein.
- Ungültige Werte oder falsche Objekttypen führen zu einem **Scriptabbruch mit Meldung**.
- Die Berechnung basiert auf der **größeren Achsausdehnung (X oder Y)** und eignet sich daher besonders für **orthogonale oder nahezu horizontale/vertikale Linien**.

---

---

# b) Kommentarblock (für den Anfang des Scripts)

```lisp
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
;;;   2. Befehl starten:  TLG
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
```

---
