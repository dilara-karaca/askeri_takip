import 'package:flutter/material.dart';
import '../widgets/app_page.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_app_bar.dart';

class ForgotVerifyScreen extends StatelessWidget {
  final TextEditingController smsCodeController = TextEditingController();

  ForgotVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text("SMS Doğrulama"),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: smsCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'SMS Kodu'),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Devam Et',
                onPressed: () {
                  final code = smsCodeController.text.trim();
                  if (code.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Kod giriniz")),
                    );
                    return;
                  }

                  Navigator.pushNamed(context, '/resetPassword');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
