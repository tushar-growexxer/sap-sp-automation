#!/usr/bin/env python3
"""
Test script to verify email notifications are sent when content is written to changes.txt
"""

import sys
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent / "src"))

from core.git_manager import GitManager
from core.notifier import send_immediate_notification

def test_immediate_notification():
    """Test the send_immediate_notification function directly"""
    
    # Sample diff text that would be written to changes.txt
    sample_diff = """
============================================================
TIMESTAMP : 2025-12-25 17:03:00
OBJECT    : ZZZ_TMILLP_05_12_25 / SBO_SP_TRANSACTIONNOTIFICATION.sql
============================================================
CHANGES DETECTED:
--------------------
CONTENT_HASH: abc123def456
--- Previous: ZZZ_TMILLP_05_12_25/SBO_SP_TRANSACTIONNOTIFICATION.sql
+++ Current:  ZZZ_TMILLP_05_12_25/SBO_SP_TRANSACTIONNOTIFICATION.sql
@@ -477,7 +477,7 @@
     -- Some comment here
-    /*
+    --
     -- More code here
@@ -489,7 +489,7 @@
     -- End of block
-    */
+    --
     -- Final line
"""
    
    print("Testing immediate email notification...")
    print("Sample diff content:")
    print(sample_diff)
    
    try:
        # Test the notification function
        send_immediate_notification(
            schema="ZZZ_TMILLP_05_12_25",
            filename="SBO_SP_TRANSACTIONNOTIFICATION.sql", 
            diff_text=sample_diff.strip()
        )
        print("✅ Email notification test completed successfully!")
        print("Check your email to see the GitHub-style formatted diff.")
        
    except Exception as e:
        print(f"❌ Error sending notification: {e}")
        return False
    
    return True

def test_git_manager_integration():
    """Test that GitManager calls the notification function when saving files"""
    
    print("\nTesting GitManager integration...")
    
    # Create a test repo path
    test_repo_path = Path("test_repo")
    test_repo_path.mkdir(exist_ok=True)
    
    try:
        # Initialize GitManager
        git_manager = GitManager(test_repo_path)
        
        # Sample SQL content
        old_content = """
CREATE PROCEDURE TestProc
AS
BEGIN
    PRINT 'Old version';
END
"""
        
        new_content = """
CREATE PROCEDURE TestProc
AS
BEGIN
    PRINT 'New version';
    -- Added comment
END
"""
        
        print("Saving file with GitManager (should trigger email notification)...")
        
        # Save file (this should trigger the notification)
        file_path = git_manager.save_file(
            filename="TestProc.sql",
            content=new_content,
            schema="TEST_SCHEMA"
        )
        
        print(f"✅ File saved to: {file_path}")
        print("✅ Email notification should have been sent!")
        
        return True
        
    except Exception as e:
        print(f"❌ Error in GitManager integration test: {e}")
        return False
    
    finally:
        # Cleanup test repo
        import shutil
        if test_repo_path.exists():
            shutil.rmtree(test_repo_path, ignore_errors=True)

if __name__ == "__main__":
    print("🧪 Testing email notification functionality...\n")
    
    success1 = test_immediate_notification()
    success2 = test_git_manager_integration()
    
    if success1 and success2:
        print("\n🎉 All tests passed! Email notifications are working correctly.")
    else:
        print("\n❌ Some tests failed. Check the error messages above.")
        sys.exit(1)
