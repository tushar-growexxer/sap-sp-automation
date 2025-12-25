import smtplib
from pathlib import Path
import json

import pytest

from src.core import notifier
from src.config import settings


class DummySMTP:
    def __init__(self, server, port, timeout=None):
        self.server = server
        self.port = port
        self.timeout = timeout
        self.sent = []
    def starttls(self):
        pass
    def login(self, user, pwd):
        pass
    def send_message(self, msg):
        self.sent.append(msg)
    def __enter__(self):
        return self
    def __exit__(self, exc_type, exc, tb):
        return False


def test_format_diff_as_html():
    txt = """
Previous: TEST/old
Current:  TEST/new
- old line
+ new line
 context line
"""
    html = notifier._format_diff_as_html(txt)
    assert 'class="removed"' in html
    assert 'class="added"' in html
    assert '<pre>' in html


def test_notify_changes_sends_email(tmp_path, monkeypatch):
    # Create a fake changes dir and file
    changes_dir = tmp_path / 'data' / 'changes' / 'MILIVE'
    changes_dir.mkdir(parents=True)
    file_path = changes_dir / 'changes_SP1.txt'
    content = "\n" + "="*60 + "\nTIMESTAMP : 2025-12-25 00:00:00\nOBJECT    : MILIVE / changes_SP1.txt\nCHANGES DETECTED:\n--- Previous: test\nSELECT COALESCE(SUM(T1."Quantity"),0) INTO X\n- old\n+ new\n"
    file_path.write_text(content, encoding='utf-8')

    # Temporary config file with recipients
    config = {"email_recipients": ["tester@example.com"]}
    config_path = tmp_path / 'config.json'
    config_path.write_text(json.dumps(config), encoding='utf-8')

    # Monkeypatch SMTP
    sent_messages = []
    def fake_smtp(server, port, timeout=None):
        return DummySMTP(server, port, timeout)

    monkeypatch.setattr(smtplib, 'SMTP', fake_smtp)

    # Provide SMTP settings on `settings` object
    from pydantic import SecretStr
    settings.SMTP_SERVER = 'smtp.example.com'
    settings.SMTP_PORT = 587
    settings.SMTP_USER = 'user@example.com'
    settings.SMTP_PASSWORD = SecretStr('dummy')

    # Run notifier (single consolidated email)
    instances = []
    def fake_smtp(server, port, timeout=None):
        inst = DummySMTP(server, port, timeout)
        instances.append(inst)
        return inst

    monkeypatch.setattr(smtplib, 'SMTP', fake_smtp)

    # First send should send one email
    notifier.send_consolidated_notifications(repo_path=tmp_path / 'data', config_path=config_path)
    assert len(instances) == 1
    # State file should be created
    state_file = tmp_path / 'data' / 'changes' / '.notifier_state.json'
    assert state_file.exists()

    # Second send should send nothing (already recorded)
    notifier.send_consolidated_notifications(repo_path=tmp_path / 'data', config_path=config_path)
    assert len(instances) == 1  # unchanged

    # But --show-all (preview) should show content even after state is updated
    notifier.send_consolidated_notifications(repo_path=tmp_path / 'data', config_path=config_path, preview=True, show_all=True)

    # Check the content of the sent message has the diff content (only diff lines should be included)
    full_msg = instances[0].sent[0].as_string()
    assert '- old' in full_msg
    assert '+ new' in full_msg
    # Ensure metadata like TIMESTAMP or OBJECT are NOT included in the email body
    assert 'TIMESTAMP :' not in full_msg
    assert 'OBJECT    :' not in full_msg
    # Ensure neutral lines like SELECT COALESCE without +/- are NOT included in the email
    assert 'SELECT COALESCE' not in full_msg
    assert file_path.exists()


def test_tabs_preserved_in_plain_text(tmp_path, monkeypatch):
    # Create a changes file that includes a tab character in an added line
    changes_dir = tmp_path / 'data' / 'changes' / 'MSPL'
    changes_dir.mkdir(parents=True)
    file_path = changes_dir / 'changes_SPX.txt'
    content = "\n" + "="*60 + "\nTIMESTAMP : 2025-12-25 00:00:00\nOBJECT    : MSPL / changes_SPX.txt\nCHANGES DETECTED:\n-\n+\t/*\n"
    file_path.write_text(content, encoding='utf-8')

    # Temporary config file with recipients
    config = {"email_recipients": ["tester2@example.com"]}
    config_path = tmp_path / 'config2.json'
    config_path.write_text(json.dumps(config), encoding='utf-8')

    # Monkeypatch SMTP
    instances = []
    def fake_smtp(server, port, timeout=None):
        inst = DummySMTP(server, port, timeout)
        instances.append(inst)
        return inst

    monkeypatch.setattr(smtplib, 'SMTP', fake_smtp)

    # Provide SMTP settings on `settings` object
    from pydantic import SecretStr
    settings.SMTP_SERVER = 'smtp.example.com'
    settings.SMTP_PORT = 587
    settings.SMTP_USER = 'user@example.com'
    settings.SMTP_PASSWORD = SecretStr('dummy')

    # Run notifier (single consolidated email)
    notifier.send_consolidated_notifications(repo_path=tmp_path / 'data', config_path=config_path)

    assert len(instances) == 1
    # Inspect the plain text part of the message to ensure the tab character is preserved
    sent_msg = instances[0].sent[0]
    # The plain text content should contain a literal tab followed by '/*'
    assert '\t/*' in sent_msg.get_body(preferencelist=('plain',)).get_content()


def test_attachment_contains_raw_diff(tmp_path, monkeypatch):
    # Create a changes file and validate that the sent email includes an attachment with the raw diff
    changes_dir = tmp_path / 'data' / 'changes' / 'MILIVE'
    changes_dir.mkdir(parents=True)
    file_path = changes_dir / 'changes_SP1.txt'
    content = "\n" + "="*60 + "\nTIMESTAMP : 2025-12-25 00:00:00\nOBJECT    : MILIVE / changes_SP1.txt\nCHANGES DETECTED:\n--- Previous: test\n- old\n+ new\n"
    file_path.write_text(content, encoding='utf-8')

    # Temporary config file with recipients
    config = {"email_recipients": ["attach@example.com"]}
    config_path = tmp_path / 'config_attach.json'
    config_path.write_text(json.dumps(config), encoding='utf-8')

    # Monkeypatch SMTP
    instances = []
    def fake_smtp(server, port, timeout=None):
        inst = DummySMTP(server, port, timeout)
        instances.append(inst)
        return inst

    monkeypatch.setattr(smtplib, 'SMTP', fake_smtp)

    # Provide SMTP settings on `settings` object
    from pydantic import SecretStr
    settings.SMTP_SERVER = 'smtp.example.com'
    settings.SMTP_PORT = 587
    settings.SMTP_USER = 'user@example.com'
    settings.SMTP_PASSWORD = SecretStr('dummy')

    # Run notifier (single consolidated email)
    notifier.send_consolidated_notifications(repo_path=tmp_path / 'data', config_path=config_path)

    assert len(instances) == 1
    sent_msg = instances[0].sent[0]
    attachments = list(sent_msg.iter_attachments())
    assert len(attachments) == 1
    att = attachments[0]
    assert att.get_filename() == 'changes.diff'
    assert '- old' in att.get_content()
    assert '+ new' in att.get_content()
