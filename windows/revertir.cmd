@echo off
rem Doble clic para deshacer lo que hizo instalar.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0revertir.ps1" %*
