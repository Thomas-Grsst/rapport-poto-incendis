# Fiche Google Play

> **L'application se diffuse aujourd'hui en APK, pas sur le Play Store.** Ce
> dossier est gardé pour le jour où elle y serait publiée — et il faudrait
> alors d'abord vider `AppSettings.defaults` et `Company.bundled`, sans quoi
> les sociétés et leurs logos partiraient à tous ceux qui l'installent.

Tout ce que la console Play demande pour publier l'application, prêt à être
copié-collé. Les visuels sont dans ce même dossier.

---

## Nom de l'application

*30 caractères maximum.*

```
Poteaux incendie
```

## Description courte

*80 caractères maximum. C'est la ligne qui s'affiche sous le nom dans les
résultats de recherche.*

```
Fiches de contrôle des poteaux d'incendie : débits, photos et PDF, hors ligne.
```

## Description complète

*4 000 caractères maximum.*

```
Remplissez la fiche de contrôle au pied du poteau, depuis votre téléphone, et
repartez avec le PDF prêt à envoyer à la collectivité et au centre de secours.
Plus de carnet à recopier le soir sur un tableur.

L'application ne vous demande pas de remplir un document : elle vous pose des
questions courtes, étape par étape, et se charge de la mise en page.

LA FICHE, DANS L'ORDRE DU MODÈLE PAPIER

Une fiche, une page A4 : l'en-tête avec la commune et le numéro d'ordre, les
coordonnées du centre du SDISS, celles de la collectivité, les
caractéristiques de l'appareil, le détail des contrôles année par année, les
trois vues photographiques et les observations.

VOUS NE RETAPEZ RIEN DEUX FOIS

Les vingt poteaux d'une commune portent la même mairie et le même centre de
secours. Ces coordonnées se saisissent une seule fois : ensuite, elles se
choisissent dans une liste. Une mairie découverte en route s'enregistre
sur-le-champ et sera proposée pour tous les poteaux suivants.

Même chose pour les marques, les modèles, les types et les diamètres : on les
touche du doigt au lieu de les taper, et une valeur inédite rejoint d'elle-même
la liste.

« Poteau suivant » duplique la fiche en gardant la commune, les coordonnées et
les caractéristiques, et repart sans numéro, sans mesure et sans photo.

PLUSIEURS ANNÉES SUR LA MÊME FICHE

Un poteau se juge sur l'évolution de son débit, pas sur une mesure isolée : le
contrôle de cette année s'écrit à côté de celui de l'an dernier, et les années
à venir restent imprimées vides, comme sur le modèle papier.

Débit maximum, pression dynamique, pression statique, débit à 1 bar, bon
fonctionnement, disponibilité. Les mesures sont gardées telles que vous les
tapez : vous écrivez « 3,2 » au bord de la route, c'est « 3,2 » qui s'imprime.

L'ÉTAT SAUTE AUX YEUX

Conforme, à suivre, indisponible : l'état est déduit du dernier contrôle et
reste modifiable. L'indisponibilité prime — c'est ce qu'un centre de secours
doit voir en premier. La liste se filtre sur ce qui reste à terminer et sur ce
qui est à suivre.

TROIS PHOTOS, CHACUNE À SA PLACE

Le plan des réseaux, l'appareil lui-même, la vue éloignée qui permet de le
retrouver depuis la rue. L'application les demande une par une plutôt que de
vous laisser un tas à trier, et les redimensionne pour qu'une tournée reste
envoyable en 4G.

DEUX SOCIÉTÉS

Choisissez la société au moment de créer la fiche : c'est son logo qui
s'imprime en tête et ses mentions légales en pied.

UN PDF TOUT DE SUITE

La fiche sort mise en page, sur une page A4. Vous pouvez l'afficher,
l'imprimer, la télécharger sur le téléphone ou l'envoyer par e-mail, SMS ou
messagerie. Le fichier s'appelle « Fiche-PI_SAINT-REMY-01_013.pdf » : il se
lit sans l'ouvrir.

100 % HORS LIGNE

Aucun compte, aucune inscription, aucune connexion nécessaire. Tout reste sur
votre téléphone, y compris les photos et les PDF — ce qui compte au bout d'un
chemin communal, là où le réseau ne passe pas.

POUR QUI

Services des eaux, délégataires, entreprises chargées du contrôle des points
d'eau incendie pour le compte des collectivités.
```

---

## Classification et informations

| Champ | Valeur |
|---|---|
| Catégorie | Professionnels (Business) |
| Type | Application |
| Application payante | Non, gratuite |
| Publicités | Aucune |
| Achats intégrés | Aucun |
| Public visé | Professionnels, 18 ans et plus |
| Pays | France (à étendre selon vos besoins) |
| Langue | Français |

### Sécurité des données

À déclarer dans la console, section **Sécurité des données** :

- **Aucune donnée collectée ni partagée.** L'application n'envoie rien à
  aucun serveur. Elle n'a pas de compte, pas d'inscription, pas d'analyse
  d'audience.
- Les données saisies (fiches, photos, PDF) restent dans l'espace privé de
  l'application sur le téléphone, et disparaissent avec sa désinstallation.
- **Chiffrement en transit** : sans objet, rien n'est transmis.
- **Suppression des données** : l'utilisateur supprime chaque fiche depuis
  l'application, ou désinstalle l'application.

La politique de confidentialité à publier est dans
[`confidentialite.md`](confidentialite.md) — Google Play en exige l'URL.

### Autorisations demandées

| Autorisation | Pourquoi |
|---|---|
| Appareil photo | Photographier le poteau et son environnement |
| Photos et médias | Choisir une photo déjà prise, un extrait de plan, un logo |

---

## Visuels

| Fichier | Usage | Format exigé |
|---|---|---|
| [`icone-512.png`](icone-512.png) | Icône de la fiche | 512 × 512, PNG 32 bits, sans transparence |
| [`banniere-1024x500.png`](banniere-1024x500.png) | Image mise en avant | 1024 × 500, JPEG ou PNG 24 bits |

Les deux sont produits par `python3 tool/icone.py`. La bannière reprend le
logotype complet de Ter2eaux dès que `assets/images/logo-ter2eaux.png` est en
place.

### Captures d'écran — à faire depuis un vrai téléphone

Google Play en demande **au moins 2**, jusqu'à 8, en 16:9 ou 9:16, chaque
côté entre 320 et 3 840 px. Les plus parlantes, dans cet ordre :

1. La liste des fiches, avec deux ou trois poteaux contrôlés.
2. Le choix de la société au moment de créer une fiche.
3. L'étape « Coordonnées », la liste du répertoire ouverte.
4. L'étape du contrôle, avec ses mesures et ses deux verdicts.
5. L'étape des photos, avec la vue de l'hydrant.
6. La fiche récapitulative, avec son état.
7. Le PDF généré.

Videz vos vraies communes avant de capturer : ces images seront publiques.

---

## Avant de publier — à vérifier

- [ ] Renseigner l'adresse et les mentions légales des sociétés, puis
      **regénérer une fiche** pour vérifier l'en-tête, le logo et le pied de
      page.
- [ ] Publier la politique de confidentialité à une URL publique et coller
      l'adresse dans la console.
- [ ] Signer l'application avec votre clé de publication (`key.properties` +
      `android/app/build.gradle.kts`) — la clé de débogage est refusée.
- [ ] Incrémenter `version:` dans `pubspec.yaml` à chaque envoi.
- [ ] `flutter build appbundle --release`, puis envoyer le `.aab`.

Le nom de paquet est `fr.ter2eaux.poteaux_incendie`. Il identifie
l'application pour toujours : **il ne pourra plus changer** après la première
publication.
