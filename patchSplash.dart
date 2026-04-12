import 'dart:io';

void main() {
  final file = File('lib/splashscreen.dart');
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();

  content = content.replaceAll(
    "import 'package:firebase_auth/firebase_auth.dart';",
    "import 'package:supabase_flutter/supabase_flutter.dart';"
  );
  // It has: "final user = FirebaseAuth.instance.currentUser;"
  content = content.replaceAll(
    "FirebaseAuth.instance.currentUser",
    "Supabase.instance.client.auth.currentUser"
  );
  
  file.writeAsStringSync(content);
}
