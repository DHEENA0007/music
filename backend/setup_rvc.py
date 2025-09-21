#!/usr/bin/env python3
"""
Setup script for RVC Voice Cloning Integration
This script helps set up the required models and dependencies for RVC voice cloning.
"""

import os
import sys
import subprocess
import requests
import zipfile
from pathlib import Path

def create_directories():
    """Create necessary directories for RVC models"""
    base_dir = Path(__file__).parent
    directories = [
        base_dir / 'models',
        base_dir / 'models' / 'weights',
        base_dir / 'models' / 'indices', 
        base_dir / 'models' / 'uvr5',
        base_dir / 'models' / 'hubert',
        base_dir / 'logs',
        base_dir / 'media' / 'songs',
        base_dir / 'media' / 'voices',
        base_dir / 'media' / 'outputs',
    ]
    
    for directory in directories:
        directory.mkdir(parents=True, exist_ok=True)
        print(f"✓ Created directory: {directory}")

def download_file(url, destination):
    """Download a file from URL to destination"""
    print(f"Downloading {url}...")
    response = requests.get(url, stream=True)
    response.raise_for_status()
    
    with open(destination, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
    
    print(f"✓ Downloaded: {destination}")

def download_hubert_model():
    """Download HuBERT base model"""
    hubert_url = "https://huggingface.co/rvc-models/hubert-base/resolve/main/hubert_base.pt"
    hubert_path = Path(__file__).parent / 'models' / 'hubert' / 'hubert_base.pt'
    
    if not hubert_path.exists():
        try:
            download_file(hubert_url, hubert_path)
        except Exception as e:
            print(f"❌ Failed to download HuBERT model: {e}")
            print("Please download manually from: https://huggingface.co/rvc-models/hubert-base")
            return False
    else:
        print(f"✓ HuBERT model already exists: {hubert_path}")
    
    return True

def download_rmvpe_model():
    """Download RMVPE model for pitch extraction"""
    rmvpe_url = "https://huggingface.co/rvc-models/rmvpe/resolve/main/rmvpe.pt"
    rmvpe_path = Path(__file__).parent / 'models' / 'rmvpe.pt'
    
    if not rmvpe_path.exists():
        try:
            download_file(rmvpe_url, rmvpe_path)
        except Exception as e:
            print(f"❌ Failed to download RMVPE model: {e}")
            print("Please download manually from: https://huggingface.co/rvc-models/rmvpe")
            return False
    else:
        print(f"✓ RMVPE model already exists: {rmvpe_path}")
    
    return True

def download_uvr5_models():
    """Download UVR5 models for source separation"""
    uvr5_models = {
        "UVR-MDX-NET-Voc_FT.onnx": "https://github.com/TRvlvr/model_repo/releases/download/all_public_uvr_models/UVR-MDX-NET-Voc_FT.onnx",
        "UVR_MDXNET_KARA_2.onnx": "https://github.com/TRvlvr/model_repo/releases/download/all_public_uvr_models/UVR_MDXNET_KARA_2.onnx",
    }
    
    uvr5_dir = Path(__file__).parent / 'models' / 'uvr5'
    
    for model_name, url in uvr5_models.items():
        model_path = uvr5_dir / model_name
        if not model_path.exists():
            try:
                download_file(url, model_path)
            except Exception as e:
                print(f"❌ Failed to download {model_name}: {e}")
                continue
        else:
            print(f"✓ UVR5 model already exists: {model_path}")

def install_rvc_package():
    """Install RVC package from GitHub"""
    try:
        # Install RVC from the GitHub repository
        subprocess.run([
            sys.executable, "-m", "pip", "install", 
            "git+https://github.com/RVC-Project/Retrieval-based-Voice-Conversion.git"
        ], check=True)
        print("✓ RVC package installed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install RVC package: {e}")
        return False

def install_dependencies():
    """Install required dependencies"""
    try:
        subprocess.run([
            sys.executable, "-m", "pip", "install", "-r", "requirements.txt"
        ], check=True)
        print("✓ Dependencies installed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install dependencies: {e}")
        return False

def setup_environment():
    """Create .env file with RVC settings"""
    env_content = """# RVC Configuration
RVC_MODEL_PATH=./models/weights/
RVC_HUBERT_PATH=./models/hubert/hubert_base.pt
RVC_INDEX_ROOT=./models/indices/
RVC_WEIGHT_ROOT=./models/weights/
RVC_RMVPE_PATH=./models/rmvpe.pt
UVR5_MODEL_PATH=./models/uvr5/

# Django Settings
DEBUG=True
SECRET_KEY=your-secret-key-here
DATABASE_URL=sqlite:///db.sqlite3

# Celery Settings
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0
"""
    
    env_path = Path(__file__).parent / '.env'
    if not env_path.exists():
        with open(env_path, 'w') as f:
            f.write(env_content)
        print(f"✓ Created .env file: {env_path}")
    else:
        print(f"✓ .env file already exists: {env_path}")

def check_system_requirements():
    """Check if system has required dependencies"""
    requirements = {
        'python': sys.version_info >= (3, 8),
        'pip': True,
    }
    
    # Check for CUDA
    try:
        import torch
        cuda_available = torch.cuda.is_available()
        print(f"✓ PyTorch CUDA available: {cuda_available}")
    except ImportError:
        print("❌ PyTorch not installed")
    
    # Check for ffmpeg
    try:
        subprocess.run(['ffmpeg', '-version'], capture_output=True, check=True)
        print("✓ FFmpeg is available")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ FFmpeg not found. Please install FFmpeg for audio processing.")
        print("   Ubuntu/Debian: sudo apt install ffmpeg")
        print("   macOS: brew install ffmpeg")
        print("   Windows: Download from https://ffmpeg.org/")

def main():
    """Main setup function"""
    print("🎵 Setting up RVC Voice Cloning Integration...")
    print("=" * 50)
    
    # Check system requirements
    print("\n1. Checking system requirements...")
    check_system_requirements()
    
    # Create directories
    print("\n2. Creating directories...")
    create_directories()
    
    # Install dependencies
    print("\n3. Installing dependencies...")
    if not install_dependencies():
        print("❌ Failed to install dependencies. Please check the error messages above.")
        return False
    
    # Install RVC package
    print("\n4. Installing RVC package...")
    if not install_rvc_package():
        print("❌ Failed to install RVC package. Please check the error messages above.")
        return False
    
    # Download models
    print("\n5. Downloading models...")
    download_hubert_model()
    download_rmvpe_model()
    download_uvr5_models()
    
    # Setup environment
    print("\n6. Setting up environment...")
    setup_environment()
    
    print("\n" + "=" * 50)
    print("🎉 Setup completed!")
    print("\nNext steps:")
    print("1. Download an RVC voice model (.pth file) and place it in ./models/weights/")
    print("2. Update the .env file with your specific settings")
    print("3. Start Redis: redis-server")
    print("4. Start Celery worker: celery -A music_voice_clone worker --loglevel=info")
    print("5. Run Django: python manage.py runserver")
    print("\nFor voice models, visit: https://huggingface.co/rvc-models")
    
    return True

if __name__ == "__main__":
    main()
