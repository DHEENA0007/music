from django.db import models
import uuid
import os

def song_upload_path(instance, filename):
    """Generate file path for uploaded song files"""
    ext = filename.split('.')[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    return os.path.join('songs', filename)

def voice_upload_path(instance, filename):
    """Generate file path for uploaded voice files"""
    ext = filename.split('.')[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    return os.path.join('voices', filename)

def output_path(instance, filename):
    """Generate file path for result files"""
    ext = 'mp3'  # Always save as mp3
    filename = f"{uuid.uuid4()}.{ext}"
    return os.path.join('outputs', filename)

class Job(models.Model):
    """Job model to track voice cloning processes"""
    
    STATUS_CHOICES = (
        ('queued', 'Queued'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
    )
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    song_file = models.FileField(upload_to=song_upload_path)
    voice_file = models.FileField(upload_to=voice_upload_path)
    consent_accepted = models.BooleanField(default=False)
    result_file = models.FileField(upload_to=output_path, null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='queued')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    error_message = models.TextField(blank=True, null=True)
    
    def __str__(self):
        return f"Job {self.id} - {self.status}"
