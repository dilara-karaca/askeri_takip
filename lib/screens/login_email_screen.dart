import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_field.dart';
import '../widgets/app_segmented.dart';
import '../widgets/auth_header.dart';

class LoginEmailScreen extends StatefulWidget {
  const LoginEmailScreen({super.key});

  @override
  State<LoginEmailScreen> createState() => _LoginEmailScreenState();
}

class _LoginEmailScreenState extends State<LoginEmailScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool obscurePassword = true;

  Future<void> loginWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("E-posta ve şifre boş olamaz.")),
      );
      return;
    }

    try {
      await _handleLogin(email, password);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Giriş hatası: ${e.message}")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  Future<void> _handleLogin(String email, String password) async {
    final userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    await _checkUserRole(userCredential.user!.uid);
  }

  Future<void> _checkUserRole(String uid) async {
    final patientDoc =
        await FirebaseFirestore.instance.collection('patients').doc(uid).get();

    if (patientDoc.exists) {
      Navigator.pushReplacementNamed(context, '/patientHome');
      return;
    }

    final relativeDoc =
        await FirebaseFirestore.instance.collection('relatives').doc(uid).get();

    if (relativeDoc.exists) {
      Navigator.pushReplacementNamed(context, '/relativeHome');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kullanıcı rolü belirlenemedi.")),
    );
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        final userExists = await _checkIfUserExists(userCredential.user!.uid);

        if (!userExists) {
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(userCredential.user!.uid)
              .set({
                'email': userCredential.user!.email,
                'name': userCredential.user!.displayName,
                'photoUrl': userCredential.user!.photoURL,
                'createdAt': FieldValue.serverTimestamp(),
              });
        }

        Navigator.pushReplacementNamed(context, '/patientHome');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google ile giriş hatası: $e")));
    }
  }

  Future<bool> _checkIfUserExists(String uid) async {
    final patientDoc =
        await FirebaseFirestore.instance.collection('patients').doc(uid).get();

    if (patientDoc.exists) return true;

    final relativeDoc =
        await FirebaseFirestore.instance.collection('relatives').doc(uid).get();

    return relativeDoc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 28,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
            left: 24,
            right: 24,
          ),
          child: Column(
            children: [
              const AuthHeader(
                title: 'Fizyolojik Takip',
                subtitle: 'Hesabınıza giriş yapın',
              ),
              const SizedBox(height: 28),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    AppSegmented(
                      labels: const ['E-mail', 'Telefon No'],
                      selectedIndex: 0,
                      onChanged: (index) {
                        if (index == 1) {
                          Navigator.pushNamed(context, '/loginPhone');
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    AppField(
                      controller: emailController,
                      label: 'E-mail',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    AppField(
                      controller: passwordController,
                      label: 'Şifre',
                      obscureText: obscurePassword,
                      suffix: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.muted,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgotPassword');
                        },
                        child: const Text('Şifremi Unuttum'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppButton(label: 'Giriş Yap', onPressed: loginWithEmail),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: AppColors.paper,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'images/google_icon.jpeg',
                            height: 20,
                            width: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text('Google ile Giriş Yap'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/registerPatient');
                      },
                      child: const Text('Hesabınız yok mu? Kayıt Olun'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
