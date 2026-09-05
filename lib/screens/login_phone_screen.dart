import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_field.dart';
import '../widgets/app_segmented.dart';
import '../widgets/auth_header.dart';

class LoginPhoneScreen extends StatefulWidget {
  const LoginPhoneScreen({super.key});

  @override
  State<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  final TextEditingController phoneController = TextEditingController(
    text: "+90",
  );
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  Future<void> loginWithPhone() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: phoneController.text.trim(),
            password: passwordController.text.trim(),
          );

      final user = userCredential.user;
      if (user == null) return;

      final patientDoc =
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(user.uid)
              .get();

      if (patientDoc.exists) {
        Navigator.pushReplacementNamed(context, '/patientHome');
      } else {
        final relativeDoc =
            await FirebaseFirestore.instance
                .collection('relatives')
                .doc(user.uid)
                .get();

        if (relativeDoc.exists) {
          Navigator.pushReplacementNamed(context, '/relativeHome');
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Kullanıcı bulunamadı")));
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${e.message ?? "Bilinmeyen hata"}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 28,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
            left: 24,
            right: 24,
          ),
          child: Form(
            key: _formKey,
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
                        selectedIndex: 1,
                        onChanged: (index) {
                          if (index == 0) {
                            Navigator.pushReplacementNamed(
                              context,
                              '/loginEmail',
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      AppField(
                        controller: phoneController,
                        label: 'Telefon Numarası (+90)',
                        keyboardType: TextInputType.phone,
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Telefon numarası giriniz'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      AppField(
                        controller: passwordController,
                        label: 'Şifre',
                        obscureText: obscurePassword,
                        validator:
                            (value) =>
                                value!.length < 6
                                    ? 'Şifre en az 6 karakter olmalı'
                                    : null,
                        suffix: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.muted,
                            size: 20,
                          ),
                          onPressed:
                              () => setState(
                                () => obscurePassword = !obscurePassword,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                              () =>
                                  Navigator.pushNamed(context, '/forgotPassword'),
                          child: const Text('Şifremi Unuttum'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AppButton(label: 'Giriş Yap', onPressed: loginWithPhone),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed:
                            () =>
                                Navigator.pushNamed(context, '/registerPatient'),
                        child: const Text('Hesabınız yok mu? Kayıt Olun'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
