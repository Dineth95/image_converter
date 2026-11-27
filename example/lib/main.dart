import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_converter/image_converter_ui.dart';

void main() => runApp(const ExampleApp());

/// A fully custom look, applied app-wide as a ThemeData extension.
const brandTheme = ImageConverterThemeData(
  primaryColor: Color(0xFF0F766E),
  onPrimaryColor: Colors.white,
  secondaryColor: Color(0xFFFDE68A),
  onSecondaryColor: Color(0xFF78350F),
  backgroundColor: Color(0xFFF0FDFA),
  progressColor: Color(0xFFF59E0B),
  progressTrackColor: Color(0xFFFDE68A),
  successContainerColor: Color(0xFFCCFBF1),
  successColor: Color(0xFF115E59),
  borderColor: Color(0xFF0F766E),
  borderWidth: 2,
  borderRadius: BorderRadius.all(Radius.circular(4)),
  buttonBorderRadius: BorderRadius.all(Radius.circular(8)),
  buttonTextStyle: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
  pageElevation: 0,
  pagePadding: EdgeInsets.all(6),
  progressHeight: 6,
  spacing: 16,
  imagesToPdfIcon: Icons.note_add_outlined,
  pdfToImagesIcon: Icons.collections_outlined,
  emptyIcon: Icons.auto_awesome_outlined,
  labels: ImageConverterLabels(
    imagesToPdf: 'Make PDF',
    pdfToImages: 'Extract pages',
    empty: 'Pick photos or a PDF to get started',
  ),
);

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool _custom = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        extensions: [if (_custom) brandTheme],
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: _custom ? ThemeMode.light : ThemeMode.system,
      home: ConverterScreen(
        custom: _custom,
        onToggleTheme: (v) => setState(() => _custom = v),
      ),
    );
  }
}

class ConverterScreen extends StatelessWidget {
  const ConverterScreen({
    super.key,
    required this.custom,
    required this.onToggleTheme,
  });

  final bool custom;
  final ValueChanged<bool> onToggleTheme;

  Future<List<Uint8List>?> _pickImages() async {
    final r = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    return r?.files.map((f) => f.bytes).whereType<Uint8List>().toList();
  }

  Future<Uint8List?> _pickPdf() async {
    final r = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    return r?.files.single.bytes;
  }

  Future<void> _savePdf(BuildContext context, Uint8List pdf) async {
    final file = File(
      '${Directory.systemTemp.path}/converted_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(pdf);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Converter'),
        actions: [
          const Text('Custom theme'),
          Switch(value: custom, onChanged: onToggleTheme),
        ],
      ),
      body: ImageConverterView(
        onPickImages: _pickImages,
        onPickPdf: _pickPdf,
        pageSize: PdfPageSize.a4,
        margin: 24,
        pdfDpi: 150,
        galleryLayout: custom ? PdfGalleryLayout.grid : PdfGalleryLayout.list,
        onPdfCreated: (pdf) => _savePdf(context, pdf),
      ),
    );
  }
}
