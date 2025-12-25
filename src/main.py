import logging
import sys
from pathlib import Path
import argparse

# Add project root to python path to avoid ModuleNotFoundError
project_root = Path(__file__).resolve().parent.parent
if str(project_root) not in sys.path:
    sys.path.append(str(project_root))

from src.config.settings import settings
from src.core.hana_client import HanaClient
from src.core.git_manager import GitManager
from src.core.orchestrator import Orchestrator
from src.core.notifier import Notifier # Updated class name
import src.core.notifier as notifier_module # For any legacy direct calls if needed

# Get the logger from settings
logger = settings.logger

def main(argv: list | None = None) -> int:
    """
    Main entry point for the SAP Automation Service.
    """

    parser = argparse.ArgumentParser()
    parser.add_argument('--preview', action='store_true', help='Preview consolidated notification emails (no send)')
    parser.add_argument('--data-dir', type=Path, help='Override DATA_DIR for scanning changes')
    parser.add_argument('--config-path', type=Path, help='Path to config.json to determine recipients')
    parser.add_argument('--no-email', action='store_true', help='Do not send notification emails after run')
    parser.add_argument('--show-all', action='store_true', help='Show all changes in preview, including already-sent ones')
    parser.add_argument('--force', action='store_true', help='Force sending notifications even if already sent')
    args = parser.parse_args(argv)

    # Initialize Notifier with the current data directory
    data_path = args.data_dir if args.data_dir is not None else settings.DATA_DIR
    notif_service = Notifier(data_dir=data_path)

    # If preview mode requested, run notifier in preview and exit early
    if args.preview:
        # Note: We use the new daily summary method for consistency
        logger.info("Running in preview mode...")
        notif_service.send_daily_summary() 
        return 0

    logger.info("SAP Automation Service Starting...")

    try:
        # 1. Initialize DB and Git Components
        hana_client = HanaClient(config=settings)
        git_manager = GitManager(repo_path=data_path)

        # 2. Initialize Orchestrator
        orchestrator = Orchestrator(
            config=settings,
            hana_client=hana_client,
            git_manager=git_manager
        )

        # 3. Run the Core Logic (Fetch -> Clean -> Store)
        logger.info("Starting extraction process...")
        orchestrator.run_fetch_and_store()

        # 4. Scan for External Changes
        try:
            logged = git_manager.scan_and_log_changes()
            if logged > 0:
                logger.info(f"Logged {logged} external change(s).")
        except Exception as e:
            logger.error(f"Failed scanning/logging external changes: {e}")

        # 5. Commit and Push to GitHub
        logger.info("Syncing with GitHub...")
        result = git_manager.add_commit_push_data()

        if result == 1:
            logger.info("Successfully pushed changes to GitHub.")
        elif result == 0:
            logger.info("No changes to push (Repository is clean).")
        else:
            logger.warning("Commit/Push finished with errors. Check logs.")

        # 6. Send Consolidated Email Summary (Schema-wise .txt attachments)
        if not args.no_email:
            logger.info("Preparing email notifications...")
            try:
                # This logic uses Util internally to create .txt files 
                # and sends them as attachments in ONE email.
                notif_service.send_daily_summary()
                logger.info("Notification summary email sent successfully.")
            except Exception as e:
                logger.error(f"Failed to send notifications: {e}")

        logger.info("Extraction completed successfully")
        return 0
        
    except Exception as e:
        logger.critical(f"Fatal error in main: {e}", exc_info=True)
        return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        logger.warning("Operation cancelled by user")
        sys.exit(1)
    except Exception as e:
        logger.critical(f"Unhandled exception: {e}", exc_info=True)
        sys.exit(1)