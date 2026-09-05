import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:kronik_hasta_takip/screens/email_verification_screen.dart';
import 'package:kronik_hasta_takip/services/patient_code_service.dart';
import '../widgets/app_page.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_field.dart';
import '../widgets/app_segmented.dart';
import '../widgets/auth_header.dart';
import '../widgets/app_app_bar.dart';

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  DateTime? selectedBirthDate;
  String? selectedBloodType;
  String? selectedGender;
  List<String> selectedDiseases = [];

  final List<String> diseaseList = [
    "KOAH",
    "Panik Atak",
    "Uyku apnesi ve Uyku Bozuklukları",
    "Diyabet",
    "Tansiyon",
    "Kalp",
    "Astım",
  ];

  bool _isValidEmail(String email) {
    return RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        ).hasMatch(email) &&
        !email.contains(' ') && // Boşluk kontrolü
        email
            .split('@')[1]
            .contains('.'); // @ sonrası nokta kontrolü (gmail.com gibi)
  }

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
                subtitle: 'Personel kaydı',
              ),
              const SizedBox(height: 20),
              AppSegmented(
                labels: const ['Personel', 'Komuta'],
                selectedIndex: 0,
                onChanged: (index) {
                  if (index == 1) {
                    Navigator.pushNamed(context, '/registerRelative');
                  }
                },
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _buildTextFields(),
                    _buildPhysicalInputs(),
                    _buildDropdowns(),
                    _buildDiseaseSelection(),
                    const SizedBox(height: 20),
                    AppButton(label: 'Kayıt Ol', onPressed: _registerPatient),
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

  Widget _buildTextFields() {
    return Column(
      children: [
        buildInputField(label: 'Ad', controller: nameController),
        buildInputField(label: 'Soyad', controller: surnameController),
        buildInputField(label: 'E-posta', controller: emailController),
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
          label: 'Şifre Tekrarı',
          controller: confirmPasswordController,
          obscureText: true,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  selectedBirthDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Doğum Tarihi',
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedBirthDate == null
                        ? 'Doğum Tarihi Seçiniz'
                        : '${selectedBirthDate!.day}.${selectedBirthDate!.month}.${selectedBirthDate!.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Icon(Icons.calendar_today, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildPhysicalInputs() {
    return Row(
      children: [
        Expanded(
          child: buildInputField(label: 'Kg', controller: weightController),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: buildInputField(label: 'cm', controller: heightController),
        ),
      ],
    );
  }

  Widget _buildDropdowns() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedBloodType,
            hint: const Text("Kan Grubu"),
            items:
                ["A+", "A-", "B+", "B-", "AB+", "AB-", "0+", "0-"]
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => selectedBloodType = value),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedGender,
            hint: const Text("Cinsiyet"),
            items:
                ["Kadın", "Erkek"]
                    .map(
                      (gender) =>
                          DropdownMenuItem(value: gender, child: Text(gender)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => selectedGender = value),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiseaseSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        MultiSelectDialogField<String>(
          items: diseaseList.map((e) => MultiSelectItem<String>(e, e)).toList(),
          title: const Text("Tıbbi Kayıtlar"),
          buttonText: const Text("Tıbbi Bilgi Seç"),
          onConfirm: (values) {
            setState(() {
              selectedDiseases = List<String>.from(values);
            });
          },
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
      ],
    );
  }

  Future<void> _registerPatient() async {
    final name = nameController.text.trim();
    final surname = surnameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final weight = weightController.text.trim();
    final height = heightController.text.trim();

    // Validation checks
    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        weight.isEmpty ||
        height.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurunuz.")),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçerli bir email adresi girin!")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Şifreler uyuşmuyor!")));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifre en az 6 karakter olmalı.")),
      );
      return;
    }

    if (selectedDiseases.isEmpty ||
        selectedBloodType == null ||
        selectedGender == null ||
        selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm bilgileri eksiksiz giriniz.")),
      );
      return;
    }

    try {
      // 1. Firebase Auth'da kullanıcı oluştur
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Doğrulama maili gönder
      await userCredential.user?.sendEmailVerification();

      final patientCode = await PatientCodeService.allocateUnique(
        userCredential.user!.uid,
      );

      // 4. Firestore'a hasta verilerini kaydet
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': name,
            'surname': surname,
            'email': email,
            'phone': '+90$phone',
            'weight': weight,
            'height': height,
            'gender': selectedGender,
            'bloodType': selectedBloodType,
            'diseases': selectedDiseases,
            'birthDate': selectedBirthDate?.toIso8601String(),
            'patientCode': patientCode.toUpperCase(),
            'role': 'patient',
            'emailVerified': false, // Doğrulama durumu
            'createdAt': Timestamp.now(),
          });

      // 5. Doğrulama sayfasına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => EmailVerificationScreen(
                email: email,
                nameController: nameController,
                surnameController: surnameController,
                phoneController: phoneController,
                weightController: weightController,
                heightController: heightController,
                selectedBirthDate: selectedBirthDate,
                selectedBloodType: selectedBloodType,
                selectedGender: selectedGender,
                selectedDiseases: selectedDiseases,
              ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Kayıt hatası: ";
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage += "Bu email zaten kullanımda";
          break;
        case 'invalid-email':
          errorMessage += "Geçersiz email adresi";
          break;
        case 'operation-not-allowed':
          errorMessage += "Email/şifre ile giriş kapalı";
          break;
        case 'weak-password':
          errorMessage += "Şifre en az 6 karakter olmalı";
          break;
        default:
          errorMessage += e.message ?? "Bilinmeyen hata";
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Sistem hatası: ${e.toString()}")));
    }
  }
}
