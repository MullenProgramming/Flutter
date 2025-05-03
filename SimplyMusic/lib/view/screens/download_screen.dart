import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:music_magic/model/database/database.dart';
import 'package:music_magic/model/object_models/audio_file.dart';
import 'package:music_magic/view/widgets/menu_drawer.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

const int maxSeeds = 300; // For loading animation.

class SunflowerWidget extends StatelessWidget {
  static const tau = math.pi * 2;
  static const scaleFactor = 1 / 40;
  static const size = 600.0;
  static final phi = (math.sqrt(5) + 1) / 2;
  static final rng = math.Random();

  final int seedsLit;

  const SunflowerWidget(this.seedsLit, {super.key});

  @override
  Widget build(BuildContext context) {
    // ******************** Loading Animations ********************
    final seedWidgets = <Widget>[];

    for (var i = 0; i < seedsLit; i++) {
      final theta = i * tau / phi;
      final r = math.sqrt(i) * scaleFactor;

      seedWidgets.add(AnimatedAlign(
        key: ValueKey(i),
        duration: Duration(milliseconds: rng.nextInt(500) + 250),
        curve: Curves.easeInOut,
        alignment: Alignment(r * math.cos(theta), -r * math.sin(theta)),
        child: const Dot(true),
      ));
    }

    for (var j = seedsLit; j < maxSeeds; j++) {
      final x = math.cos(tau * j / (maxSeeds - 1)) * 0.9;
      final y = math.sin(tau * j / (maxSeeds - 1)) * 0.9;

      seedWidgets.add(AnimatedAlign(
        key: ValueKey(j),
        duration: Duration(milliseconds: rng.nextInt(500) + 250),
        curve: Curves.easeInOut,
        alignment: Alignment(x, y),
        child: const Dot(false),
      ));
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        height: size,
        width: size,
        child: Stack(children: seedWidgets),
      ),
    );
  }
}

class Dot extends StatelessWidget {
  static const size = 5.0;
  static const radius = 3.0;

  final bool lit;

  const Dot(this.lit, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: lit ? Colors.orange : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const SizedBox(
        height: size,
        width: size,
      ),
    );
  }
}
// ************************************************************

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final TextEditingController _youtubeUrlController = TextEditingController();

  double _progress = 0.0;
  bool _isDownloading = false;
  String _statusMessage = '';

  // Transcodes .webm -> .mp3 (if no AAC available on iOS)
  // For the transcribing portion, I had a bit of trouble with this
  // so ChatGPT was utilized for assistance.
  Future<String> _transcodeToMp3(String inputPath) async {
    final outputPath = inputPath.replaceAll('.webm', '.mp3');

    setState(() => _statusMessage = 'Transcoding to MP3...');

    final command = '-i "$inputPath" -q:a 0 "$outputPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      final original = File(inputPath);
      if (original.existsSync()) {
        await original.delete();
      }
      return outputPath;
    } else {
      throw 'Transcoding failed with return code: $returnCode';
    }
  }

  Future<String> _fixMetadata(String inputPath) async {
    final extension = p.extension(inputPath).toLowerCase();
    if (extension != '.m4a' && extension != '.mp3') {
      return inputPath;
    }
    setState(() {
      _statusMessage = 'Fixing metadata...';
    });
    final base = p.basenameWithoutExtension(inputPath);
    final dir = p.dirname(inputPath);
    final fixedPath = p.join(dir, '${base}_fixed$extension');
    final command = '-i "$inputPath" -c:a copy "$fixedPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      final oldFile = File(inputPath);
      if (oldFile.existsSync()) {
        await oldFile.delete();
      }
      return fixedPath;
    } else {
      return inputPath;
    }
  }

  Future<String> _downloadAndSave(AudioOnlyStreamInfo streamInfo,
      String fileName, String extension, YoutubeExplode yt) async {
    final audioStream = yt.videos.streamsClient.get(streamInfo);
    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, '$fileName.$extension');
    final file = File(filePath);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    final totalSize = streamInfo.size.totalBytes;
    var downloadedBytes = 0;
    final sink = file.openWrite();
    await for (final data in audioStream) {
      sink.add(data);
      downloadedBytes += data.length;
      if (totalSize != 0) {
        setState(() {
          _progress = downloadedBytes / totalSize;
          _statusMessage =
              'Downloading... ${(_progress * 100).toStringAsFixed(0)}%';
        });
      }
    }
    await sink.close();
    yt.close();
    setState(() {
      _isDownloading = false;
      _statusMessage = 'Download Complete!';
      _youtubeUrlController.clear();
    });
    return filePath;
  }

  Future<Uint8List> _fetchThumbnailBytes(String thumbnailUrl) async {
    try {
      final response = await Dio().get<List<int>>(
        thumbnailUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } catch (e) {
      debugPrint('Error fetching thumbnail: $e');
      return Uint8List(0);
    }
  }

  // Main download function
  Future<void> _downloadAudio() async {
    FocusScope.of(context).unfocus();
    final url = _youtubeUrlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a valid YouTube URL.';
      });
      return;
    }
    setState(() {
      _progress = 0.0;
      _isDownloading = true;
      _statusMessage = 'Downloading audio...';
    });
    final yt = YoutubeExplode();
    try {
      final videoId = VideoId(url);
      final video = await yt.videos.get(videoId);
      final videoTitle = video.title;
      final thumbnailUrl = video.thumbnails.highResUrl;
      final thumbBytes = await _fetchThumbnailBytes(thumbnailUrl);
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;
      String localFilePath;
      if (Platform.isIOS) {
        final aacStreams = audioStreams
            .where((s) => s.codec.mimeType.contains('mp4'))
            .toList();
        AudioOnlyStreamInfo? bestAac;
        if (aacStreams.isNotEmpty) {
          bestAac = aacStreams.reduce((curr, next) =>
              curr.bitrate.bitsPerSecond > next.bitrate.bitsPerSecond
                  ? curr
                  : next);
        }
        if (bestAac != null) {
          localFilePath =
              await _downloadAndSave(bestAac, videoId.value, 'm4a', yt);
        } else {
          final fallback = audioStreams.withHighestBitrate();
          final webmPath =
              await _downloadAndSave(fallback, videoId.value, 'webm', yt);
          localFilePath = await _transcodeToMp3(webmPath);
        }
      } else {
        final bestOpus = audioStreams.withHighestBitrate();
        localFilePath =
            await _downloadAndSave(bestOpus, videoId.value, 'webm', yt);
      }
      localFilePath = await _fixMetadata(localFilePath);
      // MUST INSERT RELATIVE PATH OR FILE WILL NOT BE ABLE TO BE FOUND!
      // Only an issue for iPhone, Android seems to work fine.
      final relativePath = p.basename(localFilePath);
      final newSong = AudioFile(
        referenceId: relativePath,
        title: videoTitle,
        videoURL: url,
        thumbnailImage: thumbBytes,
        artist: '',
        genre: '',
        downloadDate: DateTime.now().millisecondsSinceEpoch,
      );
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.insertSong(newSong.toMap());
      setState(() {
        _statusMessage = 'Download Complete!';
      });
    } catch (e) {
      yt.close();
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Widget _buildInputForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: TextField(
            controller: _youtubeUrlController,
            style: TextStyle(color: Colors.grey.shade800),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: 'YouTube URL',
              labelStyle: TextStyle(color: Colors.grey.shade700),
              hintText: 'https://youtu...',
              hintStyle: TextStyle(color: Colors.grey.shade700),
              prefixIcon: const Icon(
                FontAwesomeIcons.youtube,
                color: Colors.red,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade800),
                borderRadius: BorderRadius.circular(15),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '* videos that are age restricted will not work.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCenterContent() {
    if (_isDownloading) {
      final int litSeeds = (_progress * maxSeeds).round();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 150,
            child: SunflowerWidget(litSeeds),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
          ),
        ],
      );
    } else if (_statusMessage == 'Download Complete!') {
      return Text(
        'Download Complete!',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'DancingScript',
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF1C96D),
        ),
      );
    } else if (_statusMessage.isNotEmpty) {
      return Text(
        _statusMessage,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  // ------------ Helper Widget: Download Button ------------
  Widget _buildDownloadButton() {
    return ElevatedButton(
      onPressed: _downloadAudio,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFFFC589A),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: const Text(
        'Download Audio',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 50.0, left: 10.0, right: 10.0, bottom: 0),
                child: _buildInputForm(),
              ),
              const SizedBox(height: 40),
              Container(
                alignment: Alignment.center,
                height: screenHeight * 0.4,
                child: _buildCenterContent(),
              ),
            ],
          ),
          if (!_isDownloading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 50,
              child: Center(
                child: _buildDownloadButton(),
              ),
            ),
        ],
      ),
    );
  }
}
