import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_converter/image_converter_ui.dart';
import 'package:image_converter/image_converter_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A real 1x1 PNG so Image.memory can decode it in tests.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

class _FakePlatform
    with MockPlatformInterfaceMixin
    implements ImageConverterPlatform {
  Object? failWith;

  @override
  Future<Uint8List> imagesToPdf(
    List<Uint8List> images, {
    PdfPageSize? pageSize,
    double margin = 0,
  }) async {
    if (failWith != null) throw failWith!;
    return Uint8List(2048);
  }

  @override
  Future<List<Uint8List>> pdfToImages(
    Uint8List pdf, {
    double dpi = 144,
    ImageFormat format = ImageFormat.png,
    int quality = 90,
    List<int>? pages,
  }) async {
    if (failWith != null) throw failWith!;
    return [_png, _png, _png];
  }

  @override
  Future<int> pdfPageCount(Uint8List pdf) async => 3;
}

Widget _app(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme,
  home: Scaffold(body: child),
);

ImageConverterThemeData _resolved(WidgetTester tester, Type of) =>
    ImageConverterTheme.of(tester.element(find.byType(of)));

void main() {
  late _FakePlatform fake;
  setUp(() => ImageConverterPlatform.instance = fake = _FakePlatform());

  group('ImageConverterThemeData', () {
    test('merge: non-null fields of other win', () {
      const a = ImageConverterThemeData(primaryColor: Colors.red, spacing: 4);
      const b = ImageConverterThemeData(spacing: 8);
      final m = a.merge(b);
      expect(m.primaryColor, Colors.red);
      expect(m.spacing, 8);
    });

    test('lerp interpolates numbers and colours', () {
      const a = ImageConverterThemeData(spacing: 0, primaryColor: Colors.black);
      const b = ImageConverterThemeData(
        spacing: 10,
        primaryColor: Colors.white,
      );
      final mid = a.lerp(b, 0.5);
      expect(mid.spacing, 5);
      expect(mid.primaryColor, Color.lerp(Colors.black, Colors.white, 0.5));
    });

    test('equality', () {
      expect(
        const ImageConverterThemeData(spacing: 3),
        const ImageConverterThemeData(spacing: 3),
      );
      expect(
        const ImageConverterThemeData(spacing: 3),
        isNot(const ImageConverterThemeData(spacing: 4)),
      );
    });

    testWidgets('resolution order: local > extension > defaults', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            extensions: const [
              ImageConverterThemeData(
                primaryColor: Colors.green,
                spacing: 20,
                borderWidth: 3,
              ),
            ],
          ),
          const ImageConverterTheme(
            data: ImageConverterThemeData(spacing: 30),
            child: ImageConverterTheme(
              data: ImageConverterThemeData(borderWidth: 7),
              child: SizedBox(),
            ),
          ),
        ),
      );
      final t = _resolved(tester, SizedBox);
      expect(t.primaryColor, Colors.green); // extension
      expect(t.spacing, 30); // outer local theme
      expect(t.borderWidth, 7); // inner local theme
      expect(t.iconSize, 20); // default
      expect(t.labels, isNotNull);
    });
  });

  group('widgets', () {
    testWidgets('ConverterButton uses theme, then per-widget overrides', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const ImageConverterTheme(
            data: ImageConverterThemeData(
              primaryColor: Colors.orange,
              onPrimaryColor: Colors.black,
            ),
            child: Column(
              children: [
                ConverterButton(label: 'themed', onPressed: _noop),
                ConverterButton(
                  label: 'override',
                  onPressed: _noop,
                  backgroundColor: Colors.purple,
                ),
              ],
            ),
          ),
        ),
      );
      Color? bg(String label) => tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(FilledButton),
            ),
          )
          .style!
          .backgroundColor!
          .resolve({});
      expect(bg('themed'), Colors.orange);
      expect(bg('override'), Colors.purple);
    });

    testWidgets('ConverterButton loading shows spinner and is disabled', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          ConverterButton(
            label: 'go',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('go'));
      expect(taps, 0);
    });

    testWidgets('ConversionStatusBanner colours follow type', (tester) async {
      await tester.pumpWidget(
        _app(
          const ImageConverterTheme(
            data: ImageConverterThemeData(
              errorContainerColor: Colors.pink,
              errorIcon: Icons.warning,
            ),
            child: ConversionStatusBanner(
              message: 'bad',
              type: StatusType.error,
            ),
          ),
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(ConversionStatusBanner),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((box.decoration as BoxDecoration).color, Colors.pink);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('PdfPageGallery: labels, custom item and empty builders', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ImageConverterTheme(
            data: ImageConverterThemeData(
              labels: ImageConverterLabels(page: (n) => 'Seite $n'),
            ),
            child: PdfPageGallery(pages: [_png, _png]),
          ),
        ),
      );
      expect(find.text('Seite 1'), findsOneWidget);
      expect(find.text('Seite 2'), findsOneWidget);

      await tester.pumpWidget(
        _app(
          PdfPageGallery(
            pages: [_png],
            layout: PdfGalleryLayout.grid,
            itemBuilder: (_, i, _) => Text('custom $i'),
          ),
        ),
      );
      expect(find.text('custom 0'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);

      await tester.pumpWidget(
        _app(
          PdfPageGallery(
            pages: const [],
            emptyBuilder: (_) => const Text('nothing'),
          ),
        ),
      );
      expect(find.text('nothing'), findsOneWidget);
    });
  });

  group('ImageConverterView', () {
    testWidgets('only shows buttons whose pick callback is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(ImageConverterView(onPickPdf: () async => Uint8List(1))),
      );
      expect(find.text('PDF → Images'), findsOneWidget);
      expect(find.text('Images → PDF'), findsNothing);
    });

    testWidgets('images -> pdf: status, gallery and callback', (tester) async {
      Uint8List? created;
      await tester.pumpWidget(
        _app(
          ImageConverterView(
            onPickImages: () async => [_png],
            onPdfCreated: (pdf) => created = pdf,
          ),
        ),
      );
      expect(find.text('Converted pages will appear here'), findsOneWidget);

      await tester.tap(find.text('Images → PDF'));
      await tester.pumpAndSettle();

      expect(created, hasLength(2048));
      expect(find.text('Created a 3-page PDF (2 KB)'), findsOneWidget);
      expect(find.byType(PdfPagePreview), findsWidgets);
    });

    testWidgets('errors show banner and call onError', (tester) async {
      fake.failWith = PlatformException(code: 'INVALID_PDF', message: 'nope');
      Object? error;
      await tester.pumpWidget(
        _app(
          ImageConverterView(
            onPickPdf: () async => Uint8List(1),
            onError: (e) => error = e,
          ),
        ),
      );
      await tester.tap(find.text('PDF → Images'));
      await tester.pumpAndSettle();

      expect(error, isA<PlatformException>());
      expect(
        find.text('Conversion failed (INVALID_PDF): nope'),
        findsOneWidget,
      );
    });

    testWidgets('cancelled pick does nothing', (tester) async {
      final controller = ImageConverterController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          ImageConverterView(
            controller: controller,
            onPickImages: () async => null,
          ),
        ),
      );
      await tester.tap(find.text('Images → PDF'));
      await tester.pumpAndSettle();
      expect(controller.state, ConversionState.idle);
    });

    testWidgets('theme param, labels and section builders', (tester) async {
      await tester.pumpWidget(
        _app(
          ImageConverterView(
            onPickImages: () async => [_png],
            theme: const ImageConverterThemeData(
              backgroundColor: Colors.amber,
              labels: ImageConverterLabels(imagesToPdf: 'Make PDF'),
            ),
            header: const Text('Header'),
            statusBuilder: (_, c) => Text('state: ${c.state.name}'),
            galleryBuilder: (_, c) => Text('${c.pages.length} pages'),
          ),
        ),
      );
      expect(find.text('Header'), findsOneWidget);
      expect(find.text('0 pages'), findsOneWidget);
      final bg = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(ImageConverterView),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(bg.color, Colors.amber);

      await tester.tap(find.text('Make PDF'));
      await tester.pumpAndSettle();
      expect(find.text('state: success'), findsOneWidget);
      expect(find.text('3 pages'), findsOneWidget);
    });

    testWidgets('actionsBuilder can drive the controller', (tester) async {
      await tester.pumpWidget(
        _app(
          ImageConverterView(
            actionsBuilder: (_, c) => TextButton(
              onPressed: () => c.pdfToImages(Uint8List(1)),
              child: const Text('mine'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('mine'));
      await tester.pumpAndSettle();
      expect(find.text('Rendered 3 images'), findsOneWidget);
    });
  });
}

void _noop() {}
