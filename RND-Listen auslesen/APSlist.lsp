(defun c:ExtractAPSAttributes ()
  ;; Hole den Dateinamen der aktuellen Zeichnung
  (setq dwgName (getvar "DWGNAME"))
  ;; Entferne die Dateiendung und füge ".aps" hinzu
  (setq outputFileName (strcat "C:/SWAP/RND/" (vl-filename-base dwgName) ".aps"))
  
  ;; Öffne die Datei zum Schreiben
  (setq output (open outputFileName "w"))
  
  ;; Schreibe die erste Zeile mit dem Namen der Zeichnung
  (write-line (strcat "Plan: " (vl-filename-base dwgName) ";;;;;") output)
  
  ;; Hole alle Blockeinfügungen
  (setq ss (ssget "X" '((0 . "INSERT"))))
  
  (if ss
    (progn
      ;; Durchlaufe alle Blöcke
      (repeat (setq i (sslength ss))
        (setq ent (entget (ssname ss (setq i (1- i)))))
        
        ;; Prüfe, ob der Blockname "APS_AUSZ" ist und ob der Block Attribute hat
        (if (and (eq (cdr (assoc 2 ent)) "APS_AUSZ") (assoc 66 ent))
          (progn
            ;; Lege eine leere Zeichenkette für die Attributausgabe des Blocks an
            (setq attributeLine "")
            
            ;; Attributentität des Blocks holen
            (setq att (entnext (cdr (assoc -1 ent))))
            
            ;; Attribute auslesen und zur Zeile hinzufügen
            (while (and att (= (cdr (assoc 0 (entget att))) "ATTRIB"))
              ;; Füge den Attributnamen und -wert zur Zeile hinzu, getrennt durch ": "
              (setq attributeLine (strcat attributeLine (cdr (assoc 2 ent)) " - " (cdr (assoc 2 (entget att))) ": " (cdr (assoc 1 (entget att))) "; "))
              (setq att (entnext att))
            )
            
            ;; Schreibe die gesamte Zeile für diesen Block in die Datei und füge einen Zeilenumbruch hinzu
            (write-line attributeLine output)
          )
        )
      )
    )
  )
  
  ;; Datei schließen
  (close output)
  (princ (strcat "\nAttribute für Block 'APS_AUSZ' wurden in Datei gespeichert: " outputFileName))
)

