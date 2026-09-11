# Poteaux incendie

Application mobile Flutter pour le contrôle des poteaux d'incendie. L'agent
remplit la fiche au pied de l'appareil, depuis son téléphone, et en sort le
PDF mis en page — celui que la collectivité et le centre de secours attendent.

Elle reprend l'ossature d'une application de rapports d'intervention (mêmes
couleurs, même assistant en étapes, même stockage hors ligne, même chaîne
PDF), mais ne demande plus rien des mêmes informations et ne produit plus du
tout le même document.

## La fiche

Une fiche, une page A4, dans l'ordre du modèle papier :

| Rubrique | Ce qu'elle porte |
|---|---|
| En-tête | Le logo de la société, la commune en gros, le n° d'ordre et la date d'édition |
| Coordonnées du Centre du SDISS | Adresse principale, téléphone, fax, portable |
| Coordonnées de la Collectivité | Les mêmes rubriques |
| Caractéristiques du poteau | N°, localisation, marque, modèle, type, DN canalisation |
| Détail des interventions de contrôle | Une ligne par année : date, débit maximum, pression dynamique, pression statique, débit à 1 bar, bon fonctionnement (oui/non), disponibilité (oui/non) |
| Photographies | Le plan des réseaux, la photo de l'hydrant, la photo de l'environnement |
| Observations | Texte libre, sur lignes réglées |

Le pied de page porte les mentions légales de la société et la pagination.

La mise en page vit dans
[`lib/services/fiche_pi_pdf.dart`](lib/services/fiche_pi_pdf.dart) ; les
couleurs et les briques communes dans
[`lib/services/pdf_style.dart`](lib/services/pdf_style.dart).

## La saisie

L'intervenant ne remplit pas un document : il répond à une série de questions
courtes, réparties en six étapes.

| Étape | Ce qu'on demande |
|---|---|
| 1. La fiche | Société, commune, n° d'ordre, date d'édition |
| 2. Coordonnées | Le centre du SDISS et la collectivité, choisis dans le répertoire |
| 3. Le poteau | N°, localisation, marque, modèle, type, diamètre |
| 4. Le contrôle | Date, débits, pressions, bon fonctionnement, disponibilité |
| 5. Photos | Les trois vues, une par une |
| 6. Observations | Ce qu'il faut signaler, et l'état de la fiche |

Chaque frappe est écrite dans le brouillon, et le brouillon est enregistré à
chaque changement d'étape : une fiche peut être commencée au pied d'un poteau
et terminée le soir.

## Deux sociétés

**Ter2eaux** et **Rezeau** sont livrées avec l'application, et l'on choisit
laquelle au moment de créer une fiche : c'est son logo qui s'imprime en tête
et ses mentions légales en pied. Chacune a sa fiche complète dans
Réglages → Sociétés, et l'étoile marque celle proposée en premier.

Elles arrivent avec leur nom seul : **l'adresse et les mentions légales sont à
saisir** une fois pour toutes, un bandeau sur l'accueil le rappelle tant que
ce n'est pas fait. Rien n'a été inventé à leur place — une fiche portant un
faux SIRET vaudrait moins qu'une fiche sans.

## Le répertoire : ne rien retaper deux fois

Les vingt poteaux d'une commune portent la même mairie et le même centre de
secours. Ces coordonnées se saisissent donc **une seule fois**, puis se
choisissent d'un geste :

- depuis l'assistant, à l'étape « Coordonnées » : la liste s'ouvre, on touche
  la bonne entrée ; une mairie découverte en route s'enregistre sur-le-champ
  et sera proposée pour tous les poteaux suivants ;
- depuis Réglages → Répertoires, pour préparer une tournée la veille au calme,
  ou corriger un numéro de téléphone.

La fiche en garde une **copie** plutôt qu'un renvoi : une fiche éditée reste
le reflet de ce qui était connu le jour du contrôle, et un changement de
numéro à la mairie ne réécrit pas les fiches des années précédentes.

Même principe pour les marques, modèles, types et diamètres : ils se touchent
du doigt au lieu de se taper, et une valeur inédite rejoint d'elle-même la
liste pour les fiches suivantes.

## Fonctionnalités

- **Choix de la société** à la création de chaque fiche.
- **Répertoires** des centres du SDISS et des collectivités, remplis au fil des
  tournées.
- **Plusieurs années de contrôle** sur la même fiche : c'est l'évolution du
  débit qui juge un poteau, pas une mesure isolée. Les années à venir restent
  imprimées vides, comme sur le modèle papier.
- **Mesures gardées telles qu'elles sont tapées** : on écrit « 3,2 » au bord de
  la route, et c'est « 3,2 » qui s'imprime.
- **État déduit du dernier contrôle** — conforme, à suivre, indisponible — et
  modifiable à la main. L'indisponibilité prime : c'est ce qu'un centre de
  secours doit voir en premier.
- **Trois photos nommées** plutôt qu'un tas à trier : chaque cadre de la fiche
  attend une vue précise. Les photos sont redimensionnées à l'import pour
  qu'une tournée reste envoyable en 4G.
- **« Poteau suivant »** : duplique la fiche en gardant la commune, les
  coordonnées et les caractéristiques, et repart sans numéro, sans mesure et
  sans photo.
- **N° d'ordre proposé** à partir du préfixe de la tournée et du numéro du
  poteau — « 45 » et « 013 » donnent « 45 013 » — et modifiable.
- **Recherche et filtres** par commune, rue, n° de poteau ou n° d'ordre, et par
  état (à terminer / à suivre / conformes).
- **Export PDF** : aperçu, impression, téléchargement du fichier sur l'appareil
  et envoi par e-mail, SMS ou messagerie. Le fichier s'appelle
  `Fiche-PI_SAINT-REMY-01_013.pdf` : il se lit sans l'ouvrir.
- **100 % hors ligne** : tout est stocké sur l'appareil, aucun compte ni
  connexion n'est nécessaire. La police du PDF est embarquée.

## Les logos

Deux fichiers sont attendus dans `assets/images/` :

```
assets/images/logo-ter2eaux.png
assets/images/logo-rezeau.png
```

Déposez-les et ils seront livrés avec l'application. Sans eux, la fiche imprime
la raison sociale à la place du logo — et chacun peut de toute façon choisir le
sien depuis la galerie de son téléphone, dans **Réglages → Sociétés → Logo**,
sans toucher au dépôt. Aucun logo générique n'est livré de repli.

L'icône de l'application — la goutte de Ter2eaux et le poteau d'incendie à
côté — est dessinée par [`tool/icone.py`](tool/icone.py), qui la décline dans
toutes les tailles d'Android, d'iOS et du web :

```bash
pip install Pillow
python3 tool/icone.py
```

Le logotype entier ne se lit pas à 48 pixels : l'icône en reprend la goutte
seule, son élément distinctif, et le logotype complet n'apparaît que sur la
bannière du Play Store — où il est repris tel quel dès que
`assets/images/logo-ter2eaux.png` est en place.

## Démarrage

```bash
git clone https://github.com/Thomas-Grsst/rapport-poto-incendis.git
cd rapport-poto-incendis
flutter pub get
```

Sur un téléphone ou un émulateur — c'est la cible de l'application, avec
l'appareil photo :

```bash
flutter run
```

Dans un navigateur, pour la montrer sans rien installer :

```bash
flutter run -d chrome
```

Android et iOS sont configurés, permissions caméra et galerie comprises.
Développé et vérifié avec Flutter 3.27 / Dart 3.6.

### Vérifications

```bash
flutter analyze
flutter test
```

Pour regarder le PDF produit plutôt que de se fier à la taille du fichier —
une mise en page ne se vérifie pas autrement qu'avec les yeux :

```bash
FICHE_PDF_OUT=build/apercu flutter test test/pdf_service_test.dart
```

### Version web

L'application vise le mobile, mais elle tourne aussi dans un navigateur pour
pouvoir être essayée sans téléphone. Le dossier documents y est remplacé par
le stockage local du navigateur (voir
[`lib/services/storage_service.dart`](lib/services/storage_service.dart)) ;
tout le reste — assistant, photos, PDF — est identique.

Les fiches et les réglages tiennent dans le stockage local, les photos et les
PDF dans IndexedDB — le stockage local plafonne à 5 Mo. La limite qui reste
est que les données appartiennent au navigateur utilisé : pour une tournée
réelle, c'est la version mobile qu'il faut installer.

```bash
flutter build web --release --no-web-resources-cdn
```

`--no-web-resources-cdn` embarque le moteur de rendu dans le build au lieu de
le charger depuis un CDN : la page s'ouvre alors même sans connexion.

## Organisation du code

```
lib/
├── main.dart                  Point d'entrée, injection des dépendances
├── app.dart                   MaterialApp, chargement initial
├── theme.dart                 Charte graphique (bleu #104C7E / #8FB8E8)
├── models/
│   ├── fiche_pi.dart          La fiche et ses lignes de contrôle
│   ├── contact_entry.dart     Une entrée de répertoire
│   ├── company.dart           Ter2eaux, Rezeau
│   ├── photo_item.dart        Une des trois vues
│   ├── enums.dart             États, cadres photo, répertoires
│   └── app_settings.dart      Sociétés, répertoires, listes de choix
├── services/
│   ├── storage_service.dart      Interface de stockage
│   ├── storage_service_io.dart   Fichiers, sur téléphone
│   ├── storage_service_web.dart  Stockage du navigateur
│   ├── media_store_web.dart      Photos du navigateur (IndexedDB)
│   ├── pdf_style.dart            La charte du PDF
│   ├── fiche_pi_pdf.dart         La mise en page de la fiche
│   ├── pdf_service.dart          Génération et enregistrement du PDF
│   └── pdf_download.dart         Téléchargement du PDF sur l'appareil
├── state/                     FichesProvider, SettingsProvider
├── screens/
│   ├── home_screen.dart          Liste, recherche, filtres, choix de société
│   ├── fiche_wizard_screen.dart  L'assistant en six étapes
│   ├── fiche_detail_screen.dart  La fiche et son export PDF
│   ├── settings_screen.dart      Sociétés, répertoires, listes
│   ├── company_editor_screen.dart
│   ├── directory_screen.dart
│   ├── contact_editor_screen.dart
│   └── steps/                    Les six étapes de l'assistant
└── widgets/                   Composants réutilisables
```

### Stockage

Les données sont enregistrées dans le dossier documents de l'application :

- `fiches.json` — les fiches (écriture atomique)
- `settings.json` — les sociétés, les répertoires et les listes de choix
- `media/` — photos et logos
- `fiches/` — les PDF générés

Dans un navigateur, ces mêmes entrées sont enregistrées dans le stockage local
plutôt que sur disque : les écrans manipulent des chemins sans savoir où les
fichiers atterrissent réellement.

## Construire l'APK

```bash
flutter build apk --release
```

Le fichier atterrit dans `build/app/outputs/flutter-apk/app-release.apk` :
copiez-le sur le téléphone et ouvrez-le. Android demandera d'autoriser
l'installation d'applications de cette source — c'est normal en dehors du
Play Store.

Un APK par architecture, trois fois plus léger à transférer :

```bash
flutter build apk --release --split-per-abi
```

Celui qui convient à la quasi-totalité des téléphones récents est
`app-arm64-v8a-release.apk`.

### Le NDK est nécessaire

Une compilation en `--release` réclame le **NDK Android**, même si
l'application ne contient pas une ligne de code natif : le moteur Flutter
livre un `libflutter.so` de 165 Mo par architecture, que Gradle dépouille de
ses symboles de débogage avec l'outil `strip` du NDK. Sans lui, l'APK dépasse
490 Mo au lieu d'une trentaine.

Gradle l'installe tout seul la première fois. Si l'installation échoue
(« *Install NDK (Side by side) … failed* »), passez par l'interface plutôt que
par la ligne de commande : Android Studio → **Settings** → *Languages &
Frameworks* → **Android SDK** → onglet **SDK Tools** → cochez **Show Package
Details** → dépliez **NDK (Side by side)** → cochez la version que Gradle
réclame.

### Signer avec votre clé

Sans clé de publication, Flutter signe l'APK avec sa clé de débogage. Il
s'installe très bien, mais **une mise à jour ne remplace une application
installée que si elle porte la même signature** : recompiler depuis un autre
PC obligerait à désinstaller puis réinstaller, en perdant toutes les fiches.
Une vraie clé règle la question une fois pour toutes.

Créez le magasin de clés, une seule fois, hors du dépôt :

```bash
keytool -genkey -v -keystore %USERPROFILE%\cle-poteaux.jks ^
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias poteaux
```

`keytool` est livré avec le JDK d'Android Studio ; si la commande est
introuvable, elle se trouve dans
`C:\Program Files\Android\Android Studio\jbr\bin`.

Copiez ensuite
[`android/key.properties.exemple`](android/key.properties.exemple) en
`android/key.properties` et remplissez-le. La prochaine compilation en
`--release` utilisera cette clé ; sans ce fichier, elle retombe sur la clé de
débogage.

> `key.properties` et le `.jks` ne sont pas versionnés, et ne doivent jamais
> l'être : qui les détient peut signer une mise à jour au nom de
> l'application. **Sauvegardez-les ailleurs que sur le PC de compilation** —
> une clé perdue, c'est l'impossibilité de mettre à jour les applications
> déjà installées.

Le nom de paquet est `fr.ter2eaux.poteaux_incendie` (dans
`android/app/build.gradle.kts`, `android/app/src/main/kotlin/…` et
`ios/Runner.xcodeproj/project.pbxproj`).

Le dossier [`store/`](store/) garde de quoi publier sur Google Play le jour où
ce serait utile : [fiche à copier-coller](store/fiche-play-store.md),
[politique de confidentialité](store/confidentialite.md), icône 512 × 512 et
image mise en avant. Ces fichiers ne servent à rien pour une diffusion en APK.
