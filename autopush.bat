@echo off
:loop
timeout /t 10 /nobreak >nul
cd "C:\Users\luigi\Downloads\AutofishSYSTEMGIT\AF2"
git add .
git commit -m "auto update"
git push
goto loop