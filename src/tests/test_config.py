# tests/test_config.py
import pytest
from src.config.settings import settings

def test_settings_load_env():
    """Verify essential .env variables are loaded."""
    # Ensure mandatory fields are not empty
    assert settings.HANA_ADDRESS is not None
    assert settings.HANA_USER is not None
    assert settings.OPENAI_API_KEY is not None
    assert settings.SMTP_SERVER is not None
    assert settings.SMTP_USER is not None
    
    # Check that secrets are wrapped in SecretStr (Security check)
    assert settings.HANA_PASSWORD.get_secret_value() is not None
    assert settings.OPENAI_API_KEY.get_secret_value() is not None
    assert settings.SMTP_PASSWORD.get_secret_value() is not None

def test_config_json_structure():
    """Verify config.json loaded at least one target."""
    assert len(settings.targets) > 0, "No tracking targets found in config.json"
    
    first_target = settings.targets[0]
    assert first_target.schema_name is not None
    assert isinstance(first_target.sps_to_track, list)
    assert len(first_target.sps_to_track) > 0