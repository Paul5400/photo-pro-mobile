import 'package:flutter/foundation.dart';
import '../models/gallery.dart';
import '../services/api_service.dart';

class GalleryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Gallery> _publicGalleries = [];
  Gallery? _currentPrivateGallery;
  bool _isLoading = false;
  String? _errorMessage;

  List<Gallery> get publicGalleries => _publicGalleries;
  Gallery? get currentPrivateGallery => _currentPrivateGallery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
  Future<bool> accessPrivateGallery(String code) async {
    _setLoading(true);
    try {
      _currentPrivateGallery = await _apiService.fetchPrivateGallery(code);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
