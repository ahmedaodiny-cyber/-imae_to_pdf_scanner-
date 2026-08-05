import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  static Future<String> createPdfFromImages(List<String> imagePaths) async {
    final pdf = pw.Document();

    for (final imagePath in imagePaths) {
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        final image = pw.MemoryImage(await imageFile.readAsBytes());
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }
    }

    final output = await getTemporaryDirectory();
    final file = File('\${output.path}/document_\${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static Future<void> sharePdf(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Here is your PDF document');
  }
}
