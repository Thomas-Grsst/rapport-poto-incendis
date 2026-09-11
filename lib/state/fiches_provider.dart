import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/enums.dart';
import '../models/fiche_pi.dart';
import '../models/photo_item.dart';
import '../services/storage_service.dart';

/// Filtres proposes en haut de la liste des fiches.
///
/// Ils repondent a la question que se pose un service des eaux devant sa
/// tournee : que reste-t-il a faire, et qu'ai-je trouve de casse ?
enum FicheFilter {
  toutes('Toutes'),
  aTerminer('À terminer'),
  aSuivre('À suivre'),
  conformes('Conformes');

  const FicheFilter(this.label);

  final String label;

  bool matches(FichePi fiche) {
    switch (this) {
      case FicheFilter.toutes:
        return true;
      case FicheFilter.aTerminer:
        return fiche.status == FicheStatus.brouillon;
      case FicheFilter.aSuivre:
        return fiche.status == FicheStatus.aSuivre ||
            fiche.status == FicheStatus.indisponible;
      case FicheFilter.conformes:
        return fiche.status == FicheStatus.conforme;
    }
  }
}

/// Detient la liste des fiches et la persiste dans fiches.json.
class FichesProvider extends ChangeNotifier {
  FichesProvider(this._storage);

  static const String _fileName = 'fiches.json';
  static const Uuid _uuid = Uuid();

  final StorageService _storage;

  final List<FichePi> _fiches = <FichePi>[];
  bool _loaded = false;
  String _query = '';
  FicheFilter _filter = FicheFilter.toutes;

  bool get isLoaded => _loaded;
  String get query => _query;
  FicheFilter get filter => _filter;

  /// Toutes les fiches, de la plus recemment modifiee a la plus ancienne.
  List<FichePi> get all => List.unmodifiable(_fiches);

  /// Les fiches correspondant a la recherche et au filtre en cours.
  List<FichePi> get visible {
    final normalized = _normalize(_query);
    return _fiches.where((fiche) {
      if (!_filter.matches(fiche)) return false;
      if (normalized.isEmpty) return true;
      return _normalize(fiche.searchableText).contains(normalized);
    }).toList();
  }

  int countFor(FicheFilter filter) => _fiches.where(filter.matches).length;

  Future<void> load() async {
    final json = await _storage.readJson(_fileName);
    _fiches.clear();
    if (json != null) {
      final items = json['fiches'] as List<dynamic>? ?? const <dynamic>[];
      _fiches.addAll(
        items.map((item) => FichePi.fromJson(item as Map<String, dynamic>)),
      );
      _sort();
    }
    _loaded = true;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setFilter(FicheFilter value) {
    _filter = value;
    notifyListeners();
  }

  FichePi? byId(String id) {
    for (final fiche in _fiches) {
      if (fiche.id == id) return fiche;
    }
    return null;
  }

  /// Un brouillon pre-rempli : la societe choisie, la date du jour, et une
  /// ligne de controle a l'annee en cours suivie des deux suivantes.
  ///
  /// Les trois lignes sont celles du modele papier : le controle de cette
  /// annee s'ecrit sur la premiere, et les deux autres attendent, imprimees
  /// vides, que quelqu'un repasse.
  FichePi createDraft(AppSettings settings, {required String companyId}) {
    final now = DateTime.now();

    return FichePi(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      companyId: companyId,
      editionDate: now,
      orderNumber: settings.orderNumberPrefix.trim(),
      controls: [
        for (var offset = 0; offset < 3; offset++)
          ControlRow(
            year: '${now.year + offset}',
            date: offset == 0 ? now : null,
          ),
      ],
      status: FicheStatus.brouillon,
    );
  }

  /// Enregistre une fiche (creation ou mise a jour).
  Future<void> save(FichePi fiche) async {
    fiche.updatedAt = DateTime.now();
    final index = _fiches.indexWhere((item) => item.id == fiche.id);
    if (index >= 0) {
      _fiches[index] = fiche;
    } else {
      _fiches.add(fiche);
    }
    _sort();
    notifyListeners();
    await _persist();
  }

  /// Supprime une fiche ainsi que ses photos, pour ne pas saturer le
  /// telephone au fil des tournees.
  Future<void> delete(FichePi fiche) async {
    _fiches.removeWhere((item) => item.id == fiche.id);
    notifyListeners();
    await _persist();

    for (final photo in fiche.photos) {
      await _storage.deleteFileIfExists(photo.filePath);
    }
  }

  /// Duplique une fiche.
  ///
  /// Deux poteaux d'une meme rue partagent tout sauf leur numero et leurs
  /// photos : la copie garde donc les coordonnees, la commune et les
  /// caracteristiques de l'appareil, et repart avec des mesures et des
  /// photos vierges.
  FichePi duplicate(FichePi source) {
    final now = DateTime.now();

    return FichePi.fromJson({
      ...source.clone().toJson(),
      'id': _uuid.v4(),
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'editionDate': now.toIso8601String(),
      'hydrantNumber': '',
      'orderNumber': '',
      'controls': [
        for (var offset = 0; offset < 3; offset++)
          ControlRow(
            year: '${now.year + offset}',
            date: offset == 0 ? now : null,
          ).toJson(),
      ],
      'planPhoto': null,
      'hydrantPhoto': null,
      'environmentPhoto': null,
      'observations': '',
      'status': FicheStatus.brouillon.name,
      'lastPdfPath': null,
    });
  }

  /// Une photo deja importee dans le dossier de l'application.
  PhotoItem buildPhoto(String filePath, PhotoSlot slot) =>
      PhotoItem(id: _uuid.v4(), filePath: filePath, slot: slot);

  /// Le numero d'ordre propose : le prefixe de la tournee, puis le numero de
  /// l'appareil — « 45 » et « 013 » donnent « 45 013 », comme sur le modele.
  ///
  /// Ce n'est qu'une proposition : le champ reste libre sur la fiche, car
  /// toutes les collectivites ne numerotent pas de la meme facon.
  String suggestOrderNumber(FichePi fiche, AppSettings settings) {
    final prefix = settings.orderNumberPrefix.trim();
    final number = fiche.hydrantNumber.trim();
    return [prefix, number].where((part) => part.isNotEmpty).join(' ');
  }

  void _sort() {
    _fiches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _persist() async {
    await _storage.writeJson(_fileName, {
      'version': 1,
      'fiches': _fiches.map((fiche) => fiche.toJson()).toList(),
    });
  }

  /// Recherche insensible a la casse et aux accents : « SAINT-REMY » doit
  /// repondre a « saint remy », et « Trévoux » a « trevoux ».
  static String _normalize(String value) {
    const accents = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿœæ';
    const plain = 'aaaaaceeeeiiiinooooouuuuyyoa';
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final index = accents.indexOf(char);
      buffer.write(index >= 0 ? plain[index] : char);
    }
    return buffer.toString().trim();
  }
}
