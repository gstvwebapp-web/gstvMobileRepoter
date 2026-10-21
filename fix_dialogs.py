import re
import sys

def replace_get_back(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    # The robust replacement string
    robust_get_back = '''if (Get.overlayContext != null) {
                Navigator.pop(Get.overlayContext!);
              } else {
                Get.back();
              }'''

    # We want to replace cases of Get.back(); that are used in dialogs.
    # To be safe, we will specifically replace it in the dialog callbacks.
    # Looking at the patterns:
    
    # 1. Cancel buttons
    pattern1 = '''            onPressed: () {
              Get.back();
            },'''
    replacement1 = '''            onPressed: () {
              if (Get.overlayContext != null) {
                Navigator.pop(Get.overlayContext!);
              } else {
                Get.back();
              }
            },'''
    content = content.replace(pattern1, replacement1)

    # 2. Update status button
    pattern2 = '''            onPressed: () {
              Get.back();
              _updateNewsStatus'''
    replacement2 = '''            onPressed: () {
              if (Get.overlayContext != null) {
                Navigator.pop(Get.overlayContext!);
              } else {
                Get.back();
              }
              _updateNewsStatus'''
    content = content.replace(pattern2, replacement2)

    # 3. Delete button
    pattern3 = '''            onPressed: () {
              Get.back();
              _performDeleteNews'''
    replacement3 = '''            onPressed: () {
              if (Get.overlayContext != null) {
                Navigator.pop(Get.overlayContext!);
              } else {
                Get.back();
              }
              _performDeleteNews'''
    content = content.replace(pattern3, replacement3)

    # 4. Logout button
    pattern4 = '''            onPressed: () {
              Get.back();
              _performLogout'''
    replacement4 = '''            onPressed: () {
              if (Get.overlayContext != null) {
                Navigator.pop(Get.overlayContext!);
              } else {
                Get.back();
              }
              _performLogout'''
    content = content.replace(pattern4, replacement4)

    # Also replace cancelDialogFilters and clearDialogFilters
    pattern5 = '''    Get.back();
  }'''
    replacement5 = '''    if (Get.overlayContext != null) {
      Navigator.pop(Get.overlayContext!);
    } else {
      Get.back();
    }
  }'''
    # We should only apply pattern5 if it's for clearDialogFilters or cancelDialogFilters
    # Let's just do a manual replace for the specific lines if needed.
    
    with open(file_path, 'w') as f:
        f.write(content)
    print(f"Updated {file_path}")

replace_get_back('lib/app/modules/newslist/newslist_controller.dart')
