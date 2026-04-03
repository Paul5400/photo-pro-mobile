import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/gallery.dart';

class ApiService {
  // - gateway.frontoffice (Public / Clients) -> Port 8080
  // - gateway.backoffice  (Photographes / Upload) -> Port 8081

  String get publicBaseUrl =>
      dotenv.get('PUBLIC_API_URL', fallback: 'http://localhost:8080');
  String get authBaseUrl =>
      dotenv.get('AUTH_API_URL', fallback: 'http://localhost:8081');

  /// Récupère la liste des galeries publiques (Frontoffice)
  Future<List<Gallery>> fetchPublicGalleries() async {
    try {
      final response = await http.get(Uri.parse('$publicBaseUrl/galeries'));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is Map && data.containsKey('galeries')) {
          return (data['galeries'] as List)
              .map((item) => Gallery.fromJson(item))
              .toList();
        }
        if (data is List) {
          return data.map((item) => Gallery.fromJson(item)).toList();
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      print("Erreur fetchPublicGalleries: $e");
      return [];
    }
  }

  /// Récupère une galerie spécifique via son ID (Frontoffice)
  Future<Gallery> fetchPrivateGallery(String id) async {
    try {
      final response = await http.get(Uri.parse('$publicBaseUrl/galeries/$id'));

      if (response.statusCode == 200) {
        return Gallery.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception("Galerie introuvable");
      } else {
        throw Exception("Erreur lors de l'accès à la galerie");
      }
    } catch (e) {
      throw Exception("Serveur inaccessible : $e");
    }
  }

  /// Option A : Ajouter un commentaire (Frontoffice)
  Future<void> addComment(String galleryId, String photoId, String text) async {
    final response = await http.post(
      Uri.parse(
        '$publicBaseUrl/galeries/$galleryId/photos/$photoId/commentaires',
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode != 201) {
      throw Exception("Erreur lors de l'ajout du commentaire");
    }
  }

  /// Login du photographe (Backoffice)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$authBaseUrl/auth/login/photographe'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print("DEBUG API - URL: $authBaseUrl/auth/login/photographe");
      print("DEBUG API - Status: ${response.statusCode}");
      print("DEBUG API - Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.body.contains('<!doctype html>')) {
        throw Exception(
          "Le serveur a renvoyé une page HTML (Erreur 404 ou 500 PHP). Vérifiez l'URL du backend.",
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Erreurs identifiants");
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception(
          "Le serveur n'a pas renvoyé de JSON valide. Vérifiez l'URL et le backend.",
        );
      }
      throw Exception("Erreur d'authentification : $e");
    }
  }

  /// Option B : Upload de photo (Backoffice)
  Future<void> uploadPhoto(String filePath, String token) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$authBaseUrl/photos'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));

      var response = await request.send();
      if (response.statusCode != 201) {
        throw Exception("Échec de l'upload");
      }
    } catch (e) {
      throw Exception("Erreur lors de l'upload : $e");
    }
  }
}
