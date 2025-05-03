import 'dart:typed_data';

class AudioFile {
  int? id;
  final String referenceId; // Reference to the audio file on the disk.
  final String title;
  final String videoURL;
  final Uint8List thumbnailImage; // Stores image as a BLOB in database.
  String artist;
  String genre;
  final int downloadDate;

  AudioFile(
      {this.id,
      required this.referenceId,
      required this.title,
      required this.videoURL,
      required this.thumbnailImage,
      this.artist = "",
      this.genre = "",
      required this.downloadDate});

  static AudioFile fromMap(Map<String, dynamic> map) {
    return AudioFile(
        id: map['id'],
        referenceId: map['referenceId'],
        title: map['title'],
        videoURL: map['videoURL'],
        thumbnailImage: map['thumbnailImage'] as Uint8List,
        artist: map['artist'],
        genre: map['genre'],
        downloadDate: map['downloadDate']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referenceId': referenceId,
      'title': title,
      'videoURL': videoURL,
      'thumbnailImage': thumbnailImage,
      'artist': artist,
      'genre': genre,
      'downloadDate': downloadDate,
    };
  }

  AudioFile copyWith({
    int? id,
    String? referenceId,
    String? title,
    String? videoURL,
    Uint8List? thumbnailImage,
    String? artist,
    String? genre,
    int? downloadDate,
  }) {
    return AudioFile(
      id: id ?? this.id,
      referenceId: referenceId ?? this.referenceId,
      title: title ?? this.title,
      videoURL: videoURL ?? this.videoURL,
      thumbnailImage: thumbnailImage ?? this.thumbnailImage,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      downloadDate: downloadDate ?? this.downloadDate,
    );
  }
}
