@echo off
REM ---------------------------------------------------------------
REM  Fabrique un APK a envoyer a quelqu'un, puis ouvre le dossier.
REM
REM  Il n'y a rien a taper : double-cliquez sur ce fichier.
REM  Aucun telephone n'est necessaire.
REM ---------------------------------------------------------------

setlocal
cd /d "%~dp0"
title APK a envoyer - Poteaux incendie

echo.
echo   ============================================
echo     Poteaux incendie
echo     Fabrication d'un APK a envoyer
echo   ============================================
echo.

echo   [1/2] Recuperation de la derniere version...
echo.
REM  Flutter reecrit pubspec.lock a chaque compilation : on le remet comme
REM  dans le depot, sinon git refuse la mise a jour.
git checkout -- pubspec.lock 2>nul
git pull
if errorlevel 1 goto erreur

echo.
echo   [2/2] Compilation...
echo   (c'est la partie longue, laissez faire)
echo.
REM  `--split-per-abi` fabrique un APK par architecture de processeur au lieu
REM  d'un seul qui les embarque toutes. Chacun pese environ un tiers de
REM  l'APK universel : c'est la difference entre un fichier qui passe par
REM  courriel et un qui ne passe pas.
REM
REM  `call` est indispensable : sous Windows `flutter` est lui-meme un .bat, et
REM  un .bat qui en appelle un autre sans `call` lui passe la main sans jamais
REM  la reprendre.
call flutter build apk --release --split-per-abi
if errorlevel 1 goto erreur

echo.
echo   ============================================
echo     Termine.
echo   ============================================
echo.
echo   Le dossier va s'ouvrir. Le fichier a envoyer est :
echo.
echo       app-arm64-v8a-release.apk
echo.
echo   C'est celui de tous les telephones Android recents.
echo   Les deux autres ne servent qu'aux appareils anciens
echo   ou aux emulateurs.
echo.
echo   ATTENTION : si le telephone qui le recoit a deja une
echo   version installee depuis le cable, Android refusera
echo   de l'installer par-dessus. Il faut desinstaller
echo   l'application d'abord.
echo.
start "" "%~dp0build\app\outputs\flutter-apk"
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
