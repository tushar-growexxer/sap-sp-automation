import logging
from types import SimpleNamespace
from pathlib import Path

import pytest

from src.core.git_manager import GitManager
from src.core.orchestrator import Orchestrator
from src.config.settings import Target


class DummyHanaClient:
    """A minimal context-manager HANA client for tests.

    It returns stored procedure text from a provided mapping keyed by (schema, sp_name).
    """
    def __init__(self, content_map: dict):
        self._map = content_map

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def fetch_sp_definition(self, sp_name: str, schema_name: str):
        return self._map.get((schema_name, sp_name))


def test_full_fetch_clean_save_and_commit(tmp_path):
    # Prepare a temporary repo path (GitManager will init a git repo here)
    repo_path = tmp_path / "data"

    # Prepare dummy stored procedure content with CRLF and trailing spaces
    raw_sql = "CREATE PROCEDURE SP1 AS\r\nSELECT 1;   \r\nEND;\r\n"
    content_map = {("TESTSCHEMA", "SP1"): raw_sql}

    # Instantiate dummy HANA client and GitManager
    hana_client = DummyHanaClient(content_map)
    git_manager = GitManager(repo_path=repo_path)

    # Build a minimal config object with targets expected by Orchestrator
    cfg = SimpleNamespace()
    cfg.targets = [Target(schema_name="TESTSCHEMA", sps_to_track=["SP1"]) ]

    orchestrator = Orchestrator(config=cfg, hana_client=hana_client, git_manager=git_manager)

    # Run the pipeline: fetch -> normalize -> save -> commit individual files
    orchestrator.run_fetch_and_store()

    # Assert the file was created and normalized (no CRLF and trailing whitespace trimmed)
    saved_file = repo_path / "TESTSCHEMA" / "SP1.sql"
    assert saved_file.exists(), f"Expected saved file at {saved_file}"

    saved_text = saved_file.read_text(encoding="utf-8")
    assert "\r" not in saved_text
    assert saved_text.endswith("END;")

    # There should be a per-schema changes file with a CHANGES DETECTED header
    changes_file = repo_path / "changes" / "TESTSCHEMA" / "changes_SP1.txt"
    assert changes_file.exists(), "Expected per-schema changes log"
    changes_text = changes_file.read_text(encoding="utf-8")
    assert "CHANGES DETECTED" in changes_text

    # Simulate an external edit: modify the saved file directly
    modified = saved_text + "\n-- external edit"
    saved_file.write_text(modified, encoding="utf-8", newline="\n")

    # Scan and log external changes
    logged = git_manager.scan_and_log_changes()
    assert logged >= 1

    # Now commit and (attempt to) push changes. In test environment no remote exists so function should still return 1
    result = git_manager.add_commit_push_data()
    assert result == 1

