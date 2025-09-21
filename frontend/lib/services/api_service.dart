import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Base URL for the API (change this to your Django server's address)
  final String baseUrl = 'http://10.0.2.2:8000/api';  // 10.0.2.2 points to host's localhost from Android emulator
  
  // Function to upload song and voice files
  Future<Map<String, dynamic>> uploadFiles({
    required File songFile, 
    required File voiceFile, 
    required bool consentAccepted
  }) async {
    // Create a multipart request
    var uri = Uri.parse('$baseUrl/upload/');
    var request = http.MultipartRequest('POST', uri);
    
    // Add song file to request
    request.files.add(await http.MultipartFile.fromPath(
      'song_file',
      songFile.path,
      contentType: MediaType('audio', songFile.path.endsWith('.mp3') ? 'mpeg' : 'wav'),
    ));
    
    // Add voice file to request
    request.files.add(await http.MultipartFile.fromPath(
      'voice_file',
      voiceFile.path,
      contentType: MediaType('audio', 'wav'),
    ));
    
    // Add consent field
    request.fields['consent_accepted'] = consentAccepted.toString();
    
    // Send the request
    var response = await request.send();
    
    // Check if the upload was successful
    if (response.statusCode == 201) {
      // Parse and return the response
      final responseData = await response.stream.bytesToString();
      return jsonDecode(responseData);
    } else {
      // Handle errors
      final errorResponse = await response.stream.bytesToString();
      throw Exception('Failed to upload files: ${response.statusCode}, $errorResponse');
    }
  }
  
  // Function to check job status
  Future<Map<String, dynamic>> checkJobStatus(String jobId) async {
    final response = await http.get(Uri.parse('$baseUrl/job/$jobId/'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check job status: ${response.statusCode}');
    }
  }
  
  // Record user's consent (optional, as consent is also sent with the upload)
  Future<Map<String, dynamic>> recordConsent() async {
    final response = await http.post(Uri.parse('$baseUrl/consent/'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to record consent: ${response.statusCode}');
    }
  }
}
