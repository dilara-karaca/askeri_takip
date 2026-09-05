import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page.dart';
import '../widgets/app_card.dart';
import '../widgets/app_app_bar.dart';

class PatientRelativePage extends StatefulWidget {
  const PatientRelativePage({super.key});

  @override
  State<PatientRelativePage> createState() => _PatientRelativePageState();
}

class _PatientRelativePageState extends State<PatientRelativePage> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _deleteRelative(String docId) async {
    await FirebaseFirestore.instance
        .collection('relatives')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Acil Durum İrtibatları'),
      ),
      child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('relatives')
                .where('linkedPatient', isEqualTo: currentUserId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Henüz kayıtlı irtibat yok."));
              }

              final relatives = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: relatives.length,
                itemBuilder: (context, index) {
                  final data = relatives[index];
                  final docId = data.id;
                  final name = data['name'];
                  final phone = data['phone'];

                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.danger),
                        onPressed: () => _deleteRelative(docId),
                      ),
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}

