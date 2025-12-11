import logging
import hdbcli.dbapi
from src.config.settings import settings

# Module-specific logger
logger = logging.getLogger(__name__)

class HanaClient:
    """Handles connection and queries to the SAP HANA database.

    This client is intended to be used as a context manager so a single
    connection can be opened/closed around a batch of operations.
    """

    def __init__(self, config=settings):
        """
        Initialize the HanaClient.

        Inputs:
        - config: settings object containing HANA connection details

        Outputs: None (initializes internal attributes)

        Processing: Stores the provided config and prepares logger; connection remains None until entered.
        """
        self._config = config
        self._connection = None
        # Use module logger instead of config logger
        self._logger = logging.getLogger(__name__)

    def __enter__(self):
        """
        Context manager entry: establish a connection to HANA.

        Inputs: None (reads connection parameters from `self._config`).
        Outputs: returns `self` with an active `_connection` attribute on success.

        Processing: Calls `hdbcli.dbapi.connect` with address, port, user and password.
        Raises on connection failure.
        """
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
        """
        Context manager exit: close the HANA connection if open.

        Inputs: standard context-manager exception triple (exc_type, exc_val, exc_tb).
        Outputs: None (side-effect: closes internal connection)
        Processing: If `_connection` exists, calls its `close()` method and logs a debug message.
        """
        if self._connection:
            self._connection.close()
            self._logger.debug("HANA connection closed.")

    def fetch_sp_definition(self, sp_name: str, schema_name: str) -> str | None:
        """
        Fetch the SQL definition for a stored procedure from SYS.PROCEDURES.

        Inputs:
        - sp_name (str): stored procedure name
        - schema_name (str): schema where the procedure is defined

        Outputs: str containing the stored procedure SQL definition, or None if not found or on error.

        Processing:
        - Requires an active `_connection` (raises ConnectionError if not connected).
        - Executes a SELECT on SYS.PROCEDURES and returns the first row's DEFINITION column.
        - Catches database errors, logs them, and returns None on failure.

        Note: This method currently interpolates SQL identifiers directly into the query string.
        If inputs are untrusted, parameterization should be used to avoid injection risks.
        """
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