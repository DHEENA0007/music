import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/job.dart';
import 'progress_screen.dart';

class ConsentScreen extends StatefulWidget {
  final File songFile;
  final File voiceFile;

  const ConsentScreen({
    super.key,
    required this.songFile,
    required this.voiceFile,
  });

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _consentAccepted = false;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _uploadFiles() async {
    if (!_consentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the consent before proceeding.'),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _apiService.uploadFiles(
        songFile: widget.songFile,
        voiceFile: widget.voiceFile,
        consentAccepted: _consentAccepted,
      );

      setState(() {
        _isLoading = false;
      });

      // Navigate to progress screen with job ID
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProgressScreen(
            job: Job.fromJson(response),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consent'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Uploading files...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // Consent card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Consent Agreement',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'By checking the box below, you confirm that:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '• You own the rights to the voice sample or have permission from the owner.\n\n'
                            '• You understand that this voice will be used to clone vocals in the song you uploaded.\n\n'
                            '• You agree not to use this service for any harmful, deceptive, or illegal purposes.\n\n'
                            '• You understand that the result is for personal, non-commercial use only.',
                          ),
                          const SizedBox(height: 20),
                          
                          // Consent checkbox
                          CheckboxListTile(
                            title: const Text(
                              'I confirm that I own or have permission to use this voice sample',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            value: _consentAccepted,
                            onChanged: (value) {
                              setState(() {
                                _consentAccepted = value ?? false;
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Process button
                  ElevatedButton(
                    onPressed: _uploadFiles,
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
                    child: const Text('Process My Voice Clone'),
                  ),
                ],
              ),
            ),
    );
  }
}
