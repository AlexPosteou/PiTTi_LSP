# JoinLineToPolyline.lsp

## Hinweis: die "JoinLineToPolyline.dwg" entählt ein Schaubild des Workflows
---

## 🎯 Zweck

Dieses Programm verbindet einzelne **Linien-Objekte** zu **geschlossenen Polylinien** und färbt diese ein.

Es ist besonders nützlich beim **Bereinigen von importierten oder gescannten Zeichnungen**, bei denen geschlossene Konturen aus vielen Einzellinien bestehen.

---

## 🔧 Vorgehensweise

### 1️⃣ Normalisierung

- Alle **Z-Koordinaten** der ausgewählten Linien werden auf `0` gesetzt  
- Verarbeitung erfolgt somit in der **2D-Ebene**

---

### 2️⃣ Bereinigung kurzer Linien

- Linien mit einer Länge `< 0.005` werden automatisch gelöscht  
- Diese entstehen typischerweise durch Zeichnungsfehler oder Importe

---

### 3️⃣ Erkennung überlappender Linien

Das Programm erkennt Linien, die:

- vollständig übereinander liegen (**doppelte Linien**)  
- sich teilweise überlappen (auf gleicher Geraden)

Maßnahmen:

- Die kürzere bzw. doppelte Linie wird auf den Layer  
  **`0_kurze Linie`** verschoben  
- Dieser Layer wird automatisch **eingefroren**

---

### 4️⃣ Kettenbildung

- Linien, deren Anfangs- oder Endpunkte sich exakt berühren  
- Toleranz: `0.0001`

Diese werden zu **Ketten verbunden**.

---

### 5️⃣ Polylinien-Erstellung

Geschlossene Ketten werden:

- mindestens **3 Linien**
- **Startpunkt = Endpunkt**
- in **Polylinien konvertiert**
- mit der **Farbe 171** eingefärbt

---

### 6️⃣ Aufräumen

Nach erfolgreicher Konvertierung werden die ursprünglichen Linien-Objekte gelöscht.

---

## ✅ Voraussetzungen

- AutoCAD oder kompatible CAD-Software mit **LISP-Unterstützung**
- Es werden ausschließlich `LINE`-Objekte verarbeitet  
  (keine Polylinien, Bögen, Splines etc.)
- Linien müssen sich an gemeinsamen Endpunkten berühren  
  (nicht nur überlappen)
- Für geschlossene Polylinien: mindestens **3 zusammenhängende Linien**
- Endpunkte müssen mit einer Toleranz von `0.0001` übereinstimmen
- Z-Koordinaten sollten idealerweise bereits `0` sein  
  (werden automatisch korrigiert, aber unterschiedliche Z-Werte können Probleme verursachen)

---

## 🚀 Anwendung

### 1️⃣ Datei laden

```lisp
(load "JoinLineToPolyline.lsp")
```

---

### 2️⃣ Programm starten

Befehl in der Kommandozeile:

```
JOINPOLY
```

---

### 3️⃣ Linien auswählen

- Alle zu verarbeitenden Linien markieren  
- Am besten per **Fensterauswahl** oder mit `Alle`

---

### 4️⃣ Verarbeitung

- Während der Ausführung werden Statusmeldungen angezeigt

---

### 5️⃣ Nachkontrolle

Nach Abschluss prüfen:

- ✅ Anzahl der erstellten Polylinien  
- ✅ Layer `0_kurze Linie` (ggf. auftauen für Kontrolle)  
- ✅ Nicht verarbeitete Linien (offene Ketten)

---

## ⚠️ Wichtiger Hinweis

Führe vor der Anwendung unbedingt eine **Sicherungskopie deiner Zeichnung** durch.

Das Programm:

- löscht Objekte  
- verschiebt Linien  
- friert Layer ein  

---

## 📌 Version

| Eigenschaft | Wert |
|-------------|------|
| Version     | 3.5  |
| Datum       | 02/2026 |

---

