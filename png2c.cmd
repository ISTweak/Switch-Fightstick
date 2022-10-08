@echo off

powershell -NoProfile -ExecutionPolicy Unrestricted %~dp0\png2c.ps1 %1

make clean
make
pause