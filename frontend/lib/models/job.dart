class Job {
  final String id;
  final String status;
  final String? resultUrl;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Job({
    required this.id,
    required this.status,
    this.resultUrl,
    this.errorMessage,
    this.createdAt,
    this.updatedAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      status: json['status'],
      resultUrl: json['result_url'],
      errorMessage: json['error_message'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  // Check if the job is completed
  bool get isCompleted => status == 'completed';
  
  // Check if the job is in progress
  bool get isProcessing => status == 'processing' || status == 'queued';
  
  // Check if the job has failed
  bool get isFailed => status == 'failed';
}
