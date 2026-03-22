;; ISOLAYER.LSP - Sichtbarkeit von Layern (Frieren, Tauen)
;; Autor: Claude AI
;; Datum: 2025-08-04
;; 
;; Funktionen:
;; ISOLAYER    - Alle Layer außer dem gewählten werden gefrohren
;; TAULAYER    - Alle Layer werden getaut
;; ONLY        - Eine Auswahl an Layern, die nicht gefrohren werden

;; =================================================================
;; ISOLAYER    - Alle Layer außer dem gewählten werden gefrohren
;; =================================================================

(defun c:isolayer ()
  ;; Funktion zum Isolieren eines Layers basierend auf einem gewählten Objekt
  (setq oldcmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  
  (princ "\nWähle ein Objekt: ")
  (setq sel (entsel))
  
  (if sel
    (progn
      ;; Hole das Entity-Objekt
      (setq ent (car sel))
      (setq entdata (entget ent))
      
      ;; Ermittle den Layer des gewählten Objekts
      (setq objlayer (cdr (assoc 8 entdata)))
      
      ;; Setze den Layer als aktuellen Layer
      (setvar "CLAYER" objlayer)
      (princ (strcat "\nAktueller Layer ist jetzt: " objlayer))
      
      ;; Hole alle Layer aus der Zeichnung
      (setq layertable (tblnext "LAYER" T))
      
      ;; Durchlaufe alle Layer und friere sie ein, außer dem aktuellen
      (while layertable
        (setq layername (cdr (assoc 2 layertable)))
        
        ;; Wenn es nicht der aktuelle Layer ist, friere ihn ein
        (if (and (/= layername objlayer)
                 (/= layername "0")  ; Layer 0 nicht einfrieren (optional)
                 (/= layername "Defpoints")) ; Defpoints Layer nicht einfrieren
          (progn
            (command "LAYER" "F" layername "")
            (princ (strcat "\nLayer eingefroren: " layername))
          )
        )
        
        ;; Nächsten Layer holen
        (setq layertable (tblnext "LAYER"))
      )
      
      (princ (strcat "\nAlle Layer außer '" objlayer "' wurden eingefroren."))
    )
    (princ "\nKein Objekt gewählt.")
  )
  
  ;; CMDECHO zurücksetzen
  (setvar "CMDECHO" oldcmdecho)
  (princ)
)

;; =================================================================
;; TAULAYER    - Alle Layer werden getaut
;; =================================================================

;; Funktion zum Auftauen aller gefrorenen Layer
(defun c:taulayer ()
  ;; Funktion zum Auftauen aller eingefrorenen Layer
  (setq oldcmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  
  (princ "\nTaue alle gefrorenen Layer auf...")
  
  ;; Hole alle Layer aus der Zeichnung
  (setq layertable (tblnext "LAYER" T))
  (setq count 0)
  
  ;; Durchlaufe alle Layer und taue eingefrorene Layer auf
  (while layertable
    (setq layername (cdr (assoc 2 layertable)))
    (setq layerflags (cdr (assoc 70 layertable)))
    
    ;; Prüfe ob Layer eingefroren ist (Bit 1 von layerflags)
    ;; Bit 1 = 1 bedeutet eingefroren
    (if (= (logand layerflags 1) 1)
      (progn
        (command "LAYER" "T" layername "")
        (princ (strcat "\nLayer aufgetaut: " layername))
        (setq count (1+ count))
      )
    )
    
    ;; Nächsten Layer holen
    (setq layertable (tblnext "LAYER"))
  )
  
  (if (> count 0)
    (princ (strcat "\n" (itoa count) " Layer wurden aufgetaut."))
    (princ "\nKeine gefrorenen Layer gefunden.")
  )
  
  ;; CMDECHO zurücksetzen
  (setvar "CMDECHO" oldcmdecho)
  (princ)
)

;; =================================================================
;; ONLY        - Eine Auswahl an Layern, die nicht gefrohren werden
;; =================================================================

;; Erweiterte Version - Mehrere Objekte wählen möglich
(defun c:only ()
  ;; Funktion zum Isolieren mehrerer Layer (alle anderen Layer werden eingefroren)
  (setq oldcmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)
  
  (princ "\nWähle Objekte (Enter zum Beenden): ")
  (setq selset (ssget))
  
  (if selset
    (progn
      ;; Liste für die Layer der gewählten Objekte
      (setq selectedlayers '())
      (setq firstlayer nil)
      
      ;; Durchlaufe alle gewählten Objekte
      (setq i 0)
      (repeat (sslength selset)
        (setq ent (ssname selset i))
        (setq entdata (entget ent))
        (setq objlayer (cdr (assoc 8 entdata)))
        
        ;; Füge Layer zur Liste hinzu, wenn noch nicht vorhanden
        (if (not (member objlayer selectedlayers))
          (progn
            (setq selectedlayers (cons objlayer selectedlayers))
            (if (not firstlayer)
              (setq firstlayer objlayer)
            )
          )
        )
        (setq i (1+ i))
      )
      
      ;; Setze den ersten Layer als aktuellen Layer
      (if firstlayer
        (progn
          (setvar "CLAYER" firstlayer)
          (princ (strcat "\nAktueller Layer ist jetzt: " firstlayer))
        )
      )
      
      ;; Zeige alle ausgewählten Layer an
      (princ "\nAusgewählte Layer: ")
      (foreach layer selectedlayers
        (princ (strcat layer " "))
      )
      
      ;; Hole alle Layer aus der Zeichnung
      (setq layertable (tblnext "LAYER" T))
      
      ;; Durchlaufe alle Layer und friere sie ein, außer den ausgewählten
      (while layertable
        (setq layername (cdr (assoc 2 layertable)))
        
        ;; Wenn es nicht einer der ausgewählten Layer ist, friere ihn ein
        (if (not (member layername selectedlayers))
          (progn
            (command "LAYER" "F" layername "")
            (princ (strcat "\nLayer eingefroren: " layername))
          )
        )
        
        ;; Nächsten Layer holen
        (setq layertable (tblnext "LAYER"))
      )
      
      (princ (strcat "\nAlle Layer außer den ausgewählten wurden eingefroren."))
    )
    (princ "\nKeine Objekte gewählt.")
  )
  
  ;; CMDECHO zurücksetzen
  (setvar "CMDECHO" oldcmdecho)
  (princ)
)