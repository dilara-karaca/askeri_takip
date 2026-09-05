import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page.dart';
import '../widgets/vital_card.dart';
import '../utils/physiological_status.dart';

class RelativeHomePage extends StatefulWidget {
  @override
  RelativeHomePageState createState() => RelativeHomePageState();
}

class RelativeHomePageState extends State<RelativeHomePage> {
  String? patientName;
  String? relativeName;
  bool isLoading = true;
  int notificationCount = 0;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchPatientName();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final snapshot =
          await FirebaseFirestore.instance
              .collection('notifications')
              .where('to', isEqualTo: uid)
              .orderBy('timestamp', descending: true)
              .get();

      final loadedNotifications =
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

      final unreadCount =
          loadedNotifications
              .where(
                (notif) => notif['isRead'] == false || notif['isRead'] == null,
              )
              .length;

      setState(() {
        notifications = snapshot.docs.map((doc) => doc.data()).toList();
        notificationCount = unreadCount;
      });

      FirebaseFirestore.instance.runTransaction((transaction) async {
        for (var notif in snapshot.docs) {
          transaction.update(notif.reference, {'isRead': true});
        }
      });
    } catch (e) {
      print("Bildirimler alınamadı: $e");
    }
  }

  String getPossessiveSuffix(String name) {
    if (name.isEmpty) return "Personel'in";

    final vowels = 'aeıioöuü';
    final lastVowel = name
        .split('')
        .reversed
        .firstWhere(
          (char) => vowels.contains(char.toLowerCase()),
          orElse: () => 'a',
        );

    String suffix;
    switch (lastVowel.toLowerCase()) {
      case 'a':
      case 'ı':
        suffix = "'nın";
        break;
      case 'e':
      case 'i':
        suffix = "'nin";
        break;
      case 'o':
      case 'u':
        suffix = "'nun";
        break;
      case 'ö':
      case 'ü':
        suffix = "'nün";
        break;
      default:
        suffix = "'nın";
    }

    return "$name$suffix";
  }

  Future<void> fetchPatientName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final relativeDoc =
          await FirebaseFirestore.instance
              .collection('relatives')
              .doc(uid)
              .get();

      final relativeNameFromDb = relativeDoc.data()?['name'];
      final linkedPatientId = relativeDoc.data()?['linkedPatient'];
      if (linkedPatientId == null) return;

      final patientDoc =
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(linkedPatientId)
              .get();

      final patientNameFromDb = patientDoc.data()?['name'];

      setState(() {
        relativeName = relativeNameFromDb ?? "Kullanıcı";
        patientName = patientNameFromDb ?? "Personel";
        isLoading = false;
      });
    } catch (e) {
      print("Personel veya komuta hesabı adı alınamadı: $e");
      setState(() => isLoading = false);
    }
  }

  void _showNotificationsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bildirimler",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child:
                      notifications.isEmpty
                          ? const Center(child: Text("Bildirim yok"))
                          : ListView.separated(
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                ),
                                title: Text(
                                  notification['message'] ??
                                      'Acil durum bildirimi',
                                ),
                                subtitle: Text(
                                  (notification['timestamp'] as Timestamp)
                                      .toDate()
                                      .toString(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        isLoading || patientName == null
            ? null
            : getPossessiveSuffix(patientName!.split(' ').first);
    const status = PhysiologicalStatus(
      level: PhysiologicalLevel.noData,
      title: 'VERİ BEKLENİYOR',
      message:
          'Canlı fizyolojik veri bu hesapta henüz yok. Alarm bildirimleri burada görünür.',
    );

    return AppPage(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isLoading ? "Merhaba" : "Merhaba ${relativeName ?? ''}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fraunces(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 28,
                          color: AppColors.ink,
                        ),
                        onPressed: () async {
                          await fetchNotifications();
                          _showNotificationsPanel();
                        },
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.emergency,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Center(
                              child: Text(
                                '$notificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                          "$displayName fizyolojik durumu",
                          style: GoogleFonts.sourceSans3(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: status.softColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: status.color.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FİZYOLOJİK DURUM',
                            style: GoogleFonts.sourceSans3(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: status.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status.title,
                            style: GoogleFonts.fraunces(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                              color: status.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status.message,
                            style: GoogleFonts.sourceSans3(
                              fontSize: 14,
                              height: 1.35,
                              color: AppColors.ink.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(
                          child: VitalCard(
                            title: 'Nabız',
                            value: '-',
                            unit: 'BPM',
                            imagePath: 'images/kalp.png',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: VitalCard(
                            title: 'SpO₂',
                            value: '-',
                            unit: '%',
                            imagePath: 'images/kan.png',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Expanded(
                          child: VitalCard(
                            title: 'Cilt Sıcaklığı',
                            value: '-',
                            unit: '°C',
                            imagePath: 'images/temp.png',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: VitalCard(
                            title: 'GSR / Stres',
                            value: '-',
                            unit: '',
                            imagePath: 'images/stressed.png',
                          ),
                        ),
                      ],
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
