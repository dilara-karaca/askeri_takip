import 'package:flutter/material.dart';
import 'reset_password.dart';
import 'delete_account.dart';
import '../widgets/app_page.dart';
import '../widgets/app_app_bar.dart';
import '../widgets/settings_row.dart';

class RelativeSecurity extends StatefulWidget {
  const RelativeSecurity({Key? key}) : super(key: key);

  @override
  State<RelativeSecurity> createState() => _RelativeSecurityState();
}

class _RelativeSecurityState extends State<RelativeSecurity> {
  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Güvenlik'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SettingsGroup(
            children: [
              SettingsRow(
                title: 'Şifre Yenile',
                icon: Icons.lock_reset_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ResetPasswordPage()),
                  );
                },
              ),
              SettingsRow(
                title: 'Hesabı Kapat',
                icon: Icons.delete_forever_outlined,
                destructive: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DeleteAccountPage()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
