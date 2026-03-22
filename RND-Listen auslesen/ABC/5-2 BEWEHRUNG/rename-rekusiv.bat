@echo off
setlocal enabledelayedexpansion

REM Basisverzeichnis auf das Verzeichnis setzen, in dem das Skript ausgeführt wird
set "BASE_DIR=%~dp0"

echo Starte das Umbenennen von RND*.CSV Dateien in allen Unterverzeichnissen von "%BASE_DIR%"

REM Iteriere rekursiv durch alle RND*.CSV Dateien
for /r "%BASE_DIR%" %%F in (RND*.CSV) do (
    REM Überprüfe, ob die Datei tatsächlich existiert (sicherstellen, dass keine Verzeichnisse matchen)
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
            )
        )
    )
)

echo.
echo Alle relevanten Dateien wurden verarbeitet.
pause
endlocal
