# src/tests/test_hana_client.py
import pytest
import logging
from unittest.mock import MagicMock, patch
from pydantic import SecretStr
from src.core.hana_client import HanaClient
from src.config.settings import settings
import hdbcli

@pytest.fixture
def mock_hana_connection():
    """Fixture to mock HANA connection and cursor."""
    with patch('hdbcli.dbapi.connect') as mock_connect:
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        
        # Configure the mock connection and cursor
        mock_connect.return_value = mock_conn
        mock_conn.cursor.return_value = mock_cursor
        mock_conn.close.return_value = None
        
        yield mock_connect, mock_conn, mock_cursor

@pytest.fixture
def hana_client():
    """Fixture to create a HanaClient instance with test settings."""
    test_settings = settings.model_copy(deep=True)
    test_settings.HANA_ADDRESS = "test.host"
    test_settings.HANA_PORT = 30015
    test_settings.HANA_USER = "test_user"
    test_settings.HANA_PASSWORD = SecretStr("test_password")  # Use SecretStr here
    
    return HanaClient(config=test_settings)

def test_hana_client_initialization(hana_client):
    """Test HanaClient initialization."""
    assert hana_client._connection is None
    assert hana_client._config.HANA_ADDRESS == "test.host"

def test_hana_connection_success(hana_client, mock_hana_connection):
    """Test successful HANA connection."""
    mock_connect, mock_conn, _ = mock_hana_connection
    
    with hana_client as client:
        assert client == hana_client
        mock_connect.assert_called_once_with(
            address="test.host",
            port=30015,
            user="test_user",
            password="test_password"
        )

def test_fetch_sp_definition_success(hana_client, mock_hana_connection):
    """Test successful stored procedure definition fetch."""
    _, mock_conn, mock_cursor = mock_hana_connection
    
    # Mock the cursor's fetchone to return a test procedure definition
    mock_cursor.fetchone.return_value = ["CREATE PROCEDURE test_proc AS BEGIN END;"]
    
    with hana_client:
        result = hana_client.fetch_sp_definition("test_proc", "TEST_SCHEMA")
        
        # Verify the query was built correctly
        expected_query = """
                SELECT "DEFINITION" 
                FROM SYS.PROCEDURES 
                WHERE SCHEMA_NAME = 'TEST_SCHEMA' 
                AND "PROCEDURE_NAME" = 'test_proc'
            """
        mock_cursor.execute.assert_called_once()
        assert "TEST_SCHEMA" in mock_cursor.execute.call_args[0][0]
        assert "test_proc" in mock_cursor.execute.call_args[0][0]
        assert result == "CREATE PROCEDURE test_proc AS BEGIN END;"

def test_fetch_sp_definition_not_found(hana_client, mock_hana_connection):
    """Test when stored procedure is not found."""
    _, mock_conn, mock_cursor = mock_hana_connection
    mock_cursor.fetchone.return_value = None
    
    with hana_client:
        result = hana_client.fetch_sp_definition("nonexistent", "TEST_SCHEMA")
        assert result is None

def test_connection_error_handling(hana_client, mock_hana_connection, caplog):
    """Test error handling when connection fails."""
    mock_connect, mock_conn, _ = mock_hana_connection
    mock_connect.side_effect = hdbcli.dbapi.Error("Connection failed")
    
    with pytest.raises(hdbcli.dbapi.Error), caplog.at_level(logging.CRITICAL):
        with hana_client:
            pass
    
    assert "Failed to connect to HANA" in caplog.text

def test_query_error_handling(hana_client, mock_hana_connection, caplog):
    """Test error handling when query fails."""
    _, mock_conn, mock_cursor = mock_hana_connection
    mock_cursor.execute.side_effect = hdbcli.dbapi.Error("Query failed")
    
    with hana_client, caplog.at_level(logging.ERROR):
        result = hana_client.fetch_sp_definition("test_proc", "TEST_SCHEMA")
        
        assert result is None
        assert "Error fetching test_proc from TEST_SCHEMA" in caplog.text

def test_connection_closure(hana_client, mock_hana_connection):
    """Test that the connection is properly closed."""
    _, mock_conn, _ = mock_hana_connection
    
    with hana_client:
        pass  # Connection should be closed when exiting context
    
    mock_conn.close.assert_called_once()