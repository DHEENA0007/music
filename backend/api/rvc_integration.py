"""
RVC Integration module for voice cloning functionality
"""
import os
import logging
import subprocess
import tempfile
from pathlib import Path
from typing import Optional, Tuple

from django.conf import settings

# Try to import RVC modules, fall back to mock implementations if not available
RVC_AVAILABLE = False
VC = None
UVR = None

try:
    import sys
    from pathlib import Path
    
    # Add the RVC path to sys.path if it exists
    rvc_path = Path(__file__).parent.parent.parent / "Retrieval-based-Voice-Conversion"
    if rvc_path.exists():
        sys.path.insert(0, str(rvc_path))
        
        # Try importing RVC modules
        from rvc.modules.vc.modules import VC as RVC_VC
        from rvc.modules.uvr5.modules import UVR as RVC_UVR
        VC = RVC_VC
        UVR = RVC_UVR
        RVC_AVAILABLE = True
        logging.info("RVC modules imported successfully")
    else:
        logging.warning(f"RVC directory not found at {rvc_path}")
        
except ImportError as e:
    logging.warning(f"RVC modules not available: {e}")
    logging.warning("This is expected if RVC dependencies are not installed")
    
except Exception as e:
    logging.error(f"Unexpected error importing RVC: {e}")

# If RVC is not available, create mock classes
if not RVC_AVAILABLE:
    logging.info("Using mock RVC classes - voice cloning will be disabled")
    
    class VC:
        def __init__(self):
            pass
        def get_vc(self, *args, **kwargs):
            raise NotImplementedError("RVC not available - please install RVC dependencies")
        def vc_inference(self, *args, **kwargs):
            raise NotImplementedError("RVC not available - please install RVC dependencies")
    
    class UVR:
        def __init__(self):
            pass
        def uvr_wrapper(self, *args, **kwargs):
            raise NotImplementedError("RVC not available - please install RVC dependencies")

try:
    import soundfile as sf
    import numpy as np
    AUDIO_LIBS_AVAILABLE = True
except ImportError as e:
    logging.warning(f"Audio libraries not available: {e}")
    AUDIO_LIBS_AVAILABLE = False

logger = logging.getLogger(__name__)

class RVCVoiceCloner:
    """
    Wrapper class for RVC voice cloning functionality
    """
    
    def __init__(self):
        if not RVC_AVAILABLE:
            logger.warning("RVC modules not available. Voice cloning will be disabled.")
            self.vc = None
            self.uvr = None
        else:
            try:
                self.vc = VC()
                self.uvr = UVR()
                logger.info("RVC voice cloner initialized successfully")
            except Exception as e:
                logger.error(f"Failed to initialize RVC components: {e}")
                self.vc = None
                self.uvr = None
        self.model_loaded = False
        self.current_model = None
        
    def load_model(self, model_path: str) -> bool:
        """
        Load RVC model for voice conversion
        
        Args:
            model_path: Path to the .pth model file
            
        Returns:
            bool: True if model loaded successfully
        """
        if not RVC_AVAILABLE:
            logger.error("RVC modules not available")
            return False
            
        try:
            if not os.path.exists(model_path):
                raise FileNotFoundError(f"Model file not found: {model_path}")
                
            self.vc.get_vc(model_path)
            self.current_model = model_path
            self.model_loaded = True
            logger.info(f"Successfully loaded model: {model_path}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to load model {model_path}: {str(e)}")
            self.model_loaded = False
            return False
    
    def separate_vocals(self, audio_path: str, output_dir: str) -> Tuple[Optional[str], Optional[str]]:
        """
        Separate vocals and instrumental from audio file
        
        Args:
            audio_path: Path to input audio file
            output_dir: Directory to save separated files
            
        Returns:
            Tuple of (vocals_path, instrumental_path) or (None, None) if failed
        """
        if not RVC_AVAILABLE:
            logger.error("RVC modules not available")
            return None, None
            
        try:
            os.makedirs(output_dir, exist_ok=True)
            
            # Use UVR5 for source separation
            vocals_path = os.path.join(output_dir, "vocals.wav")
            instrumental_path = os.path.join(output_dir, "instrumental.wav")
            
            # Call UVR separation
            self.uvr.uvr_wrapper(
                audio_path=Path(audio_path),
                model_name="UVR-MDX-NET-Voc_FT",  # Default vocal separation model
                temp_dir=Path(output_dir)
            )
            
            # UVR outputs files with specific naming convention
            # You may need to adjust paths based on actual UVR output
            expected_vocals = os.path.join(output_dir, f"{Path(audio_path).stem}_vocals.wav")
            expected_instrumental = os.path.join(output_dir, f"{Path(audio_path).stem}_no_vocals.wav")
            
            if os.path.exists(expected_vocals):
                os.rename(expected_vocals, vocals_path)
            if os.path.exists(expected_instrumental):
                os.rename(expected_instrumental, instrumental_path)
                
            return vocals_path, instrumental_path
            
        except Exception as e:
            logger.error(f"Failed to separate vocals: {str(e)}")
            return None, None
    
    def convert_voice(self, 
                     input_audio: str, 
                     target_voice_sample: str,
                     output_path: str,
                     **kwargs) -> bool:
        """
        Convert voice using RVC
        
        Args:
            input_audio: Path to input audio (vocals)
            target_voice_sample: Path to target voice sample (for reference)
            output_path: Path to save converted audio
            **kwargs: Additional RVC parameters
            
        Returns:
            bool: True if conversion successful
        """
        if not RVC_AVAILABLE:
            logger.error("RVC modules not available")
            return False
            
        try:
            if not self.model_loaded:
                raise ValueError("No model loaded. Call load_model() first.")
            
            # Default RVC parameters
            params = {
                'sid': kwargs.get('sid', 0),
                'f0_up_key': kwargs.get('f0_up_key', 0),
                'f0_method': kwargs.get('f0_method', 'rmvpe'),
                'index_rate': kwargs.get('index_rate', 0.75),
                'filter_radius': kwargs.get('filter_radius', 3),
                'resample_sr': kwargs.get('resample_sr', 0),
                'rms_mix_rate': kwargs.get('rms_mix_rate', 0.25),
                'protect': kwargs.get('protect', 0.33),
            }
            
            # Perform voice conversion
            tgt_sr, audio_opt, times, error = self.vc.vc_inference(
                input_audio_path=input_audio,
                **params
            )
            
            if error:
                raise Exception(f"RVC inference failed: {error}")
            
            # Save converted audio
            if AUDIO_LIBS_AVAILABLE:
                sf.write(output_path, audio_opt, tgt_sr)
            else:
                raise ImportError("Audio libraries not available")
                
            logger.info(f"Voice conversion completed: {output_path}")
            return True
            
        except Exception as e:
            logger.error(f"Voice conversion failed: {str(e)}")
            return False
    
    def mix_audio(self, vocals_path: str, instrumental_path: str, output_path: str, 
                  vocal_volume: float = 1.0, instrumental_volume: float = 1.0) -> bool:
        """
        Mix converted vocals with instrumental
        
        Args:
            vocals_path: Path to converted vocals
            instrumental_path: Path to instrumental track
            output_path: Path to save mixed audio
            vocal_volume: Volume multiplier for vocals
            instrumental_volume: Volume multiplier for instrumental
            
        Returns:
            bool: True if mixing successful
        """
        if not AUDIO_LIBS_AVAILABLE:
            logger.error("Audio libraries not available")
            return False
            
        try:
            # Load audio files
            vocals, sr_vocals = sf.read(vocals_path)
            instrumental, sr_instrumental = sf.read(instrumental_path)
            
            # Ensure same sample rate
            if sr_vocals != sr_instrumental:
                import librosa
                if sr_vocals < sr_instrumental:
                    vocals = librosa.resample(vocals, orig_sr=sr_vocals, target_sr=sr_instrumental)
                    sr = sr_instrumental
                else:
                    instrumental = librosa.resample(instrumental, orig_sr=sr_instrumental, target_sr=sr_vocals)
                    sr = sr_vocals
            else:
                sr = sr_vocals
            
            # Ensure same length
            min_length = min(len(vocals), len(instrumental))
            vocals = vocals[:min_length]
            instrumental = instrumental[:min_length]
            
            # Mix audio
            mixed = (vocals * vocal_volume) + (instrumental * instrumental_volume)
            
            # Normalize to prevent clipping
            max_val = np.max(np.abs(mixed))
            if max_val > 1.0:
                mixed = mixed / max_val
            
            # Save mixed audio
            sf.write(output_path, mixed, sr)
            logger.info(f"Audio mixing completed: {output_path}")
            return True
            
        except Exception as e:
            logger.error(f"Audio mixing failed: {str(e)}")
            return False
    
    def process_full_pipeline(self, 
                             song_path: str, 
                             voice_sample_path: str, 
                             output_path: str,
                             work_dir: str,
                             model_path: str = None) -> bool:
        """
        Complete voice cloning pipeline
        
        Args:
            song_path: Input song file
            voice_sample_path: Target voice sample
            output_path: Final output file
            work_dir: Working directory for intermediate files
            model_path: RVC model path (if different from current)
            
        Returns:
            bool: True if entire pipeline successful
        """
        if not RVC_AVAILABLE:
            logger.error("RVC modules not available. Voice cloning disabled.")
            return False
            
        try:
            # Load model if specified
            if model_path and model_path != self.current_model:
                if not self.load_model(model_path):
                    return False
            
            # Create working directory
            os.makedirs(work_dir, exist_ok=True)
            
            # Step 1: Separate vocals and instrumental
            logger.info("Step 1: Separating vocals and instrumental...")
            vocals_path, instrumental_path = self.separate_vocals(song_path, work_dir)
            if not vocals_path or not instrumental_path:
                return False
            
            # Step 2: Convert vocals to target voice
            logger.info("Step 2: Converting vocals...")
            converted_vocals_path = os.path.join(work_dir, "converted_vocals.wav")
            if not self.convert_voice(vocals_path, voice_sample_path, converted_vocals_path):
                return False
            
            # Step 3: Mix converted vocals with instrumental
            logger.info("Step 3: Mixing final audio...")
            if not self.mix_audio(converted_vocals_path, instrumental_path, output_path):
                return False
            
            logger.info("Voice cloning pipeline completed successfully!")
            return True
            
        except Exception as e:
            logger.error(f"Full pipeline failed: {str(e)}")
            return False


# Global instance
rvc_cloner = RVCVoiceCloner()
