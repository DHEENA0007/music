import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/job.dart';
import 'upload_screen.dart';

class ResultScreen extends StatefulWidget {
  final Job job;
  
  const ResultScreen({
    super.key,
    required this.job,
  });
  
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isDownloading = false;
  String? _downloadedFilePath;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadAudio();
    
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (state.playing != _isPlaying) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
    
    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _position = position;
      });
    });
    
    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  
  Future<void> _loadAudio() async {
    if (widget.job.resultUrl != null) {
      try {
        await _audioPlayer.setUrl(widget.job.resultUrl!);
      } catch (e) {
        debugPrint('Error loading audio: $e');
      }
    }
  }
  
  Future<void> _downloadAudio() async {
    if (widget.job.resultUrl == null) return;
    
    setState(() {
      _isDownloading = true;
    });
    
    try {
      final dio = Dio();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'voice_clone_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final path = '${directory.path}/$fileName';
      
      await dio.download(
        widget.job.resultUrl!,
        path,
        onReceiveProgress: (received, total) {
          debugPrint('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
        },
      );
      
      setState(() {
        _isDownloading = false;
        _downloadedFilePath = path;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File downloaded to: $path'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _shareAudio() async {
    String? filePath = _downloadedFilePath;
    
    // Download the file first if not already downloaded
    if (filePath == null) {
      await _downloadAudio();
      filePath = _downloadedFilePath;
    }
    
    if (filePath != null) {
      await Share.shareFiles([filePath], text: 'Check out my voice clone!');
    }
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Voice Clone'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Voice Cloning Complete!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              
              // Audio player card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Play/Pause button
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          size: 64,
                        ),
                        onPressed: () {
                          if (_isPlaying) {
                            _audioPlayer.pause();
                          } else {
                            _audioPlayer.play();
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      
                      // Progress slider
                      Slider(
                        value: _position.inSeconds.toDouble(),
                        min: 0,
                        max: _duration.inSeconds.toDouble() + 1.0,
                        onChanged: (value) {
                          _audioPlayer.seek(Duration(seconds: value.toInt()));
                        },
                      ),
                      
                      // Duration text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(_position)),
                            Text(_formatDuration(_duration)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Download and Share buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadAudio,
                    icon: _isDownloading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _shareAudio,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Start new button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const UploadScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Create Another Voice Clone'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
