import logging
import sys
from pathlib import Path
from src.config.settings import settings
from src.core.hana_client import HanaClient
from src.core.orchestrator import Orchestrator

# Get the module-specific logger
logger = logging.getLogger(__name__)

def setup_logging():
    """Initialize logging configuration."""
    # This will be called when the module is imported
    pass

def main():
    """Main entry point for the SAP Automation Service."""
    logger.info("SAP Automation Service Starting...")
    logger.debug("Debug logging is enabled")
    logger.info(f"Environment: {settings.ENV}")
    logger.info(f"Data directory: {settings.DATA_DIR.absolute()}")

    try:
        # 1. Initialize Components
        logger.debug("Initializing HANA client...")
        hana_client = HanaClient(config=settings)
        
        # 2. Initialize Orchestrator
        logger.debug("Initializing Orchestrator...")
        orchestrator = Orchestrator(
            config=settings,
            hana_client=hana_client
        )

        # 3. Run the Fetch Logic
        logger.info("Starting extraction process...")
        orchestrator.run_fetch_and_store()

        logger.info("Extraction completed successfully")
        return 0
        
    except Exception as e:
        logger.critical(f"Fatal error in main: {e}", exc_info=True)
        return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        logger.info("Operation cancelled by user")
        sys.exit(1)
    except Exception as e:
        logger.critical(f"Unhandled exception: {e}", exc_info=True)
        sys.exit(1)