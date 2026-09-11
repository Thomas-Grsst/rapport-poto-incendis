import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// L'application tourne aussi dans un navigateur, ou `dart:io` n'existe pas.
///
/// Un seul import oublie suffit a casser la compilation web, et l'erreur
/// n'apparait qu'au moment du build : ce test la fait apparaitre tout de
/// suite. Seules les implementations « io » du stockage et du telechargement
/// ont le droit d'y toucher — elles ne sont choisies qu'a la compilation pour
/// mobile, par import conditionnel.
void main() {
  test('lib/ n’importe pas dart:io en dehors des fichiers mobiles', () {
    const allowed = <String>{
      'lib/services/storage_service_io.dart',
      'lib/services/pdf_download_io.dart',
    };

    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !allowed.contains(file.path.replaceAll(r'\', '/')))
        .where((file) => file.readAsStringSync().contains("import 'dart:io'"))
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
