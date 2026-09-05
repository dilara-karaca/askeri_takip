import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class PatientCodeService {
  static final _codes = FirebaseFirestore.instance.collection('patientCodes');

  static String generate() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return 'HT${List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join()}';
  }

  static Future<String> allocateUnique(String patientId) async {
    while (true) {
      final code = generate();
      final existing = await _codes.doc(code).get();
      if (existing.exists) continue;
      await _codes.doc(code).set({'patientId': patientId});
      return code;
    }
  }

  static Future<void> ensureMapped(String patientId, String? code) async {
    if (code == null || code.isEmpty) return;
    await _codes.doc(code.toUpperCase()).set({
      'patientId': patientId,
    }, SetOptions(merge: true));
  }

  static Future<String?> patientIdFor(String code) async {
    final doc = await _codes.doc(code.toUpperCase()).get();
    if (!doc.exists) return null;
    return doc.data()?['patientId'] as String?;
  }
}
