class Comment {
  final String id;
  final String text;
  final String photoId;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.text,
    required this.photoId,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      photoId: json['photo_id'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'photo_id': photoId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
