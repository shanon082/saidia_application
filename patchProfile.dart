import 'dart:io';

void main() {
  final file = File('lib/screens/customers/profilepage.dart');
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();

  content = content.replaceAll(
    "import 'package:saidia_app/screens/customers/editProfilePage.dart';",
    "import 'package:saidia_app/screens/customers/editProfilePage.dart';\nimport 'package:saidia_app/screens/customers/aboutAppPage.dart';\nimport 'package:saidia_app/screens/customers/privacySecurityPage.dart';"
  );

  content = content.replaceAll(
    """                        _buildMenuItem(
                          icon: Icons.lock_outline,
                          title: 'Privacy & Security',
                          onTap: () {},
                        ),""",
    """                        _buildMenuItem(
                          icon: Icons.lock_outline,
                          title: 'Privacy & Security',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySecurityPage()));
                          },
                        ),"""
  );

  content = content.replaceAll(
    """                        _buildMenuItem(
                          icon: Icons.info_outline,
                          title: 'About SaidiA',
                          onTap: () {},
                        ),""",
    """                        _buildMenuItem(
                          icon: Icons.info_outline,
                          title: 'About SaidiA',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppPage()));
                          },
                        ),"""
  );

  content = content.replaceAll(
    """                            onTap: () {
                              // Logout logic
                            },""",
    """                            onTap: () async {
                              await Supabase.instance.client.auth.signOut();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                              }
                            },"""
  );

  file.writeAsStringSync(content);
}
