# Music Voice Clone App

A mobile application that allows users to upload a song file and a voice sample, then clones the song's vocals into the uploaded voice.

## Architecture

### Frontend (Flutter/Dart)

The frontend is built using Flutter and includes the following key features:

- Upload song files (MP3/WAV) and voice samples (WAV)
- Record voice samples directly from the app
- Consent screen for permission acknowledgment
- Job status tracking with progress indicators
- Audio playback for the resulting cloned track
- Download and share functionality

### Backend (Django/Python)

The backend is built with Django and Django REST Framework and provides:

- REST API endpoints for file uploads and job status
- Celery background tasks for processing audio
- Placeholder ML functions for:
  - Source separation (vocals/instrumental)
  - Voice conversion
  - Audio mixing

## Setup Instructions

### Backend Setup

1. Navigate to the backend directory:
   ```
   cd backend
   ```

2. Create and activate a virtual environment (optional but recommended):
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

4. Apply database migrations:
   ```
   python manage.py migrate
   ```

5. Start the Django development server:
   ```
   python manage.py runserver
   ```

6. In a separate terminal, start Redis (required for Celery):
   ```
   redis-server
   ```

7. In another terminal, start Celery worker:
   ```
   cd backend
   source venv/bin/activate  # If using a virtual environment
   celery -A music_voice_clone worker --loglevel=info
   ```

### Frontend Setup

1. Navigate to the frontend directory:
   ```
   cd frontend/voice_clone_app
   ```

2. Get Flutter dependencies:
   ```
   flutter pub get
   ```

3. Run the app:
   ```
   flutter run
   ```

## API Endpoints

- `POST /api/upload/`: Upload song and voice files, returns job ID
- `GET /api/job/{job_id}/`: Get job status and result URL (if ready)
- `POST /api/consent/`: Record user's consent

## Notes for Development

- The backend ML functionality is implemented as placeholders with comments explaining where real models would be integrated
- To connect to a real backend, update the `baseUrl` in `api_service.dart` to point to your backend server
- For Android emulator, use `10.0.2.2` to connect to localhost on the host machine
- For iOS simulator, use `localhost` or `127.0.0.1`

## Requirements

- Flutter SDK (3.9.0 or higher)
- Python 3.7+ with pip
- Redis server (for Celery task queue)
- Required Python packages in requirements.txt
- Required Flutter packages in pubspec.yaml
# music
