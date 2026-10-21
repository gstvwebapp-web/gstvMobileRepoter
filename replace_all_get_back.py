import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content

    # Replace onPressed: Get.back
    content = re.sub(r'onPressed:\s*Get\.back(,?)\s*', r'onPressed: () => Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back()\1', content)

    # Replace Get.back(result: X) 
    # Be careful not to replace if it's already in the replacement
    # We can use negative lookbehind or just a careful regex
    
    # Let's find all Get.back() that are not preceded by `else {` or `: `
    # But wait, `Get.overlayContext != null ? Navigator.pop(...) : Get.back()` has `: Get.back()`.
    
    # We'll use a function for re.sub to avoid double replacing.
    
    def repl_no_args(match):
        prefix = match.group(1)
        if 'Navigator.pop' in prefix or '?' in prefix or ':' in prefix:
            return match.group(0) # skip
        return f"{prefix}Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back()"

    # (?<!\:\s)Get\.back\(\)
    # But Python's lookbehind must be fixed width.
    
    # Let's just do it manually with split/replace or regex.
    # To be safe, we will just find all `Get.back()` and `Get.back(result: ...)`
    
    # First, let's normalize everything to avoid replacing already replaced ones.
    # Actually, the user's project only has a few files. Let's just scan lib/
    
    content = re.sub(r'Get\.back\(\)', r'Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back()', content)
    content = re.sub(r'Get\.back\(result:\s*([^)]+)\)', r'Get.overlayContext != null ? Navigator.pop(Get.overlayContext!, \1) : Get.back(result: \1)', content)

    # Now we need to fix cases where we accidentally replaced it inside the replacement itself!
    # Because if we replaced `Get.back()` with `... : Get.back()`, the second run won't affect it, but the first run did it correctly.
    # Wait, the first run replaces `Get.back()` with `Get.overlayContext != null ? Navigator.pop(...) : Get.back()`.
    # Then it contains `Get.back()`. If I run it again, it replaces the second one!
    # But I only run it once.
    # WAIT! `Get.back()` inside the replacement will be matched if I run the script again.
    
    # Better approach:
    # Read file, find all `Get.back` and replace cautiously.
    pass

def safe_replace(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    orig = content
    
    # 1. tear-offs
    content = re.sub(r'onPressed:\s*Get\.back\b', r'onPressed: () => Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back()', content)

    # 2. Get.back(result: X)
    # Match Get.back(result: X) but only if not preceded by ': '
    content = re.sub(r'(?<!:\s)Get\.back\(result:\s*([^)]+)\)', r'Get.overlayContext != null ? Navigator.pop(Get.overlayContext!, \1) : Get.back(result: \1)', content)

    # 3. Get.back()
    # Match Get.back() but only if not preceded by ': ' or 'else {\n                '
    content = re.sub(r'(?<!:\s)(?<!\{\n                )(?<!\{\n      )Get\.back\(\)', r'Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back()', content)

    # Clean up double replacements if any
    content = content.replace(
        'Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back()',
        'Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back()'
    )
    # And for results:
    content = re.sub(
        r'Get\.overlayContext != null \? Navigator\.pop\(Get\.overlayContext!, ([^)]+)\) : Get\.overlayContext != null \? Navigator\.pop\(Get\.overlayContext!, \1\) : Get\.back\(result: \1\)',
        r'Get.overlayContext != null ? Navigator.pop(Get.overlayContext!, \1) : Get.back(result: \1)',
        content
    )
    
    # Also fix cases where I previously used if-else blocks:
    # if (Get.overlayContext != null) {
    #   Navigator.pop(Get.overlayContext!);
    # } else {
    #   Get.overlayContext != null ? ...
    # This might happen if I already manually edited some files.
    
    if orig != content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            safe_replace(os.path.join(root, file))

