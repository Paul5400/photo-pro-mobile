import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/upload_provider.dart';
import '../services/api_service.dart';
import '../models/upload_history.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedImage;
  bool _isUploading = false;
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection : $e')),
      );
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception("Non authentifié");

      final response = await _apiService.uploadPhoto(
        _selectedImage!.path,
        token,
      );

      if (mounted) {
        // Enregistrer dans l'historique
        final uploadItem = UploadHistoryItem(
          id:
              response['photo_id'] ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          filePath: _selectedImage!.path,
          s3Url: response['url'],
          uploadDate: DateTime.now(),
          isSynced: true,
        );
        context.read<UploadProvider>().addToHistory(uploadItem);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo envoyée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedImage = null;
        });
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'envoi : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Envoyer une photo')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child:
                    _selectedImage != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.contain,
                          ),
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune image sélectionnée',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isUploading
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Galerie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[50],
                      foregroundColor: Colors.blueGrey[800],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isUploading
                            ? null
                            : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Caméra'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[50],
                      foregroundColor: Colors.blueGrey[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed:
                    (_selectedImage == null || _isUploading)
                        ? null
                        : _handleUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child:
                    _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'PUBLIER SUR PHOTOPRO',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
