import 'contact_entry.dart';
import 'enums.dart';
import 'photo_item.dart';

/// Un releve de controle, pour une annee donnee.
///
/// La fiche en porte plusieurs : le modele papier reserve trois lignes, une
/// par annee, pour que le controle de l'an prochain se lise a cote de celui
/// de cette annee. C'est tout l'interet de la fiche — un poteau se juge sur
/// l'evolution de son debit, pas sur une mesure isolee.
///
/// Les mesures sont gardees telles que l'intervenant les a tapees, et non
/// converties en nombres : sur un telephone on ecrit « 3,2 », la virgule
/// francaise, et c'est cette valeur-la qui doit s'imprimer. Un aller-retour
/// par un `double` la transformerait en « 3.2 » sur la fiche.
class ControlRow {
  ControlRow({
    required this.year,
    this.date,
    this.maxFlow = '',
    this.dynamicPressure = '',
    this.staticPressure = '',
    this.flowAtOneBar = '',
    this.goodOperation,
    this.available,
  });

  /// L'annee du controle, telle qu'elle s'imprime en tete de ligne : "2025".
  String year;

  /// La date exacte du controle.
  DateTime? date;

  /// Debit maximum, en m3/h.
  String maxFlow;

  /// Pression dynamique, en bar.
  String dynamicPressure;

  /// Pression statique au poteau, en bar.
  String staticPressure;

  /// Debit a 1 bar de pression dynamique, en m3/h.
  ///
  /// C'est la valeur de reference des services d'incendie : elle dit ce que
  /// l'hydrant delivre vraiment a la lance.
  String flowAtOneBar;

  /// Bon fonctionnement : oui, non, ou pas encore renseigne.
  bool? goodOperation;

  /// Disponibilite de l'hydrant : oui, non, ou pas encore renseigne.
  bool? available;

  /// Vrai des qu'une valeur a ete saisie sur la ligne.
  ///
  /// Les lignes vides existent quand meme : le modele papier reserve les
  /// annees a venir, et la fiche s'imprime avec ses lignes en attente.
  bool get isFilled =>
      date != null ||
      goodOperation != null ||
      available != null ||
      [maxFlow, dynamicPressure, staticPressure, flowAtOneBar]
          .any((value) => value.trim().isNotEmpty);

  ControlRow clone() => ControlRow(
        year: year,
        date: date,
        maxFlow: maxFlow,
        dynamicPressure: dynamicPressure,
        staticPressure: staticPressure,
        flowAtOneBar: flowAtOneBar,
        goodOperation: goodOperation,
        available: available,
      );

  Map<String, dynamic> toJson() => {
        'year': year,
        'date': date?.toIso8601String(),
        'maxFlow': maxFlow,
        'dynamicPressure': dynamicPressure,
        'staticPressure': staticPressure,
        'flowAtOneBar': flowAtOneBar,
        'goodOperation': goodOperation,
        'available': available,
      };

  factory ControlRow.fromJson(Map<String, dynamic> json) => ControlRow(
        year: json['year'] as String? ?? '',
        date: _parseDate(json['date']),
        maxFlow: json['maxFlow'] as String? ?? '',
        dynamicPressure: json['dynamicPressure'] as String? ?? '',
        staticPressure: json['staticPressure'] as String? ?? '',
        flowAtOneBar: json['flowAtOneBar'] as String? ?? '',
        goodOperation: json['goodOperation'] as bool?,
        available: json['available'] as bool?,
      );
}

/// La fiche de controle d'un poteau d'incendie.
///
/// Elle suit rubrique par rubrique le modele papier : l'en-tete (numero
/// d'ordre, commune, date d'edition), les coordonnees du centre du SDISS et
/// de la collectivite, les caracteristiques de l'appareil, le detail des
/// controles annuels, les trois vues photographiques et les observations.
///
/// Les champs sont mutables : une fiche est un brouillon que l'intervenant
/// remplit sur le terrain, souvent en plusieurs fois — releve d'abord,
/// photos ensuite, observations une fois revenu au camion.
class FichePi {
  FichePi({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.companyId = '',
    this.orderNumber = '',
    this.communeName = '',
    DateTime? editionDate,
    this.sdisCenter,
    this.collectivity,
    this.hydrantNumber = '',
    this.location = '',
    this.brand = '',
    this.model = '',
    this.hydrantType = '',
    this.pipeDiameter = '',
    List<ControlRow>? controls,
    this.planPhoto,
    this.hydrantPhoto,
    this.environmentPhoto,
    this.observations = '',
    this.status = FicheStatus.brouillon,
    this.lastPdfPath,
  })  : editionDate = editionDate ?? DateTime.now(),
        controls = controls ?? <ControlRow>[];

  final String id;
  final DateTime createdAt;
  DateTime updatedAt;

  // --- En-tete --------------------------------------------------------------

  /// La societe qui edite la fiche : [Company.ter2eauxId] ou
  /// [Company.rezeauId]. Choisie a la creation, elle decide du logo en tete
  /// et des mentions legales en pied.
  String companyId;

  /// Le numero d'ordre de la fiche : "45 013".
  String orderNumber;

  /// La commune, telle qu'elle s'imprime en gros au centre : "SAINT-REMY (01)".
  String communeName;

  /// La date d'edition portee en haut a droite.
  DateTime editionDate;

  // --- Coordonnees ----------------------------------------------------------

  /// Copie des coordonnees choisies dans le repertoire, figee dans la fiche.
  ContactEntry? sdisCenter;
  ContactEntry? collectivity;

  // --- Caracteristiques du poteau -------------------------------------------

  /// Le numero de l'appareil sur la commune : "013".
  String hydrantNumber;

  /// "187 Ch du Colombier (Grange Carrée)"
  String location;

  /// "BAYARD", "PONT-A-MOUSSON", ...
  String brand;

  /// "EMERAUDE", "RUBIS", ...
  String model;

  /// "ECS4", "PI 100", ...
  String hydrantType;

  /// Diametre de la canalisation d'alimentation : "DN 100".
  String pipeDiameter;

  // --- Controles ------------------------------------------------------------

  /// Les releves annuels, du plus ancien au plus recent.
  final List<ControlRow> controls;

  // --- Photographies --------------------------------------------------------

  PhotoItem? planPhoto;
  PhotoItem? hydrantPhoto;
  PhotoItem? environmentPhoto;

  String observations;
  FicheStatus status;

  /// Chemin du dernier PDF genere, pour le retrouver sans le refabriquer.
  String? lastPdfPath;

  // --- Lectures -------------------------------------------------------------

  /// Les photos presentes, dans l'ordre des cadres de la fiche.
  List<PhotoItem> get photos => <PhotoItem>[
        if (planPhoto != null) planPhoto!,
        if (hydrantPhoto != null) hydrantPhoto!,
        if (environmentPhoto != null) environmentPhoto!,
      ];

  PhotoItem? photoOf(PhotoSlot slot) {
    switch (slot) {
      case PhotoSlot.plan:
        return planPhoto;
      case PhotoSlot.hydrant:
        return hydrantPhoto;
      case PhotoSlot.environnement:
        return environmentPhoto;
    }
  }

  void setPhoto(PhotoSlot slot, PhotoItem? photo) {
    switch (slot) {
      case PhotoSlot.plan:
        planPhoto = photo;
      case PhotoSlot.hydrant:
        hydrantPhoto = photo;
      case PhotoSlot.environnement:
        environmentPhoto = photo;
    }
  }

  /// Le controle le plus recent effectivement rempli — celui qui decide de
  /// l'etat de la fiche et de ce qu'on lit dans la liste.
  ControlRow? get latestControl {
    ControlRow? best;
    for (final row in controls) {
      if (!row.isFilled) continue;
      if (best == null || _yearOf(row) >= _yearOf(best)) best = row;
    }
    return best;
  }

  static int _yearOf(ControlRow row) =>
      row.date?.year ?? int.tryParse(row.year.trim()) ?? 0;

  /// "SAINT-REMY (01)", ou le lieu-dit tant que la commune n'est pas saisie.
  String get displayTitle {
    final commune = communeName.trim();
    if (commune.isNotEmpty) return commune;
    final where = location.trim();
    return where.isEmpty ? 'Fiche sans commune' : where;
  }

  /// "Poteau n° 013 — 187 Ch du Colombier"
  String get displaySubtitle {
    final number = hydrantNumber.trim();
    final parts = <String>[
      if (number.isNotEmpty) 'Poteau n° $number',
      if (location.trim().isNotEmpty) location.trim(),
    ];
    return parts.isEmpty ? 'Poteau à identifier' : parts.join(' — ');
  }

  /// L'etat que le dernier controle designe.
  ///
  /// Un poteau indisponible passe avant tout le reste : c'est l'information
  /// qu'un centre de secours doit voir en premier. Vient ensuite le mauvais
  /// fonctionnement, qui se repare sans que la ressource en eau soit perdue.
  FicheStatus get suggestedStatus {
    final row = latestControl;
    if (row == null) return FicheStatus.brouillon;
    if (row.available == false) return FicheStatus.indisponible;
    if (row.goodOperation == false) return FicheStatus.aSuivre;
    if (row.available == true && row.goodOperation == true) {
      return FicheStatus.conforme;
    }
    return FicheStatus.brouillon;
  }

  /// Tout ce sur quoi la recherche de l'accueil porte.
  String get searchableText => [
        communeName,
        location,
        hydrantNumber,
        orderNumber,
        brand,
        model,
        hydrantType,
        collectivity?.displayLine ?? '',
        sdisCenter?.displayLine ?? '',
      ].join(' ');

  // --- Copie et serialisation -----------------------------------------------

  /// Une copie independante, que l'assistant modifie sans toucher a la fiche
  /// enregistree tant que l'intervenant n'a pas valide.
  FichePi clone() => FichePi.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'companyId': companyId,
        'orderNumber': orderNumber,
        'communeName': communeName,
        'editionDate': editionDate.toIso8601String(),
        'sdisCenter': sdisCenter?.toJson(),
        'collectivity': collectivity?.toJson(),
        'hydrantNumber': hydrantNumber,
        'location': location,
        'brand': brand,
        'model': model,
        'hydrantType': hydrantType,
        'pipeDiameter': pipeDiameter,
        'controls': controls.map((row) => row.toJson()).toList(),
        'planPhoto': planPhoto?.toJson(),
        'hydrantPhoto': hydrantPhoto?.toJson(),
        'environmentPhoto': environmentPhoto?.toJson(),
        'observations': observations,
        'status': status.name,
        'lastPdfPath': lastPdfPath,
      };

  factory FichePi.fromJson(Map<String, dynamic> json) {
    ContactEntry? contact(String key) {
      final value = json[key];
      return value == null
          ? null
          : ContactEntry.fromJson(value as Map<String, dynamic>);
    }

    PhotoItem? photo(String key) {
      final value = json[key];
      return value == null
          ? null
          : PhotoItem.fromJson(value as Map<String, dynamic>);
    }

    return FichePi(
      id: json['id'] as String,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      companyId: json['companyId'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      editionDate: _parseDate(json['editionDate']),
      sdisCenter: contact('sdisCenter'),
      collectivity: contact('collectivity'),
      hydrantNumber: json['hydrantNumber'] as String? ?? '',
      location: json['location'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      hydrantType: json['hydrantType'] as String? ?? '',
      pipeDiameter: json['pipeDiameter'] as String? ?? '',
      controls: (json['controls'] as List<dynamic>? ?? const <dynamic>[])
          .map((row) => ControlRow.fromJson(row as Map<String, dynamic>))
          .toList(),
      planPhoto: photo('planPhoto'),
      hydrantPhoto: photo('hydrantPhoto'),
      environmentPhoto: photo('environmentPhoto'),
      observations: json['observations'] as String? ?? '',
      status: FicheStatus.fromName(json['status'] as String?),
      lastPdfPath: json['lastPdfPath'] as String?,
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
