import logging
import json
import smtplib
from datetime import datetime
from pathlib import Path
from email.message import EmailMessage
from src.config.settings import settings
from src.core.util import Util 

logger = logging.getLogger(__name__)

class Notifier:
    def __init__(self, data_dir: Path):
        self._data_dir = data_dir
        self._changes_root = data_dir / "changes"
        self._state_file = self._changes_root / ".notifier_state.json"

    def send_daily_summary(self):
        """Processes unsent changes and emails them using in-memory generation."""
        new_changes = self._collect_unsent_changes()
        if not new_changes:
            logger.info("No new changes to notify.")
            return

        # Prepare attachments in memory: List of tuples (filename, content_string)
        attachments = []
        for schema, sp_map in new_changes.items():
            # Use Util to get formatted text and filename (No disk I/O)
            content = Util.format_schema_report_text(schema, sp_map)
            filename = Util.get_report_filename(schema)
            attachments.append((filename, content))

        if not attachments:
            return

        # Email logic
        try:
            self._send_email_in_memory(attachments)
            
            # Update State (mark changes as sent)
            self._update_state(new_changes)
            
            logger.info("Email sent successfully (in-memory attachments).")
        except Exception as e:
            logger.error(f"Notification failed: {e}")

    def _collect_unsent_changes(self) -> dict:
        """Identifies changes not yet marked as 'sent' in state file."""
        state = self._load_state()
        updates = {}

        if not self._changes_root.exists():
            return updates

        for schema_dir in [d for d in self._changes_root.iterdir() if d.is_dir()]:
            schema = schema_dir.name
            for sp_file in schema_dir.glob("changes_*.txt"):
                sp_name = sp_file.stem.replace("changes_", "")
                last_entry = self._parse_last_entry(sp_file)
                
                if last_entry and state.get(schema, {}).get(sp_name) != last_entry['hash']:
                    updates.setdefault(schema, {})[sp_name] = last_entry
        return updates

    def _send_email_in_memory(self, attachments: list[tuple]):
        """
        Sends an email with attachments created from memory strings.
        Args:
            attachments: List of (filename, content_string) tuples
        """
        recipients = settings.email_recipients
        
        if not recipients:
            logger.warning("Skipping email: No recipients configured.")
            return

        msg = EmailMessage()
        msg['Subject'] = f"SAP SP Updates - {datetime.now().strftime('%d-%m-%Y')}"
        msg['From'] = settings.SMTP_USER
        msg['To'] = ', '.join(recipients)
        
        body = (
            "Hello,<br><br>"
            "Please find attached the latest changes detected in SAP HANA Stored Procedures.<br><br>"
            f"Total Schemas Updated: <b>{len(attachments)}</b><br>"
            "See attached text files for details.<br><br>"
            "---<br>"
            "<b>Analysis Methodology (Prompt):</b><br><br>"
            "<b>Role:</b> You are a Senior Technical Writer and SQL Expert. Your task is to translate a raw git unified diff of a SQL Stored Procedure into a concise, non-technical business summary.<br><br>"
            "<b>Input:</b> A single git unified diff containing @@ hunks.<br><br>"
            "<b>Processing Logic:</b><br>"
            "<ul>"
            "<li>Analyze Net Change: Look at the relationship between Removed lines (-) and Added lines (+).</li>"
            "  <ul>"
            "  <li>If code is replaced (- then + at same spot): Treat as \"Updated\"</li>"
            "  <li>If code is wrapped in /* ... */: Treat as \"Disabled\"</li>"
            "  <li>If comment markers are removed: Treat as \"Enabled\"</li>"
            "  <li>If lines are added: Treat as \"Added\"</li>"
            "  <li>If lines are removed: Treat as \"Removed\"</li>"
            "  </ul>"
            "<li>Ignore Noise:</li>"
            "  <ul>"
            "  <li>Disregard changes that only affect whitespace, indentation, or capitalization</li>"
            "  <li>Ignore file headers and timestamps</li>"
            "  </ul>"
            "<li>Identify Context (The \"Why\"): For every change, scan the immediate surrounding code (up to 20 lines) to find:</li>"
            "  <ul>"
            "  <li>Error Assignment: error := &lt;num&gt; or error_message := 'string'</li>"
            "  <li>Variable Declaration: DECLARE &lt;Variable&gt; &lt;Type&gt;</li>"
            "  <li>Constraint: Extract only the most relevant one of each per bullet</li>"
            "  </ul>"
            "</ul>"
            "<b>Formatting Rules:</b><br>"
            "<ul>"
            "<li><b>Output:</b> Strictly a bulleted list (hyphen + space)</li>"
            "<li><b>Length:</b> Maximum 15 words per bullet</li>"
            "<li><b>Language:</b> Plain, professional English. Avoid \"code-speak\" (e.g., don't say \"Uncommented IF block\", say \"Enabled conditional check\")</li>"
            "<li><b>Structure:</b> [Action Verb] [Business Object/Logic] (Context Info)</li>"
            "<li><b>Context Format:</b> Append found context in parentheses: (Var: Name) or (Err: \"Message\")</li>"
            "<li><b>Limit:</b> Max 6 bullets. If more changes exist, summarize the 6 most impactful (Logic changes > New features > Cleanups)</li>"
            "</ul>"
            "<b>Allowed Verbs:</b> Enabled, Disabled, Updated, Added, Removed, Fixed<br><br>"
            "<b>Example Output:</b><br>"
            "<ul>"
            "<li>Enabled validation for sales order limits (Err: \"Limit Exceeded\")</li>"
            "<li>Updated tax calculation logic for international shipping</li>"
            "<li>Declared new variable for temporary storage (Var: TempDate)</li>"
            "</ul>"
            "---"
        )
        msg.set_content(body, subtype='html')

        for filename, content in attachments:
            # Add attachment directly from string bytes (no file reading)
            msg.add_attachment(
                content.encode('utf-8'),
                maintype='text',
                subtype='plain',
                filename=filename
            )

        with smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT) as s:
            s.starttls()
            s.login(settings.SMTP_USER, settings.SMTP_PASSWORD.get_secret_value())
            s.send_message(msg)
            logger.info(f"Email sent with {len(attachments)} reports.")

    def _parse_last_entry(self, file_path: Path) -> dict | None:
        """Parses the latest diff and hash from the change log."""
        try:
            content = file_path.read_text(encoding='utf-8')
            separator = "\n" + "=" * 60
            parts = content.split(separator)
            
            # Get the last block (handle potential empty trailing split)
            last_chunk = parts[-1].strip()
            if not last_chunk and len(parts) > 1:
                last_chunk = parts[-2].strip()

            if not last_chunk: return None

            h, d = "unknown", []
            for line in last_chunk.splitlines():
                if line.startswith("CONTENT_HASH:"): 
                    h = line.split(":", 1)[1].strip()
                elif not any(line.startswith(x) for x in ["TIMESTAMP", "OBJECT", "CHANGES"]): 
                    d.append(line)
            return {'hash': h, 'diff': "\n".join(d).strip()}
        except Exception: 
            return None

    def _load_state(self):
        if self._state_file.exists():
            try:
                with open(self._state_file, 'r') as f: return json.load(f)
            except: pass
        return {}

    def _update_state(self, new_changes):
        state = self._load_state()
        for s, sps in new_changes.items():
            state.setdefault(s, {}).update({sp: data['hash'] for sp, data in sps.items()})
        try:
            with open(self._state_file, 'w') as f: json.dump(state, f, indent=2)
        except Exception as e:
            logger.error(f"Failed to update state file: {e}")