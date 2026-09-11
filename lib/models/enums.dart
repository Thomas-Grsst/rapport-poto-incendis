/// Etat d'une fiche de poteau d'incendie.
///
/// Il ne decrit pas l'avancement de la saisie mais ce que le controle a
/// donne : c'est ce qu'un service des eaux cherche des yeux dans une liste de
/// deux cents hydrants — lesquels sont hors service, lesquels sont a suivre.
enum FicheStatus {
  brouillon('BROUILLON'),
  conforme('CONFORME'),
  aSuivre('À SUIVRE'),
  indisponible('INDISPONIBLE');

  const FicheStatus(this.label);

  /// Libelle affiche dans l'application.
  final String label;

  static FicheStatus fromName(String? name) => FicheStatus.values.firstWhere(
        (status) => status.name == name,
        orElse: () => FicheStatus.brouillon,
      );
}

/// Les trois images de la fiche, a leur place fixe dans la page.
///
/// Le modele papier ne laisse pas l'intervenant ranger ses photos comme il
/// l'entend : chaque cadre attend une vue precise, et le lecteur sait ou
/// regarder. L'application demande donc les trois, une par une.
enum PhotoSlot {
  plan(
    'Plan des réseaux',
    "Extrait de plan situant l'hydrant sur le réseau",
  ),
  hydrant(
    "Photo de l'hydrant contrôlé",
    "L'appareil lui-même, de face, numéro lisible",
  ),
  environnement(
    "Photo de l'environnement",
    'Vue éloignée, pour retrouver le poteau depuis la rue',
  );

  const PhotoSlot(this.label, this.hint);

  /// Titre imprime au-dessus du cadre, dans le PDF.
  final String label;

  /// Phrase d'aide affichee dans l'assistant de saisie.
  final String hint;

  static PhotoSlot fromName(String? name) => PhotoSlot.values.firstWhere(
        (slot) => slot.name == name,
        orElse: () => PhotoSlot.hydrant,
      );
}

/// Les deux repertoires de coordonnees tenus dans les reglages.
///
/// Un centre de secours dessert des dizaines de communes et une collectivite
/// compte des dizaines de poteaux : leurs coordonnees se saisissent une fois
/// puis se choisissent dans une liste, au lieu d'etre retapees a chaque fiche.
enum DirectoryKind {
  sdis(
    'Centres du SDISS',
    'Centre du SDISS',
    'Ex. : Centre de secours de Bourg-en-Bresse',
  ),
  collectivite(
    'Collectivités',
    'Collectivité',
    'Ex. : Mairie de Saint Rémy',
  );

  const DirectoryKind(this.plural, this.singular, this.hint);

  /// Intitule de la liste, dans les reglages.
  final String plural;

  /// Intitule d'une entree, au singulier.
  final String singular;

  /// Exemple montre dans le champ de saisie.
  final String hint;

  static DirectoryKind fromName(String? name) =>
      DirectoryKind.values.firstWhere(
        (kind) => kind.name == name,
        orElse: () => DirectoryKind.collectivite,
      );
}
