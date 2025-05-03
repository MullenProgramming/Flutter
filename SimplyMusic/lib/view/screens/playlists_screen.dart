import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:music_magic/model/database/database.dart';
import 'package:music_magic/model/object_models/playlist.dart';
import 'package:music_magic/view/screens/add_playlist_screen.dart';
import 'package:music_magic/view/screens/playlist_screen.dart';
import 'package:music_magic/view/widgets/menu_drawer.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final dbHelper = DatabaseHelper.instance;
    final playlistMaps = await dbHelper.queryPlaylists();
    setState(() {
      _playlists = playlistMaps.map((map) => Playlist.fromMap(map)).toList();
    });
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final sm = ScaffoldMessenger.of(context);
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.deletePlaylistSongs(playlist.id!);
    int rowsDeleted = await dbHelper.deletePlaylist(playlist.id!);
    if (rowsDeleted > 0) {
      setState(() {
        _playlists.remove(playlist);
      });
      sm.showSnackBar(
        const SnackBar(content: Text('Playlist deleted')),
      );
    } else {
      sm.showSnackBar(
        const SnackBar(content: Text('Error deleting playlist')),
      );
    }
  }

  Future<void> _editPlaylist(Playlist playlist) async {
    final TextEditingController titleController =
        TextEditingController(text: playlist.title);
    Uint8List? updatedImage = playlist.image;
    final ImagePicker picker = ImagePicker();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Playlist'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 16),
                    updatedImage != null
                        ? GestureDetector(
                            onTap: () async {
                              final XFile? pickedFile = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 70,
                              );
                              if (pickedFile != null) {
                                final bytes = await pickedFile.readAsBytes();
                                setStateDialog(() {
                                  updatedImage = bytes;
                                });
                              }
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey.shade700, width: 1),
                              ),
                              child: Image.memory(
                                updatedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                              minimumSize: const Size(100, 45),
                            ),
                            onPressed: () async {
                              final XFile? pickedFile = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 70,
                              );
                              if (pickedFile != null) {
                                final bytes = await pickedFile.readAsBytes();
                                setStateDialog(() {
                                  updatedImage = bytes;
                                });
                              }
                            },
                            icon: const Icon(
                              Icons.image,
                              color: Colors.white,
                              size: 32,
                            ),
                            label: const Text(
                              'Add Image',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final sm = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    final newTitle = titleController.text.trim();
                    if (newTitle.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title cannot be empty')),
                      );
                      return;
                    }
                    final updatedPlaylist = Playlist(
                      id: playlist.id,
                      title: newTitle,
                      image: updatedImage,
                      createdAt: playlist.createdAt,
                    );
                    final dbHelper = DatabaseHelper.instance;
                    int rowsUpdated =
                        await dbHelper.updatePlaylist(updatedPlaylist.toMap());
                    if (rowsUpdated > 0) {
                      setState(() {
                        final index =
                            _playlists.indexWhere((p) => p.id == playlist.id);
                        if (index != -1) {
                          _playlists[index] = updatedPlaylist;
                        }
                      });
                      sm.showSnackBar(
                        const SnackBar(content: Text('Playlist updated')),
                      );
                    } else {
                      sm.showSnackBar(
                        const SnackBar(
                            content: Text('Error updating playlist')),
                      );
                    }
                    nav.pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistTile(Playlist playlist) {
    return Slidable(
      key: Key(playlist.id.toString()),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) async {
              await _deletePlaylist(playlist);
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
              await _editPlaylist(playlist);
            },
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: playlist.image != null
            ? Image.memory(
                playlist.image!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.black,
                  border: Border.all(
                    color: const Color(0xFFFC589A),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Color(0xFFFC589A),
                ),
              ),
        title: Text(
          playlist.title,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 18),
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PlaylistScreen(playlist: playlist),
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: _playlists.isEmpty
                ? Center(
                    child: Text(
                      'No playlists yet.',
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: _playlists.length,
                    itemBuilder: (context, index) {
                      return _buildPlaylistTile(_playlists[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFC589A),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddPlaylistScreen()),
          );
          _loadPlaylists();
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
