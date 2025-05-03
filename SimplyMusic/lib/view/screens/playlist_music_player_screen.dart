import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:marquee/marquee.dart';
import 'package:music_magic/model/object_models/audio_file.dart';
import 'package:share_plus/share_plus.dart';

// This class is unneeded as I should've just adjusted the music player screen,
// however I was feeling lazy.

class PlaylistMusicPlayerScreen extends StatefulWidget {
  final List<AudioFile> songs;
  final int initialIndex;
  final bool isShuffle;

  const PlaylistMusicPlayerScreen({
    super.key,
    required this.songs,
    required this.initialIndex,
    this.isShuffle = false,
  });

  @override
  State<PlaylistMusicPlayerScreen> createState() =>
      _PlaylistMusicPlayerScreenState();
}

class _PlaylistMusicPlayerScreenState extends State<PlaylistMusicPlayerScreen> {
  late AudioPlayer _audioPlayer;
  late List<AudioFile> _songs;
  late int _currentIndex;
  late ConcatenatingAudioSource _playlist;
  bool _isPlaying = true;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;
  bool _userIsDragging = false;
  double? _dragValue;

  AudioFile get currentSong => _songs[_currentIndex];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _songs = List<AudioFile>.from(widget.songs);
    _currentIndex = widget.initialIndex;
    if (widget.isShuffle) {
      final tappedSong = _songs[_currentIndex];
      _songs.shuffle();
      final newIndex = _songs.indexWhere((song) => song.id == tappedSong.id);
      if (newIndex > 0) {
        final temp = _songs[0];
        _songs[0] = tappedSong;
        _songs[newIndex] = temp;
        _currentIndex = 0;
      }
    }

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
      });
    });

    _currentIndexSubscription = _audioPlayer.currentIndexStream.listen((index) {
      if (index == null) return;
      setState(() {
        _currentIndex = index;
      });
    });

    _loadPlaylistAndPlay(_currentIndex);
  }

  Future<void> _loadPlaylistAndPlay(int initialIndex) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final tempDir = await getTemporaryDirectory();

    final List<AudioSource> sources = _songs.map((song) {
      final fullPath = p.join(documentsDir.path, song.referenceId);
      final thumbPath = p.join(tempDir.path, '${song.referenceId}_thumb.jpg');
      final thumbFile = File(thumbPath);
      if (!thumbFile.existsSync()) {
        thumbFile.writeAsBytesSync(song.thumbnailImage);
      }
      return AudioSource.uri(
        Uri.file(fullPath),
        tag: MediaItem(
          id: song.referenceId,
          album: 'Simply Music',
          title: song.title,
          artist: song.artist.isNotEmpty ? song.artist : '<Artist>',
          artUri: Uri.file(thumbPath),
        ),
      );
    }).toList();

    _playlist = ConcatenatingAudioSource(children: sources);

    try {
      await _audioPlayer.setAudioSource(
        _playlist,
        initialIndex: initialIndex,
      );
      await _audioPlayer.play();
      if (!mounted) return;
      setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint('Error setting playlist: $e');
    }
  }

  Future<void> _playPrevious() async {
    try {
      await _audioPlayer.seekToPrevious();
    } catch (e) {
      debugPrint('Error playing previous: $e');
    }
  }

  Future<void> _playNext() async {
    try {
      await _audioPlayer.seekToNext();
    } catch (e) {
      debugPrint('Error playing next: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play();
      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildMarquee() {
    return SizedBox(
      height: 24,
      child: Marquee(
        text: currentSong.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        scrollAxis: Axis.horizontal,
        blankSpace: 50,
        velocity: 30,
        pauseAfterRound: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildArtistText() {
    if (currentSong.artist.isNotEmpty) {
      return Text(
        currentSong.artist,
        style: const TextStyle(
          fontFamily: 'DancingScript',
          fontSize: 35,
          color: Color(0xFFF1C96D),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = Colors.black87;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: appBarColor,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final sm = ScaffoldMessenger.of(context);
              final box = context.findRenderObject() as RenderBox?;
              if (value == 'share') {
                final documentsDir = await getApplicationDocumentsDirectory();
                final filePath =
                    p.join(documentsDir.path, currentSong.referenceId);
                final file = File(filePath);
                if (!file.existsSync()) {
                  sm.showSnackBar(
                    const SnackBar(content: Text('Audio file not found.')),
                  );
                  return;
                }
                final result = await Share.shareXFiles(
                  [XFile(filePath)],
                  text: '',
                  sharePositionOrigin:
                      box!.localToGlobal(Offset.zero) & box.size,
                );
                if (result.status == ShareResultStatus.success) {
                  debugPrint('Audio file shared successfully: ${result.raw}');
                } else if (result.status == ShareResultStatus.dismissed) {
                  debugPrint('Share dismissed');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Text('Export audio file'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/music_player_page.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 50.0),
                      child: currentSong.thumbnailImage.isEmpty
                          ? Icon(
                              Icons.music_note,
                              size: screenWidth * 0.9,
                              color: Colors.grey.shade400,
                            )
                          : Image.memory(
                              currentSong.thumbnailImage,
                              width: screenWidth * 0.9,
                              fit: BoxFit.contain,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildArtistText(),
                    ),
                  ],
                ),
              ),
              Container(
                height: 180,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: _buildMarquee(),
                    ),
                    StreamBuilder<Duration>(
                      stream: _audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final total = _audioPlayer.duration ?? Duration.zero;
                        final double currentValue = _userIsDragging
                            ? (_dragValue ?? position.inMilliseconds.toDouble())
                            : position.inMilliseconds.toDouble();
                        final double maxValue = total.inMilliseconds
                            .toDouble()
                            .clamp(0, double.infinity);
                        return Column(
                          children: [
                            Slider(
                              min: 0,
                              max: maxValue,
                              value: currentValue.clamp(0, maxValue),
                              activeColor: const Color(0xFFFC589A),
                              inactiveColor: const Color(0xFF653B4C),
                              onChangeStart: (_) {
                                setState(() {
                                  _userIsDragging = true;
                                });
                              },
                              onChanged: (value) {
                                setState(() {
                                  _dragValue = value;
                                });
                              },
                              onChangeEnd: (value) {
                                setState(() {
                                  _userIsDragging = false;
                                  _dragValue = null;
                                });
                                _audioPlayer.seek(
                                  Duration(milliseconds: value.round()),
                                );
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(Duration(
                                      milliseconds: currentValue.round())),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  _formatDuration(total),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(
                            Icons.skip_previous,
                            color: Color(0xFFFC589A),
                          ),
                          onPressed: _playPrevious,
                        ),
                        const SizedBox(width: 30.0),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade700,
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            iconSize: 30,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: const Color(0xFFFC589A),
                            ),
                            onPressed: _togglePlayPause,
                          ),
                        ),
                        const SizedBox(width: 30.0),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(
                            Icons.skip_next,
                            color: Color(0xFFFC589A),
                          ),
                          onPressed: _playNext,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10.0),
            ],
          ),
        ],
      ),
    );
  }
}
