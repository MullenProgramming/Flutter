import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final _databaseName = "music_magic.db";
  static final _databaseVersion = 2;

  // Songs table.
  static final tableSongs = 'songs';
  static final columnId = 'id';
  static final columnReferenceId = 'referenceId';
  static final columnTitle = 'title';
  static final columnURL = 'videoURL';
  static final columnThumbnail = 'thumbnailImage';
  static final columnArtist = 'artist';
  static final columnGenre = 'genre';
  static final columnDate = 'downloadDate';

  // Playlists table.
  static final tablePlaylists = 'playlists';
  static final columnPlaylistId = 'id';
  static final columnPlaylistTitle = 'title';
  static final columnPlaylistImage = 'image';
  static final columnPlaylistCreatedAt = 'created_at';

  // Join table for playlists and songs.
  static final tablePlaylistSongs = 'playlist_songs';
  static final columnPlaylistSongId = 'id';
  static final columnPlaylistSongPlaylistId = 'playlist_id';
  static final columnPlaylistSongSongId = 'song_id';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableSongs (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnReferenceId TEXT NOT NULL,
            $columnTitle TEXT NOT NULL,
            $columnURL TEXT NOT NULL,
            $columnThumbnail BLOB NOT NULL,
            $columnArtist TEXT,
            $columnGenre TEXT,
            $columnDate INTEGER
          )
          ''');

    await db.execute('''
          CREATE TABLE $tablePlaylists (
            $columnPlaylistId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnPlaylistTitle TEXT NOT NULL,
            $columnPlaylistImage BLOB,
            $columnPlaylistCreatedAt INTEGER
          )
          ''');

    await db.execute('''
          CREATE TABLE $tablePlaylistSongs (
            $columnPlaylistSongId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnPlaylistSongPlaylistId INTEGER NOT NULL,
            $columnPlaylistSongSongId INTEGER NOT NULL,
            FOREIGN KEY ($columnPlaylistSongPlaylistId) REFERENCES $tablePlaylists($columnPlaylistId) ON DELETE CASCADE,
            FOREIGN KEY ($columnPlaylistSongSongId) REFERENCES $tableSongs($columnId) ON DELETE CASCADE
          )
          ''');
    return;
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        image BLOB,
        created_at INTEGER
      )
    ''');

      await db.execute('''
      CREATE TABLE playlist_songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        song_id INTEGER NOT NULL,
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');
    }
  }

  // ************************ CRUD OPERATIONS ************************
  Future<List<Map<String, dynamic>>> querySongs() async {
    Database db = await instance.database;
    return await db.query(tableSongs);
  }

  Future<int> insertSong(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableSongs, row);
  }

  Future<int> updateSong(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db
        .update(tableSongs, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deleteSong(int id) async {
    Database db = await instance.database;
    return await db.delete(tableSongs, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryPlaylists() async {
    Database db = await instance.database;
    return await db.query(tablePlaylists);
  }

  Future<int> insertPlaylist(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tablePlaylists, row);
  }

  Future<int> updatePlaylist(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnPlaylistId];
    return await db.update(tablePlaylists, row,
        where: '$columnPlaylistId = ?', whereArgs: [id]);
  }

  Future<int> deletePlaylist(int id) async {
    Database db = await instance.database;
    return await db.delete(tablePlaylists,
        where: '$columnPlaylistId = ?', whereArgs: [id]);
  }

  Future<int> insertPlaylistSong(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tablePlaylistSongs, row);
  }

  Future<List<Map<String, dynamic>>> queryPlaylistSongs(int playlistId) async {
    Database db = await instance.database;
    return await db.query(tablePlaylistSongs,
        where: '$columnPlaylistSongPlaylistId = ?', whereArgs: [playlistId]);
  }

  Future<int> deletePlaylistSongs(int playlistId) async {
    Database db = await instance.database;
    return await db.delete(tablePlaylistSongs,
        where: '$columnPlaylistSongPlaylistId = ?', whereArgs: [playlistId]);
  }

  Future<int> deletePlaylistSong(int playlistId, int songId) async {
    Database db = await instance.database;
    return await db.delete(
      tablePlaylistSongs,
      where:
          '$columnPlaylistSongPlaylistId = ? AND $columnPlaylistSongSongId = ?',
      whereArgs: [playlistId, songId],
    );
  }
}
