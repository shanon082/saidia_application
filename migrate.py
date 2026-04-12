import os
import re

def process_dart_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # 1. Replace Imports
    content = re.sub(r"import 'package:cloud_firestore/cloud_firestore\.dart';\n", "", content)
    content = re.sub(r"import 'package:firebase_auth/firebase_auth\.dart'([a-zA-Z0-9\s]*);\n", "", content)
    content = re.sub(r"import 'package:firebase_storage/firebase_storage\.dart';\n", "", content)

    # 2. Add Supabase import if needed, but actually we will just provide the mocks in a new file,
    # or just let firestore_services.dart provide the mock classes.
    # Wait, if we remove firebase_auth, what about FirebaseAuth.instance?
    
    content = content.replace("FirebaseAuth.instance.currentUser?.uid", "FirestoreService.instance.currentUid")
    content = content.replace("FirebaseAuth.instance.currentUser", "FirestoreService.instance.currentUser")
    content = content.replace("FirebaseAuth.instance", "Supabase.instance.client.auth")
    
    # 3. Replace FieldValue.serverTimestamp() since they imported it directly sometimes?
    # No, it's usually inside firestore_services.dart
    
    # 4. If the file is missing the firestore_services import but needs the mocks
    # We will put the mocks in firestore_services.dart
    if 'import \'package:saidia_app/services/firestore_services.dart\';' not in content:
        if 'class ' in content:
            content = "import 'package:saidia_app/services/firestore_services.dart';\n" + content
            
    # Add supabase import to all files just in case
    if 'import \'package:supabase_flutter/supabase_flutter.dart\';' not in content:
        content = "import 'package:supabase_flutter/supabase_flutter.dart';\n" + content

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

def process_directory(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                process_dart_file(os.path.join(root, file))

if __name__ == "__main__":
    process_directory('lib/screens')
    process_directory('lib/auth')
    process_directory('lib/services')
    # update main as well but we did that manually
