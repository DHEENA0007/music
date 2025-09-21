import os
import logging
import shutil
from celery import shared_task
from django.conf import settings
from .models import Job
from .rvc_integration import rvc_cloner

logger = logging.getLogger(__name__)

@shared_task
def process_voice_clone(job_id):
    """
    Process the voice cloning job in the background using RVC
    
    This task:
    1. Updates job status to 'processing'
    2. Separates the song into vocals and instrumental using UVR5
    3. Clones the vocals to the uploaded voice using RVC
    4. Mixes the cloned vocals with the instrumental
    5. Saves the result file to the job
    """
    try:
        # Get the job object
        job = Job.objects.get(pk=job_id)
        
        # Update status to processing
        job.status = 'processing'
        job.save(update_fields=['status', 'updated_at'])
        
        # Get file paths
        song_path = job.song_file.path
        voice_path = job.voice_file.path
        
        # Create directory for intermediate files
        base_dir = os.path.dirname(song_path)
        work_dir = os.path.join(base_dir, 'processing', str(job.id))
        os.makedirs(work_dir, exist_ok=True)
        
        # Final output path
        output_path = os.path.join(work_dir, 'output.wav')
        
        # Get RVC model path from settings
        model_path = getattr(settings, 'RVC_MODEL_PATH', 
                           os.path.join(settings.BASE_DIR, 'models', 'rvc_model.pth'))
        
        logger.info(f"Starting voice cloning for job {job_id}")
        logger.info(f"Song: {song_path}")
        logger.info(f"Voice sample: {voice_path}")
        logger.info(f"Model: {model_path}")
        
        # Process using RVC pipeline
        success = rvc_cloner.process_full_pipeline(
            song_path=song_path,
            voice_sample_path=voice_path,
            output_path=output_path,
            work_dir=work_dir,
            model_path=model_path
        )
        
        if not success:
            raise Exception("RVC processing pipeline failed")
        
        # Convert to MP3 for final output
        final_output_path = os.path.join(work_dir, 'output.mp3')
        
        # Use ffmpeg for conversion (you may need to install ffmpeg)
        import subprocess
        try:
            subprocess.run([
                'ffmpeg', '-i', output_path, 
                '-codec:a', 'mp3', '-b:a', '192k',
                final_output_path, '-y'
            ], check=True, capture_output=True)
        except subprocess.CalledProcessError:
            # Fallback: just rename if ffmpeg fails
            logger.warning("FFmpeg conversion failed, using original format")
            final_output_path = output_path
        
        # Save the result file to the job
        with open(final_output_path, 'rb') as f:
            job.result_file.save('output.mp3', f, save=False)
        
        # Update job status to completed
        job.status = 'completed'
        job.save()
        
        logger.info(f"Voice cloning completed successfully for job {job_id}")
        
        # Clean up intermediate files
        try:
            shutil.rmtree(work_dir)
        except Exception as e:
            logger.warning(f"Failed to clean up work directory: {e}")
        
    except Exception as e:
        # If any exception occurs, update job status to failed
        try:
            job = Job.objects.get(pk=job_id)
            job.status = 'failed'
            job.error_message = str(e)
            job.save(update_fields=['status', 'error_message', 'updated_at'])
        except:
            pass
        
        # Re-raise the exception for Celery to log
        raise
