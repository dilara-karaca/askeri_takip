import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// UI-only display thresholds from the SAVTEK 2026 paper.
/// This app does not contain an LSTM autoencoder or backend anomaly engine.
class PhysiologicalThresholds {
  static const double spo2NormalMin = 95;
  static const double spo2CautionMin = 90;
  static const double tempNormalMin = 33;
  static const double tempNormalMax = 37;
  static const double tempCritical = 38.5;
  static const double gsrRestMax = 20;
  static const double gsrCaution = 40;
  static const double bpmNormalMin = 60;
  static const double bpmNormalMax = 100;
  static const double bpmAnomalyLow = 50;
  static const double bpmAnomalyHigh = 120;
}

enum PhysiologicalLevel { noData, normal, caution, critical }

class PhysiologicalStatus {
  final PhysiologicalLevel level;
  final String title;
  final String message;

  const PhysiologicalStatus({
    required this.level,
    required this.title,
    required this.message,
  });

  Color get color {
    switch (level) {
      case PhysiologicalLevel.normal:
        return AppColors.teal;
      case PhysiologicalLevel.caution:
        return AppColors.caution;
      case PhysiologicalLevel.critical:
        return AppColors.emergency;
      case PhysiologicalLevel.noData:
        return AppColors.muted;
    }
  }

  Color get softColor {
    switch (level) {
      case PhysiologicalLevel.normal:
        return AppColors.mint;
      case PhysiologicalLevel.caution:
        return AppColors.cautionSoft;
      case PhysiologicalLevel.critical:
        return AppColors.emergencySoft;
      case PhysiologicalLevel.noData:
        return AppColors.line;
    }
  }
}

class PhysiologicalEvaluator {
  static double? parseNumber(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-') return null;
    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(trimmed);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  static String gsrDisplay(String? raw) {
    if (raw == null) return '-';
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-') return '-';

    final value = parseNumber(trimmed);
    if (value != null) {
      if (value <= PhysiologicalThresholds.gsrRestMax) return 'Düşük';
      if (value <= PhysiologicalThresholds.gsrCaution) return 'Orta';
      return 'Yüksek';
    }

    return trimmed;
  }

  static PhysiologicalStatus evaluate({
    double? bpm,
    double? spo2,
    double? tempC,
    double? gsrUs,
    String? gsrLabel,
  }) {
    final hasGsrLabel =
        gsrLabel != null && gsrLabel.trim().isNotEmpty && gsrLabel != '-';
    final hasAny =
        bpm != null ||
        spo2 != null ||
        tempC != null ||
        gsrUs != null ||
        hasGsrLabel;

    if (!hasAny) {
      return const PhysiologicalStatus(
        level: PhysiologicalLevel.noData,
        title: 'VERİ BEKLENİYOR',
        message: 'Fizyolojik ölçüm henüz alınmadı.',
      );
    }

    var critical = false;
    var caution = false;

    if (spo2 != null) {
      if (spo2 < PhysiologicalThresholds.spo2CautionMin) {
        critical = true;
      } else if (spo2 < PhysiologicalThresholds.spo2NormalMin) {
        caution = true;
      }
    }

    if (tempC != null) {
      if (tempC > PhysiologicalThresholds.tempCritical) {
        critical = true;
      } else if (tempC < PhysiologicalThresholds.tempNormalMin ||
          tempC > PhysiologicalThresholds.tempNormalMax) {
        caution = true;
      }
    }

    if (bpm != null) {
      if (bpm < PhysiologicalThresholds.bpmAnomalyLow ||
          bpm > PhysiologicalThresholds.bpmAnomalyHigh) {
        critical = true;
      } else if (bpm < PhysiologicalThresholds.bpmNormalMin ||
          bpm > PhysiologicalThresholds.bpmNormalMax) {
        caution = true;
      }
    }

    if (gsrUs != null && gsrUs > PhysiologicalThresholds.gsrCaution) {
      caution = true;
    }

    if (hasGsrLabel && gsrLabel.toLowerCase().contains('yüksek')) {
      caution = true;
    }

    if (critical) {
      return const PhysiologicalStatus(
        level: PhysiologicalLevel.critical,
        title: 'KRİTİK',
        message: 'Kritik fizyolojik anomali tespit edildi.',
      );
    }

    if (caution) {
      return const PhysiologicalStatus(
        level: PhysiologicalLevel.caution,
        title: 'DİKKAT',
        message: 'Fizyolojik değerlerde anormal değişim tespit edildi.',
      );
    }

    return const PhysiologicalStatus(
      level: PhysiologicalLevel.normal,
      title: 'NORMAL',
      message: 'Tüm fizyolojik parametreler normal aralıkta.',
    );
  }
}
