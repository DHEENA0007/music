from rest_framework import serializers
from .models import Job

class JobSerializer(serializers.ModelSerializer):
    """Serializer for Job model"""
    result_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Job
        fields = ['id', 'song_file', 'voice_file', 'consent_accepted', 
                  'status', 'created_at', 'updated_at', 'result_url']
        read_only_fields = ['id', 'status', 'created_at', 'updated_at', 'result_url']
    
    def get_result_url(self, obj):
        """Return the URL of the result file if available"""
        if obj.result_file and obj.status == 'completed':
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.result_file.url)
        return None

    def validate(self, data):
        """Validate the input data"""
        # Check if consent is accepted
        if not data.get('consent_accepted'):
            raise serializers.ValidationError("You must accept the consent to use this service.")
        
        # Validate file types
        song_file = data.get('song_file')
        voice_file = data.get('voice_file')
        
        if song_file and not song_file.name.lower().endswith(('.mp3', '.wav')):
            raise serializers.ValidationError("Song file must be in MP3 or WAV format.")
        
        if voice_file and not voice_file.name.lower().endswith('.wav'):
            raise serializers.ValidationError("Voice sample must be in WAV format.")
            
        return data

class JobStatusSerializer(serializers.ModelSerializer):
    """Simplified serializer for checking job status"""
    result_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Job
        fields = ['id', 'status', 'result_url', 'error_message']
        read_only_fields = ['id', 'status', 'result_url', 'error_message']
    
    def get_result_url(self, obj):
        """Return the URL of the result file if available"""
        if obj.result_file and obj.status == 'completed':
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.result_file.url)
        return None
