"""Dessine l'icone de l'application et la decline dans toutes les tailles.

L'icone dit ce que fait l'application : la goutte de Ter2eaux, et le poteau
d'incendie a cote. Elle est dessinee en grand puis reduite, pour que les bords
restent nets a 48 pixels comme a 1024.

    python3 tool/icone.py

reecrit les icones d'Android, d'iOS et du web, plus les visuels de la fiche
Google Play. Aucune dependance en dehors de Pillow :

    pip install Pillow

Le logotype complet de Ter2eaux ne se lit pas a 48 pixels : l'icone en reprend
donc la goutte seule, son element distinctif, et le logotype entier n'apparait
que sur la banniere du Play Store, ou il y a la place. Deposez-le dans
`assets/images/logo-ter2eaux.png` et la banniere s'en servira ; sans lui, elle
retombe sur la goutte.
"""
import json
import pathlib

from PIL import Image, ImageDraw

RACINE = pathlib.Path(__file__).resolve().parent.parent

LOGO_TER2EAUX = RACINE / 'assets/images/logo-ter2eaux.png'

# Android : densites classiques, en dp.
DENSITES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

# Les couleurs de Ter2eaux, relevees sur le logotype.
CYAN = (41, 168, 212)
CYAN_SOMBRE = (26, 130, 170)
VERT = (122, 182, 72)
BRUN = (91, 58, 41)

# Les couleurs de l'application, pour le fond des visuels.
BLEU_FONCE = (16, 76, 126)     # #104C7E
BLEU_MOYEN = (27, 106, 168)

# Le poteau d'incendie.
ROUGE = (199, 42, 34)
ROUGE_SOMBRE = (150, 28, 22)
GRIS = (120, 128, 136)
BLANC = (255, 255, 255)

SS = 4  # facteur de surechantillonnage


def fond(taille, rayon_ratio=0.2235):
    """Le carre blanc a coins arrondis sur lequel le dessin se pose.

    Blanc et non bleu : le logotype de Ter2eaux est multicolore et concu pour
    du blanc ; le poser sur un aplat fonce eteindrait ses verts et son cyan.
    """
    t = taille * SS
    if rayon_ratio <= 0:
        return Image.new('RGBA', (t, t), BLANC + (255,))

    image = Image.new('RGBA', (t, t), (0, 0, 0, 0))
    ImageDraw.Draw(image).rounded_rectangle(
        [0, 0, t - 1, t - 1], radius=int(t * rayon_ratio), fill=BLANC + (255,))
    return image


def goutte(dessin, cx, cy, largeur, couleur):
    """Une goutte d'eau : un disque surmonte d'une pointe."""
    r = largeur / 2
    bas = cy + r
    haut = cy - largeur * 0.92
    dessin.ellipse([cx - r, cy - r, cx + r, cy + r], fill=couleur)
    # Les flancs de la pointe partent des cotes du disque, un peu au-dessus de
    # son centre, pour que le raccord ne fasse pas d'angle.
    dessin.polygon(
        [(cx, haut), (cx + r * 0.995, cy + r * 0.08),
         (cx, bas), (cx - r * 0.995, cy + r * 0.08)],
        fill=couleur,
    )


def _courbe(depart, controle, arrivee, pas=28):
    """Les points d'une courbe de Bezier quadratique."""
    points = []
    for i in range(pas + 1):
        k = i / pas
        u = 1 - k
        points.append((
            u * u * depart[0] + 2 * u * k * controle[0] + k * k * arrivee[0],
            u * u * depart[1] + 2 * u * k * controle[1] + k * k * arrivee[1],
        ))
    return points


def feuille(dessin, depart, arrivee, bombe, couleur):
    """La feuille du logotype : deux arcs opposes, pointus aux deux bouts.

    Deux demi-cercles accoles donneraient une forme a bords plats ; c'est le
    renflement entre deux pointes qui fait lire une feuille, d'ou les deux
    courbes symetriques.
    """
    dx, dy = arrivee[0] - depart[0], arrivee[1] - depart[1]
    longueur = max((dx * dx + dy * dy) ** 0.5, 1e-6)
    # La normale a l'axe de la feuille, ou se porte le renflement.
    nx, ny = -dy / longueur, dx / longueur
    milieu = ((depart[0] + arrivee[0]) / 2, (depart[1] + arrivee[1]) / 2)

    contour = []
    for sens in (1, -1):
        controle = (milieu[0] + nx * bombe * 2 * sens,
                    milieu[1] + ny * bombe * 2 * sens)
        arc = _courbe(depart, controle, arrivee)
        contour += arc if sens == 1 else list(reversed(arc))

    dessin.polygon(contour, fill=couleur)


def poteau(dessin, cx, bas, hauteur, simple=False):
    """Un poteau d'incendie, vu de face.

    Le corps, sa calotte bombee, ses deux demi-raccords lateraux et son socle.
    [simple] retire la plaque numerotee et les raccords : en dessous de 32
    pixels ils se rejoignent en une tache, et deux formes lisibles valent
    mieux que cinq illisibles.
    """
    largeur = hauteur * 0.36
    gauche, droite = cx - largeur / 2, cx + largeur / 2
    haut_corps = bas - hauteur * 0.80

    # Le socle.
    socle_h = hauteur * 0.10
    dessin.rounded_rectangle(
        [cx - largeur * 0.82, bas - socle_h, cx + largeur * 0.82, bas],
        radius=socle_h * 0.3, fill=GRIS)

    # Le corps.
    dessin.rounded_rectangle(
        [gauche, haut_corps, droite, bas - socle_h * 0.6],
        radius=largeur * 0.16, fill=ROUGE)

    if not simple:
        # Les deux demi-raccords lateraux, a mi-hauteur.
        y = haut_corps + hauteur * 0.34
        ep = hauteur * 0.10
        for sens in (-1, 1):
            x0 = cx + sens * largeur * 0.5
            x1 = cx + sens * largeur * 0.92
            dessin.rounded_rectangle(
                [min(x0, x1), y - ep / 2, max(x0, x1), y + ep / 2],
                radius=ep * 0.35, fill=ROUGE_SOMBRE)

    # La calotte bombee.
    calotte = hauteur * 0.26
    dessin.ellipse(
        [gauche, haut_corps - calotte / 2, droite, haut_corps + calotte / 2],
        fill=ROUGE)
    # Le collet, juste sous la calotte.
    dessin.rectangle(
        [gauche, haut_corps + calotte * 0.20,
         droite, haut_corps + calotte * 0.42],
        fill=ROUGE_SOMBRE)

    if not simple:
        # La plaque numerotee, blanche, sur le haut du corps.
        plaque_h = hauteur * 0.19
        y = haut_corps + calotte * 0.60
        dessin.rounded_rectangle(
            [gauche + largeur * 0.16, y,
             droite - largeur * 0.16, y + plaque_h],
            radius=largeur * 0.08, fill=BLANC)


def glyphe(image, echelle=1.0, simple=False):
    """La goutte de Ter2eaux et le poteau d'incendie, poses sur [image]."""
    t = image.size[0]
    d = ImageDraw.Draw(image)
    cx, cy = t / 2, t / 2

    # La goutte occupe la gauche, le poteau la droite. Les deux sont cales sur
    # une meme hauteur utile pour ne pas donner l'air de flotter.
    hauteur = t * 0.70 * echelle
    ecart = t * 0.04 * echelle

    largeur_goutte = hauteur * 0.55
    goutte_cx = cx - ecart / 2 - largeur_goutte * 0.52
    goutte_cy = cy + hauteur * 0.20

    # A plat, sans ombre : un degrade ou un liston plus sombre se transforme
    # en salissure des que l'icone descend a 48 pixels.
    goutte(d, goutte_cx, goutte_cy, largeur_goutte, CYAN)

    if not simple:
        # La feuille part du haut de la goutte et file vers la droite, comme
        # sur le logotype.
        base = (goutte_cx + largeur_goutte * 0.10,
                goutte_cy - largeur_goutte * 0.82)
        pointe = (goutte_cx + largeur_goutte * 0.90,
                  goutte_cy - largeur_goutte * 1.24)
        # La tige brune, signature du logotype, tracee avant la feuille : son
        # bout disparait dessous et le raccord ne fait pas de nœud.
        d.line(
            [(goutte_cx - largeur_goutte * 0.06,
              goutte_cy - largeur_goutte * 0.66), base],
            fill=BRUN, width=max(1, int(largeur_goutte * 0.09)))
        feuille(d, base, pointe, largeur_goutte * 0.16, VERT)

    poteau(d, cx + ecart / 2 + hauteur * 0.20, cy + hauteur / 2, hauteur,
           simple=simple)


def icone(taille, rayon_ratio=0.2235, echelle=1.0, simple=None):
    image = fond(taille, rayon_ratio)
    glyphe(image, echelle, simple=taille <= 32 if simple is None else simple)
    return image.resize((taille, taille), Image.LANCZOS)


def premier_plan(taille, echelle=0.66):
    """L'avant-plan de l'icone adaptative Android : le glyphe, fond nu."""
    t = taille * SS
    image = Image.new('RGBA', (t, t), (0, 0, 0, 0))
    glyphe(image, echelle)
    return image.resize((taille, taille), Image.LANCZOS)


def banniere(largeur, hauteur):
    """Le visuel large de la fiche Play Store.

    C'est le seul endroit assez large pour le logotype entier : il y est
    repris tel quel quand le fichier est la, et remplace par l'icone sinon.
    """
    degrade = Image.new('RGB', (largeur, 1))
    for x in range(largeur):
        k = x / (largeur - 1)
        degrade.putpixel((x, 0), tuple(
            round(BLEU_FONCE[i] + (BLEU_MOYEN[i] - BLEU_FONCE[i]) * k)
            for i in range(3)))
    image = degrade.resize((largeur, hauteur)).convert('RGBA')

    marque = icone(int(hauteur * 0.62))
    image.paste(marque, (int(largeur * 0.09),
                         (hauteur - marque.size[1]) // 2), marque)

    if LOGO_TER2EAUX.exists():
        logo = Image.open(LOGO_TER2EAUX).convert('RGBA')
        cible = int(largeur * 0.42)
        logo = logo.resize(
            (cible, max(1, round(cible * logo.size[1] / logo.size[0]))),
            Image.LANCZOS)
        # Le logotype est dessine pour du blanc : on lui pose son propre
        # cartouche plutot que de l'ecraser sur le degrade bleu.
        cartouche = Image.new(
            'RGBA',
            (logo.size[0] + int(hauteur * 0.10),
             logo.size[1] + int(hauteur * 0.10)),
            (0, 0, 0, 0))
        ImageDraw.Draw(cartouche).rounded_rectangle(
            [0, 0, cartouche.size[0] - 1, cartouche.size[1] - 1],
            radius=int(hauteur * 0.05), fill=BLANC + (255,))
        cartouche.paste(logo, (int(hauteur * 0.05), int(hauteur * 0.05)), logo)

        image.paste(
            cartouche,
            (int(largeur * 0.46), (hauteur - cartouche.size[1]) // 2),
            cartouche)

    return image


# --- Ecriture dans les dossiers des plateformes ------------------------------


def ecrire(image, chemin):
    chemin.parent.mkdir(parents=True, exist_ok=True)
    image.save(chemin)
    print(' ', chemin.relative_to(RACINE), image.size)


def android():
    for densite, k in DENSITES.items():
        dossier = RACINE / 'android/app/src/main/res' / f'mipmap-{densite}'
        # L'icone classique, pour les lanceurs d'avant l'icone adaptative.
        ecrire(icone(round(48 * k)), dossier / 'ic_launcher.png')
        # L'avant-plan de l'icone adaptative : 108 dp, dont seuls les 72 dp
        # centraux sont surs — le lanceur rogne le reste a sa guise.
        ecrire(premier_plan(round(108 * k)),
               dossier / 'ic_launcher_foreground.png')


def ios():
    dossier = RACINE / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    contenu = json.loads((dossier / 'Contents.json').read_text())
    for image in contenu['images']:
        cote = float(image['size'].split('x')[0])
        echelle = int(image['scale'].rstrip('x'))
        # iOS arrondit les coins lui-meme et n'accepte pas la transparence.
        plate = icone(round(cote * echelle), rayon_ratio=0).convert('RGB')
        ecrire(plate, dossier / image['filename'])


def web():
    # 32 plutot que 16 : les onglets des ecrans denses y gagnent en nettete,
    # et le navigateur reduit lui-meme quand il a besoin de plus petit.
    ecrire(icone(32, rayon_ratio=0.18), RACINE / 'web/favicon.png')
    for taille in (192, 512):
        ecrire(icone(taille), RACINE / f'web/icons/Icon-{taille}.png')
        # Les icones « maskable » sont rognees en cercle par le systeme : le
        # dessin y est plus petit, et le fond va jusqu'aux bords.
        ecrire(icone(taille, rayon_ratio=0, echelle=0.72),
               RACINE / f'web/icons/Icon-maskable-{taille}.png')


def boutique():
    dossier = RACINE / 'store'
    ecrire(icone(512, rayon_ratio=0).convert('RGB'), dossier / 'icone-512.png')
    ecrire(banniere(1024, 500).convert('RGB'),
           dossier / 'banniere-1024x500.png')


if __name__ == '__main__':
    android()
    ios()
    web()
    boutique()
