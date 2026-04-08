import 'package:flutter/foundation.dart';
import '../models/gallery.dart';
import '../services/api_service.dart';

class GalleryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Gallery> _publicGalleries = [];
  List<Gallery> _allPhotographerGalleries = [];
  Gallery? _currentPrivateGallery;
  String? _lastPrivateAccessCode;
  bool _isLoading = false;
  String? _errorMessage;

  List<Gallery> get publicGalleries => _publicGalleries;
  List<Gallery> get allPhotographerGalleries => _allPhotographerGalleries;
  Gallery? get currentPrivateGallery => _currentPrivateGallery;
  String? get lastPrivateAccessCode => _lastPrivateAccessCode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge TOUTES les galeries pour le photographe.
  Future<void> loadPhotographerGalleries() async {
    _setLoading(true);
    try {
      _allPhotographerGalleries = await _apiService.fetchAllGalleries();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Charge les galeries publiques.
  Future<void> loadPublicGalleries() async {
    _setLoading(true);
    try {
      _publicGalleries = await _apiService.fetchPublicGalleries();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Tente d'accéder à une galerie privée avec un code.
  Future<bool> accessPrivateGallery(String codeOrId) async {
    _setLoading(true);
    try {
      // 1. On tente d'abord de récupérer la galerie en utilisant le code comme ID
      final galleryById = await _apiService.fetchGalleryWithAccess(
        codeOrId,
        code: codeOrId,
      );
      _currentPrivateGallery = galleryById;
      _lastPrivateAccessCode = codeOrId;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      // 2. Si ça échoue, on tente d'utiliser le code comme paramètre de recherche global (si implémenté côté backend)
      // Ou on peut essayer un ID de test connu pour valider la route
      _errorMessage = "Galerie introuvable ou code invalide";
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Réinitialise l'erreur après affichage (Ex: dans une SnackBar).
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
