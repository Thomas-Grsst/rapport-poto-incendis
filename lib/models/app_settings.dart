import 'company.dart';
import 'contact_entry.dart';
import 'enums.dart';

/// Les reglages de l'application.
///
/// Tout ce qui se trouve ici existe pour une seule raison : ne rien retaper
/// deux fois. Les deux societes, les centres du SDISS, les collectivites et
/// les listes de marques ou de types se saisissent une fois, puis se
/// choisissent d'un geste au moment de remplir une fiche.
class AppSettings {
  const AppSettings({
    this.companies = const <Company>[],
    this.defaultCompanyId = Company.ter2eauxId,
    this.sdisCenters = const <ContactEntry>[],
    this.collectivities = const <ContactEntry>[],
    this.brandPresets = const <String>[],
    this.modelPresets = const <String>[],
    this.typePresets = const <String>[],
    this.diameterPresets = const <String>[],
    this.observationPresets = const <String>[],
    this.orderNumberPrefix = '',
  });

  /// Les societes entre lesquelles on choisit a la creation d'une fiche.
  final List<Company> companies;

  /// Celle qui est pre-selectionnee : celle sur laquelle on travaille le plus.
  final String defaultCompanyId;

  /// Le repertoire des centres de secours.
  final List<ContactEntry> sdisCenters;

  /// Le repertoire des collectivites.
  final List<ContactEntry> collectivities;

  /// Marques d'appareils proposees : BAYARD, PONT-A-MOUSSON, ...
  final List<String> brandPresets;

  /// Modeles proposes : EMERAUDE, RUBIS, ...
  final List<String> modelPresets;

  /// Types proposes : ECS4, PI 100, ...
  final List<String> typePresets;

  /// Diametres de canalisation proposes : DN 80, DN 100, ...
  final List<String> diameterPresets;

  /// Observations toutes faites, R.A.S. en tete.
  final List<String> observationPresets;

  /// Debut du numero d'ordre, commun a toutes les fiches d'une meme tournee.
  ///
  /// Sur le modele, « 45 013 » se lit : le dossier 45, l'appareil 013. Le
  /// prefixe evite de retaper le premier nombre a chaque poteau — le numero
  /// reste modifiable a la main sur la fiche.
  final String orderNumberPrefix;

  Company? companyById(String? id) {
    for (final company in companies) {
      if (company.id == id) return company;
    }
    return null;
  }

  /// La societe d'une fiche, avec un repli sur la societe par defaut puis sur
  /// la premiere de la liste : une fiche doit toujours pouvoir s'imprimer,
  /// meme si la societe qui l'a creee a ete retiree des reglages.
  Company companyFor(String? id) {
    return companyById(id) ??
        companyById(defaultCompanyId) ??
        (companies.isNotEmpty
            ? companies.first
            : const Company(id: Company.ter2eauxId));
  }

  List<ContactEntry> directory(DirectoryKind kind) {
    switch (kind) {
      case DirectoryKind.sdis:
        return sdisCenters;
      case DirectoryKind.collectivite:
        return collectivities;
    }
  }

  AppSettings withDirectory(DirectoryKind kind, List<ContactEntry> entries) {
    switch (kind) {
      case DirectoryKind.sdis:
        return copyWith(sdisCenters: entries);
      case DirectoryKind.collectivite:
        return copyWith(collectivities: entries);
    }
  }

  List<String> presetsOf(PresetList list) {
    switch (list) {
      case PresetList.brands:
        return brandPresets;
      case PresetList.models:
        return modelPresets;
      case PresetList.types:
        return typePresets;
      case PresetList.diameters:
        return diameterPresets;
      case PresetList.observations:
        return observationPresets;
    }
  }

  AppSettings withPresets(PresetList list, List<String> values) {
    switch (list) {
      case PresetList.brands:
        return copyWith(brandPresets: values);
      case PresetList.models:
        return copyWith(modelPresets: values);
      case PresetList.types:
        return copyWith(typePresets: values);
      case PresetList.diameters:
        return copyWith(diameterPresets: values);
      case PresetList.observations:
        return copyWith(observationPresets: values);
    }
  }

  /// Les reglages livres avec l'application.
  ///
  /// Les deux societes sont la des la premiere ouverture, avec leur logo,
  /// ainsi que les marques et les types que l'on rencontre sur le terrain.
  /// Les repertoires, eux, partent vides : ils se remplissent tournee apres
  /// tournee, et chaque entree saisie une fois ne l'est plus jamais.
  static AppSettings get defaults => const AppSettings(
        companies: Company.bundled,
        defaultCompanyId: Company.ter2eauxId,
        brandPresets: <String>[
          'BAYARD',
          'PONT-A-MOUSSON',
          'AVK',
          'SAINT-GOBAIN',
          'SAPPEL',
          'HYDRANT',
        ],
        modelPresets: <String>[
          'EMERAUDE',
          'RUBIS',
          'SAPHIR',
          'TOPAZE',
          'DIAMANT',
        ],
        typePresets: <String>[
          'ECS4',
          'PI 100',
          'PI 150',
          'BI 100',
          'PIBI 100',
          'Poteau relais',
        ],
        diameterPresets: <String>[
          'DN 80',
          'DN 100',
          'DN 125',
          'DN 150',
          'DN 200',
        ],
        observationPresets: <String>[
          'R.A.S.',
          'Bouchons à revisser',
          'Peinture à reprendre',
          'Fuite au capot',
          'Appareil difficile à manœuvrer',
          'Végétation à dégager autour du poteau',
          'Signalisation à remettre en place',
          'Débit insuffisant, à signaler au SDISS',
        ],
      );

  AppSettings copyWith({
    List<Company>? companies,
    String? defaultCompanyId,
    List<ContactEntry>? sdisCenters,
    List<ContactEntry>? collectivities,
    List<String>? brandPresets,
    List<String>? modelPresets,
    List<String>? typePresets,
    List<String>? diameterPresets,
    List<String>? observationPresets,
    String? orderNumberPrefix,
  }) {
    return AppSettings(
      companies: companies ?? this.companies,
      defaultCompanyId: defaultCompanyId ?? this.defaultCompanyId,
      sdisCenters: sdisCenters ?? this.sdisCenters,
      collectivities: collectivities ?? this.collectivities,
      brandPresets: brandPresets ?? this.brandPresets,
      modelPresets: modelPresets ?? this.modelPresets,
      typePresets: typePresets ?? this.typePresets,
      diameterPresets: diameterPresets ?? this.diameterPresets,
      observationPresets: observationPresets ?? this.observationPresets,
      orderNumberPrefix: orderNumberPrefix ?? this.orderNumberPrefix,
    );
  }

  Map<String, dynamic> toJson() => {
        'companies': companies.map((company) => company.toJson()).toList(),
        'defaultCompanyId': defaultCompanyId,
        'sdisCenters': sdisCenters.map((entry) => entry.toJson()).toList(),
        'collectivities':
            collectivities.map((entry) => entry.toJson()).toList(),
        'brandPresets': brandPresets,
        'modelPresets': modelPresets,
        'typePresets': typePresets,
        'diameterPresets': diameterPresets,
        'observationPresets': observationPresets,
        'orderNumberPrefix': orderNumberPrefix,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        (json[key] as List<dynamic>? ?? const <dynamic>[])
            .map((value) => value.toString())
            .toList();

    List<ContactEntry> contacts(String key) =>
        (json[key] as List<dynamic>? ?? const <dynamic>[])
            .map((value) =>
                ContactEntry.fromJson(value as Map<String, dynamic>))
            .toList();

    final companies = (json['companies'] as List<dynamic>? ?? const <dynamic>[])
        .map((value) => Company.fromJson(value as Map<String, dynamic>))
        .toList();

    return AppSettings(
      // Une installation dont les societes auraient disparu du fichier
      // repartirait sinon sans aucun choix a la creation d'une fiche.
      companies: companies.isEmpty ? Company.bundled : companies,
      defaultCompanyId:
          json['defaultCompanyId'] as String? ?? Company.ter2eauxId,
      sdisCenters: contacts('sdisCenters'),
      collectivities: contacts('collectivities'),
      brandPresets: strings('brandPresets'),
      modelPresets: strings('modelPresets'),
      typePresets: strings('typePresets'),
      diameterPresets: strings('diameterPresets'),
      observationPresets: strings('observationPresets'),
      orderNumberPrefix: json['orderNumberPrefix'] as String? ?? '',
    );
  }
}

/// Les listes de choix rapides configurables dans les reglages.
enum PresetList {
  brands('Marques'),
  models('Modèles'),
  types('Types'),
  diameters('Diamètres de canalisation'),
  observations('Observations types');

  const PresetList(this.label);

  final String label;
}
