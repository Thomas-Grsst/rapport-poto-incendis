/// Une societe qui edite des fiches.
///
/// L'application en connait plusieurs — Ter2eaux et Rezeau —, et l'on choisit
/// laquelle au moment de creer une fiche : c'est son logo qui s'imprime en
/// tete de la page et ses mentions legales en pied.
class Company {
  const Company({
    required this.id,
    this.legalForm = '',
    this.name = '',
    this.addressLine = '',
    this.postalCode = '',
    this.city = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.siret = '',
    this.ape = '',
    this.rcs = '',
    this.vatNumber = '',
    this.capital = '',
    this.logoPath,
    this.logoAsset,
  });

  /// Identifiant stable, garde dans la fiche : "ter2eaux", "rezeau".
  ///
  /// C'est lui qui relie une fiche a sa societe, et non le nom : renommer
  /// « Ter2eaux » en « Ter2eaux SAS » ne doit pas orpheliner deux ans de
  /// fiches.
  final String id;

  final String legalForm;
  final String name;
  final String addressLine;
  final String postalCode;
  final String city;
  final String phone;
  final String email;
  final String website;

  // --- Mentions legales -----------------------------------------------------
  //
  // Imprimees en pied de la fiche.

  final String siret;
  final String ape;
  final String rcs;
  final String vatNumber;

  /// Capital social, ex. "2 000,00 €".
  final String capital;

  /// Chemin local du logo choisi dans les reglages.
  ///
  /// Null tant qu'aucun n'a ete choisi : [logoAsset], livre avec
  /// l'application, sert alors de valeur par defaut.
  final String? logoPath;

  /// Logo livre avec l'application pour cette societe.
  final String? logoAsset;

  /// "SASU TER2EAUX"
  String get displayName =>
      [legalForm, name].where((part) => part.trim().isNotEmpty).join(' ');

  /// "01600 TREVOUX"
  String get cityLine =>
      [postalCode, city].where((part) => part.trim().isNotEmpty).join(' ');

  /// "164, Route de Lyon - 01600 TREVOUX"
  String get addressOneLine => [addressLine, cityLine]
      .where((part) => part.trim().isNotEmpty)
      .join(' - ');

  /// Coordonnees de la societe, sur une ligne.
  String get contactLine {
    final parts = <String>[
      if (displayName.isNotEmpty) displayName,
      if (addressOneLine.isNotEmpty) addressOneLine,
      if (phone.isNotEmpty) 'Tél. : $phone',
      if (email.isNotEmpty) 'Mail : $email',
    ];
    return parts.join('  -  ');
  }

  /// Coordonnees de l'en-tete de la fiche, une information par ligne.
  List<String> get contactLines => <String>[
        if (addressOneLine.isNotEmpty) addressOneLine,
        if (phone.isNotEmpty) 'Tél. : $phone',
        if (email.isNotEmpty) 'Mail : $email',
        if (website.isNotEmpty) website,
      ];

  /// Mentions legales imprimees en pied de page.
  ///
  /// Retombe sur les coordonnees tant qu'aucune mention n'est renseignee :
  /// un pied de page vide ferait plus mauvais effet qu'une adresse repetee.
  String get legalLine {
    final parts = <String>[
      if (displayName.isNotEmpty) displayName,
      if (siret.trim().isNotEmpty) 'SIRET : ${siret.trim()}',
      if (ape.trim().isNotEmpty) 'APE : ${ape.trim()}',
      if (rcs.trim().isNotEmpty) 'RCS ${rcs.trim()}',
      if (vatNumber.trim().isNotEmpty) 'N° TVA intracom : ${vatNumber.trim()}',
      if (capital.trim().isNotEmpty) 'Capital : ${capital.trim()}',
    ];
    return parts.length <= 1 ? contactLine : parts.join(' - ');
  }

  /// Vrai tant que la societe n'a pas d'adresse : la fiche sortirait alors
  /// sans en-tete ni mentions legales, et on ne s'en apercevrait qu'une fois
  /// le PDF envoye.
  bool get needsSetup => addressOneLine.trim().isEmpty;

  Company copyWith({
    String? id,
    String? legalForm,
    String? name,
    String? addressLine,
    String? postalCode,
    String? city,
    String? phone,
    String? email,
    String? website,
    String? siret,
    String? ape,
    String? rcs,
    String? vatNumber,
    String? capital,
    String? logoPath,
    String? logoAsset,
    bool clearLogo = false,
  }) {
    return Company(
      id: id ?? this.id,
      legalForm: legalForm ?? this.legalForm,
      name: name ?? this.name,
      addressLine: addressLine ?? this.addressLine,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      siret: siret ?? this.siret,
      ape: ape ?? this.ape,
      rcs: rcs ?? this.rcs,
      vatNumber: vatNumber ?? this.vatNumber,
      capital: capital ?? this.capital,
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
      logoAsset: logoAsset ?? this.logoAsset,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'legalForm': legalForm,
        'name': name,
        'addressLine': addressLine,
        'postalCode': postalCode,
        'city': city,
        'phone': phone,
        'email': email,
        'website': website,
        'siret': siret,
        'ape': ape,
        'rcs': rcs,
        'vatNumber': vatNumber,
        'capital': capital,
        'logoPath': logoPath,
        'logoAsset': logoAsset,
      };

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String? ?? 'ter2eaux',
      legalForm: json['legalForm'] as String? ?? '',
      name: json['name'] as String? ?? '',
      addressLine: json['addressLine'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      website: json['website'] as String? ?? '',
      siret: json['siret'] as String? ?? '',
      ape: json['ape'] as String? ?? '',
      rcs: json['rcs'] as String? ?? '',
      vatNumber: json['vatNumber'] as String? ?? '',
      capital: json['capital'] as String? ?? '',
      logoPath: json['logoPath'] as String?,
      logoAsset: json['logoAsset'] as String?,
    );
  }

  // --- Les deux societes livrees avec l'application -------------------------

  static const String ter2eauxId = 'ter2eaux';
  static const String rezeauId = 'rezeau';

  /// Ter'2eaux et Rezeau, telles qu'elles sont proposees a la creation d'une
  /// fiche.
  ///
  /// Les mentions legales viennent du registre du commerce, pas d'une
  /// approximation : une fiche qui sortirait avec un faux SIRET serait pire
  /// qu'une fiche sans. Ce qui n'a pas ete trouve reste vide, et se saisit
  /// dans Réglages → Sociétés.
  ///
  /// Les numeros de TVA se deduisent du SIREN par la regle publiee —
  /// FR, puis (12 + 3 × (SIREN modulo 97)) modulo 97, puis le SIREN.
  static const List<Company> bundled = <Company>[
    Company(
      id: ter2eauxId,
      legalForm: 'SAS',
      name: "TER'2EAUX",
      addressLine: 'Allée des Tanneurs',
      postalCode: '01600',
      city: 'TREVOUX',
      website: 'www.ter2eaux.fr',
      siret: '95071699300015',
      ape: '7112B',
      rcs: 'BOURG EN BRESSE 950 716 993',
      vatNumber: 'FR45950716993',
      capital: '5 000,00 €',
      logoAsset: 'assets/images/logo-ter2eaux.png',
    ),
    Company(
      id: rezeauId,
      legalForm: 'SAS',
      name: 'REZEAU',
      addressLine: '2140, Route de Charnay',
      postalCode: '69480',
      city: 'MORANCE',
      phone: '04 78 22 41 42',
      email: 'contact@rezeau.fr',
      website: 'www.rezeau.fr',
      siret: '84510281300027',
      ape: '7120B',
      rcs: 'VILLEFRANCHE-TARARE 845 102 813',
      vatNumber: 'FR51845102813',
      capital: '10 000,00 €',
      logoAsset: 'assets/images/logo-rezeau.png',
    ),
  ];
}
