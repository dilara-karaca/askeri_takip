import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronik_hasta_takip/screens/login_email_screen.dart';
import 'profile.dart';
import 'security.dart';
import 'device_connection.dart';
import 'help.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page.dart';
import '../widgets/settings_row.dart';

class Settings extends StatelessWidget {
  final double titleFontSize = 20;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            Text(
              'Ayarlar',
              style: GoogleFonts.fraunces(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hesap, cihaz ve güvenlik',
              style: GoogleFonts.sourceSans3(
                fontSize: 15,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 26),
            SettingsGroup(
              label: 'Hesap',
              children: [
                SettingsRow(
                  title: "Profil",
                  subtitle: 'Kişisel bilgileriniz',
                  icon: Icons.person_outline,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      ),
                ),
                SettingsRow(
                  title: "Güvenlik",
                  subtitle: 'Şifre ve hesap işlemleri',
                  icon: Icons.lock_outline,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SecurityPage()),
                      ),
                ),
                SettingsRow(
                  title: "Cihaz Bağlantısı",
                  subtitle: 'Giyilebilir cihazı yönetin',
                  icon: Icons.watch_outlined,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeviceConnection(),
                        ),
                      ),
                ),
              ],
            ),
            SettingsGroup(
              label: 'Destek',
              children: [
                SettingsRow(
                  title: "Yardım",
                  subtitle: 'Uygulama kılavuzu',
                  icon: Icons.help_outline,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HelpPage()),
                      ),
                ),
              ],
            ),
            SettingsGroup(
              children: [
                SettingsRow(
                  title: "Çıkış Yap",
                  icon: Icons.logout,
                  destructive: true,
                  onTap: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text("Çıkış Yap"),
                            content: const Text(
                              "Çıkış yapmak istediğinize emin misiniz?",
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text("Hayır"),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text("Evet"),
                              ),
                            ],
                          ),
                    );

                    if (shouldLogout == true) {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginEmailScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
