@echo off
REM ---------------------------------------------------------------
REM  Installe la derniere version de l'application sur le telephone.
REM
REM  Il n'y a rien a taper : double-cliquez sur ce fichier.
REM  Le telephone doit etre branche en USB, debogage USB active.
REM ---------------------------------------------------------------

setlocal
cd /d "%~dp0"
title Installation - Poteaux incendie

echo.
echo   ============================================
echo     Poteaux incendie
echo     Installation sur le telephone
echo   ============================================
echo.

echo   [1/4] Recuperation de la derniere version...
echo.
git pull
if errorlevel 1 goto erreur

echo.
echo   [2/4] Recherche du telephone...

REM  Sans telephone branche, `flutter install` prend le premier appareil qu'il
REM  trouve - le navigateur Chrome, par exemple - et annonce une installation
REM  reussie qui n'a touche aucun telephone. On cherche donc nous-memes un
REM  appareil Android, et on s'arrete s'il n'y en a pas.
REM
REM  La recherche passe par PowerShell : `flutter devices --machine` repond en
REM  JSON, que le traitement par lots ne sait pas lire. La sortie est
REM  rassemblee en une seule chaine avant d'etre lue : ConvertFrom-Json, sous
REM  PowerShell 5, echoue sur une entree donnee ligne par ligne. Et on part du
REM  premier crochet, pour ignorer un eventuel avertissement en tete.
set "TELEPHONE="
for /f "usebackq tokens=* delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; $sortie = (flutter devices --machine ^| Out-String); $debut = $sortie.IndexOf('['); if ($debut -ge 0) { ($sortie.Substring($debut) ^| ConvertFrom-Json ^| Where-Object { $_.targetPlatform -like 'android*' } ^| Select-Object -First 1).id }"`) do set "TELEPHONE=%%i"

if not defined TELEPHONE goto pas_de_telephone
echo   Telephone trouve : %TELEPHONE%

echo.
echo   [3/4] Compilation de la nouvelle version...
echo   (c'est la partie longue, laissez faire)
echo.
REM  `flutter install` ne compile pas : il installe l'APK deja present sur le
REM  disque. Sans cette etape, le `git pull` ci-dessus ne servirait a rien et on
REM  reinstallerait indefiniment la version precedente.
REM
REM  `call` est indispensable : sous Windows `flutter` est lui-meme un .bat, et
REM  un .bat qui en appelle un autre sans `call` lui passe la main sans jamais
REM  la reprendre. La suite du script n'etait jamais executee, et la fenetre se
REM  fermait sans rien dire.
call flutter build apk --release
if errorlevel 1 goto erreur

echo.
echo   [4/4] Installation sur le telephone...
echo.
call flutter install --release -d %TELEPHONE%
if errorlevel 1 goto erreur

echo.
echo   ============================================
echo     Termine. L'application est a jour
echo     sur le telephone.
echo     Vous pouvez fermer cette fenetre.
echo   ============================================
echo.
pause
exit /b 0

:pas_de_telephone
echo.
echo   ============================================
echo     Aucun telephone detecte.
echo   ============================================
echo.
echo   Voici ce que Flutter voit, pour comparaison :
echo.
call flutter devices
echo.
echo   Rien n'a ete installe. A verifier, dans l'ordre :
echo.
echo     1. Le telephone est bien branche en USB.
echo     2. Le cable transfere les donnees (certains ne
echo        font que recharger - essayez-en un autre).
echo     3. Le debogage USB est active sur le telephone :
echo        Parametres / A propos / appuyer 7 fois sur
echo        "Numero de build", puis Parametres / Systeme /
echo        Options pour les developpeurs / Debogage USB.
echo     4. Le telephone affiche une demande d'autorisation
echo        a accepter - regardez son ecran, il est peut-etre
echo        en train de l'attendre.
echo.
pause
exit /b 1

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
