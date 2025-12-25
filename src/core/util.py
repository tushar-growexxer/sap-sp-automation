import logging
from datetime import datetime
from typing import Dict

logger = logging.getLogger(__name__)

class Util:
    """
    General utility class for formatting and helper functions.
    Now optimized to handle data in memory (RAM).
    """

    @staticmethod
    def format_schema_report_text(schema: str, sp_data: Dict[str, dict]) -> str:
        """
        Generates the content for the .txt file in memory.
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %I:%M %p")
        
        lines = [
            f"SCHEMA CHANGE REPORT: {schema}",
            f"DATE/TIME: {timestamp} IST",
            "=" * 60,
            ""
        ]

        for sp_name, data in sp_data.items():
            diff_text = data.get('diff', 'No differences recorded.')
            lines.append(f"OBJECT: {sp_name}")
            lines.append("-" * 40)
            lines.append(diff_text)
            lines.append("\n" + ("=" * 40) + "\n")

        return "\n".join(lines)

    @staticmethod
    def get_report_filename(schema: str) -> str:
        """Generates the standardized filename for the attachment."""
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        return f"{schema}_changes_{timestamp}.txt"