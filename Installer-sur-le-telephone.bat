@echo off
REM ---------------------------------------------------------------
REM  Installe la derniere version de l'application sur le telephone.
REM
REM  Il n'y a rien a taper : double-cliquez sur ce fichier.
REM  Le telephone doit etre branche en USB, debogage USB active.
REM ---------------------------------------------------------------

cd /d "%~dp0"
title Installation - Poteaux incendie

echo.
echo   ============================================
echo     Poteaux incendie
echo     Installation sur le telephone
echo   ============================================
echo.
echo   Le telephone doit etre branche en USB.
echo.

echo   [1/2] Recuperation de la derniere version...
echo.
git pull
if errorlevel 1 goto erreur

echo.
echo   [2/2] Compilation et installation...
echo   (c'est la partie longue, laissez faire)
echo.
flutter install --release
if errorlevel 1 goto erreur

echo.
echo   ============================================
echo     Termine. L'application est a jour.
echo     Vous pouvez fermer cette fenetre.
echo   ============================================
echo.
pause
exit /b 0

:erreur
echo.
echo   ============================================
echo     Quelque chose n'a pas marche.
echo   ============================================
echo.
echo   Selectionnez tout le texte de cette fenetre,
echo   copiez-le (Ctrl+C) et envoyez-le a Claude.
echo.
pause
exit /b 1
