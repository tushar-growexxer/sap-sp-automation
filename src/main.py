import logging
import sys
from pathlib import Path

# Add project root to python path to avoid ModuleNotFoundError
project_root = Path(__file__).resolve().parent.parent
if str(project_root) not in sys.path:
    sys.path.append(str(project_root))

from src.config.settings import settings
from src.core.hana_client import HanaClient
from src.core.git_manager import GitManager
from src.core.orchestrator import Orchestrator

# Get the logger from settings (so we use the configured one)
logger = settings.logger

def main():
    """
    Main entry point for the SAP Automation Service.

    Purpose:
    - Initialize components (HanaClient, GitManager, Orchestrator), run the fetch/store pipeline,
      scan for external changes, and commit/push data to Git.

    Inputs: None (reads configuration from `settings`).
    Outputs: int exit code (0 on success, 1 on fatal error).

    Processing:
    - Instantiate `HanaClient` and `GitManager` using `settings`.
    - Create an `Orchestrator` and call `run_fetch_and_store()` to perform fetch/clean/save.
    - Run `git_manager.scan_and_log_changes()` to log external edits.
    - Run `git_manager.add_commit_push_data()` and interpret the returned status code.
    """

    logger.info("SAP Automation Service Starting...")

    try:
        # 1. Initialize Components
        logger.debug("Initializing HANA client...")
        hana_client = HanaClient(config=settings)
        
        logger.debug(f"Initializing Git Manager at {settings.DATA_DIR}...")
        git_manager = GitManager(repo_path=settings.DATA_DIR)

        # 2. Initialize Orchestrator
        logger.debug("Initializing Orchestrator...")
        orchestrator = Orchestrator(
            config=settings,
            hana_client=hana_client,
            git_manager=git_manager  # Pass the instance here
        )

        # 3. Run the Fetch Logic (Fetch -> Clean -> Store)
        logger.info("Starting extraction process...")
        orchestrator.run_fetch_and_store()

        # 4. Scan for External Changes (Manual edits / New files outside of HANA fetch)
        try:
            logged = git_manager.scan_and_log_changes()
            if logged > 0:
                logger.info(f"Logged {logged} external change(s) to changes.txt")
            else:
                logger.debug("No external changes detected.")
        except Exception as e:
            logger.error(f"Failed scanning/logging external changes: {e}")

        # 5. Commit and Push to GitHub (The Final Step)
        logger.info("Syncing with GitHub...")
        result = git_manager.add_commit_push_data()

        if result == 1:
            logger.info("Successfully pushed changes to GitHub.")
        elif result == 0:
            logger.info("No changes to push (Repository is clean).")
        else:
            logger.warning("Commit/Push finished with errors. Check logs.")

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