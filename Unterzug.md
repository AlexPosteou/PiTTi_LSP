# Unterzug.lsp

<br/><br/>

<hr style="border:0;height:20px;background:lightblue">

<div style="padding:10px;border-radius:5px;display:inline-block">
  <h2 style="margin:0;font-size:2em;color:darkblue;display:flex;align-items:flex-start">
    <span style="font-size:1em">❓</span>Frage
  </h2>
</div>


<br/><br/>

<hr style="border:0;height:20px;background:lightblue">

<div style="padding:10px;border-radius:5px;display:inline-block">
  <h2 style="margin:0;font-size:2em;color:darkblue;display:flex;align-items:flex-start">
    <span style="font-size:1em">📌</span>Antwort
  </h2>
</div>

---

# ✅ 1️⃣ Kurz-Dokumentation (Markdown-Version)

---

# Unterzug.lsp

---

## 🎯 Zweck

Das Programm `unterzug.lsp` (Befehl: `UZ`) erkennt **parallele, gleichlange Linien oder Polylinien-Segmente**, die in einem definierten Abstand zueinander liegen, und wandelt diese automatisch in **geschlossene Rechtecke (Polylinien)** um.

Typischer Anwendungsfall:

- Darstellung von **Unterzügen**
- Erkennen von Doppellinien
- Umwandlung in saubere Rechteck-Geometrie
- Aufräumen von Architekturplänen

---

## 🔎 Verarbeitete Objekte

- `LINE`
- `LWPOLYLINE`
- `POLYLINE`

Polylinien werden segmentweise ausgewertet.

---

## ⚙️ Funktionsweise

### 1️⃣ Layer-Vorbereitung

Falls nicht vorhanden, wird automatisch erstellt:

| Eigenschaft | Wert |
|-------------|------|
| Layername   | `UZ_TEMP` |
| Farbe       | 5 |
| Linientyp   | `HIDDEN4` |

---

### 2️⃣ Segment-Extraktion

- Linien → direkt Start-/Endpunkt
- Polylinien → Zerlegung in Einzelsegmente
- Geschlossene Polylinien → letztes Segment wird ergänzt

---

### 3️⃣ Prüfbedingungen für Linienpaare

Zwei Segmente werden als Unterzug erkannt, wenn:

| Kriterium | Bedingung |
|------------|------------|
| Parallelität | Winkeldifferenz < 0.02 rad |
| Längengleichheit | Differenz < 0.05 |
| Mindestlänge | ≥ 0.55 |
| Abstand | > 0.001 und ≤ 0.50 |
| Layer | Nicht: `BETON`, `OBJEKT`, `ACHSEN` |

---

### 4️⃣ Abstandsermittlung

Berechnung des minimalen senkrechten Abstands:

- Punkt-zu-Linie Projektionen
- Minimum der gültigen Abstände

---

### 5️⃣ Rechteck-Erstellung

Wenn alle Bedingungen erfüllt sind:

- Erzeugung einer geschlossenen `PLINE`
- Eigenschaften:
  - Farbe: `VONLAYER`
  - Linientyp: `VONLAYER`
- Verschiebung auf Layer `UZ_TEMP`

---

### 6️⃣ Aufräumen

- Ursprüngliche Linien/Polylinien werden gelöscht
- Verarbeitete Elemente werden markiert
- Mehrfachverarbeitung wird verhindert

---

## 🚀 Anwendung

### Laden

```lisp
(load "unterzug.lsp")
```

---

### Starten

```
UZ
```

---

### Ablauf

1. Objekte auswählen
2. Automatische Analyse
3. Rechtecke werden erzeugt
4. Ergebnisanzahl wird ausgegeben

---

## ⚠️ Wichtige Parameter

| Parameter | Wert |
|------------|--------|
| Parallel-Toleranz | 0.02 rad |
| Längentoleranz | 0.05 |
| Mindestlänge | 0.55 |
| Abstand min | 0.001 |
| Abstand max | 0.50 |

---

## ⚠️ Einschränkungen / ABER

- Nur gerade Segmente werden berücksichtigt
- Bögen werden ignoriert
- Keine 3D-Unterstützung
- Toleranzen sind fest im Code definiert
- Performance bei sehr großen Auswahlen kann sinken (O(n²)-Vergleich)

---

## 💡 Typischer Anwendungsfall

```
Zwei parallele Linien mit 25 cm Abstand
→ Automatische Umwandlung in Rechteck-Unterzug
→ Saubere CAD-Struktur
```

---

## 📌 Version

| Eigenschaft | Wert |
|-------------|------|
| Datei | unterzug.lsp |
| Befehl | UZ |
| Typ | Geometrie-Analyse & Automatisierung |

---

---

# ✅ 2️⃣ Kommentarblock für die LSP-Datei

Diesen Block kannst du direkt oben in die Datei einfügen:

```lisp
;; ============================================================================
;; unterzug.lsp
;; ============================================================================
;;
;; ZWECK:
;; ------
;; Dieses Programm erkennt parallele, gleichlange Linien oder
;; Polylinien-Segmente und wandelt diese automatisch in geschlossene
;; Rechtecke (Polylinien) um.
;;
;; Typischer Anwendungsfall:
;; - Darstellung von Unterzügen
;; - Erkennung von Doppellinien
;; - Bereinigung von Architekturzeichnungen
;;
;; FUNKTIONSWEISE:
;; ---------------
;; 1. Erstellung des Layers "UZ_TEMP" (falls nicht vorhanden)
;;    - Farbe: 5
;;    - Linientyp: HIDDEN4
;;
;; 2. Segment-Extraktion:
;;    - LINE → direktes Segment
;;    - LWPOLYLINE / POLYLINE → Zerlegung in Einzelsegmente
;;
;; 3. Zwei Segmente werden als Paar erkannt, wenn:
;;    - Parallelität (Winkeldifferenz < 0.02 rad)
;;    - Längendifferenz < 0.05
;;    - Mindestlänge ≥ 0.55
;;    - Abstand > 0.001 und ≤ 0.50
;;    - Layer nicht: BETON, OBJEKT, ACHSEN
;;
;; 4. Rechteckerzeugung:
;;    - Erstellung einer geschlossenen Polyline
;;    - Eigenschaften: Farbe & Linientyp = VONLAYER
;;    - Verschiebung auf Layer UZ_TEMP
;;
;; 5. Aufräumen:
;;    - Ursprüngliche Objekte werden gelöscht
;;    - Mehrfachverarbeitung wird verhindert
;;
;; EINSCHRÄNKUNGEN:
;; ----------------
;; - Nur 2D-Geometrie
;; - Keine Unterstützung für Bögen
;; - Toleranzen sind fest im Code definiert
;; - O(n²)-Vergleich → Performance kann bei großen Auswahlen sinken
;;
;; ANWENDUNG:
;; ----------
;; (load "unterzug.lsp")
;; Befehl: UZ
;;
;; ============================================================================
```

---

# 🧠 Technische Einschätzung (kurz & ehrlich)

PiTTi, dein Script ist:

✅ sauber strukturiert  
✅ logisch aufgebaut  
✅ gut segmentiert  
✅ robust gegen Mehrfachverarbeitung  

ABER:

⚠️ Performance ist quadratisch (n²)  
⚠️ Toleranzen sind hardcoded  
⚠️ Keine Z-Normalisierung wie im Join-Script  
⚠️ Keine Bounding-Box-Vorfilterung  

Wenn du willst, kann ich dir daraus eine **Version 2.0 mit Performance-Optimierung und parametrisierbaren Toleranzen** bauen 😎

---

## 🎯 Kurzfazit

Dein `unterzug.lsp` erkennt sauber parallele Linienpaare und ersetzt sie automatisiert durch Rechtecke auf einem definierten Layer.  
