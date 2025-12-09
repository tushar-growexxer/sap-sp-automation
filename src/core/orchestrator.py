# src/core/orchestrator.py
from pathlib import Path
import logging
from src.config.settings import settings
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
        hana_client: HanaClient
    ):
        self._config = config
        self._hana = hana_client
        self._targets = config.targets
        # Use module logger instead of config logger
        self._logger = logging.getLogger(__name__)

    def run_fetch_and_store(self):
        """Executes the Fetch -> Process -> Store cycle."""
        
        self._logger.info(f"Starting extraction for {len(self._targets)} schema targets.")
        
        try:
            # Open one connection for the whole batch
            with self._hana as hana:
                for target in self._targets:
                    self._process_schema(hana, target)
                    
        except Exception as e:
            self._logger.critical(f"Orchestration failed: {e}", exc_info=True)

    def _process_schema(self, hana: HanaClient, target):
        """Process a single schema target."""
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
                # Define the full path
                file_name = f"{sp_name}.sql"
                schema_dir = self._config.DATA_DIR / schema
                file_path = schema_dir / file_name

                # Create directory if it doesn't exist
                schema_dir.mkdir(parents=True, exist_ok=True)

                # Write the file
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(clean_content)

                self._logger.info(f"   Saved: {file_path.name}")
            
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