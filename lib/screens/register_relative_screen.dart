import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kronik_hasta_takip/services/patient_code_service.dart';
import '../widgets/app_page.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_field.dart';
import '../widgets/app_segmented.dart';
import '../widgets/auth_header.dart';
import '../widgets/app_app_bar.dart';

class RegisterRelativeScreen extends StatefulWidget {
  const RegisterRelativeScreen({super.key});

  @override
  State<RegisterRelativeScreen> createState() => _RegisterRelativeScreenState();
}

class _RegisterRelativeScreenState extends State<RegisterRelativeScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController patientCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBar: AppBar(leading: const AppBackButton()),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            children: [
              const AuthHeader(
                title: 'Fizyolojik Takip',
                subtitle: 'Komuta kaydı',
              ),
              const SizedBox(height: 20),
              AppSegmented(
                labels: const ['Personel', 'Komuta'],
                selectedIndex: 1,
                onChanged: (index) {
                  if (index == 0) {
                    Navigator.pushNamed(context, '/registerPatient');
                  }
                },
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    buildInputField(label: 'Ad', controller: nameController),
                    buildInputField(
                      label: 'Soyad',
                      controller: surnameController,
                    ),
                    buildInputField(
                      label: 'E-posta',
                      controller: emailController,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: AppField(
                        controller: phoneController,
                        label: 'Telefon Numarası',
                        prefixText: '+90 ',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    buildInputField(
                      label: 'Şifre',
                      controller: passwordController,
                      obscureText: true,
                    ),
                    buildInputField(
                      label: 'Şifre Tekrar',
                      controller: confirmPasswordController,
                      obscureText: true,
                    ),
                    buildInputField(
                      label: 'Personel Bağlantı Kodu',
                      controller: patientCodeController,
                    ),
                    const SizedBox(height: 8),
                    AppButton(label: 'Kayıt Ol', onPressed: _registerRelative),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AppField(
        controller: controller,
        label: label,
        obscureText: obscureText,
      ),
    );
  }

  Future<void> _registerRelative() async {
    final name = nameController.text.trim();
    final surname = surnameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final patientCode = patientCodeController.text.trim().toUpperCase();

    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        patientCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tüm alanları doldurmalısınız.")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Şifreler eşleşmiyor.")));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifre en az 6 karakter olmalı.")),
      );
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final relativeUid = userCredential.user!.uid;

      final patientId = await PatientCodeService.patientIdFor(patientCode);
      if (patientId == null) {
        await userCredential.user?.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Geçersiz personel bağlantı kodu.")),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('relatives')
          .doc(relativeUid)
          .set({
            'uid': relativeUid,
            'name': name,
            'surname': surname,
            'email': email,
            'phone': '+90$phone',
            'linkedPatient': patientId,
            'role': 'relative',
            'createdAt': Timestamp.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kayıt başarılı! Giriş ekranına yönlendiriliyorsunuz."),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacementNamed(context, '/loginEmail');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata oluştu: ${e.toString()}")));
    }
  }
}
