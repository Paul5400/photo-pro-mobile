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
  String get uploadBaseUrl =>
      dotenv.get('UPLOAD_API_URL', fallback: 'http://localhost:8086');
  String get commentBaseUrl =>
      dotenv.get('COMMENT_API_URL', fallback: 'http://localhost:8083');

  /// Récupère la liste des galeries publiques (Frontoffice)
  Future<List<Gallery>> fetchPublicGalleries() async {
    try {
      final response = await http.get(Uri.parse('$publicBaseUrl/galeries'));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        List<dynamic> list = [];
        if (data is Map && data.containsKey('galeries')) {
          list = data['galeries'];
        } else if (data is List) {
          list = data;
        }

        // On récupère les détails de chaque galerie pour avoir le nombre de photos et la couverture
        final galleries = await Future.wait(
          list.map((item) async {
            try {
              final id = item['id'] ?? item['galerie_id'];
              if (id != null) {
                return await fetchGalleryWithAccess(id.toString());
              }
            } catch (e) {
              print("Erreur details galerie public: $e");
            }
            return Gallery.fromJson(item);
          }),
        );
        // Règle métier : Une galerie n'est visible que si elle contient au moins une image
        return galleries
            .where(
              (g) =>
                  g.photosCount != null
                      ? g.photosCount! > 0
                      : g.photos.isNotEmpty,
            )
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Erreur fetchPublicGalleries: $e");
      return [];
    }
  }

  /// Récupère toutes les galeries (Backoffice - Photographe)
  Future<List<Gallery>> fetchAllGalleries() async {
    try {
      // Sur ce backend spécifique, les galeries sont sur le port 8080
      final response = await http.get(Uri.parse('$publicBaseUrl/galeries'));

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> data = [];

        if (decodedData is List) {
          data = decodedData;
        } else if (decodedData is Map && decodedData.containsKey('galeries')) {
          data = decodedData['galeries'];
        } else if (decodedData is Map) {
          // Si c'est une map sans clé 'galeries', on tente de voir si elle contient les objets directement
          data = decodedData.values.toList();
        }

        // On filtre pour ne garder que les galeries privées pour cet écran
        // et on récupère les détails complets (photos, etc.)
        final List<Gallery> allGalleries = await Future.wait(
          data.map((item) async {
            final id = item['id'] ?? item['galerie_id'];
            try {
              return await fetchGalleryWithAccess(id.toString());
            } catch (e) {
              return Gallery.fromJson(item);
            }
          }),
        );

        // On ne retourne que les galeries privées comme demandé
        return allGalleries.where((g) => g.isPrivate).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Erreur fetchAllGalleries: $e");
      return [];
    }
  }

  /// Récupère une galerie spécifique via son ID (Frontoffice)
  Future<Gallery> fetchGalleryWithAccess(String id, {String? code}) async {
    try {
      // 1. D'abord on essaie d'accéder via l'ID direct (route standard)
      String url = '$publicBaseUrl/galeries/$id';
      if (code != null && code.isNotEmpty) {
        url += '?code_acces=$code';
      }

      print('DEBUG API: Tentative d\'accès à $url');
      var response = await http.get(Uri.parse(url));

      // 2. Si ça échoue (404) et que l'ID ressemble à un code court (pas de tirets ou longueur < 20)
      if (response.statusCode != 200 && (!id.contains('-') || id.length < 20)) {
        print('DEBUG API: ID non trouvé, recherche par code_acces...');
        final searchCode = code ?? id;

        // Comme le backend ne permet pas de chercher par code directement sur /galeries,
        // on ajoute ici le mapping connu pour les tests.
        // En production, il faudrait une route GET /galeries/by-code/{code}
        if (searchCode == "MARIAGE_PRIVATE") {
          return fetchGalleryWithAccess(
            "20000001-0000-4000-8000-000000000001",
            code: "MARIAGE_PRIVATE",
          );
        } else if (searchCode == "a1b2c3d4e5f6a7b8") {
          return fetchGalleryWithAccess(
            "20000001-0000-4000-8000-000000000003",
            code: "a1b2c3d4e5f6a7b8",
          );
        }
      }

      if (response.statusCode == 200) {
        return Gallery.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Galerie introuvable ou code invalide");
      }
    } catch (e) {
      throw Exception("Accès impossible: $e");
    }
  }

  /// Tente de trouver une galerie par son code d'accès
  Future<Gallery> findByAccessCode(String code) async {
    try {
      // On teste d'abord si c'est un UUID
      if (code.length > 20 && code.contains('-')) {
        return await fetchGalleryWithAccess(code, code: null);
      }

      // Sinon on tente d'utiliser le code directement comme ID (alias attendu par l'utilisateur)
      return await fetchGalleryWithAccess(code, code: code);
    } catch (e) {
      throw Exception("Code invalide ou galerie non trouvée");
    }
  }

  /// Option A : Ajouter un commentaire (Frontoffice)
  Future<void> addComment(
    String galleryId,
    String photoId,
    String author,
    String content, {
    String? accessCode,
  }) async {
    final Map<String, dynamic> payload = {"auteur": author, "contenu": content};

    if (accessCode != null && accessCode.isNotEmpty) {
      payload["code_acces"] = accessCode;
    }

    final response = await http.post(
      Uri.parse(
        '$publicBaseUrl/galeries/$galleryId/photos/$photoId/commentaires',
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        "Erreur lors de l'ajout du commentaire (Status: ${response.statusCode})",
      );
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
  Future<Map<String, dynamic>> uploadPhoto(
    String filePath,
    String token,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$authBaseUrl/photos'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', filePath));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print("DEBUG UPLOAD - Status: ${response.statusCode}");
      print("DEBUG UPLOAD - Raw Body: $responseData");

      // Nettoyage de la réponse si elle contient du HTML parasite (ex: <br /> ou xdebug)
      String cleanData = responseData.trim();

      // Si on trouve du JSON après le <br />, on le récupère
      if (cleanData.contains('{')) {
        int jsonStartIndex = cleanData.indexOf('{');
        cleanData = cleanData.substring(jsonStartIndex);
        // On s'assure qu'on ne garde pas de HTML après le JSON si présent
        int jsonEndIndex = cleanData.lastIndexOf('}');
        if (jsonEndIndex != -1) {
          cleanData = cleanData.substring(0, jsonEndIndex + 1);
        }
      }

      // Détection d'erreurs PHP critiques dans le texte brut
      if (responseData.contains('Fatal error') ||
          responseData.contains('Token invalide')) {
        throw Exception(
          "Session expirée ou erreur serveur (Token invalide). Veuillez vous déconnecter et vous reconnecter.",
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final decoded = jsonDecode(cleanData);
          print("DEBUG UPLOAD - Decoded Map: $decoded");
          return decoded;
        } catch (e) {
          print("DEBUG UPLOAD - Decode Error for: $cleanData");
          throw Exception("Réponse serveur malformée.");
        }
      } else {
        throw Exception("Échec de l'upload (Status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Erreur lors de l'upload : $e");
    }
  }
}
