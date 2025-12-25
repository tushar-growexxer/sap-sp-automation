import git
import difflib
import hashlib
from datetime import datetime
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

class GitManager:
    """
    Manages file storage, git versioning, logging changes to changes.txt, and remote syncing.
    """
    
    def __init__(self, repo_path: Path):
        """
        Initialize the GitManager instance.

        Inputs:
        - repo_path (Path): Base directory where files are read/written and where the git repo is expected.

        Outputs:
        - None (sets up instance attributes `_repo_path`, `_repo`, `_changes_file`).

        Processing:
        - Ensures the repo_path exists and initializes or opens a git.Repo via `_init_repo()`.
        """
        self._repo_path = repo_path
        self._repo = self._init_repo()
        self._changes_file = None

    def _init_repo(self) -> git.Repo:
        """
        Initialize or find a git.Repo for `self._repo_path`.

        Inputs: None (operates on `self._repo_path`).
        Outputs: git.Repo instance. If a parent repository is found, that top-level repo is preferred.
        Processing:
        - Creates the directory if needed.
        - Tries to open an existing repo (preferring a top-level parent repo when nested).
        - Falls back to initializing a new repo under `self._repo_path`.
        """
        self._repo_path.mkdir(parents=True, exist_ok=True)
        try:
            repo = git.Repo(self._repo_path, search_parent_directories=True)
            # Logic to prefer top-level repo if nested
            candidate = None
            cur = Path(self._repo_path).resolve()
            root = cur.anchor
            while True:
                if (cur / ".git").exists():
                    candidate = cur
                if str(cur) == root:
                    break
                cur = cur.parent
            if candidate:
                return git.Repo(candidate)
            return repo
        except Exception:
            return git.Repo.init(self._repo_path)

    def save_file(self, filename: str, content: str, schema: str) -> Path:
        """
        Save (or overwrite) a SQL file under the given schema directory and log diffs.

        Inputs:
        - filename (str): Name of the file (may or may not include .sql extension).
        - content (str): File content to write.
        - schema (str): Subdirectory under the repo path where the file is stored.

        Outputs:
        - Path to the written file.

        Processing:
        - Ensures a .sql suffix, reads existing content if present.
        - If the file is new or has changed, calls `_log_change_to_file` to append a diff to per-schema changes.
        - Writes the file using UTF-8 and LF newlines.
        """
        if not filename.endswith(".sql"):
            filename += ".sql"
            
        schema_dir = self._repo_path / schema
        schema_dir.mkdir(parents=True, exist_ok=True)
        file_path = schema_dir / filename

        file_exists = file_path.exists()
        old_content = ""
        if file_exists:
            with open(file_path, "r", encoding="utf-8") as f:
                old_content = f.read()

        # Log change if it's new or different
        if (not file_exists) or (old_content != content):
            try:
                self._log_change_to_file(schema, filename, old_content, content)
                logger.info(f"Diff logged to changes.txt for {schema}/{filename}")
            except Exception:
                logger.exception("Failed to write diff to changes.txt")

        with open(file_path, "w", encoding="utf-8", newline="\n") as f:
            f.write(content)

        return file_path

    def _log_change_to_file(self, schema: str, filename: str, old_str: str, new_str: str):
        """
        Generate a unified diff between `old_str` and `new_str` and append a human-readable change log.

        Inputs:
        - schema (str), filename (str), old_str (str), new_str (str)

        Outputs:
        - None (side-effect: appends to `<repo>/changes/<schema>/changes_<sp_base>.txt`).

        Processing:
        - Builds a unified diff via `difflib.unified_diff`.
        - Prepends a header with timestamp and a SHA-256 content hash of the new content.
        - Prevents duplicate entries by comparing the last stored CONTENT_HASH when present.
        """
        from_path = f"Previous: {schema}/{filename}"
        to_path = f"Current:  {schema}/{filename}"

        diff_gen = difflib.unified_diff(
            old_str.splitlines(),
            new_str.splitlines(),
            fromfile=from_path,
            tofile=to_path,
            lineterm=''
        )
        diff_lines = list(diff_gen)
        if not diff_lines:
            return

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        normalized_new = new_str.lstrip('\ufeff').replace('\r\n', '\n').replace('\r', '\n')
        content_hash = hashlib.sha256(normalized_new.encode('utf-8')).hexdigest()

        header = [
            "\n" + "=" * 60,
            f"TIMESTAMP : {timestamp}",
            f"OBJECT    : {schema} / {filename}",
            "=" * 60,
            "CHANGES DETECTED:",
            "-" * 20,
            f"CONTENT_HASH: {content_hash}",
        ]
        log_entry = header + diff_lines + ["\n"]

        try:
            schema_name = schema or "global"
            sp_base = Path(filename).stem
            per_schema_dir = Path(self._repo_path) / "changes" / schema_name
            per_schema_dir.mkdir(parents=True, exist_ok=True)
            per_schema_file = per_schema_dir / f"changes_{sp_base}.txt"

            if per_schema_file.exists():
                try:
                    with open(per_schema_file, 'r', encoding='utf-8') as pf:
                        data = pf.read()
                    idx = data.rfind('CONTENT_HASH:')
                    if idx != -1:
                        last_line = data[idx:idx+200].splitlines()[0]
                        last_hash = last_line.split(':', 1)[1].strip()
                        if last_hash == content_hash:
                            return
                except Exception:
                    pass

            with open(per_schema_file, "a", encoding="utf-8", newline="\n") as f:
                f.write("\n".join(log_entry))
            
        except Exception:
            logger.exception(f"Failed to write per-schema change file for {schema}/{filename}")

    def has_changes(self, file_path: Path) -> bool:
        """
        Check whether `file_path` has uncommitted changes (either untracked or modified).

        Inputs: file_path (Path)
        Outputs: bool (True if untracked or modified, False otherwise)

        Processing:
        - Converts the absolute path to a repo-relative path and checks `repo.untracked_files`.
        - Uses `repo.index.diff(None, paths=rel_path)` to detect unstaged changes.
        """
        try:
            rel_path = file_path.relative_to(self._repo_path).as_posix()
        except ValueError:
            return False

        if rel_path in self._repo.untracked_files:
            return True
        if self._repo.index.diff(None, paths=rel_path):
            return True
        return False

    def commit_changes(self, file_path: Path):
        """
        Stage and commit a single file with a standard auto-update message.

        Inputs: file_path (Path)
        Outputs: None (performs a git commit as a side-effect)

        Processing:
        - Adds the repo-relative path to the index and commits with message `Auto-update: {rel_path}`.
        - Exceptions are logged.
        """
        try:
            rel_path = file_path.relative_to(self._repo_path).as_posix()
            self._repo.index.add([rel_path])
            self._repo.index.commit(f"Auto-update: {rel_path}")
            logger.info(f"Committed to Git: {rel_path}")
        except Exception as e:
            logger.error(f"Failed to commit {file_path}: {e}")

    def get_diff_str(self, file_path: Path) -> str:
        """
        Return a unified diff string for `file_path` comparing working tree to HEAD.

        Inputs: file_path (Path)
        Outputs: str (diff text). For new/untracked files returns the full file content prefixed by "NEW FILE CREATED:".
        """
        try:
            rel_path = file_path.relative_to(self._repo_path).as_posix()
            if rel_path in self._repo.untracked_files:
                with open(file_path, 'r', encoding='utf-8') as f:
                    return f"NEW FILE CREATED:\n{f.read()}"
            return self._repo.git.diff("HEAD", "--", rel_path)
        except Exception:
            return ""

    def scan_and_log_changes(self):
        """
        Walk the repository for `*.sql` files and log external edits or new files.

        Inputs: None
        Outputs: int — the number of logged change entries created during the scan.

        Processing:
        - Iterates all SQL files under `self._repo_path`.
        - For untracked files logs the new content; for tracked files compares HEAD content and logs diffs when different.
        - Returns the total number of logged entries.
        """
        logged = 0
        for file_path in self._repo_path.rglob("*.sql"):
            try:
                repo_root = Path(self._repo.working_tree_dir) if self._repo.working_tree_dir else self._repo_path
                rel_path = file_path.relative_to(repo_root).as_posix()
            except ValueError:
                continue

            parts = Path(rel_path).parts
            if parts and parts[0].lower() == "data" and len(parts) > 1:
                schema = parts[1]
            else:
                schema = parts[0] if parts else ""
            filename = Path(rel_path).name

            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    working_content = f.read()
            except Exception:
                continue

            if rel_path in self._repo.untracked_files:
                self._log_change_to_file(schema, filename, "", working_content)
                logged += 1
                continue

            try:
                try:
                    head_content = self._repo.git.show(f"HEAD:{rel_path}")
                except Exception:
                    head_content = ""

                if head_content != working_content:
                    self._log_change_to_file(schema, filename, head_content, working_content)
                    logged += 1
            except Exception:
                pass
        return logged

    def add_commit_push_data(self) -> int:
        """
        Stage all files under the repo path, commit them with a timestamped message (IST), and push to `origin` if configured.

        Inputs: None
        Outputs: int status code:
          - 1 => committed (and pushed if remote exists)
          - 0 => nothing to commit
          - -1 => error during commit/push

        Processing:
        - Runs `git add` on the repo path, inspects the cached diff to see if anything staged.
        - Commits with time in IST (tries `zoneinfo`, falls back to timezone offset).
        - Pushes `origin` if present; returns 1 on success or -1 on failure.
        """
        try:
            # Stage everything
            self._repo.git.add(str(self._repo_path))

            # Check if anything is staged
            if not self._repo.git.diff('--cached', '--name-only').strip():
                return 0

            # Commit with IST 12-hour format like '11-12-2025 03:08 PM IST'
            try:
                from zoneinfo import ZoneInfo
                ist = ZoneInfo('Asia/Kolkata')
            except Exception:
                from datetime import timezone, timedelta
                ist = timezone(timedelta(hours=5, minutes=30))

            now = datetime.now(ist) if ist is not None else datetime.now()
            timestamp = now.strftime('%d-%m-%Y %I:%M %p IST')
            self._repo.index.commit(f"SPs Updated : {timestamp}")

            # Push
            if 'origin' in self._repo.remotes:
                branch = self._repo.active_branch.name
                self._repo.remotes.origin.push(refspec=branch)
                return 1
            return 1 # Committed but no remote to push to
        except Exception as e:
            logger.error(f"Failed to push: {e}")
            return -1