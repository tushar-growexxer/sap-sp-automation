# SAP Stored Procedure Automation

This project automates the extraction and management of SAP HANA stored procedures. It provides tools to connect to SAP HANA, extract stored procedure definitions, and manage them in a version-controlled manner.

## Prerequisites

- Python 3.11 or higher
- SAP HANA client libraries
- Git (for version control)
- Access to SAP HANA database

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/yourusername/sap-sp-automation.git
cd sap-sp-automation
```

### Set Up Environment

1. Create and activate a virtual environment (recommended):

   ```bash
   # Windows
   python -m venv .venv
   .venv\Scripts\activate

   # macOS/Linux
   python3 -m venv .venv
   source .venv/bin/activate
   ```

2. Install dependencies:

   ```bash
   pip install -e ".[dev]"
   ```

### Configuration

1. Create a `.env` file in the project root with your SAP HANA credentials:

   ```env
   # SAP HANA Configuration
   HANA_ADDRESS=your_hana_host
   HANA_PORT=30015
   HANA_USER=your_username
   HANA_PASSWORD=your_password
   
   # Optional: OpenAI API Key for future enhancements
   # OPENAI_API_KEY=your_openai_api_key
   
   # SMTP Configuration (for email notifications)
   SMTP_SERVER=your_smtp_server
   SMTP_PORT=587
   SMTP_USER=your_smtp_username
   SMTP_PASSWORD=your_smtp_password
   ```

2. Configure the stored procedures to track in `src/config/config.json`:

   ```json
   {
     "targets": [
       {
         "schema": "YOUR_SCHEMA",
         "sps": ["PROCEDURE_NAME"],
         "email_recipients": ["email@example.com"]
       }
     ]
   }
   ```

## Usage

### Running the Application

1. Activate your virtual environment if not already activated:

   ```bash
   # Windows
   .venv\Scripts\activate
   
   # macOS/Linux
   source .venv/bin/activate
   ```

2. Run the main script:

   ```bash
   python -m src.main
   ```

   This will:
   - Connect to the SAP HANA database
   - Extract the specified stored procedures
   - Save them to the `data/` directory

### Running Tests

To run the test suite:

```bash
pytest
```

For more detailed test output:

```bash
pytest -v
```

## Project Structure

```
sap-sp-automation/
├── data/                   # Extracted stored procedures
├── logs/                   # Application logs
├── src/
│   ├── config/             # Configuration files
│   │   ├── __init__.py
│   │   ├── config.json     # Stored procedure configurations
│   │   ├── logger.py       # Logging configuration
│   │   └── settings.py     # Application settings
│   ├── core/               # Core application logic
│   │   ├── __init__.py
│   │   ├── hana_client.py  # SAP HANA client
│   │   └── orchestrator.py # Main orchestration logic
│   └── main.py             # Entry point
├── tests/                  # Test files
├── .env.example           # Example environment variables
├── .gitignore
├── pyproject.toml         # Project dependencies
└── README.md
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [SAP HANA Client](https://help.sap.com/viewer/f1b440ded6144a54ada97ff95dac7adf/2.0.05/en-US/f3b8fabf34324302b123297cdbe710f0.html)
- [Pydantic](https://pydantic-docs.helpmanual.io/)
- [Rich](https://rich.readthedocs.io/)

## Support

For support, please open an issue in the GitHub repository or contact the maintainers.