class UploadHistoryItem {
  final String id;
  final String filePath;
  final String? s3Url;
  final DateTime uploadDate;
  final bool isSynced;

  UploadHistoryItem({
    required this.id,
    required this.filePath,
    this.s3Url,
    required this.uploadDate,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    's3Url': s3Url,
    'uploadDate': uploadDate.toIso8601String(),
    'isSynced': isSynced,
  };

  factory UploadHistoryItem.fromJson(Map<String, dynamic> json) =>
      UploadHistoryItem(
        id: json['id'],
        filePath: json['filePath'],
        s3Url: json['s3Url'],
        uploadDate: DateTime.parse(json['uploadDate']),
        isSynced: json['isSynced'] ?? false,
      );
}
