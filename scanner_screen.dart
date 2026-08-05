import 'dart:io';
import 'package:flutter/material.dart';
import 'package:edge_detection/edge_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/pdf_service.dart';
import '../services/unity_ads_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final List<File> _scannedImages = [];
  bool _isScanning = false;
  bool _isConverting = false;

  Future<void> _scanDocument() async {
    bool isCameraGranted = await Permission.camera.request().isGranted;
    if (!isCameraGranted) {
      _showSnackBar('Camera permission is required');
      return;
    }

    setState(() => _isScanning = true);

    try {
      String imagePath = '${(await getApplicationSupportDirectory()).path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpeg';

      bool success = await EdgeDetection.detectEdge(
        imagePath,
        canUseGallery: true,
        androidScanTitle: 'Scanning',
        androidCropTitle: 'Crop',
        androidCropBlackWhiteTitle: 'Black White',
        androidCropReset: 'Reset',
      );

      if (success && await File(imagePath).exists()) {
        setState(() => _scannedImages.add(File(imagePath)));
      }
    } catch (e) {
      _showSnackBar('Scan failed: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _convertToPdf() async {
    if (_scannedImages.isEmpty) return;
    setState(() => _isConverting = true);

    await UnityAdsService.showInterstitialAd(
      onComplete: () async => await _generatePdf(),
      onFailed: () async => await _generatePdf(),
    );
  }

  Future<void> _generatePdf() async {
    try {
      final paths = _scannedImages.map((f) => f.path).toList();
      final pdfPath = await PdfService.createPdfFromImages(paths);
      setState(() => _isConverting = false);
      if (mounted) _showPdfReadyDialog(pdfPath);
    } catch (e) {
      setState(() => _isConverting = false);
      if (mounted) _showSnackBar('Error: $e');
    }
  }

  void _showPdfReadyDialog(String pdfPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Created!'),
        content: const Text('Your scanned document has been saved as PDF.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              PdfService.sharePdf(pdfPath);
              Navigator.pop(context);
            },
            child: const Text('Share PDF'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner'),
        actions: [
          if (_scannedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () => setState(() => _scannedImages.clear()),
            ),
        ],
      ),
      body: _scannedImages.isEmpty ? _buildEmptyState() : _buildScannedList(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_scannedImages.isNotEmpty)
            FloatingActionButton.extended(
              heroTag: 'convert',
              onPressed: _isConverting ? null : _convertToPdf,
              backgroundColor: Colors.deepPurple,
              icon: _isConverting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isConverting ? 'Converting...' : 'Convert to PDF'),
            ),
          if (_scannedImages.isNotEmpty) const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'scan',
            onPressed: _isScanning ? null : _scanDocument,
            child: _isScanning
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.document_scanner, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No scanned documents',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _scanDocument,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan Document'),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedList() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _scannedImages.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_scannedImages[index], fit: BoxFit.cover),
        );
      },
    );
  }
}
