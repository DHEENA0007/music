import 'dart:async';
import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class ProgressScreen extends StatefulWidget {
  final Job job;

  const ProgressScreen({
    super.key,
    required this.job,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Job _currentJob;
  final ApiService _apiService = ApiService();
  Timer? _pollingTimer;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentJob = widget.job;
    
    // Start polling for job status
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final response = await _apiService.checkJobStatus(_currentJob.id);
        final updatedJob = Job.fromJson(response);
        
        setState(() {
          _currentJob = updatedJob;
          
          // Update progress based on status
          if (updatedJob.status == 'queued') {
            _progress = 0.1;
          } else if (updatedJob.status == 'processing') {
            // Gradually increase progress for better UX
            if (_progress < 0.9) {
              _progress += 0.1;
            }
          } else if (updatedJob.status == 'completed') {
            _progress = 1.0;
            _pollingTimer?.cancel();
            
            // Navigate to result screen after a short delay
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultScreen(job: _currentJob),
                  ),
                );
              }
            });
          } else if (updatedJob.status == 'failed') {
            _pollingTimer?.cancel();
          }
        });
      } catch (e) {
        debugPrint('Error polling job status: $e');
      }
    });
  }

  String _getStatusMessage() {
    switch (_currentJob.status) {
      case 'queued':
        return 'Your job is queued and will start processing soon...';
      case 'processing':
        return 'Processing your voice clone...';
      case 'completed':
        return 'Voice cloning completed!';
      case 'failed':
        return 'Error: ${_currentJob.errorMessage ?? 'Unknown error occurred'}';
      default:
        return 'Waiting for status update...';
    }
  }

  Widget _buildProgressIndicator() {
    if (_currentJob.status == 'failed') {
      return const Icon(
        Icons.error_outline,
        color: Colors.red,
        size: 80,
      );
    } else {
      return Column(
        children: [
          CircularProgressIndicator(
            value: _currentJob.status == 'completed' ? 1.0 : null,
            strokeWidth: 6,
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: _progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 40),
              Text(
                _getStatusMessage(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Job ID: ${_currentJob.id}',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              
              // Show error details if the job failed
              if (_currentJob.status == 'failed') 
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go Back'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
