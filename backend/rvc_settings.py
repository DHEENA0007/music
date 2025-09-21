# RVC Configuration for Django Settings

# Add these to your Django settings.py file:

# RVC Model Configuration
RVC_MODEL_PATH = os.path.join(BASE_DIR, 'models', 'rvc_model.pth')
RVC_HUBERT_PATH = os.path.join(BASE_DIR, 'models', 'hubert_base.pt')
RVC_INDEX_ROOT = os.path.join(BASE_DIR, 'models', 'indices')
RVC_WEIGHT_ROOT = os.path.join(BASE_DIR, 'models', 'weights')

# RVC Processing Settings
RVC_SETTINGS = {
    'device': 'cuda:0' if torch.cuda.is_available() else 'cpu',
    'is_half': True,  # Use FP16 for faster processing (requires compatible GPU)
    'f0_method': 'rmvpe',  # Default pitch extraction method
    'index_rate': 0.75,
    'filter_radius': 3,
    'rms_mix_rate': 0.25,
    'protect': 0.33,
}

# UVR5 Model Settings
UVR5_MODEL_PATH = os.path.join(BASE_DIR, 'models', 'uvr5')
UVR5_DEFAULT_MODEL = 'UVR-MDX-NET-Voc_FT'

# Audio Processing Settings
AUDIO_PROCESSING = {
    'sample_rate': 44100,
    'bit_rate': '192k',
    'format': 'wav',
    'max_file_size': 100 * 1024 * 1024,  # 100MB
    'allowed_formats': ['wav', 'mp3', 'flac', 'm4a', 'aac'],
}

# Celery Configuration for RVC
CELERY_TASK_ROUTES = {
    'api.tasks.process_voice_clone': {'queue': 'voice_clone'},
}

# Create models directory structure
import os
MODEL_DIRS = [
    os.path.join(BASE_DIR, 'models'),
    os.path.join(BASE_DIR, 'models', 'weights'),
    os.path.join(BASE_DIR, 'models', 'indices'),
    os.path.join(BASE_DIR, 'models', 'uvr5'),
    os.path.join(BASE_DIR, 'models', 'hubert'),
]

for dir_path in MODEL_DIRS:
    os.makedirs(dir_path, exist_ok=True)

# Logging Configuration for RVC
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': os.path.join(BASE_DIR, 'logs', 'rvc.log'),
            'formatter': 'verbose',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'api.rvc_integration': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': True,
        },
        'api.tasks': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}
