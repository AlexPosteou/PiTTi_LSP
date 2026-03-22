;; ============================================================================
;; unterzug.lsp - Doppellinien und Polylinien in Rechtecke umwandeln
;; Kommando: uz
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


(defun c:uz (/ ss i ent1 ent2 seg1_list seg2_list seg1 seg2
             pt1s pt1e pt2s pt2e len1 len2 dist para
             ang1 ang2 rect_list processed)
  
  ;; Layer UZ_TEMP erstellen falls nicht vorhanden
  (if (not (tblsearch "LAYER" "UZ_TEMP"))
    (progn
      (command "._-LAYER" "_M" "UZ_TEMP" "_C" "5" "" "_L" "HIDDEN4" "" "")
      (princ "\nLayer UZ_TEMP wurde erstellt.")
    )
  )
  
  ;; Funktion: Prüft ob Linien parallel sind
  (defun parallel-p (ang1 ang2 tol)
    (or (< (abs (- ang1 ang2)) tol)
        (< (abs (- (abs (- ang1 ang2)) pi)) tol)
    )
  )
  
  ;; Funktion: Berechnet kürzesten Abstand zwischen zwei Liniensegmenten
  (defun line-distance (pt1s pt1e pt2s pt2e / vec perp dist1 dist2 dist3 dist4 min-dist)
    ;; Berechne Abstand von jedem Punkt zur anderen Linie
    (setq vec (mapcar '- pt1e pt1s))
    
    ;; Abstand von pt1s zu Linie 2
    (setq dist1 (distance pt1s (inters pt1s 
                                       (polar pt1s (+ (angle pt2s pt2e) (/ pi 2)) 1.0) 
                                       pt2s pt2e nil)))
    
    ;; Abstand von pt1e zu Linie 2
    (setq dist2 (distance pt1e (inters pt1e 
                                       (polar pt1e (+ (angle pt2s pt2e) (/ pi 2)) 1.0) 
                                       pt2s pt2e nil)))
    
    ;; Abstand von pt2s zu Linie 1
    (setq dist3 (distance pt2s (inters pt2s 
                                       (polar pt2s (+ (angle pt1s pt1e) (/ pi 2)) 1.0) 
                                       pt1s pt1e nil)))
    
    ;; Abstand von pt2e zu Linie 1
    (setq dist4 (distance pt2e (inters pt2e 
                                       (polar pt2e (+ (angle pt1s pt1e) (/ pi 2)) 1.0) 
                                       pt1s pt1e nil)))
    
    ;; Minimum der gültigen Abstände zurückgeben
    (setq min-dist nil)
    (if dist1 (setq min-dist dist1))
    (if (and dist2 (or (not min-dist) (< dist2 min-dist))) (setq min-dist dist2))
    (if (and dist3 (or (not min-dist) (< dist3 min-dist))) (setq min-dist dist3))
    (if (and dist4 (or (not min-dist) (< dist4 min-dist))) (setq min-dist dist4))
    
    min-dist
  )
  
  ;; Funktion: Prüft ob Layer ausgeschlossen ist
  (defun excluded-layer-p (layer-name)
    (or (= (strcase layer-name) "BETON")
        (= (strcase layer-name) "OBJEKT")
        (= (strcase layer-name) "ACHSEN"))
  )
  
  ;; Funktion: Extrahiert Segmente aus Polylinie
  (defun get-pline-segments (ent / entdata pt_list i seg_list pts pte)
    (setq entdata (entget ent))
    (setq pt_list '())
    
    ;; Punkte sammeln
    (foreach item entdata
      (if (= (car item) 10)
        (setq pt_list (append pt_list (list (cdr item))))
      )
    )
    
    ;; Wenn geschlossene Polylinie, ersten Punkt auch am Ende anfügen
    (if (= 1 (logand 1 (cdr (assoc 70 entdata))))
      (setq pt_list (append pt_list (list (car pt_list))))
    )
    
    ;; Segmente erstellen
    (setq seg_list '())
    (setq i 0)
    (while (< i (- (length pt_list) 1))
      (setq pts (nth i pt_list))
      (setq pte (nth (+ i 1) pt_list))
      (setq seg_list (append seg_list (list (list pts pte))))
      (setq i (1+ i))
    )
    seg_list
  )
  
  ;; Funktion: Extrahiert Segment aus Linie
  (defun get-line-segment (ent / entdata)
    (setq entdata (entget ent))
    (list (list (cdr (assoc 10 entdata)) (cdr (assoc 11 entdata))))
  )
  
  ;; Funktion: Holt alle Segmente eines Objekts
  (defun get-segments (ent / obj-type)
    (setq obj-type (cdr (assoc 0 (entget ent))))
    (cond
      ((= obj-type "LINE") (get-line-segment ent))
      ((or (= obj-type "LWPOLYLINE") (= obj-type "POLYLINE")) 
       (get-pline-segments ent))
      (T nil)
    )
  )
  
  ;; Funktion: Erstellt Rechteck aus zwei Segmenten
  (defun create-rectangle (pt1s pt1e pt2s pt2e / corner1 corner2 corner3 corner4 
                          dist13 dist14 rect)
    ;; Die beiden nächstliegenden Punkte finden
    (setq dist13 (distance pt1s pt2s))
    (setq dist14 (distance pt1s pt2e))
    
    (if (< dist13 dist14)
      (progn
        (setq corner1 pt1s)
        (setq corner2 pt2s)
        (setq corner3 pt2e)
        (setq corner4 pt1e)
      )
      (progn
        (setq corner1 pt1s)
        (setq corner2 pt2e)
        (setq corner3 pt2s)
        (setq corner4 pt1e)
      )
    )
    
    ;; Rechteck mit Polyline erstellen
    (command "._PLINE" corner1 corner2 corner3 corner4 "_C")
    (setq rect (entlast))
    
    ;; Eigenschaften setzen
    (command "._CHPROP" rect "" "_C" "VONLAYER" "_LT" "VONLAYER" "")
    
    ;; Auf Layer verschieben
    (command "._CHANGE" rect "" "_P" "_LA" "UZ_TEMP" "")
    
    rect
  )
  
  ;; Hauptprogramm
  (princ "\nWählen Sie die Objekte aus (Linien und Polylinien): ")
  (setq ss (ssget '((-4 . "<OR") (0 . "LINE") (0 . "LWPOLYLINE") (0 . "POLYLINE") (-4 . "OR>"))))
  
  (if ss
    (progn
      (setq rect_list '())
      (setq processed '())
      (setq i 0)
      
      (princ (strcat "\nVerarbeite " (itoa (sslength ss)) " Objekte..."))
      
      ;; Durch alle Objekte iterieren
      (repeat (sslength ss)
        (setq ent1 (ssname ss i))
        
        ;; Prüfen ob bereits verarbeitet
        (if (not (member ent1 processed))
          (progn
            (setq entdata1 (entget ent1))
            (setq layer1 (cdr (assoc 8 entdata1)))
            (setq seg1_list (get-segments ent1))
            
            ;; Nur wenn Layer erlaubt ist
            (if (and seg1_list (not (excluded-layer-p layer1)))
              (progn
                ;; Durch alle Segmente von Objekt 1
                (foreach seg1 seg1_list
                  (setq pt1s (car seg1))
                  (setq pt1e (cadr seg1))
                  (setq len1 (distance pt1s pt1e))
                  (setq ang1 (angle pt1s pt1e))
                  
                  ;; Prüfen ob Mindestlänge erreicht
                  (if (>= len1 0.55)
                    (progn
                      ;; Mit allen anderen Objekten vergleichen
                      (setq j (+ i 1))  ;; Nur nachfolgende Objekte prüfen
                      (setq found nil)
                      (while (and (< j (sslength ss)) (not found))
                        (setq ent2 (ssname ss j))
                        (if (not (member ent2 processed))
                          (progn
                            (setq entdata2 (entget ent2))
                            (setq layer2 (cdr (assoc 8 entdata2)))
                            (setq seg2_list (get-segments ent2))
                            
                            ;; Durch alle Segmente von Objekt 2
                            (if (and seg2_list (not (excluded-layer-p layer2)))
                              (foreach seg2 seg2_list
                                (if (not found)
                                  (progn
                                    (setq pt2s (car seg2))
                                    (setq pt2e (cadr seg2))
                                    (setq len2 (distance pt2s pt2e))
                                    (setq ang2 (angle pt2s pt2e))
                                    
                                    ;; Debug-Ausgabe
                                    (princ (strcat "\nPrüfe: Len1=" (rtos len1 2 3) 
                                                   " Len2=" (rtos len2 2 3)
                                                   " Ang1=" (rtos ang1 2 3)
                                                   " Ang2=" (rtos ang2 2 3)))
                                    
                                    ;; Alle Bedingungen prüfen
                                    (if (and (parallel-p ang1 ang2 0.02)  ;; Toleranz erhöht
                                             (< (abs (- len1 len2)) 0.05)  ;; Längentoleranz erhöht
                                             (>= len2 0.55))
                                      (progn
                                        (setq dist (line-distance pt1s pt1e pt2s pt2e))
                                        (princ (strcat " Dist=" (if dist (rtos dist 2 3) "nil")))
                                        
                                        ;; Abstand prüfen
                                        (if (and dist (> dist 0.001) (<= dist 0.50))
                                          (progn
                                            ;; Rechteck erstellen
                                            (setq rect (create-rectangle pt1s pt1e pt2s pt2e))
                                            
                                            ;; Originallinien löschen
                                            (entdel ent1)
                                            (entdel ent2)
                                            
                                            ;; Als verarbeitet markieren
                                            (setq processed (append processed (list ent1 ent2)))
                                            (setq rect_list (cons rect rect_list))
                                            (setq found T)
                                            
                                            (princ "\n>>> Linienpaar gefunden und ersetzt! <<<")
                                          )
                                          (princ " - Abstand nicht OK")
                                        )
                                      )
                                      (princ " - Nicht parallel/gleich lang")
                                    )
                                  )
                                )
                              )
                            )
                          )
                        )
                        (setq j (1+ j))
                      )
                    )
                  )
                )
              )
            )
          )
        )
        (setq i (1+ i))
      )
      
      (princ (strcat "\n\n" (itoa (length rect_list)) " Rechteck(e) erstellt."))
    )
    (princ "\nKeine Auswahl getroffen.")
  )
  
  (princ)
)

(princ "\nUnterzug-Programm geladen (Linien & Polylinien). Tippen Sie 'uz' zum Starten.")
(princ)
