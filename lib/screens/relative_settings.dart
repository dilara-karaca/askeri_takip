import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronik_hasta_takip/screens/login_email_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kronik_hasta_takip/screens/relative_profile.dart';
import 'relative_help.dart';
import 'relative_security.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page.dart';
import '../widgets/settings_row.dart';

class RelativeSettings extends StatelessWidget {
  const RelativeSettings({super.key});

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
              'Hesap ve izleme',
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
                  subtitle: 'Komuta hesabı bilgileri',
                  icon: Icons.person_outline,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RelativeProfile()),
                      ),
                ),
                SettingsRow(
                  title: "Güvenlik",
                  subtitle: 'Şifre ve hesap işlemleri',
                  icon: Icons.lock_outline,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RelativeSecurity(),
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
                  subtitle: 'Sistem kılavuzu',
                  icon: Icons.help_outline,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RelativeHelp()),
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
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text("Çıkış Yap"),
                            content: const Text(
                              "Çıkmak istediğinize emin misiniz?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Hayır"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Evet"),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginEmailScreen(),
                        ),
                        (_) => false,
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
