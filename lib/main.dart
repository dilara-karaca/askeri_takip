import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/login_email_screen.dart';
import 'screens/login_phone_screen.dart';
import 'screens/login_sms_screen.dart';
import 'screens/map_screen.dart';
import 'screens/register_patient_screen.dart';
import 'screens/register_relative_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/forgot_password_verify_screen.dart';
import 'screens/forgot_password_reset_screen.dart';
import 'screens/emergency.dart';
import 'screens/relative_home_page.dart';
import 'screens/relative_settings.dart';
import 'screens/relative_profile.dart';
import 'screens/relative_security.dart';
import 'screens/relative_help.dart';
import 'screens/home_page.dart';
import 'screens/settings.dart' as general_settings;
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'widgets/docked_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const KronikHastaTakipApp());
}

class KronikHastaTakipApp extends StatelessWidget {
  const KronikHastaTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fizyolojik Takip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/loginEmail',
      routes: {
        '/loginEmail': (context) => const LoginEmailScreen(),
        '/loginPhone': (context) => const LoginPhoneScreen(),
        '/loginSms': (context) => const LoginSmsScreen(),
        '/registerPatient': (context) => const RegisterPatientScreen(),
        '/registerRelative': (context) => const RegisterRelativeScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/forgotVerify': (context) => ForgotVerifyScreen(),
        '/resetPassword': (context) => const ForgotResetScreen(),
        '/patientHome': (context) => const AltNavigasyon(),
        '/relativeProfile': (context) => RelativeProfile(),
        '/patientsSecurity': (context) => const RelativeSecurity(),
        '/patientsHelp': (context) => RelativeHelp(),
        '/redirectAfterLogin': (context) => RedirectAfterLogin(),
        '/relativeHome': (context) => RelativeNavigasyon(),
      },
    );
  }
}

class RedirectAfterLogin extends StatelessWidget {
  const RedirectAfterLogin({super.key});

  Future<String?> getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final patientsDoc =
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(user.uid)
            .get();
    if (patientsDoc.exists) return 'patient';

    final relativesDoc =
        await FirebaseFirestore.instance
            .collection('relatives')
            .doc(user.uid)
            .get();
    if (relativesDoc.exists) return 'relative';

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.canvas,
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          final role = snapshot.data;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (role == 'patient') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AltNavigasyon(),
                ),
              );
            } else if (role == 'relative') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const RelativeNavigasyon(),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Geçersiz kullanıcı rolü.")),
              );
            }
          });
        } else {
          return const Scaffold(
            backgroundColor: AppColors.canvas,
            body: Center(
              child: Text("Giriş başarısız veya kullanıcı verisi yok."),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}

class RelativeNavigasyon extends StatefulWidget {
  const RelativeNavigasyon({super.key});

  @override
  State<RelativeNavigasyon> createState() => _RelativeNavigasyonState();
}

class _RelativeNavigasyonState extends State<RelativeNavigasyon> {
  int _seciliIndex = 0;

  final List<Widget> _sayfalar = [RelativeHomePage(), RelativeSettings()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _sayfalar[_seciliIndex],
      floatingActionButton: EmergencyFab(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MapScreen()),
          );
        },
        child: const Icon(
          Icons.location_on_rounded,
          size: 38,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _AppBottomBar(
        selectedIndex: _seciliIndex,
        onHome: () => setState(() => _seciliIndex = 0),
        onSettings: () => setState(() => _seciliIndex = 1),
      ),
    );
  }
}

class AltNavigasyon extends StatefulWidget {
  const AltNavigasyon({super.key});

  @override
  State<AltNavigasyon> createState() => _AltNavigasyonState();
}

class _AltNavigasyonState extends State<AltNavigasyon> {
  int _seciliIndex = 0;

  final List<Widget> _sayfalar = [
    const HomePage(),
    general_settings.Settings(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _sayfalar[_seciliIndex],
      floatingActionButton: EmergencyFab(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Emergency()),
          );
        },
        child: Text(
          "ACİL",
          style: GoogleFonts.sourceSans3(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 0.6,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _AppBottomBar(
        selectedIndex: _seciliIndex,
        onHome: () => setState(() => _seciliIndex = 0),
        onSettings: () => setState(() => _seciliIndex = 1),
      ),
    );
  }
}

class _AppBottomBar extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onHome;
  final VoidCallback onSettings;

  const _AppBottomBar({
    required this.selectedIndex,
    required this.onHome,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.forest,
      elevation: 0,
      clipBehavior: Clip.none,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            Expanded(
              child: _NavTab(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Ana Sayfa',
                selected: selectedIndex == 0,
                onTap: onHome,
              ),
            ),
            const SizedBox(width: 108),
            Expanded(
              child: _NavTab(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Ayarlar',
                selected: selectedIndex == 1,
                onTap: onSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xFF9BB0A8);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.sourceSans3(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
