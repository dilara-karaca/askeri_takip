import 'package:flutter/material.dart';
import '../widgets/app_page.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_app_bar.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();

    return AppPage(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Şifremi Unuttum'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Şifremi Unuttum',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Kayıtlı telefon numaranızı girin.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'SMS Gönder',
                onPressed: () {
                  final phone = phoneController.text.trim();
                  if (phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Telefon numarası giriniz")),
                    );
                    return;
                  }

                  Navigator.pushNamed(context, '/forgotVerify');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
