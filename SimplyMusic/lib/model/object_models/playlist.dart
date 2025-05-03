import 'dart:typed_data';

class Playlist {
  int? id;
  final String title;
  final Uint8List? image; // image stored as a BLOB
  final int createdAt;

  Playlist({
    this.id,
    required this.title,
    this.image,
    required this.createdAt,
  });

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      title: map['title'],
      image: map['image'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'created_at': createdAt,
    };
  }
}
