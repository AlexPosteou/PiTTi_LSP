@echo off
setlocal enabledelayedexpansion

REM Setze das aktuelle Verzeichnis als Basis
set "BASE_DIR=C:\Users\BRAUP\Desktop\ABC\5-2 BEWEHRUNG"

REM Wechsle in das Basisverzeichnis
cd /d "%BASE_DIR%"

REM Lösche vorherige RND_GESAMT.CSV, falls vorhanden
if exist "RND_GESAMT.CSV" del /f /q "RND_GESAMT.CSV"


REM Durchlaufe alle Unterordner
for /d %%F in (*) do (
    REM Überprüfe, ob RND.CSV im Unterordner existiert
    if exist "%%F\RND.CSV" (
        REM Benenne die Datei um
        set "FOLDER_NAME=%%~nF"
        set "NEW_NAME=RND_!FOLDER_NAME!.CSV"
        ren "%%F\RND.CSV" "!NEW_NAME!"
        
        REM Kopiere die umbenannte Datei in das Basisverzeichnis
        copy /y "%%F\!NEW_NAME!" "%BASE_DIR%"
    )
)

REM Füge die spezifische Zeichenkette in die zweite Zeile jeder RND_*.CSV ein
for %%G in (RND_*.CSV) do (
    set "FILENAME_NO_EXT=%%~nG"
    set "INSERT_LINE=!FILENAME_NO_EXT!;;;;;"
    
    REM Erstelle eine temporäre Datei
    set "TEMP_FILE=%%G.tmp"
    
    REM Initialisiere eine Zählvariable
    set "LINE_COUNT=0"
    
    REM Schreibe die ersten Zeilen in die temporäre Datei
    > "!TEMP_FILE!" (
        for /f "usebackq delims=" %%A in ("%%G") do (
            set /a LINE_COUNT+=1
            if !LINE_COUNT! equ 1 (
                echo %%A
                echo !INSERT_LINE!
            ) else (
                echo %%A
            )
        )
    )
    
    REM Ersetze die Originaldatei mit der temporären Datei
    move /y "!TEMP_FILE!" "%%G" >nul
)

REM Füge alle RND_*.CSV Dateien in RND_GESAMT.CSV zusammen
REM Überspringe die Kopfzeile (angenommen, jede CSV hat eine Kopfzeile)
set "FIRST_FILE=1"
for %%G in (RND_*.CSV) do (
    if "!FIRST_FILE!"=="1" (
        copy /y "%%G" "RND_GESAMT.CSV" >nul
        set "FIRST_FILE=0"
    ) else (
        more +1 "%%G" >> "RND_GESAMT.CSV"
    )
)

echo Verarbeitung abgeschlossen. Die Datei RND_GESAMT.CSV wurde erstellt.
pause

:ende