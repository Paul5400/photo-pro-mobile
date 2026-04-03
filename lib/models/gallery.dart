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
  });

  factory Gallery.fromJson(Map<String, dynamic> json) {
    return Gallery(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverPhotoUrl: json['cover_photo_url'] ?? '',
      publicationDate:
          json['publication_date'] != null
              ? DateTime.parse(json['publication_date'])
              : null,
      layoutMode: LayoutMode.values.firstWhere(
        (e) => e.toString().split('.').last == (json['layout_mode'] ?? 'grid'),
        orElse: () => LayoutMode.grid,
      ),
      isPrivate: json['is_private'] ?? false,
      accessCode: json['access_code'],
      photos:
          json['photos'] != null
              ? (json['photos'] as List).map((p) => Photo.fromJson(p)).toList()
              : [],
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
