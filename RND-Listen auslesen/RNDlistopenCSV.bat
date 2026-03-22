::RNDlistopenCSV.bat    erstellt 2024-11-08   P. Brau
::
::Erweitert 2025-09-26 um das Auslesen von APS, HBT und MAT

::Zweck: Aus einem Projekt sollen die gesamten Stahlmassen aus den Bewehrungsplänen herausgezogen werden
::======


::Vorbereitung:  Die Dateien werden in einen gemeinsamen Ordner C:\SWAP\RND kopiert, Unterordner sind nicht möglich!
::=============

Wenn die DWGs bereits ausgelesen sind, dann die Sprungbefehl GOTO PART2 aktivieren
::=============


::Ablauf der Programme:
::=====================

:: 1.  "RNDlistopenCSV.bat" tauscht die "acaddoc.LSP" gegen eine modifizierte Version "acaddoc.RND" aus
:: 2.  Startet den Explorer mit C:\SWAP\RND  (zur besseren Übersicht)
:: 3.  Führt die Datei "RNDlistopenDWGs.scr" aus
:: 4.  "RNDlistopenDWGs.scr" startet den Befehl "openclose" aus der "RNDlistopenDWGs.lsp"
:: 5.1 "RNDlistopenDWGs.lsp" öffnet jede DWG des Verzeichnisses ...
:: 6.1 ... und führt damit die Datei "acaddoc.LSP" aus (= AutoCAD-Automatismus für jede neu geladene Datei)
:: 6.2 "acaddoc.LSP" läd "RNDlist.LSP" und führt deren Befehl "ExtractAttributes" aus (bei jeder neu geöffneten Datei)
:: 6.3 "ExtractAttributes" liest aus jeder DWG die Block-Attribute RND_LIS2 (enthalten die Stahlinformationen für jede RND-Position)
:: 6.4 Sammelt und schreibt die Werte für jede DWG in die Datei "PLANNAME.RND"
:: 5.2 Schließt jede DWG im Anschluß daran wieder.
:: 7.  Öffnet die "RNDlistopenDWGs.dwg", welche diese Programmbeschreibung enthält und sonst keine Funktion erfüllt.
:: 8.  AutoCAD wird geschlossen
:: 9.  "acaddoc.RND" wird wieder durch die normale "acaddoc.LSP" ersetzt
:: 10. Alle Einzeldateien "DateiName.RND" werden in eine Sammeldatei kopiert und dabei in ein sauberes CSV-Format konvertiert: "RND.CSV"

:: Der Vorgang ist für das aktuelle Verzeichnis abgeschlossen.

:: 11. Optional: Werden mehrere Ordner (z.B. sortiert nach Bauteilen)) bearbeitet (jeder für sich! sh. Bsp-Ordner ABC), kann
::     die Datei "CSV-Gesamt.bat" die einzelnen RND.CSV-Dateien entsprechend ihres Ordners umbenennen z.B. in RND_Wände.CSV
::     Zudem fügt die "CSV-Gesamt.bat" alle CSV-Dateien in eine "RND_GESAMT.CSV"

::     Wichtig vor Ausführung der "CSV-Gesamt.bat" muss der Pfad für zu den Bewehrungsplänen in der BAT-Datei angepasst werden!

:: 12. Was dann noch notwendig ist: Die CSV-Datei in eine Excel-Datei zu wandeln und auszuwerten. (Die RND_Gesamt.XLSM enthält ein Makro,
::     das für solche Aufgaben ausgebaut werden könnte.)

::  Achtung: Bei der Erstellung wurde die "RNDlistopenDWGs.dwg" mit aufgelistet und summiert das ist wohl noch ein Fehler!!!
::===========



@echo off
color 1F

::GOTO PART2

::PART 1
::

copy C:\BieberCAD\lsp_und_dcl\acaddoc.RND C:\BieberCAD\lsp_und_dcl\acaddoc.LSP


cls
echo.
echo.
echo.
echo Es wird AutoCAD geöffnet,
echo.
echo und alle Zeichnungen ausgelesen ...
echo.
echo Bitte etwas Geduld, das kann dauern ...
echo.
echo.
echo.
echo.
echo                    Wenn AutoCAD fertig, dann bitte AutoCAD schliessen !!!
echo.
echo.
echo.
echo                                       ... und auch dann noch etwas Geduld                                                  
echo.


set "acad_path=C:\Program Files\Autodesk\AutoCAD 2019\acad.exe"
::set "script_path=C:\BieberCAD\lsp_und_dcl\RNDlist.scr"
set "script_path=C:\BieberCAD\lsp_und_dcl\RNDlistopenDWGs.scr"
set "dwg_folder=C:\SWAP\RND"

start "RND" "C:\SWAP\RND\"

::for %%f in ("%dwg_folder%\*.dwg") do (
::    "%acad_path%" /nologo "%%f" /b "%script_path%"
::)


"%acad_path%" /b "%script_path%" C:\BieberCAD\lsp_und_dcl\RNDlistopenDWGs.dwg


cls
echo.
echo.
echo.
echo Wurden alle Zeichnungen ausgelesen ?
echo.
echo.
::echo Dann weiter mit beliebiger Taste ...
echo.
echo.
echo.
::pause > nul
taskkill /IM "acad.exe" /F






:part2


::PART 2
::
::Ab hier wird die RND.csv mit den gesammelten Stahlpositionen erstellt

@echo off
color AC

copy C:\BieberCAD\lsp_und_dcl\acaddoc.ORG C:\BieberCAD\lsp_und_dcl\acaddoc.LSP

del C:\SWAP\RND\RNDlistopenDWGs.rnd
del C:\SWAP\RND\RNDlistopenDWGs.aps
del C:\SWAP\RND\RNDlistopenDWGs.hbt
del C:\SWAP\RND\RNDlistopenDWGs.mat


================================================
:RND
================================================

setlocal enabledelayedexpansion


set "sourceDir=C:\SWAP\RND"
set "filePattern=*.rnd"
set "outputFile=C:\SWAP\RND\RND.csv"
set "tempFile=C:\SWAP\RND\RND_temp.txt"
set "dumyFile=C:\SWAP\RND\RNDlistopenDWGs.rnd"

if not exist "%sourceDir%" (
    echo Das Verzeichnis %sourceDir% existiert nicht.
    md %sourceDir%
    echo Das Verzeichnis %sourceDir% wurde angelegt.
)


cls
echo.
echo.
echo.
echo Liegen alle RND-Dateien im Verzeichnis %sourceDir% ?
echo.
echo.
::echo Dann weiter mit beliebiger Taste ...
echo.
echo.
echo.
::pause > nul

if exist "%outputFile%" (
    del "%outputFile%"
)

for %%f in ("%sourceDir%\%filePattern%") do (
    type "%%f" >> "%outputFile%"
)

if not exist "%outputFile%" (
    echo Keine Dateien des Typs %filePattern% gefunden.
    goto APS
)

(
    for /f "delims=" %%i in (%outputFile%) do (
        set "line=%%i"
        set "line=!line:RND_LIS2 - POS1:=!"
        set "line=!line:RND_LIS2 - STK1:=!"
        set "line=!line:RND_LIS2 - DS1:=!"
        set "line=!line:RND_LIS2 - LANG1:=!"
        set "line=!line:RND_LIS2 - GEW:=!"
        set "line=!line: =!"
	set "line=!line:.=,!"
        echo !line!
    )
) > "%tempFile%"

(
    echo POS;STÜCK;DURCHM;LÄNGE;GEWICHT;
    type "%tempFile%"
) > "%outputFile%"

del "%tempFile%"
del "%dumyFile%"

echo Die Dateien wurden erfolgreich kombiniert, die Zeichenketten wurden ersetzt und die neue Zeile wurde hinzugefügt.

start "" "%outputFile%"
endlocal


::pause



================================================
:APS
================================================

setlocal enabledelayedexpansion


set "sourceDir=C:\SWAP\RND"
set "filePattern=*.aps"
set "outputFile=C:\SWAP\RND\APS.csv"
set "tempFile=C:\SWAP\RND\APS_temp.txt"
set "dumyFile=C:\SWAP\RND\RNDlistopenDWGs.aps"


cls
echo.
echo.
echo.
echo Liegen alle APS-Dateien im Verzeichnis %sourceDir% ?
echo.
echo.
::echo Dann weiter mit beliebiger Taste ...
echo.
echo.
echo.
::pause > nul

if exist "%outputFile%" (
     del "%outputFile%"
)

for %%f in ("%sourceDir%\%filePattern%") do (
    type "%%f" >> "%outputFile%"
)

if not exist "%outputFile%" (
    echo Keine Dateien des Typs %filePattern% gefunden.
    goto HBT
)

(
    for /f "delims=" %%i in (%outputFile%) do (
        set "line=%%i"
        set "line=!line:APS_AUSZ - POSA:=!"
        set "line=!line:APS_AUSZ - STKA:=!"
        set "line=!line:APS_AUSZ - ARTA:=!"
        set "line=!line:APS_AUSZ - TEXTA:=!"
        set "line=!line: =!"
	set "line=!line:.=,!"
        echo !line!
    )
) > "%tempFile%"

(
    echo POS;STÜCK;APSTA-TYP;TEXT;GEWICHT;
    type "%tempFile%"
) > "%outputFile%"

del "%tempFile%"
del "%dumyFile%"

echo Die Dateien wurden erfolgreich kombiniert, die Zeichenketten wurden ersetzt und die neue Zeile wurde hinzugefügt.


type  "C:\BieberCAD\lsp_und_dcl\GEWICHT-APS.CSV" >>"%outputFile%"
start "" "%outputFile%"
endlocal



::pause



================================================
:HBT
================================================

setlocal enabledelayedexpansion


set "sourceDir=C:\SWAP\RND"
set "filePattern=*.hbt"
set "outputFile=C:\SWAP\RND\HBT.csv"
set "tempFile=C:\SWAP\RND\HBT_temp.txt"
set "dumyFile=C:\SWAP\RND\RNDlistopenDWGs.hbt"

if not exist "%sourceDir%" (
    echo Das Verzeichnis %sourceDir% existiert nicht.
    md %sourceDir%
    echo Das Verzeichnis %sourceDir% wurde angelegt.
)


cls
echo.
echo.
echo.
echo Liegen alle HBT-Dateien im Verzeichnis %sourceDir% ?
echo.
echo.
::echo Dann weiter mit beliebiger Taste ...
echo.
echo.
echo.
::pause > nul

if exist "%outputFile%" (
    del "%outputFile%"
)

for %%f in ("%sourceDir%\%filePattern%") do (
    type "%%f" >> "%outputFile%"
)

if not exist "%outputFile%" (
    echo Keine Dateien des Typs %filePattern% gefunden.
    goto MAT
)

(
    for /f "delims=" %%i in (%outputFile%) do (
        set "line=%%i"
        set "line=!line:HBT_LEI - POSH:=!"
        set "line=!line:HBT_LEI - STKH:=!"
        set "line=!line:HBT_LEI - ARTH:=!"
        set "line=!line:HBT_LEI - TEXTH:=!"
        set "line=!line: =!"
	set "line=!line:.=,!"
        echo !line!
    )
) > "%tempFile%"

(
    echo POS;STÜCK;HBT-TYP;TEXT;GEWICHT;
    type "%tempFile%"
) > "%outputFile%"

del "%tempFile%"
del "%dumyFile%"

echo Die Dateien wurden erfolgreich kombiniert, die Zeichenketten wurden ersetzt und die neue Zeile wurde hinzugefügt.

type  "C:\BieberCAD\lsp_und_dcl\GEWICHT-HBT.CSV" >>"%outputFile%"
start "" "%outputFile%"
endlocal



::pause



================================================
:MAT
================================================

setlocal enabledelayedexpansion


set "sourceDir=C:\SWAP\RND"
set "filePattern=*.mat"
set "outputFile=C:\SWAP\RND\MAT.csv"
set "tempFile=C:\SWAP\RND\MAT_temp.txt"
set "dumyFile=C:\SWAP\RND\RNDlistopenDWGs.mat"

if not exist "%sourceDir%" (
    echo Das Verzeichnis %sourceDir% existiert nicht.
    md %sourceDir%
    echo Das Verzeichnis %sourceDir% wurde angelegt.
)


cls
echo.
echo.
echo.
echo Liegen alle MAT-Dateien im Verzeichnis %sourceDir% ?
echo.
echo.
::echo Dann weiter mit beliebiger Taste ...
echo.
echo.
echo.
::pause > nul

if exist "%outputFile%" (
    del "%outputFile%"
)

for %%f in ("%sourceDir%\%filePattern%") do (
    type "%%f" >> "%outputFile%"
)

if not exist "%outputFile%" (
    echo Keine Dateien des Typs %filePattern% gefunden.
    goto MAT
)

(
    for /f "delims=" %%i in (%outputFile%) do (
        set "line=%%i"
        set "line=!line:MAT_AUSZ - POSM:=!"
        set "line=!line:MAT_AUSZ - STKM:=!"
        set "line=!line:MAT_AUSZ - TYP:=!"
        set "line=!line:MAT_AUSZ - WO:=!"
        set "line=!line:MAT_AUSZ - LM:=!"
        set "line=!line:MAT_AUSZ - BM:=!"
        set "line=!line:MAT_AUSZ - WIEOFTM:=!"
        set "line=!line: =!"
	set "line=!line:.=,!"
        echo !line!
    )
) > "%tempFile%"

(
    echo POS;STÜCK;MAT-TYP;WO;LÄNGE;BREITE;WIEOFT;GEWICHT;
    type "%tempFile%"
) > "%outputFile%"

del "%tempFile%"
del "%dumyFile%"

echo Die Dateien wurden erfolgreich kombiniert, die Zeichenketten wurden ersetzt und die neue Zeile wurde hinzugefügt.

type  "C:\BieberCAD\lsp_und_dcl\GEWICHT-MAT.CSV" >>"%outputFile%"
start "" "%outputFile%"
endlocal



::pause
goto ende
del C:\SWAP\RND\APS_temp.txt
del C:\SWAP\RND\HBT_temp.txt
del C:\SWAP\RND\MAT_temp.txt
del C:\SWAP\RND\RND_temp.txt




:ende