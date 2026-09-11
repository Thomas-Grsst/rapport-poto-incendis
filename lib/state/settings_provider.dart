import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/company.dart';
import '../models/contact_entry.dart';
import '../models/enums.dart';
import '../services/storage_service.dart';

/// Detient les reglages — societes, repertoires, listes de choix — et les
/// persiste dans settings.json.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage);

  static const String _fileName = 'settings.json';
  static const Uuid _uuid = Uuid();

  final StorageService _storage;

  AppSettings _settings = AppSettings.defaults;
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _loaded;

  List<Company> get companies => _settings.companies;

  /// La societe d'une fiche, ou celle par defaut.
  Company companyFor(String? id) => _settings.companyFor(id);

  Future<void> load() async {
    final json = await _storage.readJson(_fileName);
    if (json != null) {
      _settings = AppSettings.fromJson(json);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _storage.writeJson(_fileName, settings.toJson());
  }

  // --- Societes -------------------------------------------------------------

  Future<void> updateCompany(Company company) {
    final next = _settings.companies
        .map((item) => item.id == company.id ? company : item)
        .toList();
    return update(_settings.copyWith(companies: next));
  }

  Future<void> setDefaultCompany(String id) =>
      update(_settings.copyWith(defaultCompanyId: id));

  /// Remplace le logo d'une societe par le fichier choisi, en supprimant
  /// l'ancien pour ne pas laisser de fichiers orphelins sur le telephone.
  Future<void> setLogo(String companyId, String sourcePath) async {
    final company = _settings.companyById(companyId);
    if (company == null) return;

    final imported = await _storage.importMedia(sourcePath, prefix: 'logo');
    final previous = company.logoPath;
    await updateCompany(company.copyWith(logoPath: imported));
    if (previous != imported) {
      await _storage.deleteFileIfExists(previous);
    }
  }

  /// Revient au logo livre avec l'application.
  Future<void> removeLogo(String companyId) async {
    final company = _settings.companyById(companyId);
    if (company == null) return;

    final previous = company.logoPath;
    await updateCompany(company.copyWith(clearLogo: true));
    await _storage.deleteFileIfExists(previous);
  }

  // --- Repertoires ----------------------------------------------------------

  List<ContactEntry> directory(DirectoryKind kind) =>
      _settings.directory(kind);

  /// Enregistre une entree du repertoire — ajout si elle est nouvelle,
  /// remplacement sinon — et renvoie l'entree telle qu'elle a ete rangee.
  ///
  /// C'est le seul point d'entree : l'assistant de saisie s'en sert pour
  /// memoriser une mairie decouverte sur le terrain, et les reglages pour
  /// corriger un numero de telephone. Les deux doivent aboutir au meme
  /// endroit, sans doublon.
  Future<ContactEntry> saveContact(
    DirectoryKind kind,
    ContactEntry entry,
  ) async {
    final stored = entry.id.isEmpty ? entry.copyWith(id: _uuid.v4()) : entry;
    final entries = [..._settings.directory(kind)];
    final index = entries.indexWhere((item) => item.id == stored.id);
    if (index >= 0) {
      entries[index] = stored;
    } else {
      entries.add(stored);
    }
    entries.sort((a, b) => a.displayLine
        .toLowerCase()
        .compareTo(b.displayLine.toLowerCase()));

    await update(_settings.withDirectory(kind, entries));
    return stored;
  }

  Future<void> removeContact(DirectoryKind kind, String id) {
    final entries = _settings
        .directory(kind)
        .where((entry) => entry.id != id)
        .toList();
    return update(_settings.withDirectory(kind, entries));
  }

  /// Un identifiant tout neuf, pour une entree de repertoire en cours de
  /// saisie qui n'a pas encore ete enregistree.
  String newContactId() => _uuid.v4();

  // --- Listes de choix rapides ----------------------------------------------

  List<String> presetsOf(PresetList list) => _settings.presetsOf(list);

  /// Ajoute une valeur a une liste si elle n'y est pas deja.
  ///
  /// Appele quand l'intervenant saisit une marque ou un type qui n'etait pas
  /// propose : la valeur devient disponible pour les fiches suivantes.
  Future<void> rememberPreset(PresetList list, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final current = _settings.presetsOf(list);
    if (current.any((item) => item.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    await update(_settings.withPresets(list, [...current, trimmed]));
  }

  Future<void> replacePresets(PresetList list, List<String> values) =>
      update(_settings.withPresets(list, values));
}
