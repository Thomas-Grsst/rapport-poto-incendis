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

echo   [1/3] Recuperation de la derniere version...
echo.
git pull
if errorlevel 1 goto erreur

echo.
echo   [2/3] Compilation de la nouvelle version...
echo   (c'est la partie longue, laissez faire)
echo.
REM  `flutter install` ne compile pas : il installe l'APK deja present sur le
REM  disque. Sans cette etape, le `git pull` ci-dessus ne servait a rien et on
REM  reinstallait indefiniment la version precedente.
REM
REM  `call` est indispensable : sous Windows `flutter` est lui-meme un .bat,
REM  et un .bat qui en appelle un autre sans `call` lui passe la main sans
REM  jamais la reprendre. La suite du script n'etait jamais executee, et la
REM  fenetre se fermait sans rien dire.
call flutter build apk --release
if errorlevel 1 goto erreur

echo.
echo   [3/3] Installation sur le telephone...
echo.
call flutter install --release
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
