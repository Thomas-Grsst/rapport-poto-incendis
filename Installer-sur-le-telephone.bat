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

REM  Sans telephone, `flutter install` prend le premier appareil venu - le
REM  navigateur Chrome - et annonce une installation reussie qui n'a touche
REM  aucun telephone. On cherche donc nous-memes, et on s'arrete sinon.
REM
REM  La recherche passe par adb plutot que par `flutter devices` : c'est lui
REM  qui fait autorite pour Android, sa sortie est faite de colonnes qu'un
REM  fichier de commandes sait lire, et il distingue le telephone branche mais
REM  non autorise - le cas le plus frequent sur un appareil neuf.
set "ADB="
where adb >nul 2>&1 && set "ADB=adb"
if not defined ADB if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not defined ADB if exist "%ANDROID_HOME%\platform-tools\adb.exe" set "ADB=%ANDROID_HOME%\platform-tools\adb.exe"
if not defined ADB if exist "%ANDROID_SDK_ROOT%\platform-tools\adb.exe" set "ADB=%ANDROID_SDK_ROOT%\platform-tools\adb.exe"
if not defined ADB goto pas_d_adb

set "APPAREILS=%TEMP%\appareils-android.txt"
"%ADB%" devices > "%APPAREILS%" 2>&1

REM  La premiere ligne est un en-tete, d'ou le skip. Chaque ligne suivante
REM  porte l'identifiant puis l'etat : "device" pour un telephone pret.
set "TELEPHONE="
for /f "usebackq skip=1 tokens=1,2" %%a in ("%APPAREILS%") do (
  if "%%b"=="device" if not defined TELEPHONE set "TELEPHONE=%%a"
)

REM  Compare a une chaine vide, et non `if defined` : la boucle peut laisser la
REM  variable definie mais vide, et `-d` sans valeur fait echouer flutter sur
REM  "Missing argument".
if "%TELEPHONE%"=="" goto pas_de_telephone
echo   Telephone trouve : %TELEPHONE%

REM  Le processeur du telephone decide quel APK lui convient. On lit la reponse
REM  avec findstr plutot que de composer un nom de fichier a partir d'elle :
REM  adb termine ses lignes par un retour chariot que le nom traine ensuite.
set "APK="
"%ADB%" -s %TELEPHONE% shell getprop ro.product.cpu.abi > "%TEMP%\abi-android.txt" 2>&1
findstr /C:"arm64-v8a" "%TEMP%\abi-android.txt" >nul && set "APK=app-arm64-v8a-release.apk"
if not defined APK findstr /C:"armeabi-v7a" "%TEMP%\abi-android.txt" >nul && set "APK=app-armeabi-v7a-release.apk"
if not defined APK findstr /C:"x86_64" "%TEMP%\abi-android.txt" >nul && set "APK=app-x86_64-release.apk"
if not defined APK set "APK=app-arm64-v8a-release.apk"

echo.
echo   [3/4] Compilation de la nouvelle version...
echo   (c'est la partie longue, laissez faire)
echo.
REM  `--split-per-abi` fabrique un APK par processeur. C'est le meme reglage
REM  que le fichier qui prepare un APK a envoyer, et c'est voulu : Android
REM  numerote ces APK differemment de l'APK universel, et refuse d'installer
REM  par-dessus une version qu'il juge plus ancienne. Les deux fichiers
REM  produisent donc la meme sorte d'APK, pour que l'un puisse toujours
REM  remplacer l'autre sans desinstaller.
REM
REM  `call` est indispensable : sous Windows `flutter` est lui-meme un .bat, et
REM  un .bat qui en appelle un autre sans `call` lui passe la main sans jamais
REM  la reprendre.
call flutter build apk --release --split-per-abi
if errorlevel 1 goto erreur

echo.
echo   [4/4] Installation sur le telephone...
echo.
REM  `adb install -r` remplace l'application en place, en gardant ses donnees.
set "COMPTE_RENDU=%TEMP%\installation-android.txt"
"%ADB%" -s %TELEPHONE% install -r "build\app\outputs\flutter-apk\%APK%" > "%COMPTE_RENDU%" 2>&1
type "%COMPTE_RENDU%"
findstr /C:"Success" "%COMPTE_RENDU%" >nul || goto echec_installation

echo.
echo   ============================================
echo     Termine. L'application est a jour
echo     sur le telephone.
echo     Vous pouvez fermer cette fenetre.
echo   ============================================
echo.
pause
exit /b 0

:echec_installation
findstr /C:"VERSION_DOWNGRADE" "%COMPTE_RENDU%" >nul && goto version_plus_ancienne

echo.
echo   ============================================
echo     L'installation a echoue.
echo   ============================================
echo.
echo   Le message d'adb est affiche juste au-dessus.
echo   Copiez-le et envoyez-le a Claude.
echo.
pause
exit /b 1

:version_plus_ancienne
echo.
echo   ============================================
echo     Une version plus recente est installee.
echo   ============================================
echo.
echo   Android refuse de revenir en arriere. Desinstallez
echo   l'application du telephone, puis relancez ce fichier :
echo   ce sera la derniere fois, les versions suivantes
echo   s'installeront par-dessus.
echo.
pause
exit /b 1

:pas_de_telephone
findstr /C:"unauthorized" "%APPAREILS%" >nul && goto non_autorise
findstr /C:"offline" "%APPAREILS%" >nul && goto hors_ligne

echo.
echo   ============================================
echo     Aucun telephone detecte.
echo   ============================================
echo.
echo   Rien n'a ete installe. A verifier, dans l'ordre :
echo.
echo     1. Le telephone est bien branche en USB.
echo     2. Le cable transfere les donnees : certains ne
echo        font que recharger. Essayez-en un autre.
echo     3. Le debogage USB est active sur le telephone :
echo        Parametres / A propos / appuyer 7 fois sur
echo        "Numero de build", puis Parametres / Systeme /
echo        Options pour les developpeurs / Debogage USB.
echo.
echo   Le mode "Transfert de fichiers" n'a rien a voir : il
echo   n'est pas necessaire, c'est le debogage USB qui compte.
echo.
echo   Voici ce qu'a repondu adb :
echo.
type "%APPAREILS%"
echo.
pause
exit /b 1

:non_autorise
echo.
echo   ============================================
echo     Autorisation a donner sur le telephone.
echo   ============================================
echo.
echo   Le telephone est branche et le debogage USB est bien
echo   active. Il manque seulement votre accord.
echo.
echo   REGARDEZ L'ECRAN DU TELEPHONE : une fenetre y demande
echo   "Autoriser le debogage USB ?". Cochez "Toujours
echo   autoriser depuis cet ordinateur", appuyez sur
echo   Autoriser, puis relancez ce fichier.
echo.
echo   Si la fenetre ne s'affiche pas, debranchez et
echo   rebranchez le cable : elle revient au branchement.
echo.
pause
exit /b 1

:hors_ligne
echo.
echo   ============================================
echo     Le telephone ne repond pas.
echo   ============================================
echo.
echo   Il est vu, mais dans l'etat "offline". Debranchez le
echo   cable, attendez deux secondes, rebranchez-le, puis
echo   relancez ce fichier.
echo.
pause
exit /b 1

:pas_d_adb
echo.
echo   ============================================
echo     Outil adb introuvable.
echo   ============================================
echo.
echo   adb est livre avec le SDK Android. Il est installe par
echo   Android Studio, dans "SDK Manager / SDK Tools /
echo   Android SDK Platform-Tools".
echo.
echo   Envoyez ce message a Claude avec la sortie de la
echo   commande : flutter doctor -v
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
