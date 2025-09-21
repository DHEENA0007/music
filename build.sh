#!/bin/bash

# Music AI Voice Cloning Application Build Script
# This script sets up the complete application with RVC integration

set -e  # Exit on any error

echo "🎵 Music AI Voice Cloning - Build Script"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if we're in the right directory
if [ ! -d "backend" ] || [ ! -d "frontend" ] || [ ! -d "Retrieval-based-Voice-Conversion" ]; then
    print_error "Please run this script from the music-ai directory"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
echo -e "\n${BLUE}1. Checking System Requirements${NC}"
echo "--------------------------------"

# Check Python
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version | cut -d ' ' -f 2)
    print_status "Python $PYTHON_VERSION found"
else
    print_error "Python 3 is required but not found"
    exit 1
fi

# Check Node.js (for potential future needs)
if command_exists node; then
    NODE_VERSION=$(node --version)
    print_status "Node.js $NODE_VERSION found"
fi

# Check Flutter
if command_exists flutter; then
    FLUTTER_VERSION=$(flutter --version | head -n 1 | cut -d ' ' -f 2)
    print_status "Flutter $FLUTTER_VERSION found"
else
    print_warning "Flutter not found - you'll need it for the mobile app"
fi

# Check Redis
if command_exists redis-server; then
    print_status "Redis server found"
else
    print_warning "Redis not found - install with: sudo apt install redis-server"
fi

# Check FFmpeg
if command_exists ffmpeg; then
    print_status "FFmpeg found"
else
    print_warning "FFmpeg not found - install with: sudo apt install ffmpeg"
fi

# Setup Backend
echo -e "\n${BLUE}2. Setting Up Backend${NC}"
echo "---------------------"

cd backend

# Create virtual environment
if [ ! -d "venv" ]; then
    print_info "Creating Python virtual environment..."
    python3 -m venv venv
    print_status "Virtual environment created"
fi

# Activate virtual environment
print_info "Activating virtual environment..."
source venv/bin/activate

# Install RVC package first
print_info "Installing RVC package from GitHub..."
pip install git+https://github.com/RVC-Project/Retrieval-based-Voice-Conversion.git || {
    print_warning "RVC package installation failed, continuing with local setup..."
}

# Install Python dependencies
print_info "Installing Python dependencies..."
pip install -r requirements.txt
print_status "Python dependencies installed"

# Copy RVC source code to backend
if [ -d "../Retrieval-based-Voice-Conversion/rvc" ]; then
    print_info "Copying RVC source code..."
    cp -r ../Retrieval-based-Voice-Conversion/rvc ./rvc_source/
    print_status "RVC source code copied"
fi

# Run RVC setup script
if [ -f "setup_rvc.py" ]; then
    print_info "Running RVC setup..."
    python setup_rvc.py
    print_status "RVC setup completed"
fi

# Django setup
print_info "Setting up Django..."

# Create migrations
python manage.py makemigrations
python manage.py migrate
print_status "Database migrations completed"

# Collect static files (if needed)
# python manage.py collectstatic --noinput

cd ..

# Setup Frontend
echo -e "\n${BLUE}3. Setting Up Frontend${NC}"
echo "----------------------"

cd frontend

if command_exists flutter; then
    print_info "Getting Flutter dependencies..."
    flutter pub get
    print_status "Flutter dependencies installed"
    
    print_info "Running Flutter doctor..."
    flutter doctor
else
    print_warning "Skipping Flutter setup - Flutter not installed"
fi

cd ..

# Setup RVC Models
echo -e "\n${BLUE}4. Setting Up RVC Models${NC}"
echo "------------------------"

# Create models directory structure
mkdir -p backend/models/{weights,indices,uvr5,hubert}

print_info "Model directories created"
print_warning "You need to download RVC models manually:"
print_warning "1. Download HuBERT model: https://huggingface.co/rvc-models/hubert-base"
print_warning "2. Download voice models: https://huggingface.co/rvc-models"
print_warning "3. Download UVR5 models: https://github.com/TRvlvr/model_repo/releases"

# Create example .env file
if [ ! -f "backend/.env" ]; then
    print_info "Creating example .env file..."
    cat > backend/.env << EOF
# Django Configuration
DEBUG=True
SECRET_KEY=your-very-secret-key-change-this-in-production
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DATABASE_URL=sqlite:///db.sqlite3

# Celery Configuration  
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# RVC Configuration
RVC_MODEL_PATH=./models/weights/default_model.pth
RVC_HUBERT_PATH=./models/hubert/hubert_base.pt
RVC_INDEX_ROOT=./models/indices/
RVC_WEIGHT_ROOT=./models/weights/
UVR5_MODEL_PATH=./models/uvr5/

# Audio Processing
MAX_UPLOAD_SIZE=104857600
ALLOWED_AUDIO_FORMATS=wav,mp3,flac,m4a,aac
EOF
    print_status "Example .env file created"
fi

# Create startup scripts
echo -e "\n${BLUE}5. Creating Startup Scripts${NC}"
echo "----------------------------"

# Backend startup script
cat > start_backend.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting Music AI Backend..."

# Check if virtual environment exists
if [ ! -d "backend/venv" ]; then
    echo "❌ Virtual environment not found. Run build.sh first."
    exit 1
fi

# Start Redis (if not running)
if ! pgrep redis-server > /dev/null; then
    echo "📡 Starting Redis server..."
    redis-server --daemonize yes
fi

cd backend

# Activate virtual environment
source venv/bin/activate

# Start Celery worker in background
echo "🔄 Starting Celery worker..."
celery -A music_voice_clone worker --loglevel=info --detach

# Start Django development server
echo "🌐 Starting Django server..."
python manage.py runserver 0.0.0.0:8000
EOF

# Frontend startup script
cat > start_frontend.sh << 'EOF'
#!/bin/bash

echo "📱 Starting Music AI Frontend..."

cd frontend

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Start Flutter app
echo "🚀 Starting Flutter app..."
flutter run
EOF

# Stop script
cat > stop_services.sh << 'EOF'
#!/bin/bash

echo "🛑 Stopping Music AI services..."

# Stop Celery workers
pkill -f "celery.*worker" && echo "✓ Celery workers stopped"

# Stop Django
pkill -f "manage.py runserver" && echo "✓ Django server stopped"

# Stop Redis (optional)
# pkill redis-server && echo "✓ Redis server stopped"

echo "🏁 All services stopped"
EOF

# Make scripts executable
chmod +x start_backend.sh start_frontend.sh stop_services.sh

print_status "Startup scripts created"

# Create development VS Code configuration
mkdir -p .vscode

cat > .vscode/launch.json << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Django",
            "type": "python",
            "request": "launch",
            "program": "${workspaceFolder}/backend/manage.py",
            "args": ["runserver"],
            "django": true,
            "cwd": "${workspaceFolder}/backend",
            "env": {
                "DJANGO_SETTINGS_MODULE": "music_voice_clone.settings"
            }
        },
        {
            "name": "Flutter",
            "type": "dart",
            "request": "launch",
            "program": "${workspaceFolder}/frontend/lib/main.dart",
            "cwd": "${workspaceFolder}/frontend"
        }
    ]
}
EOF

cat > .vscode/settings.json << 'EOF'
{
    "python.pythonPath": "./backend/venv/bin/python",
    "python.defaultInterpreterPath": "./backend/venv/bin/python",
    "files.exclude": {
        "**/venv": true,
        "**/__pycache__": true,
        "**/node_modules": true,
        "**/.flutter-plugins": true,
        "**/.flutter-plugins-dependencies": true
    }
}
EOF

print_status "VS Code configuration created"

# Final setup summary
echo -e "\n${GREEN}🎉 Build Complete!${NC}"
echo "=================="

echo -e "\n${BLUE}Next Steps:${NC}"
echo "1. Download required models (see RVC_INTEGRATION_GUIDE.md)"
echo "2. Update backend/.env with your settings"
echo "3. Start services:"
echo "   - Backend: ./start_backend.sh"
echo "   - Frontend: ./start_frontend.sh"

echo -e "\n${BLUE}Useful Commands:${NC}"
echo "- Stop all services: ./stop_services.sh"
echo "- View logs: tail -f backend/logs/rvc.log"
echo "- Django admin: cd backend && python manage.py createsuperuser"

echo -e "\n${BLUE}URLs:${NC}"
echo "- API: http://localhost:8000/api/"
echo "- Admin: http://localhost:8000/admin/"
echo "- Docs: See RVC_INTEGRATION_GUIDE.md"

echo -e "\n${YELLOW}Important:${NC}"
echo "- Install Redis: sudo apt install redis-server"
echo "- Install FFmpeg: sudo apt install ffmpeg" 
echo "- Download RVC models before first use"

echo -e "\n${GREEN}Build completed successfully!${NC} 🚀"
EOF
