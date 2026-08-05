import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/pdf_service.dart';
import '../services/unity_ads_service.dart';

class PdfConverterScreen extends StatefulWidget {
  const PdfConverterScreen({super.key});

  @override
  State<PdfConverterScreen> createState() => _PdfConverterScreenState();
}

class _PdfConverterScreenState extends State<PdfConverterScreen> {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isConverting = false;

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((xfile) => File(xfile.path)));
      });
    }
  }

  Future<void> _convertToPdf() async {
    if (_selectedImages.isEmpty) {
      _showSnackBar('Please select at least one image');
      return;
    }

    setState(() => _isConverting = true);

    await UnityAdsService.showInterstitialAd(
      onComplete: () async => await _generatePdf(),
      onFailed: () async => await _generatePdf(),
    );
  }

  Future<void> _generatePdf() async {
    try {
      final paths = _selectedImages.map((f) => f.path).toList();
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
        content: const Text('Your PDF has been generated successfully.'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _removeImage(int index) => setState(() => _selectedImages.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image to PDF'),
        actions: [
          if (_selectedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () => setState(() => _selectedImages.clear()),
            ),
        ],
      ),
      body: _selectedImages.isEmpty ? _buildEmptyState() : _buildImageGrid(),
      floatingActionButton: _selectedImages.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isConverting ? null : _convertToPdf,
              icon: _isConverting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isConverting ? 'Converting...' : 'Convert to PDF'),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No images selected',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Select Images'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImages[index], fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add),
            label: const Text('Add More Images'),
          ),
        ),
      ],
    );
  }
}
