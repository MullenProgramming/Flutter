import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:music_magic/model/database/database.dart';
import 'package:music_magic/model/object_models/audio_file.dart';
import 'package:music_magic/view/screens/music_player_screen.dart';
import 'package:music_magic/view/widgets/menu_drawer.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SongsScreen extends StatefulWidget {
  final bool nested;
  const SongsScreen({super.key, this.nested = false});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final List<AudioFile> _songs = [];
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  String? _lastSelectedLetter;
  bool _isShuffleActive = false;

  @override
  void initState() {
    super.initState();
    _loadSongsFromDB();
  }

  Future<void> _loadSongsFromDB() async {
    final dbHelper = DatabaseHelper.instance;
    final songMaps = await dbHelper.querySongs();
    final songList = songMaps.map(AudioFile.fromMap).toList();

    setState(() {
      _songs.clear();
      _songs.addAll(songList);
    });
  }

  Future<void> _deleteSong(AudioFile song) async {
    final sm = ScaffoldMessenger.of(context);
    if (song.id == null) return;
    final dbHelper = DatabaseHelper.instance;
    final documentsDir = await getApplicationDocumentsDirectory();
    final filePath = p.join(documentsDir.path, song.referenceId);
    final file = File(filePath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }
    }

    final rowsDeleted = await dbHelper.deleteSong(song.id!);
    if (rowsDeleted > 0) {
      setState(() {
        _songs.remove(song);
      });
      sm.showSnackBar(
        const SnackBar(
          content: Text('Song deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      sm.showSnackBar(
        const SnackBar(
          content: Text('Error deleting song'),
          duration: Duration(seconds: 2),
        ),
      );
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
          border: Border.all(
            color: Colors.grey.shade700,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.music_note,
          color: Colors.grey.shade700,
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.grey.shade700,
            width: 1,
          ),
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

  Widget _buildSlidableSongTile(AudioFile song) {
    return Slidable(
      key: Key(song.id?.toString() ?? song.referenceId),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (BuildContext context) async {
              await _deleteSong(song);
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
            onPressed: (BuildContext context) async {
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
        title: Text(
          song.title,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        onTap: () async {
          final sm = ScaffoldMessenger.of(context);
          final nav = Navigator.of(context);
          final documentsDir = await getApplicationDocumentsDirectory();
          final filePath = p.join(documentsDir.path, song.referenceId);
          final file = File(filePath);

          if (!file.existsSync()) {
            sm.showSnackBar(
              SnackBar(
                content: Text('File not found: ${song.title}'),
              ),
            );
            return;
          }

          if (_isShuffleActive) {
            final shuffledSongs = List<AudioFile>.from(_songs);
            shuffledSongs.shuffle();
            final tappedSong = song;
            final index =
                shuffledSongs.indexWhere((s) => s.id == tappedSong.id);
            if (index > 0) {
              final temp = shuffledSongs[0];
              shuffledSongs[0] = tappedSong;
              shuffledSongs[index] = temp;
            }
            nav.push(
              MaterialPageRoute(
                builder: (_) => MusicPlayerScreen(
                  songs: shuffledSongs,
                  initialIndex: 0,
                  preserveOrder: true,
                ),
              ),
            );
          } else {
            nav.push(
              MaterialPageRoute(
                builder: (_) => MusicPlayerScreen(
                  songs: _songs,
                  initialIndex: _songs.indexOf(song),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  List<Widget> _buildGroupedSongList() {
    final List<AudioFile> sorted = [..._songs];
    sorted.sort((a, b) {
      final aTitle = a.title.trim();
      final bTitle = b.title.trim();
      final aStart = aTitle.isNotEmpty ? aTitle[0].toUpperCase() : '';
      final bStart = bTitle.isNotEmpty ? bTitle[0].toUpperCase() : '';

      final bool aIsAlpha =
          (aStart.compareTo('A') >= 0 && aStart.compareTo('Z') <= 0);
      final bool bIsAlpha =
          (bStart.compareTo('A') >= 0 && bStart.compareTo('Z') <= 0);

      if (aIsAlpha && bIsAlpha) {
        return aTitle.toLowerCase().compareTo(bTitle.toLowerCase());
      }
      if (!aIsAlpha && bIsAlpha) return -1;
      if (aIsAlpha && !bIsAlpha) return 1;
      return aTitle.toLowerCase().compareTo(bTitle.toLowerCase());
    });

    final List<_Section> sections = [];
    final List<AudioFile> nonAlphaSongs = sorted.where((song) {
      if (song.title.isEmpty) return true;
      final first = song.title[0].toUpperCase();
      return (first.compareTo('A') < 0 || first.compareTo('Z') > 0);
    }).toList();
    if (nonAlphaSongs.isNotEmpty) {
      sections.add(
          _Section('#', nonAlphaSongs)); // Uses '#' for non-alphabetical titles
    }

    for (int codeUnit = 65; codeUnit <= 90; codeUnit++) {
      final letter = String.fromCharCode(codeUnit);
      final letterSongs = sorted.where((song) {
        if (song.title.isEmpty) return false;
        return song.title[0].toUpperCase() == letter;
      }).toList();

      if (letterSongs.isNotEmpty) {
        sections.add(_Section(letter, letterSongs));
      }
    }

    final List<Widget> groupedWidgets = [];
    for (final section in sections) {
      final key = _sectionKeys.putIfAbsent(section.header, () => GlobalKey());
      groupedWidgets.add(
        Padding(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            section.header,
            style: const TextStyle(
              color: Color(0xFFFC589A),
              fontSize: 12,
            ),
          ),
        ),
      );
      for (final song in section.songs) {
        groupedWidgets.add(_buildSlidableSongTile(song));
      }
    }
    return groupedWidgets;
  }

  Widget _buildBody() {
    final groupedSongWidgets = _buildGroupedSongList();
    return Stack(
      children: [
        ListView(
          controller: _scrollController,
          children: groupedSongWidgets,
        ),
        Positioned(
          right: 0,
          top: 50,
          bottom: 50,
          child: _buildAlphabetSlider(),
        ),
      ],
    );
  }

  Widget _buildAlphabetSlider() {
    final letters = _sectionKeys.keys.toList()..sort();
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderHeight = constraints.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (details) {
            _handleLetterSelection(
                details.localPosition.dy, letters, sliderHeight);
          },
          onVerticalDragUpdate: (details) {
            _handleLetterSelection(
                details.localPosition.dy, letters, sliderHeight);
          },
          onTapDown: (details) {
            _handleLetterSelection(
                details.localPosition.dy, letters, sliderHeight);
          },
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: letters.map((letter) {
                final isSelected = letter == _lastSelectedLetter;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFFC589A)
                          : Colors.grey.shade700,
                      fontSize: isSelected ? 16 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _handleLetterSelection(
      double dy, List<String> letters, double sliderHeight) {
    int index = (dy / sliderHeight * letters.length)
        .clamp(0, letters.length - 1)
        .toInt();
    final letter = letters[index];

    if (letter != _lastSelectedLetter) {
      setState(() {
        _lastSelectedLetter = letter;
      });
      HapticFeedback.lightImpact();
    }

    final key = _sectionKeys[letter];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        alignment: 0.0, // top alignment
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nested) {
      return SizedBox(
        height: MediaQuery.of(context).size.height,
        child: _buildBody(),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const kDrawer_Menu(),
        appBar: AppBar(
          automaticallyImplyLeading: true,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: const Text(
            "Simply Music",
            style: TextStyle(
              fontFamily: 'DancingScript',
              fontSize: 40,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              icon: Icon(
                Icons.shuffle,
                color:
                    _isShuffleActive ? const Color(0xFFFC589A) : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isShuffleActive = !_isShuffleActive;
                });
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/dark_palm_page.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBody(),
            ),
          ],
        ),
      );
    }
  }
}

class _Section {
  final String header;
  final List<AudioFile> songs;
  _Section(this.header, this.songs);
}
