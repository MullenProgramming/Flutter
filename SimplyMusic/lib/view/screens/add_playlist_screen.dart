import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:music_magic/model/database/database.dart';
import 'package:music_magic/model/object_models/audio_file.dart';

class AddPlaylistScreen extends StatefulWidget {
  const AddPlaylistScreen({super.key});

  @override
  State<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends State<AddPlaylistScreen> {
  final TextEditingController _titleController = TextEditingController();
  // For song search.
  final TextEditingController _searchController = TextEditingController();
  List<AudioFile> _allSongs = [];
  List<AudioFile> _filteredSongs = [];
  // To track which songs are selected (by song id).
  final Set<int> _selectedSongIds = {};

  Uint8List? _playlistImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _searchController.addListener(_filterSongs);
  }

  Future<void> _loadSongs() async {
    final dbHelper = DatabaseHelper.instance;
    final songMaps = await dbHelper.querySongs();
    setState(() {
      _allSongs = songMaps.map((map) => AudioFile.fromMap(map)).toList();
      _filteredSongs = List.from(_allSongs);
    });
  }

  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSongs = List.from(_allSongs);
      } else {
        _filteredSongs = _allSongs.where((song) {
          return song.title.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _createPlaylist() async {
    final sm = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    if (_selectedSongIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one song')),
      );
      return;
    }

    final dbHelper = DatabaseHelper.instance;
    final now = DateTime.now().millisecondsSinceEpoch;
    final playlistMap = {
      'title': title,
      'image': _playlistImage,
      'created_at': now,
    };
    int playlistId = await dbHelper.insertPlaylist(playlistMap);

    for (var songId in _selectedSongIds) {
      await dbHelper.insertPlaylistSong({
        'playlist_id': playlistId,
        'song_id': songId,
      });
    }

    sm.showSnackBar(
      const SnackBar(content: Text('Playlist created')),
    );
    nav.pop();
  }

  /// Uses image_picker to pick an image from the gallery.
  Future<void> _pickImage() async {
    final sm = ScaffoldMessenger.of(context);
    try {
      // Pick an image from the gallery with quality set to 70%.
      // If quality set to 100% the image seems to not load for some reason.
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _playlistImage = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      sm.showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSongTile(AudioFile song) {
    final isSelected = _selectedSongIds.contains(song.id);
    return ListTile(
      leading: song.thumbnailImage.isEmpty
          ? Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade700, width: 1),
              ),
              child: Icon(Icons.music_note, color: Colors.grey.shade700),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade700, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.memory(
                  song.thumbnailImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ),
      title: Text(
        song.title,
        style: TextStyle(color: Colors.grey.shade700),
      ),
      trailing:
          isSelected ? const Icon(Icons.check, color: Color(0xFFFC589A)) : null,
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSongIds.remove(song.id);
          } else {
            _selectedSongIds.add(song.id!);
          }
        });
      },
    );
  }

  Widget _buildImagePicker() {
    if (_playlistImage != null) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFFC589A), width: 1),
          ),
          child: Image.memory(
            _playlistImage!,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade800,
          minimumSize: const Size(100, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: _pickImage,
        icon: const Icon(Icons.image, color: Colors.white, size: 32),
        label: const Text(
          'Add Image',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'New Playlist',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        iconTheme: IconThemeData(color: Colors.grey.shade700),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildImagePicker(),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Playlist Title',
                  labelStyle:
                      TextStyle(color: Colors.grey.shade700, fontSize: 18),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFFFC589A)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Songs search bar.
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
                  labelText: 'Search Songs',
                  labelStyle: TextStyle(color: Colors.grey.shade700),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFFFC589A)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _filteredSongs.isEmpty
                  ? Center(
                      child: Text(
                        'No songs found.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredSongs.length,
                      itemBuilder: (context, index) {
                        return _buildSongTile(_filteredSongs[index]);
                      },
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFC589A),
        onPressed: _createPlaylist,
        child: const Icon(
          Icons.check,
          color: Colors.white,
        ),
      ),
    );
  }
}
