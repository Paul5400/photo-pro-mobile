import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gallery.dart';
import '../services/api_service.dart';

class GalleryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Gallery> _publicGalleries = [];
  List<Gallery> _allPhotographerGalleries = [];
  List<Gallery> _unlockedGalleries = [];
  Gallery? _currentPrivateGallery;
  String? _lastPrivateAccessCode;
  bool _isLoading = false;
  String? _errorMessage;

  List<Gallery> get publicGalleries => _publicGalleries;

  /// Retourne les galeries du photographe ET les galeries débloquées par code.
  List<Gallery> get allPhotographerGalleries {
    // On fusionne les listes en évitant les doublons par ID
    final Set<String> ids = _allPhotographerGalleries.map((e) => e.id).toSet();
    final List<Gallery> combined = List.from(_allPhotographerGalleries);

    for (var g in _unlockedGalleries) {
      if (!ids.contains(g.id)) {
        combined.add(g);
        ids.add(g.id);
      }
    }
    return combined;
  }

  Gallery? get currentPrivateGallery => _currentPrivateGallery;
  String? get lastPrivateAccessCode => _lastPrivateAccessCode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  GalleryProvider() {
    _loadUnlockedGalleries();
  }

  /// Charge les galeries débloquées depuis le stockage local.
  Future<void> _loadUnlockedGalleries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? galleriesJson = prefs.getString('unlocked_galleries');
      if (galleriesJson != null) {
        final List<dynamic> list = jsonDecode(galleriesJson);
        _unlockedGalleries = list.map((e) => Gallery.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading unlocked galleries: $e');
    }
  }

  /// Sauvegarde une galerie débloquée en local.
  Future<void> _saveGalleryLocally(Gallery gallery) async {
    // Vérifier si déjà présente
    if (_unlockedGalleries.any((g) => g.id == gallery.id)) return;

    _unlockedGalleries.add(gallery);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String galleriesJson = jsonEncode(
        _unlockedGalleries.map((e) => e.toJson()).toList(),
      );
      await prefs.setString('unlocked_galleries', galleriesJson);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving gallery: $e');
    }
  }

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

      // Sauvegarde dans le profil local pour accès futur dans "Mes galeries"
      await _saveGalleryLocally(galleryById);

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
