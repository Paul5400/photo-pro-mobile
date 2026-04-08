import 'photo.dart';

enum LayoutMode { grid, list, masonry }

class Gallery {
  final String id;
  final String title;
  final String description;
  final String coverPhotoUrl;
  final DateTime? publicationDate;
  final LayoutMode layoutMode;
  final bool isPrivate;
  final String? accessCode;
  final List<Photo> photos;
  final int? photosCount;

  Gallery({
    required this.id,
    required this.title,
    required this.description,
    required this.coverPhotoUrl,
    this.publicationDate,
    required this.layoutMode,
    required this.isPrivate,
    this.accessCode,
    this.photos = const [],
    this.photosCount,
  });

  factory Gallery.fromJson(Map<String, dynamic> json) {
    // Gestion du nouveau format avec "galerie" et "photos" séparés
    final Map<String, dynamic> galleryData =
        json.containsKey('galerie') ? json['galerie'] : json;
    final List<dynamic> photosData =
        json.containsKey('photos')
            ? json['photos']
            : (galleryData['photos'] ?? []);

    return Gallery(
      id: galleryData['id'] ?? galleryData['galerie_id'] ?? '',
      title: galleryData['titre'] ?? galleryData['title'] ?? '',
      description: galleryData['description'] ?? '',
      coverPhotoUrl:
          galleryData['cover_url'] ??
          galleryData['cover_photo_url'] ??
          (photosData.isNotEmpty ? photosData.first['url'] ?? '' : ''),
      publicationDate:
          galleryData['published_at'] != null
              ? DateTime.parse(galleryData['published_at'])
              : (galleryData['publication_date'] != null
                  ? DateTime.parse(galleryData['publication_date'])
                  : null),
      layoutMode: LayoutMode.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            (galleryData['mode_mise_en_page'] ??
                galleryData['layout_mode'] ??
                'grid'),
        orElse: () => LayoutMode.grid,
      ),
      isPrivate:
          galleryData['type'] == 'privée' ||
          (galleryData['is_private'] ?? false),
      accessCode: galleryData['access_code'] ?? galleryData['code'],
      photos: photosData.map((p) => Photo.fromJson(p)).toList(),
      photosCount:
          galleryData['photos_count'] ??
          galleryData['nb_photos'] ??
          photosData.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_photo_url': coverPhotoUrl,
      'publication_date': publicationDate?.toIso8601String(),
      'layout_mode': layoutMode.toString().split('.').last,
      'is_private': isPrivate,
      'access_code': accessCode,
      'photos': photos.map((p) => p.toJson()).toList(),
    };
  }
}
