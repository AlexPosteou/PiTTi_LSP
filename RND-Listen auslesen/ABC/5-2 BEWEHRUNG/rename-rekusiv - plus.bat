::Falls Sie zusätzliche Anforderungen haben, wie zum Beispiel das Einfügen einer Zeichenkette
::in die Dateien nach der Umbenennung oder das Zusammenführen der Dateien, können wir das 
::Skript weiter anpassen. 

::Hier ist eine erweiterte Version, die nach dem Umbenennen der Dateien 
::eine spezifische Zeichenkette in die zweite Zeile jeder RND.CSV einfügt.


@echo off
setlocal enabledelayedexpansion

REM Basisverzeichnis auf das Verzeichnis setzen, in dem das Skript ausgeführt wird
set "BASE_DIR=%~dp0"

echo Starte das Umbenennen von RND*.CSV Dateien in allen Unterverzeichnissen von "%BASE_DIR%"

REM Iteriere rekursiv durch alle RND*.CSV Dateien
for /r "%BASE_DIR%" %%F in (RND*.CSV) do (
    REM Überprüfe, ob die Datei tatsächlich existiert
    if exist "%%F" (
        REM Extrahiere das Verzeichnis der aktuellen Datei
        set "FILE_DIR=%%~dpF"
        
        REM Definiere den neuen Dateinamen
        set "NEW_NAME=RND.CSV"
        
        REM Überprüfe, ob bereits eine RND.CSV im Zielverzeichnis existiert
        if exist "!FILE_DIR!!NEW_NAME!" (
            echo WARNUNG: "!FILE_DIR!!NEW_NAME!" existiert bereits. Überspringe "%%F".
        ) else (
            echo Benenne "%%F" zu "!NEW_NAME!" um...
            ren "%%F" "!NEW_NAME!"
            if errorlevel 1 (
                echo FEHLER: Konnte "%%F" nicht umbenennen.
            ) else (
                echo Erfolgreich umbenannt.
                
                REM Füge die spezifische Zeichenkette in die zweite Zeile ein
                set "TARGET_FILE=!FILE_DIR!!NEW_NAME!"
                set "FILENAME_NO_EXT=RND" REM Da der neue Name immer RND.CSV ist
                
                REM Erstelle eine temporäre Datei
                set "TEMP_FILE=!FILE_DIR!!NEW_NAME!.tmp"
                
                REM Zähler initialisieren
                set "LINE_COUNT=0"
                
                REM Verarbeite die Datei
                > "!TEMP_FILE!" (
                    for /f "usebackq delims=" %%A in ("!TARGET_FILE!") do (
                        set /a LINE_COUNT+=1
                        if !LINE_COUNT! equ 1 (
                            echo %%A
                            echo !FILENAME_NO_EXT!;;;;;
                        ) else (
                            echo %%A
                        )
                    )
                )
                
                REM Ersetze die Originaldatei mit der temporären Datei
                move /y "!TEMP_FILE!" "!TARGET_FILE!" >nul
                if errorlevel 1 (
                    echo FEHLER: Konnte "!TARGET_FILE!" nicht aktualisieren.
                ) else (
                    echo Erfolgreich die Zeichenkette eingefügt.
                )
            )
        )
    )
)

echo.
echo Alle relevanten Dateien wurden umbenannt und bearbeitet.
pause
endlocal

