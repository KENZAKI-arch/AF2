@echo off
:loop
timeout /t 10 /nobreak >nul
cd "C:\Users\luigi\Downloads\AutofishSYSTEMGIT\AF2"
git add .
git commit -m "auto update" >nul 2>&1
git push >nul 2>&1
goto loop