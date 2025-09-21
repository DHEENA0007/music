# RVC Voice Cloning Integration Guide

This document explains how to integrate the Retrieval-based-Voice-Conversion (RVC) system into your existing music-AI application.

## Overview

RVC is a state-of-the-art voice conversion framework that can:
1. **Source Separation**: Extract vocals from songs using UVR5 models
2. **Voice Conversion**: Convert vocals to match a target voice using trained RVC models
3. **Audio Mixing**: Combine converted vocals with instrumental tracks

## Architecture Integration

### Current Flow
```
Flutter App → Django API → Celery Tasks → [Placeholder Processing] → Results
```

### New Flow with RVC
```
Flutter App → Django API → Celery Tasks → RVC Pipeline → Results
                                          ↓
                                    1. UVR5 Separation
                                    2. RVC Voice Conversion  
                                    3. Audio Mixing
```

## Installation Steps

### 1. Install RVC Dependencies

```bash
cd /home/dheena/Documents/music-ai/backend
pip install -r requirements.txt
python setup_rvc.py
```

### 2. Download Required Models

The setup script will download:
- **HuBERT Base Model**: For speech feature extraction
- **RMVPE Model**: For pitch estimation  
- **UVR5 Models**: For vocal separation

### 3. Download RVC Voice Model

You need an RVC voice model (.pth file) for voice conversion:

```bash
# Example: Download a pre-trained model
wget https://huggingface.co/rvc-models/example-voice/resolve/main/model.pth -O models/weights/voice_model.pth
```

### 4. System Dependencies

Install system-level dependencies:

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ffmpeg libsndfile1 libsndfile1-dev

# macOS
brew install ffmpeg libsndfile

# Windows
# Download and install FFmpeg from https://ffmpeg.org/
```

## Configuration

### 1. Django Settings

Add to your `settings.py`:

```python
# Import RVC settings
from .rvc_settings import *

# Add to INSTALLED_APPS if needed
INSTALLED_APPS = [
    # ... existing apps
    'api',
]

# Media files configuration
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
```

### 2. Environment Variables

Update your `.env` file:

```env
# RVC Configuration
RVC_MODEL_PATH=./models/weights/voice_model.pth
RVC_HUBERT_PATH=./models/hubert/hubert_base.pt
RVC_INDEX_ROOT=./models/indices/
RVC_WEIGHT_ROOT=./models/weights/
UVR5_MODEL_PATH=./models/uvr5/

# Redis for Celery
REDIS_URL=redis://localhost:6379/0
```

### 3. Celery Configuration

Update `celery.py`:

```python
from celery import Celery
import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'music_voice_clone.settings')

app = Celery('music_voice_clone')
app.config_from_object('django.conf:settings', namespace='CELERY')

# Configure RVC-specific queue
app.conf.task_routes = {
    'api.tasks.process_voice_clone': {'queue': 'voice_clone'},
}

app.autodiscover_tasks()
```

## Usage

### 1. Start Services

```bash
# Terminal 1: Start Redis
redis-server

# Terminal 2: Start Celery Worker
cd /home/dheena/Documents/music-ai/backend
celery -A music_voice_clone worker --loglevel=info --queue=voice_clone

# Terminal 3: Start Django
python manage.py runserver
```

### 2. API Usage

The existing API endpoints remain the same:

```bash
# Create a voice cloning job
curl -X POST http://localhost:8000/api/jobs/ \
  -F "song_file=@song.mp3" \
  -F "voice_file=@voice_sample.wav" \
  -F "consent_accepted=true"

# Check job status
curl -X GET http://localhost:8000/api/jobs/{job_id}/status/
```

### 3. Flutter Integration

No changes required in Flutter app - the existing UI will work with the new RVC backend.

## RVC Pipeline Details

### 1. Source Separation (UVR5)
- **Input**: Original song file
- **Output**: Vocals + Instrumental tracks
- **Models**: UVR-MDX-NET-Voc_FT (default)
- **Quality**: Professional-grade separation

### 2. Voice Conversion (RVC)
- **Input**: Extracted vocals + Target voice sample
- **Output**: Converted vocals matching target voice
- **Parameters**:
  - `f0_up_key`: Pitch shift (-12 to +12 semitones)
  - `f0_method`: Pitch extraction (rmvpe, harvest, pm, dio)
  - `index_rate`: Feature matching strength (0.0-1.0)
  - `protect`: Consonant protection (0.0-0.5)

### 3. Audio Mixing
- **Input**: Converted vocals + Original instrumental
- **Output**: Final mixed song
- **Features**: Volume balancing, sample rate matching

## Customization Options

### 1. Voice Model Training

Train custom RVC models:

```bash
# Use RVC training pipeline
rvc train --input_dir ./voice_samples --model_name custom_voice
```

### 2. Parameter Tuning

Adjust RVC parameters in `rvc_integration.py`:

```python
# Custom parameters for better quality
params = {
    'f0_up_key': 2,        # Slight pitch increase
    'f0_method': 'rmvpe',  # Best quality pitch extraction
    'index_rate': 0.8,     # Higher feature matching
    'protect': 0.25,       # Moderate consonant protection
}
```

### 3. Multiple Voice Models

Support multiple voices:

```python
# In views.py
@action(detail=False, methods=['get'])
def available_voices(self, request):
    """List available voice models"""
    voices = []
    weights_dir = settings.RVC_WEIGHT_ROOT
    for file in os.listdir(weights_dir):
        if file.endswith('.pth'):
            voices.append({
                'id': file,
                'name': file.replace('.pth', '').replace('_', ' ').title()
            })
    return Response({'voices': voices})
```

## Performance Optimization

### 1. GPU Acceleration

Enable CUDA if available:

```python
# In RVC_SETTINGS
RVC_SETTINGS = {
    'device': 'cuda:0' if torch.cuda.is_available() else 'cpu',
    'is_half': True,  # Use FP16 for 2x speed boost
}
```

### 2. Model Caching

Keep models loaded in memory:

```python
# Global model instance
rvc_cloner = RVCVoiceCloner()

# Load model once at startup
rvc_cloner.load_model(settings.RVC_MODEL_PATH)
```

### 3. Batch Processing

Process multiple jobs efficiently:

```python
@shared_task
def process_batch_voice_clone(job_ids):
    """Process multiple voice cloning jobs in batch"""
    for job_id in job_ids:
        process_voice_clone.delay(job_id)
```

## Monitoring and Debugging

### 1. Logs

Monitor RVC processing:

```bash
# View RVC logs
tail -f logs/rvc.log

# View Celery logs  
celery -A music_voice_clone worker --loglevel=debug
```

### 2. Error Handling

Common issues and solutions:

- **CUDA Out of Memory**: Reduce batch size or use CPU
- **Model Not Found**: Check model paths in .env
- **Audio Format Issues**: Ensure FFmpeg is installed
- **Long Processing Times**: Use GPU acceleration

### 3. Quality Assessment

Test voice quality:

```python
# Add quality metrics to job model
class Job(models.Model):
    # ... existing fields
    quality_score = models.FloatField(null=True, blank=True)
    processing_time = models.DurationField(null=True, blank=True)
```

## Deployment Considerations

### 1. Docker Integration

Create Dockerfile with RVC:

```dockerfile
FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsndfile1 \
    libsndfile1-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application
COPY . /app
WORKDIR /app

# Download models
RUN python setup_rvc.py

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```

### 2. Production Settings

```python
# Production RVC settings
RVC_SETTINGS = {
    'device': 'cuda:0',
    'is_half': True,
    'batch_size': 4,  # Process multiple files
    'num_workers': 2, # Parallel processing
}
```

### 3. Storage Configuration

Use cloud storage for models:

```python
# AWS S3 model storage
AWS_S3_CUSTOM_DOMAIN = 'your-bucket.s3.amazonaws.com'
RVC_MODEL_PATH = f'https://{AWS_S3_CUSTOM_DOMAIN}/models/voice_model.pth'
```

## Next Steps

1. **Run Setup**: Execute `python setup_rvc.py`
2. **Download Models**: Get RVC voice models from HuggingFace
3. **Test Integration**: Upload a song and voice sample
4. **Optimize Parameters**: Tune RVC settings for your use case
5. **Scale Infrastructure**: Add GPU support and load balancing

## Resources

- **RVC Project**: https://github.com/RVC-Project/Retrieval-based-Voice-Conversion
- **Models**: https://huggingface.co/rvc-models
- **Documentation**: https://github.com/RVC-Project/Retrieval-based-Voice-Conversion/wiki
- **Community**: https://discord.gg/HcsmBBGyVk
