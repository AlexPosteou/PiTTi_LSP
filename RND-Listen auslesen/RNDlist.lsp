(defun c:ExtractAttributes ()
  ;; Hole den Dateinamen der aktuellen Zeichnung
  (setq dwgName (getvar "DWGNAME"))
  ;; Entferne die Dateiendung und füge ".rnd" hinzu
  (setq outputFileName (strcat "C:/SWAP/RND/" (vl-filename-base dwgName) ".rnd"))
  
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
        
        ;; Prüfe, ob der Blockname "RND_LIS2" ist und ob der Block Attribute hat
        (if (and (eq (cdr (assoc 2 ent)) "RND_LIS2") (assoc 66 ent))
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
  (princ (strcat "\nAttribute für Block 'RND_LIS2' wurden in Datei gespeichert: " outputFileName))
)

