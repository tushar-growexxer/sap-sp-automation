import json
import logging
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import SecretStr, BaseModel, Field, PrivateAttr
from .logger import setup_logging

class Target(BaseModel):
    schema_name: str
    sps_to_track: list[str]
    email_recipients: list[str] = Field(default_factory=list)
    
class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    ENV: str = "dev"

    # Paths
    BASE_DIR: Path = Field(default_factory=lambda: Path(__file__).parent.parent.parent)
    DATA_DIR: Path = Field(default_factory=lambda: Path(__file__).parent.parent.parent / "data")
    
    # Secrets
    HANA_ADDRESS: str
    HANA_PORT: int = 30015
    HANA_USER: str
    HANA_PASSWORD: SecretStr
    
    OPENAI_API_KEY: SecretStr
    AI_MODEL: str = "gpt-4o-mini"
    
    SMTP_SERVER: str
    SMTP_PORT: int = 587
    SMTP_USER: str
    SMTP_PASSWORD: SecretStr

    # Email recipients (global)
    email_recipients: list[str] = Field(default_factory=list)

    targets: list[Target] = Field(default_factory=list)
    
    def model_post_init(self, __context):
        # Initialize logger after model is fully constructed
        object.__setattr__(self, 'logger', setup_logging(self.ENV))
        self.logger.info(f"Application starting in [bold cyan]{self.ENV.upper()}[/bold cyan] mode.")
        self.logger.debug(f"Secrets loaded from .env (HANA: {self.HANA_ADDRESS})")
        
        # Load targets after logger is initialized
        self._load_targets()
    
    def _load_targets(self):
        """Load targets and email recipients from the config.json file"""
        config_path = Path(__file__).parent / "config.json"

        self.logger.debug(f"Reading configuration from: {config_path}")

        if config_path.exists():
            
            try:
                with open(config_path, "r") as f:
                    config = json.load(f)
                    self.targets = [Target(**target) for target in config.get("targets", [])]
                    # Load global email recipients
                    self.email_recipients = config.get("email_recipients", [])

                self.logger.info(f"Successfully loaded {len(self.targets)} schema targets from config.json")
                if self.email_recipients:
                    self.logger.info(f"Loaded {len(self.email_recipients)} email recipients")
            except json.JSONDecodeError as e:
                self.logger.critical(f"Invalid JSON in config.json: {e}")
                raise
            except Exception as e:
                self.logger.critical(f"Failed to load targets: {e}")
                raise
        else:
            self.logger.warning(f"config.json not found at {config_path}. No SPs will be tracked.")

settings = Settings()