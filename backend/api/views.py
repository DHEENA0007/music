from rest_framework import viewsets, status, permissions
from rest_framework.response import Response
from rest_framework.decorators import action
from django.shortcuts import get_object_or_404
from .models import Job
from .serializers import JobSerializer, JobStatusSerializer
from .tasks import process_voice_clone

class JobViewSet(viewsets.ModelViewSet):
    """ViewSet for handling Job resources"""
    queryset = Job.objects.all().order_by('-created_at')
    permission_classes = [permissions.AllowAny]  # For demo purposes
    
    def get_serializer_class(self):
        """Return different serializers based on action"""
        if self.action == 'retrieve' or self.action == 'status':
            return JobStatusSerializer
        return JobSerializer
    
    def create(self, request, *args, **kwargs):
        """Create a new job with uploaded files"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        job = serializer.save()
        
        # Start the background task
        process_voice_clone.delay(str(job.id))
        
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
    @action(detail=True, methods=['get'])
    def status(self, request, pk=None):
        """Endpoint for checking job status"""
        job = get_object_or_404(Job, pk=pk)
        serializer = self.get_serializer(job)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def consent(self, request):
        """Record user's consent (this is mostly a placeholder endpoint)"""
        return Response({'status': 'Consent recorded'}, status=status.HTTP_200_OK)
