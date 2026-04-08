import 'comment.dart';

class Photo {
  final String id;
  final String? title;
  final String mimeType;
  final double sizeMb;
  final String originalFileName;
  final DateTime uploadDate;
  final String url;
  final List<Comment> comments;

  Photo({
    required this.id,
    this.title,
    required this.mimeType,
    required this.sizeMb,
    required this.originalFileName,
    required this.uploadDate,
    required this.url,
    this.comments = const [],
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    final commentsData = json['commentaires'];
    final List<Comment> parsedComments =
        commentsData is List
            ? commentsData
                .whereType<Map<String, dynamic>>()
                .map(Comment.fromJson)
                .toList()
            : const [];

    return Photo(
      id: json['id']?.toString() ?? '',
      title: json['titre'] ?? json['title'],
      mimeType: json['mime_type'] ?? 'image/jpeg',
      sizeMb: (json['taille_mo'] ?? json['size_mb'] ?? 0.0).toDouble(),
      originalFileName:
          json['nom_fichier_original'] ??
          json['original_file_name'] ??
          'unknown.jpg',
      uploadDate: DateTime.parse(
        json['uploaded_at'] ??
            json['upload_date'] ??
            DateTime.now().toIso8601String(),
      ),
      url: json['chemin_s3'] ?? json['url'] ?? '',
      comments: parsedComments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'mime_type': mimeType,
      'size_mb': sizeMb,
      'original_file_name': originalFileName,
      'upload_date': uploadDate.toIso8601String(),
      'url': url,
    };
  }
}
