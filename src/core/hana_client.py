import logging
import hdbcli.dbapi
from src.config.settings import settings

# Module-specific logger
logger = logging.getLogger(__name__)

class HanaClient:
    """Handles connection and queries to the SAP HANA database."""

    def __init__(self, config=settings):
        self._config = config
        self._connection = None
        # Use module logger instead of config logger
        self._logger = logging.getLogger(__name__)

    def __enter__(self):
        """Context Manager: Connects upon entering 'with' block."""
        try:
            self._connection = hdbcli.dbapi.connect(
                address=self._config.HANA_ADDRESS,
                port=self._config.HANA_PORT,
                user=self._config.HANA_USER,
                password=self._config.HANA_PASSWORD.get_secret_value()
            )
            self._logger.debug(f"Connected to HANA at {self._config.HANA_ADDRESS}")
            return self
        except Exception as e:
            self._logger.critical(f"Failed to connect to HANA: {e}")
            raise

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context Manager: Closes connection upon exiting 'with' block."""
        if self._connection:
            self._connection.close()
            self._logger.debug("HANA connection closed.")

    def fetch_sp_definition(self, sp_name: str, schema_name: str) -> str | None:
        """Fetches the SQL definition for a given stored procedure name."""
        if not self._connection:
            raise ConnectionError("HANA connection is not active.")
        
        try:
            cursor = self._connection.cursor()
            # Query the system table for the SP definition
            query = f"""
                SELECT "DEFINITION" 
                FROM SYS.PROCEDURES 
                WHERE SCHEMA_NAME = '{schema_name}' 
                AND "PROCEDURE_NAME" = '{sp_name}'
            """
            cursor.execute(query)
            result = cursor.fetchone()
            cursor.close()
            
            if result:
                return result[0]  # The raw SQL text
            return None

        except Exception as e:
            self._logger.error(f"Error fetching {sp_name} from {schema_name}: {e}")
            return None