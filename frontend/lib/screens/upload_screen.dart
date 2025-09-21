import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import 'consent_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _songFile;
  File? _voiceFile;
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  bool _recorderInitialized = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      debugPrint('Microphone permission not granted');
      return;
    }
    
    await _audioRecorder.openRecorder();
    _recorderInitialized = true;
  }

  @override
  void dispose() {
    if (_recorderInitialized) {
      _audioRecorder.closeRecorder();
    }
    super.dispose();
  }

  Future<void> _pickSongFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav'],
    );

    if (result != null) {
      setState(() {
        _songFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickVoiceFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav'],
    );

    if (result != null) {
      setState(() {
        _voiceFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!_recorderInitialized) {
        await _initRecorder();
      }
      
      // Get the temporary directory
      final directory = await getTemporaryDirectory();
      _recordingPath = '${directory.path}/voice_sample.wav';
      
      // Start recording
      await _audioRecorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.pcm16WAV,
        sampleRate: 44100,
        bitRate: 128000,
      );
      
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      debugPrint('Error recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stopRecorder();
      
      setState(() {
        _isRecording = false;
        if (path != null) {
          _voiceFile = File(path);
        }
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  void _proceedToConsent() {
    if (_songFile != null && _voiceFile != null) {
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => ConsentScreen(
            songFile: _songFile!,
            voiceFile: _voiceFile!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both a song and a voice sample.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Clone'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Song upload section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload a Song',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select an MP3 or WAV file',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _songFile != null
                        ? ListTile(
                            leading: const Icon(Icons.music_note),
                            title: Text(_songFile!.path.split('/').last),
                            subtitle: const Text('Song file selected'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => setState(() => _songFile = null),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _pickSongFile,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Select Song File'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Voice sample section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voice Sample',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload or record a voice sample (WAV)',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _voiceFile != null
                        ? ListTile(
                            leading: const Icon(Icons.record_voice_over),
                            title: Text(_voiceFile!.path.split('/').last),
                            subtitle: const Text('Voice sample selected'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => setState(() => _voiceFile = null),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickVoiceFile,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload Voice'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _isRecording ? _stopRecording : _startRecording,
                                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                                label: Text(_isRecording ? 'Stop Recording' : 'Record Voice'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isRecording ? Colors.red : null,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Continue button
            ElevatedButton(
              onPressed: _proceedToConsent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
