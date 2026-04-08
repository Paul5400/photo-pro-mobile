class Comment {
  final String id;
  final String photoId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.photoId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      photoId: json['photo_id']?.toString() ?? '',
      authorName:
          json['auteur'] ?? json['nom_auteur'] ?? json['pseudo'] ?? 'Anonyme',
      content: json['contenu'] ?? json['text'] ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : (json['date_commentaire'] != null
                  ? DateTime.parse(json['date_commentaire'])
                  : DateTime.now()),
    );
  }
}
