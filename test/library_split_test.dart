import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Walks the relative imports/exports reachable from [entry] and returns
/// every `package:` URI they pull in.
Set<String> _packageImports(String entry) {
  final seen = <String>{};
  final packages = <String>{};
  final directive = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  void visit(File file) {
    if (!seen.add(file.absolute.path)) return;
    for (final m in directive.allMatches(file.readAsStringSync())) {
      final uri = m.group(1)!;
      if (uri.startsWith('dart:')) continue;
      if (uri.startsWith('package:image_converter/')) {
        visit(File('lib/${uri.substring('package:image_converter/'.length)}'));
      } else if (uri.startsWith('package:')) {
        packages.add(uri);
      } else {
        visit(File(file.parent.uri.resolve(uri).toFilePath()));
      }
    }
  }

  visit(File(entry));
  return packages;
}

void main() {
  test('core library has no widget/Material dependency', () {
    final imports = _packageImports('lib/image_converter.dart');
    expect(
      imports.where(
        (u) => RegExp(
          r'package:flutter/(material|widgets|cupertino|rendering|painting)\.dart',
        ).hasMatch(u),
      ),
      isEmpty,
      reason: 'lib/image_converter.dart must stay UI-free; found $imports',
    );
  });

  test('UI library re-exports the core', () {
    expect(
      File('lib/image_converter_ui.dart').readAsStringSync(),
      contains("export 'image_converter.dart';"),
    );
  });
}
