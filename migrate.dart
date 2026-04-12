import 'dart:io';

void processDartFile(String filepath) {
  final file = File(filepath);
  if (!file.existsSync()) return;

  var content = file.readAsStringSync();
  final original = content;

  // 1. Replace Imports
  content = content.replaceAll("import 'package:cloud_firestore/cloud_firestore.dart';", "");
  content = content.replaceAll(RegExp(r"import 'package:firebase_auth/firebase_auth.dart'[a-zA-Z0-9\s]*;"), "");
  content = content.replaceAll("import 'package:firebase_storage/firebase_storage.dart';", "");

  // 2. Replace auth logic
  content = content.replaceAll("FirebaseAuth.instance.currentUser?.uid", "FirestoreService.instance.currentUid");
  content = content.replaceAll("FirebaseAuth.instance.currentUser", "FirestoreService.instance.currentUser");
  content = content.replaceAll("FirebaseAuth.instance", "Supabase.instance.client.auth");
  
  if (!content.contains("import 'package:saidia_app/services/firestore_services.dart';")) {
    if (content.contains("class ")) {
      content = "import 'package:saidia_app/services/firestore_services.dart';\n$content";
    }
  }
  
  if (!content.contains("import 'package:supabase_flutter/supabase_flutter.dart';")) {
    content = "import 'package:supabase_flutter/supabase_flutter.dart';\n$content";
  }

  if (content != original) {
    file.writeAsStringSync(content);
    print("Updated $filepath");
  }
}

void processDirectory(String directoryPath) {
  final dir = Directory(directoryPath);
  if (!dir.existsSync()) return;

  final entities = dir.listSync(recursive: true);
  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.dart')) {
      processDartFile(entity.path);
    }
  }
}

void main() {
  processDirectory('lib/screens');
  processDirectory('lib/auth');
  processDirectory('lib/services');
}
