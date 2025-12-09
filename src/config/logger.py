# src/config/logger.py
import logging
import sys
from pathlib import Path
from logging.handlers import RotatingFileHandler
from rich.logging import RichHandler

def setup_logging(env: str = "dev"):
    """
    Configures logging based on the environment.
    DEV: DEBUG level, Rich console output.
    PROD: INFO level, JSON-like file output, minimal console.
    """
    
    # Define Log Directory
    base_dir = Path(__file__).parent.parent.parent
    log_dir = base_dir / "logs"
    log_dir.mkdir(exist_ok=True)
    log_file = log_dir / "app.log"

    # Determine Log Level
    log_level = logging.DEBUG if env.lower() == "dev" else logging.INFO

    # 1. File Handler (Rotating - max 5MB, keep 3 backups)
    file_handler = RotatingFileHandler(log_file, maxBytes=5*1024*1024, backupCount=3, encoding='utf-8')
    file_handler.setLevel(log_level)
    file_format = logging.Formatter(
        '%(asctime)s - %(name)-20s - %(levelname)-8s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    file_handler.setFormatter(file_format)

    # 2. Console Handler (Rich for beautiful logs)
    console_handler = RichHandler(
        rich_tracebacks=True,
        markup=True,
        show_path=False,
        omit_repeated_times=False,
        log_time_format='%H:%M:%S'
    )
    console_handler.setLevel(log_level)
    
    # Configure console format for RichHandler
    console_format = logging.Formatter(
        '%(asctime)s - %(name)-20s - %(levelname)-8s - %(message)s',
        datefmt='%H:%M:%S'
    )
    console_handler.setFormatter(console_format)

    # 3. Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(log_level)
    
    # Clear any existing handlers
    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)
    
    # Add our handlers
    root_logger.addHandler(file_handler)
    root_logger.addHandler(console_handler)
    
    # Configure specific loggers
    logging.getLogger("hdbcli").setLevel(logging.WARNING)  # Reduce HDB CLI logs
    logging.getLogger("urllib3").setLevel(logging.WARNING)  # Reduce HTTP logs
    
    # Return a module-specific logger
    return logging.getLogger("orchestrator")