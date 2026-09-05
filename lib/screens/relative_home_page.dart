import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page.dart';
import '../widgets/metric_tile.dart';

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
    if (name.isEmpty) return "Hasta'nın";

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
        patientName = patientNameFromDb ?? "Hasta";
        isLoading = false;
      });
    } catch (e) {
      print("Hasta veya yakını adı alınamadı: $e");
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
                              final patient = patientName ?? "Hasta";
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
            : "${getPossessiveSuffix(patientName!.split(' ').first)}";

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
                          "$displayName Verileri",
                          style: GoogleFonts.sourceSans3(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                    const SizedBox(height: 16),
                    const MetricTile(
                      title: 'Kalp Atışı',
                      value: '67 bpm',
                      imagePath: 'images/kalp.png',
                    ),
                    const MetricTile(
                      title: 'Tansiyon',
                      value: '126/70',
                      imagePath: 'images/tansiyon.png',
                    ),
                    const MetricTile(
                      title: 'Vücut Sıcaklığı',
                      value: '37°C',
                      imagePath: 'images/temp.png',
                    ),
                    const MetricTile(
                      title: 'Kan Oksijen',
                      value: '96 %',
                      imagePath: 'images/kan.png',
                    ),
                    const MetricTile(
                      title: 'Stres Seviyesi',
                      value: 'Düşük',
                      imagePath: 'images/stressed.png',
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
