import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class Emergency extends StatefulWidget {
  const Emergency({Key? key}) : super(key: key);

  @override
  State<Emergency> createState() => _EmergencyState();
}

class _EmergencyState extends State<Emergency>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> relatives = [];
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    fetchRelatives();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> fetchRelatives() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('relatives')
            .where('linkedPatient', isEqualTo: uid)
            .get();

    setState(() {
      relatives =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'uid': data['uid'] ?? '',
              'name': '${data['name'] ?? ''} ${data['surname'] ?? ''}',
              'phone': data['phone'] ?? '',
            };
          }).toList();
    });
  }

  Future<void> callRelative(String phoneNumber) async {
    await _openDialer(phoneNumber);
  }

  /// Opens the phone keypad with the number filled in. Does not place the call.
  Future<void> _openDialer(String phoneNumber) async {
    final digits = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) {
      _showDialError();
      return;
    }

    final uri = Uri.parse('tel:$digits');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        _showDialError();
      }
    }
  }

  void _showDialError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Arama ekranı açılamadı.")),
    );
  }

  Future<void> sendEmergencyNotification(String relativeUid) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'to': relativeUid,
      'message': 'Personel acil fizyolojik durum bildirimi gönderdi.',
      'timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Bildirim gönderildi.")));
  }

  void _call112() {
    HapticFeedback.heavyImpact();
    _openDialer('112');
  }

  Future<void> _notifyAllLinkedContacts() async {
    if (relatives.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıtlı irtibat bulunmuyor.")),
      );
      return;
    }

    for (final contact in relatives) {
      final uid = contact['uid'] as String? ?? '';
      if (uid.isEmpty) continue;
      await FirebaseFirestore.instance.collection('notifications').add({
        'to': uid,
        'message': 'Personel acil fizyolojik durum bildirimi gönderdi.',
        'timestamp': Timestamp.now(),
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Bildirim gönderildi.")));
  }

  void _openContactActions(Map<String, dynamic> contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2C9C4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  contact['name'] ?? '',
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nasıl ulaşmak istiyorsunuz?',
                  style: GoogleFonts.sourceSans3(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _SheetAction(
                        icon: Icons.notification_important_outlined,
                        label: 'Bildirim Gönder',
                        color: AppColors.emergency,
                        onTap: () {
                          Navigator.pop(context);
                          sendEmergencyNotification(contact['uid'] ?? '');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SheetAction(
                        icon: Icons.phone_outlined,
                        label: 'Telefonla Ara',
                        color: AppColors.forest,
                        onTap: () {
                          Navigator.pop(context);
                          callRelative(contact['phone'] ?? '');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6EEEC),
        body: Column(
          children: [
            _EmergencyHeader(onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'KRİTİK FİZYOLOJİK ANOMALİ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sourceSans3(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppColors.emergency,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SosButton(pulse: _pulse, onPressed: _call112),
                    const SizedBox(height: 14),
                    Text(
                      'Acil durum tespit edildi.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '112 tuş takımını açar. Bildirimler kayıtlı irtibat hesaplarına gönderilir.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sourceSans3(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _EmergencyActionButton(
                      icon: Icons.medical_services_outlined,
                      label: 'Sağlık Desteği Bildir',
                      onTap: _notifyAllLinkedContacts,
                    ),
                    const SizedBox(height: 10),
                    _EmergencyActionButton(
                      icon: Icons.phone_in_talk_outlined,
                      label: "112'yi Ara",
                      filled: true,
                      onTap: _call112,
                    ),
                    const SizedBox(height: 10),
                    _EmergencyActionButton(
                      icon: Icons.campaign_outlined,
                      label: 'Bölüğe Bildir',
                      onTap: _notifyAllLinkedContacts,
                    ),
                    const SizedBox(height: 28),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'KAYITLI İRTİBAT',
                        style: GoogleFonts.sourceSans3(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Komuta ve sağlık desteği irtibatlarını bilgilendirin.',
                        style: GoogleFonts.sourceSans3(
                          fontSize: 14,
                          color: AppColors.ink.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (relatives.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 22,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8D4D0)),
                        ),
                        child: Text(
                          'Kayıtlı irtibat bulunmuyor.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sourceSans3(
                            fontSize: 15,
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    else
                      ...relatives.map(
                        (contact) => _RelativeCard(
                          name: contact['name'] ?? '',
                          onNotify: () => sendEmergencyNotification(
                            contact['uid'] ?? '',
                          ),
                          onCall: () => callRelative(contact['phone'] ?? ''),
                          onMore: () => _openContactActions(contact),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _EmergencyHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE8D4D0)),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Acil Durum',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.emergencySoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '112',
                style: GoogleFonts.sourceSans3(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.emergency,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  final Animation<double> pulse;
  final VoidCallback onPressed;

  const _SosButton({required this.pulse, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = Curves.easeOut.transform(pulse.value);
        return SizedBox(
          width: 248,
          height: 248,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _PulseRing(progress: t, size: 236, opacity: 0.18),
              _PulseRing(
                progress: (t + 0.45) % 1.0,
                size: 200,
                opacity: 0.12,
              ),
              const IgnorePointer(
                child: CustomPaint(
                  size: Size.square(220),
                  painter: _CircularGlowPainter(),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Ink(
            width: 168,
            height: 168,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD6453D), Color(0xFF8E1A14)],
              ),
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xFFFFD0C8), width: 3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '112',
                  style: GoogleFonts.fraunces(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.w600,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ARA',
                  style: GoogleFonts.sourceSans3(
                    color: Color(0xE6FFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.2,
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

class _CircularGlowPainter extends CustomPainter {
  const _CircularGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 6);
    final paint = Paint()
      ..color = const Color(0x668E1A14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, 78, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulseRing extends StatelessWidget {
  final double progress;
  final double size;
  final double opacity;

  const _PulseRing({
    required this.progress,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final scale = 0.72 + (progress * 0.28);
    return Opacity(
      opacity: (1 - progress) * opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.emergency,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _RelativeCard extends StatelessWidget {
  final String name;
  final VoidCallback onNotify;
  final VoidCallback onCall;
  final VoidCallback onMore;

  const _RelativeCard({
    required this.name,
    required this.onNotify,
    required this.onCall,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D4D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.emergencySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.emergency,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onMore,
              behavior: HitTestBehavior.opaque,
              child: Text(
                name,
                style: GoogleFonts.sourceSans3(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          _RoundAction(
            icon: Icons.notifications_active_outlined,
            tooltip: 'Bildirim Gönder',
            onTap: onNotify,
          ),
          _RoundAction(
            icon: Icons.phone_outlined,
            tooltip: 'Telefonla Ara',
            onTap: onCall,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;

  const _RoundAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: filled ? AppColors.emergency : AppColors.emergencySoft,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                icon,
                size: 20,
                color: filled ? Colors.white : AppColors.emergency,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _EmergencyActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: filled ? AppColors.emergency : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: filled ? AppColors.emergency : const Color(0xFFE8D4D0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: filled ? Colors.white : AppColors.emergency,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.sourceSans3(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: filled ? Colors.white : AppColors.ink,
                    ),
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

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.sourceSans3(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
