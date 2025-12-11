from pathlib import Path
import logging
from src.config.settings import settings
from src.core.git_manager import GitManager
from src.core.hana_client import HanaClient

# Module-specific logger
logger = logging.getLogger(__name__)

class Orchestrator:
    """
    Manages the workflow: Fetch -> Clean -> Store (Local File).
    """
    def __init__(
        self,
        config,
        hana_client: HanaClient,
        git_manager: GitManager
    ):
        """
        Initialize the Orchestrator.

        Inputs:
        - config: configuration/settings object (must include `targets`)
        - hana_client (HanaClient): client used to fetch stored procedures
        - git_manager (GitManager): manager used to save files and handle git operations

        Outputs: None (stores injected dependencies and targets list)

        Processing: Saves provided objects into instance attributes and prepares a module logger.
        """
        self._config = config
        self._hana = hana_client
        self._git = git_manager
        self._targets = config.targets
        # Use module logger instead of config logger
        self._logger = logging.getLogger(__name__)

    def run_fetch_and_store(self):
        """Executes the Fetch -> Process -> Store cycle."""
        """
        Run the full extraction pipeline for all configured targets.

        Inputs: None (uses `self._targets`, `self._hana`, and `self._git`).
        Outputs: None (side-effects: fetches, normalizes, writes files, possibly commits.)

        Processing:
        - Opens a single HANA connection for the batch using the HanaClient context manager.
        - Iterates each target and delegates to `_process_schema` to handle per-schema work.
        - Logs a critical error if orchestration fails.
        """
        self._logger.info(f"Starting extraction for {len(self._targets)} schema targets.")

        try:
            # Open one connection for the whole batch
            with self._hana as hana:
                for target in self._targets:
                    self._process_schema(hana, target)

        except Exception as e:
            self._logger.critical(f"Orchestration failed: {e}", exc_info=True)

    def _process_schema(self, hana: HanaClient, target):
        """
        Process a single schema target: fetch each stored procedure, normalize and save it.

        Inputs:
        - hana (HanaClient): active client instance (already entered as context manager)
        - target: an object with `schema_name` (str) and `sps_to_track` (iterable of procedure names)

        Outputs: None (side-effects: writes files and optionally commits them)

        Processing:
        - For each SP name, fetch definition from HANA, normalize the SQL, and call `self._git.save_file`.
        - If `self._git.has_changes` reports the file changed, commit via `self._git.commit_changes`.
        - Logs per-SP errors without stopping the whole schema processing.
        """
        schema = target.schema_name
        
        self._logger.info(f"Processing Schema: [bold cyan]{schema}[/bold cyan]")

        for sp_name in target.sps_to_track:
            try:
                # 1. Fetch
                raw_content = hana.fetch_sp_definition(sp_name, schema)
                
                if not raw_content:
                    self._logger.warning(f"   SP '{sp_name}' not found in HANA. Skipping.")
                    continue

                # 2. Process (Clean)
                clean_content = self._normalize_sql(raw_content)

                # 3. Store (Save to data/{schema}/{sp_name}.sql)
                # The git_manager handles diff logging to changes.txt internally
                file_path = self._git.save_file(sp_name, clean_content, schema=schema)

                self._logger.info(f"   Saved: {file_path.name}")

                # 4. Commit individual file changes (optional step, allows granular history)
                if self._git.has_changes(file_path):
                    self._git.commit_changes(file_path)
            
            except Exception as e:
                self._logger.error(f"Error saving {sp_name}: {e}")

    def _normalize_sql(self, content: str) -> str:
        """
        Cleans up the SQL to ensure consistent storage.
        - Fixes Windows/Linux line ending differences.
        - Trims trailing whitespace.
        """
        if not content:
            return ""

        # Standardize line endings to \n
        content = content.replace('\r\n', '\n').replace('\r', '\n')

        # Remove trailing whitespace from each line (prevents noisy diffs)
        lines = [line.rstrip() for line in content.split('\n')]

        return '\n'.join(lines).strip()