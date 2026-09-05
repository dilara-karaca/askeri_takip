import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kronik_hasta_takip/services/patient_code_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_app_bar.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final TextEditingController nameController;
  final TextEditingController surnameController;
  final TextEditingController phoneController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final DateTime? selectedBirthDate;
  final String? selectedBloodType;
  final String? selectedGender;
  final List<String> selectedDiseases;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.nameController,
    required this.surnameController,
    required this.phoneController,
    required this.weightController,
    required this.heightController,
    required this.selectedBirthDate,
    required this.selectedBloodType,
    required this.selectedGender,
    required this.selectedDiseases,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isVerified = false;
  bool _isLoading = false;
  bool _isResending = false;

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Doğrulama maili tekrar gönderildi!"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: ${e.toString()}")));
    } finally {
      setState(() => _isResending = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user?.emailVerified ?? false) {
        await _saveToFirestore(user!.uid);
        setState(() => _isVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Doğrulama başarılı!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lütfen önce emailinizi doğrulayın"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Doğrulama hatası: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToFirestore(String uid) async {
    try {
      final existingPatient =
          await FirebaseFirestore.instance.collection('patients').doc(uid).get();
      if (existingPatient.exists) {
        await existingPatient.reference.update({
          'emailVerified': true,
          'lastLogin': Timestamp.now(),
        });
        await PatientCodeService.ensureMapped(
          uid,
          existingPatient.data()?['patientCode'] as String?,
        );
        return;
      }

      String patientCode;
      bool codeExists;

      do {
        patientCode = PatientCodeService.generate();
        final existing = await PatientCodeService.patientIdFor(patientCode);
        codeExists = existing != null;
      } while (codeExists);

      await FirebaseFirestore.instance.collection('patients').doc(uid).set({
        'uid': uid,
        'email': widget.email,
        'name': widget.nameController.text.trim(),
        'surname': widget.surnameController.text.trim(),
        'phone': '+90${widget.phoneController.text.trim()}',
        'weight': widget.weightController.text.trim(),
        'height': widget.heightController.text.trim(),
        'birthDate': widget.selectedBirthDate?.toIso8601String(),
        'bloodType': widget.selectedBloodType,
        'gender': widget.selectedGender,
        'diseases': widget.selectedDiseases,
        'patientCode': patientCode.toUpperCase(),
        'emailVerified': true,
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        'role': 'patient',
      });
      await PatientCodeService.ensureMapped(uid, patientCode);
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        code: e.code,
        message: 'Firestore kayıt hatası: ${e.message}',
      );
    } catch (e) {
      throw Exception('Beklenmeyen hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Hesap Doğrulama'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  "Hesap Doğrulama",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  "Doğrulama linki şu adrese gönderildi:",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.email,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (_isVerified) ...[
                  const Icon(
                    Icons.verified,
                    color: AppColors.teal,
                    size: 50,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Hesabınız Doğrulandı",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Giriş Ekranına Dön',
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/loginEmail');
                    },
                  ),
                ] else ...[
                  AppButton(
                    label: 'Doğruladım',
                    loading: _isLoading,
                    onPressed: _checkVerification,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isResending ? null : _resendVerification,
                    child:
                        _isResending
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Doğrulama Mailini Tekrar Gönder'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Eğer emaili bulamadıysanız spam klasörünü kontrol edin.",
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
