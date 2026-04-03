class Photo {
  final String id;
  final String? title;
  final String mimeType;
  final double sizeMb;
  final String originalFileName;
  final DateTime uploadDate;
  final String url;

  Photo({
    required this.id,
    this.title,
    required this.mimeType,
    required this.sizeMb,
    required this.originalFileName,
    required this.uploadDate,
    required this.url,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] ?? '',
      title: json['title'],
      mimeType: json['mime_type'] ?? 'image/jpeg',
      sizeMb: (json['size_mb'] ?? 0.0).toDouble(),
      originalFileName: json['original_file_name'] ?? 'unknown.jpg',
      uploadDate: DateTime.parse(
        json['upload_date'] ?? DateTime.now().toIso8601String(),
      ),
      url: json['url'] ?? '',
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
