# ISOLAYER.LSP - Mehrere Layer frieren und tauen
<br/><br/>

<hr style="border:0;height:20px;background:lightblue">

<div style="padding:10px;border-radius:5px;display:inline-block">
  <h2 style="margin:0;font-size:2em;color:darkblue;display:flex;align-items:flex-start">
    <span style="font-size:1em">❓</span>Frage
  </h2>
</div>


# In den Kommentarzeilen dieses LISP-Programms steht eine Zeile, für die es noch keine Funktion gibt:
```
;; ONLYX       - Eine Auswahl an Layern, die gefrohren werden    
```
Siehst du eine Möglichkeit, dafür die passende Funktion zu schaffen, anlog zu ONLY?


<br/><br/>

<hr style="border:0;height:20px;background:lightblue">

<div style="padding:10px;border-radius:5px;display:inline-block">
  <h2 style="margin:0;font-size:2em;color:darkblue;display:flex;align-items:flex-start">
    <span style="font-size:1em">📌</span>Antwort
  </h2>
</div>


### 🧠 Rolle: AutoLISP-Entwickler

Hey PiTTi! Na klar sehe ich die Möglichkeit – und die Umsetzung ist eigentlich recht elegant, weil `ONLYX` quasi das **logische Inverse** von `ONLY` ist. Bei `ONLY` werden alle Layer **außer** den gewählten eingefroren. Bei `ONLYX` werden **genau** die gewählten Layer eingefroren – alle anderen bleiben sichtbar.

___

### 🔍 Logischer Unterschied `ONLY` vs. `ONLYX`

| Funktion | Gewählte Layer | Alle anderen Layer |
| --- | --- | --- |
| `ONLY` | bleiben sichtbar (getaut) | werden eingefroren |
| `ONLYX` | werden eingefroren | bleiben sichtbar (getaut) |

___

### ✅ Implementierung `c:onlyx`

```
;; =================================================================
;; ONLYX       - Eine Auswahl an Layern, die gefrohren werden
;; =================================================================

(defun c:onlyx ()
  ;; Funktion zum Einfrieren ausgewählter Layer (alle anderen bleiben sichtbar)
  (setq oldcmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)

  (princ "\nWähle Objekte deren Layer eingefroren werden sollen (Enter zum Beenden): ")
  (setq selset (ssget))

  (if selset
    (progn
      ;; Liste für die Layer der gewählten Objekte
      (setq selectedlayers '())

      ;; Durchlaufe alle gewählten Objekte
      (setq i 0)
      (repeat (sslength selset)
        (setq ent (ssname selset i))
        (setq entdata (entget ent))
        (setq objlayer (cdr (assoc 8 entdata)))

        ;; Füge Layer zur Liste hinzu, wenn noch nicht vorhanden
        (if (not (member objlayer selectedlayers))
          (setq selectedlayers (cons objlayer selectedlayers))
        )
        (setq i (1+ i))
      )

      ;; Zeige alle ausgewählten Layer an
      (princ "\nEinzufrierende Layer: ")
      (foreach layer selectedlayers
        (princ (strcat layer " "))
      )

      ;; Aktuellen Layer ermitteln
      (setq currentlayer (getvar "CLAYER"))

      ;; Durchlaufe alle gewählten Layer und friere sie ein
      (foreach layername selectedlayers
        (cond
          ;; Aktuellen Layer nicht einfrieren (AutoCAD würde das ohnehin verweigern)
          ((= layername currentlayer)
           (princ (strcat "\nLayer '" layername "' ist der aktuelle Layer - wird übersprungen."))
          )
          ;; Layer 0 und Defpoints schützen
          ((or (= layername "0")
               (= layername "Defpoints"))
           (princ (strcat "\nLayer '" layername "' wird nicht eingefroren (geschützter Layer)."))
          )
          ;; Einfrieren
          (T
           (command "LAYER" "F" layername "")
           (princ (strcat "\nLayer eingefroren: " layername))
          )
        )
      )

      (princ "\nAusgewählte Layer wurden eingefroren.")
    )
    (princ "\nKeine Objekte gewählt.")
  )

  ;; CMDECHO zurücksetzen
  (setvar "CMDECHO" oldcmdecho)
  (princ)
)
```

___

### 💡 Hinweise zur Implementierung

-   **Aktueller Layer (`CLAYER`):** AutoCAD verweigert das Einfrieren des aktuell gesetzten Layers. Die Funktion prüft das explizit und überspringt ihn mit einer Meldung – statt stumm zu scheitern.
-   **Layer `0` und `Defpoints`:** Analog zu `ONLY` werden diese geschützt. Du kannst diesen Schutz natürlich entfernen, wenn du ihn nicht brauchst.
-   **Keine Änderung des `CLAYER`:** Im Gegensatz zu `ONLY` gibt es keinen Grund, den aktuellen Layer zu wechseln – die Funktion friert ja nur ein, ohne eine „Arbeitsebene" zu definieren.
-   **Doppelte Layer:** Wählt der Nutzer mehrere Objekte auf demselben Layer, wird dieser trotzdem nur **einmal** eingefroren (dank der `member`\-Prüfung).

___

> **Kurzfazit für PiTTi:** `ONLYX` ist das spiegelbildliche Gegenstück zu `ONLY` – statt alle _anderen_ Layer einzufrieren, werden genau die _gewählten_ eingefroren. Die Logik ist nahezu identisch, nur der `foreach`\-Block am Ende arbeitet auf der `selectedlayers`\-Liste direkt statt auf der Gesamtlayer-Tabelle. Der einzige echte Fallstrick ist der aktuelle Layer, der in AutoCAD grundsätzlich nicht eingefroren werden kann – das wird sauber abgefangen. 🧊




<br/><br/>

<hr style="border:0;height:20px;background:lightblue">

<div style="padding:10px;border-radius:5px;display:inline-block">
  <h2 style="margin:0;font-size:2em;color:darkblue;display:flex;align-items:flex-start">
    <span style="font-size:1em">❓</span>Frage
  </h2>
</div>


# Kannst du noch eine kleine Anpassung vornehmen:
Wenn einer der gewählten Layer zum Zeitpunkt seiner Wahl der aktuelle Layer ist, kann er nicht gefroren werden.

Ich hätte zwei Lösungen:

1. präventiv Layer "0" auf aktuell setzen
oder
2. Nur wenn einer der gewählten Layer der aktuelle ist Layer "0" auf aktuell setzen

Würde das mit überschaubarem Aufwand möglich sein?


<br/><br/>

<hr style="border:0;height:20px;background:lightblue">

<div style="padding:10px;border-radius:5px;display:inline-block">
  <h2 style="margin:0;font-size:2em;color:darkblue;display:flex;align-items:flex-start">
    <span style="font-size:1em">📌</span>Antwort
  </h2>
</div>


#### 💡 Lösung 2 ist die elegantere Wahl

Hey PiTTi! Beide Varianten sind mit überschaubarem Aufwand machbar. Aber ich würde klar **Lösung 2** empfehlen:

- Lösung 1 setzt **immer** Layer `0` als aktuell – auch wenn es gar nicht nötig wäre. Das ist unnötig invasiv.
- Lösung 2 greift **nur ein, wenn es wirklich nötig ist** – sauberer, weniger Seiteneffekte.

---

### ✅ Angepasste Funktion `c:onlyx` mit Lösung 2

```lisp
;; =================================================================
;; ONLYX       - Eine Auswahl an Layern, die gefrohren werden
;; =================================================================

(defun c:onlyx ()
  ;; Funktion zum Einfrieren ausgewählter Layer (alle anderen bleiben sichtbar)
  (setq oldcmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)

  (princ "\nWähle Objekte deren Layer eingefroren werden sollen (Enter zum Beenden): ")
  (setq selset (ssget))

  (if selset
    (progn
      ;; Liste für die Layer der gewählten Objekte
      (setq selectedlayers '())

      ;; Durchlaufe alle gewählten Objekte
      (setq i 0)
      (repeat (sslength selset)
        (setq ent (ssname selset i))
        (setq entdata (entget ent))
        (setq objlayer (cdr (assoc 8 entdata)))

        ;; Füge Layer zur Liste hinzu, wenn noch nicht vorhanden
        (if (not (member objlayer selectedlayers))
          (setq selectedlayers (cons objlayer selectedlayers))
        )
        (setq i (1+ i))
      )

      ;; Zeige alle ausgewählten Layer an
      (princ "\nEinzufrierende Layer: ")
      (foreach layer selectedlayers
        (princ (strcat layer " "))
      )

      ;; Aktuellen Layer ermitteln
      (setq currentlayer (getvar "CLAYER"))

      ;; -------------------------------------------------------
      ;; Nur wenn der aktuelle Layer in der Auswahl enthalten ist:
      ;; Layer "0" als aktuellen Layer setzen
      ;; -------------------------------------------------------
      (if (member currentlayer selectedlayers)
        (progn
          (setvar "CLAYER" "0")
          (princ (strcat "\nLayer '" currentlayer "' ist der aktuelle Layer."))
          (princ "\nAktueller Layer wurde auf '0' gesetzt.")
        )
      )

      ;; Durchlaufe alle gewählten Layer und friere sie ein
      (foreach layername selectedlayers
        (cond
          ;; Layer 0 und Defpoints schützen
          ((or (= layername "0")
               (= layername "Defpoints"))
           (princ (strcat "\nLayer '" layername "' wird nicht eingefroren (geschützter Layer)."))
          )
          ;; Einfrieren
          (T
           (command "LAYER" "F" layername "")
           (princ (strcat "\nLayer eingefroren: " layername))
          )
        )
      )

      (princ "\nAusgewählte Layer wurden eingefroren.")
    )
    (princ "\nKeine Objekte gewählt.")
  )

  ;; CMDECHO zurücksetzen
  (setvar "CMDECHO" oldcmdecho)
  (princ)
)
```

---

### 🔍 Was hat sich geändert?

| Bereich | Vorher | Nachher |
|---|---|---|
| Prüfung auf aktuellen Layer | Im `foreach` beim Einfrieren | **Vorab**, vor der Einfrierloop |
| Reaktion auf Konflikt | Nur Meldung, Layer wird übersprungen | Layer `0` wird als aktuell gesetzt → Layer kann eingefroren werden |
| Layer `0` als Fallback | Nie | **Nur wenn nötig** (Lösung 2) |

---

> **Kurzfazit für PiTTi:**
> Die Anpassung war tatsächlich überschaubar – ein einzelner `if (member ...)`-Block vor der Einfrierloop erledigt den Job. Die separate Prüfung im `cond` für den aktuellen Layer ist damit überflüssig geworden und wurde entfernt, weil der Konflikt jetzt **präventiv** gelöst wird, bevor er entstehen kann. Sauber. 🧊