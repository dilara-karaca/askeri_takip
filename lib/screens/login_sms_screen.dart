import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_app_bar.dart';
import '../widgets/auth_header.dart';

class LoginSmsScreen extends StatefulWidget {
  const LoginSmsScreen({super.key});

  @override
  State<LoginSmsScreen> createState() => _LoginSmsScreenState();
}

class _LoginSmsScreenState extends State<LoginSmsScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  late String verificationId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    verificationId = ModalRoute.of(context)!.settings.arguments as String;
  }

  void _handleInput(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _handleBackspace(String value, int index) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getSmsCode() {
    return _controllers.map((c) => c.text.trim()).join();
  }

  Future<void> _verifyCode() async {
    final smsCode = _getSmsCode();
    if (smsCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen 6 haneli kodu girin.")),
      );
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hatalı kod: ${e.message}")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: ${e.toString()}")));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('SMS Doğrulama'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            children: [
              const AuthHeader(
                title: 'Fizyolojik Takip',
                subtitle: 'SMS kodunu girin',
                logoSize: 96,
              ),
              const SizedBox(height: 28),
              AppCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Text(
                      'SMS Doğrulama',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 42,
                          height: 50,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: Theme.of(context).textTheme.titleLarge,
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.paper,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) => _handleInput(value, index),
                            onEditingComplete:
                                () => _handleBackspace(
                                  _controllers[index].text,
                                  index,
                                ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    AppButton(label: 'Giriş Yap', onPressed: _verifyCode),
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
