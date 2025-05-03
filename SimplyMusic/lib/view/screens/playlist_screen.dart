import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:music_magic/model/database/database.dart';
import 'package:music_magic/model/object_models/audio_file.dart';
import 'package:music_magic/model/object_models/playlist.dart';
import 'package:music_magic/view/screens/playlist_music_player_screen.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PlaylistScreen extends StatefulWidget {
  final Playlist playlist;
  const PlaylistScreen({super.key, required this.playlist});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<AudioFile> _songs = [];
  bool _isShuffleActive = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylistSongs();
  }

  Future<void> _loadPlaylistSongs() async {
    final dbHelper = DatabaseHelper.instance;
    final joinRows = await dbHelper.queryPlaylistSongs(widget.playlist.id!);
    final List<int> songIds = joinRows
        .map((row) => row[DatabaseHelper.columnPlaylistSongSongId] as int)
        .toList();
    if (songIds.isNotEmpty) {
      final db = await dbHelper.database;
      final songsResult = await db.query(
        DatabaseHelper.tableSongs,
        where: 'id IN (${List.filled(songIds.length, '?').join(',')})',
        whereArgs: songIds,
      );
      setState(() {
        _songs = songsResult.map((map) => AudioFile.fromMap(map)).toList();
      });
    } else {
      setState(() {
        _songs = [];
      });
    }
  }

  Future<void> _removeSongFromPlaylist(AudioFile song) async {
    final sm = ScaffoldMessenger.of(context);
    final dbHelper = DatabaseHelper.instance;
    int rowsDeleted =
        await dbHelper.deletePlaylistSong(widget.playlist.id!, song.id!);
    if (rowsDeleted > 0) {
      setState(() {
        _songs.removeWhere((s) => s.id == song.id);
      });
      sm.showSnackBar(
          const SnackBar(content: Text('Song removed from playlist')));
    } else {
      sm.showSnackBar(const SnackBar(content: Text('Error removing song')));
    }
  }

  Future<void> _editSong(AudioFile song) async {
    final TextEditingController titleController =
        TextEditingController(text: song.title);
    final TextEditingController artistController =
        TextEditingController(text: song.artist);
    final DateTime date =
        DateTime.fromMillisecondsSinceEpoch(song.downloadDate).toLocal();
    final String formattedDate =
        '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.year}';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Metadata'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: artistController,
                  decoration: const InputDecoration(
                    labelText: 'Artist',
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'URL: ${song.videoURL}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date Added: $formattedDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                final sm = ScaffoldMessenger.of(context);

                final String newTitle = titleController.text.trim();
                final String newArtist = artistController.text.trim();

                if (newTitle.isEmpty) {
                  sm.showSnackBar(
                    const SnackBar(
                      content: Text('Title cannot be empty'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                if (newTitle != song.title || newArtist != song.artist) {
                  final updatedSong = song.copyWith(
                    title: newTitle,
                    artist: newArtist,
                  );
                  final dbHelper = DatabaseHelper.instance;
                  final int rowsUpdated =
                      await dbHelper.updateSong(updatedSong.toMap());
                  if (rowsUpdated > 0) {
                    setState(() {
                      final index = _songs.indexWhere((s) => s.id == song.id);
                      if (index != -1) {
                        _songs[index] = updatedSong;
                      }
                    });
                    sm.showSnackBar(
                      const SnackBar(
                        content: Text('Song updated'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    sm.showSnackBar(
                      const SnackBar(
                        content: Text('Error updating song'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
                nav.pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThumbnail(Uint8List thumbData) {
    if (thumbData.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade700, width: 1),
        ),
        child: Icon(Icons.music_note, color: Colors.grey.shade700),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade700, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Image.memory(
            thumbData,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }

  Widget _buildSongTile(AudioFile song) {
    return Slidable(
      key: Key(song.id?.toString() ?? song.referenceId),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) async {
              await _removeSongFromPlaylist(song);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) async {
              await _editSong(song);
            },
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
        ],
      ),
      child: ListTile(
        leading: _buildThumbnail(song.thumbnailImage),
        title: Text(song.title, style: TextStyle(color: Colors.grey.shade700)),
        onTap: () async {
          final sm = ScaffoldMessenger.of(context);
          final nav = Navigator.of(context);
          final documentsDir = await getApplicationDocumentsDirectory();
          final filePath = p.join(documentsDir.path, song.referenceId);
          final file = File(filePath);
          if (!file.existsSync()) {
            sm.showSnackBar(
              SnackBar(content: Text('File not found: ${song.title}')),
            );
            return;
          }

          nav.push(MaterialPageRoute(
            builder: (_) => PlaylistMusicPlayerScreen(
              songs: _songs,
              initialIndex: _songs.indexOf(song),
              isShuffle: _isShuffleActive,
            ),
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.playlist.title,
            style: TextStyle(color: Colors.grey.shade700)),
        iconTheme: IconThemeData(color: Colors.grey.shade700),
        actions: [
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: _isShuffleActive ? const Color(0xFFFC589A) : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isShuffleActive = !_isShuffleActive;
              });
            },
          ),
        ],
      ),
      body: _songs.isEmpty
          ? Center(
              child: Text('No songs in this playlist.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 18)))
          : Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/dark_palm_page.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: ListView.builder(
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      return _buildSongTile(_songs[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
