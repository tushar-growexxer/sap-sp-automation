from pathlib import Path
import json

from src.main import main
from src.core import notifier


def test_main_preview_cli(tmp_path, capsys, monkeypatch):
    # Prepare changes files
    changes_dir = tmp_path / 'data' / 'changes' / 'MSPL'
    changes_dir.mkdir(parents=True)
    file_path = changes_dir / 'changes_SPX.txt'
    content = "\n" + "="*60 + "\nTIMESTAMP : 2025-12-25 00:00:00\nOBJECT    : MSPL / changes_SPX.txt\nCHANGES DETECTED:\n- old\n+ new\n"
    file_path.write_text(content, encoding='utf-8')

    # Create config with recipients
    config = {"email_recipients": ["preview@example.com"]}
    config_path = tmp_path / 'config.json'
    config_path.write_text(json.dumps(config), encoding='utf-8')

    # Call main in preview mode, pointing data-dir to tmp_path/data and config
    rc = main(['--preview', '--data-dir', str(tmp_path / 'data'), '--config-path', str(config_path)])
    assert rc == 0

    captured = capsys.readouterr()
    assert 'SUBJECT:' in captured.out
    assert 'MSPL' in captured.out
    assert 'preview@example.com' in captured.out
