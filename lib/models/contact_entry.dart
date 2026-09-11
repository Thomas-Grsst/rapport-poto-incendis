/// Des coordonnees enregistrees une fois puis choisies dans une liste.
///
/// Le meme type sert aux centres du SDISS et aux collectivites : les deux
/// cadres de la fiche portent les memes rubriques — une adresse principale,
/// un telephone, un fax, un portable — et rien ne justifie deux modeles
/// jumeaux.
///
/// Une fiche en garde une **copie** plutot qu'un renvoi vers le repertoire :
/// une fiche editee reste le reflet de ce qui etait connu le jour du
/// controle, et un changement de numero a la mairie ne recrit pas les fiches
/// des annees precedentes. L'[id] dit seulement de quelle entree du
/// repertoire la copie provient, pour proposer la mise a jour le jour ou
/// l'on refait une fiche au meme endroit.
class ContactEntry {
  const ContactEntry({
    required this.id,
    this.name = '',
    this.addressLine = '',
    this.postalCode = '',
    this.city = '',
    this.phone = '',
    this.fax = '',
    this.mobile = '',
  });

  final String id;

  /// "Mairie de Saint Rémy", "Centre de secours de Bourg-en-Bresse".
  final String name;

  /// "999, route de St Rémy"
  final String addressLine;

  final String postalCode;
  final String city;

  final String phone;
  final String fax;

  /// Le portable de l'agent d'astreinte : la ligne « Port : » de la fiche.
  final String mobile;

  /// "01310 SAINT-REMY"
  String get cityLine =>
      [postalCode, city].where((part) => part.trim().isNotEmpty).join(' ');

  /// Les lignes imprimees dans la case « ADRESSE PRINCIPALE ».
  ///
  /// Le nom passe en premier quand il est renseigne : sur le modele papier,
  /// la case de la collectivite s'ouvre sur « Mairie de Saint Rémy », celle
  /// du centre de secours directement sur la rue.
  List<String> get addressLines => <String>[
        if (name.trim().isNotEmpty) name.trim(),
        if (addressLine.trim().isNotEmpty) addressLine.trim(),
        if (cityLine.isNotEmpty) cityLine,
      ];

  /// De quoi reconnaitre l'entree dans une liste deroulante.
  String get displayLine {
    final title = name.trim().isNotEmpty ? name.trim() : addressLine.trim();
    final place = cityLine;
    if (title.isEmpty) return place;
    if (place.isEmpty || title.toUpperCase().contains(city.toUpperCase())) {
      return title;
    }
    return '$title — $place';
  }

  bool get isEmpty => addressLines.isEmpty && phone.trim().isEmpty;

  ContactEntry copyWith({
    String? id,
    String? name,
    String? addressLine,
    String? postalCode,
    String? city,
    String? phone,
    String? fax,
    String? mobile,
  }) {
    return ContactEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      addressLine: addressLine ?? this.addressLine,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      fax: fax ?? this.fax,
      mobile: mobile ?? this.mobile,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'addressLine': addressLine,
        'postalCode': postalCode,
        'city': city,
        'phone': phone,
        'fax': fax,
        'mobile': mobile,
      };

  factory ContactEntry.fromJson(Map<String, dynamic> json) => ContactEntry(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        addressLine: json['addressLine'] as String? ?? '',
        postalCode: json['postalCode'] as String? ?? '',
        city: json['city'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        fax: json['fax'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
      );
}
