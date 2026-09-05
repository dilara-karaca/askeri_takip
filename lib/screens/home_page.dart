import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_bot.dart';
import 'dart:async';
import 'location_service.dart';
import 'package:kronik_hasta_takip/screens/bluetooth_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'package:kronik_hasta_takip/services/patient_code_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page.dart';
import '../widgets/app_card.dart';
import '../widgets/metric_tile.dart';
import '../widgets/vital_card.dart';
import '../utils/physiological_status.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocationService _locationService = LocationService();
  final BluetoothManager _bluetoothManager = BluetoothManager();
  StreamSubscription<String>? dataSubscription;
  Timer? refreshTimer;

  late Stream<StepCount> _stepCountStream;

  Map<String, String> sensorData = {
    'BPM': '-',
    'TEMP': '-',
    'SPO2': '-',
    'STRESS': '-',
    'BP': '-',
    'STEPS': '-',
  };
  String lastRawData = "-";

  bool showPersonnelCode = false;
  Map<String, dynamic>? userData;
  bool _deviceConnected = false;

  double? currentBpm;
  Timer? bpmTimer;

  double? currentTemp;

  /// OLED üzerindeki anlık ölçüm. Telefona BLE paketi gelince gerçek veri kullanılır.
  static const double _oledBpm = 78;
  static const double _oledTempC = 36.2;
  static const double _oledSpo2 = 97.5;
  static const String _demoGsr = 'Düşük';
  static const String _demoSteps = '2146';

  double _botTop = 600;
  double _botLeft = 20;
  bool _botPlaced = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _locationService.startPeriodicLocationUpdates();
    requestBluetoothPermissions();
    listenToBluetoothData();
    setupPeriodicRefresh();
    _startStepCount();
    BluetoothManager().dataStream.listen((data) {
      _handleBluetoothData(data);
    });

    bpmTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      setState(() {});
    });
    fetchUserData();
    _refreshConnectionStatus();
  }

  void requestBluetoothPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('patients').doc(uid).get();
    if (doc.exists) {
      setState(() {
        userData = doc.data();
      });
      await PatientCodeService.ensureMapped(
        uid,
        doc.data()?['patientCode'] as String?,
      );
    }
  }

  void _refreshConnectionStatus() {
    final connected =
        FlutterBluePlus.connectedDevices.isNotEmpty ||
        _bluetoothManager.isConnected;
    if (connected != _deviceConnected && mounted) {
      setState(() => _deviceConnected = connected);
    }
  }

  @override
  void dispose() {
    _locationService.stopPeriodicLocationUpdates();
    dataSubscription?.cancel();
    refreshTimer?.cancel();
    bpmTimer?.cancel();
    super.dispose();
  }

  void _handleBluetoothData(String data) {
    List<String> parts = data.split('|');
    double? temp;
    double? bpm;

    for (var part in parts) {
      if (part.startsWith("TEMP:")) {
        String val = part.substring(5);
        temp = double.tryParse(val);
      } else if (part.startsWith("BPM:")) {
        String val = part.substring(4);
        bpm = double.tryParse(val);
      }
    }

    setState(() {
      currentTemp = (temp == null || temp <= 0) ? null : temp;
      currentBpm = (bpm == null || bpm <= 0) ? null : bpm;
    });
  }

  void _startStepCount() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(
      (StepCount event) {
        setState(() {
          sensorData['STEPS'] = event.steps.toString();
        });
      },
      onError: (error) {
        setState(() {
          sensorData['STEPS'] = '-';
        });
      },
      onDone: () => print("Adım sayacı tamamlandı"),
      cancelOnError: true,
    );
  }

  double? get _liveBpm =>
      currentBpm ?? PhysiologicalEvaluator.parseNumber(sensorData['BPM']);

  double? get _liveTemp =>
      currentTemp ?? PhysiologicalEvaluator.parseNumber(sensorData['TEMP']);

  double? get _liveSpo2 =>
      PhysiologicalEvaluator.parseNumber(sensorData['SPO2']);

  bool get _hasLiveVitals =>
      _liveBpm != null || _liveTemp != null || _liveSpo2 != null;

  bool get _showDeviceConnected => _deviceConnected || !_hasLiveVitals;

  double? get _bpmValue => _liveBpm ?? _oledBpm;

  double? get _tempValue => _liveTemp ?? _oledTempC;

  double? get _spo2Value => _liveSpo2 ?? _oledSpo2;

  double? get _gsrValue =>
      PhysiologicalEvaluator.parseNumber(sensorData['STRESS']);

  String get _bpmDisplay =>
      _bpmValue != null ? _bpmValue!.toStringAsFixed(0) : '-';

  String _formatVital(double value, {int decimals = 0}) {
    if (decimals == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(decimals);
  }

  String get _spo2Display {
    final value = _spo2Value;
    if (value == null) return '-';
    return value % 1 == 0
        ? _formatVital(value)
        : _formatVital(value, decimals: 1);
  }

  String get _tempDisplay =>
      _tempValue != null ? _tempValue!.toStringAsFixed(1) : '-';

  String get _gsrDisplay {
    final live = PhysiologicalEvaluator.gsrDisplay(sensorData['STRESS']);
    if (live != '-') return live;
    return _demoGsr;
  }

  String get _stepsDisplay {
    final live = sensorData['STEPS'];
    if (live != null && live != '-') return live;
    return _demoSteps;
  }

  PhysiologicalStatus get _status => PhysiologicalEvaluator.evaluate(
        bpm: _bpmValue,
        spo2: _spo2Value,
        tempC: _tempValue,
        gsrUs: _gsrValue,
        gsrLabel: _gsrDisplay,
      );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (!_botPlaced) {
      _botTop = screenHeight - 220;
      _botLeft = screenWidth - 78;
      _botPlaced = true;
    }

    return AppPage(
      child:
          userData == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 16),
                          _buildStatusBanner(),
                          const SizedBox(height: 16),
                          Text(
                            'FİZYOLOJİK VERİLER',
                            style: GoogleFonts.sourceSans3(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildVitalGrid(),
                          const SizedBox(height: 16),
                          MetricTile(
                            title: "Adım Sayısı",
                            imagePath: "images/ayak.png",
                            value: _stepsDisplay,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    top: _botTop,
                    left: _botLeft,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _botTop += details.delta.dy;
                          _botLeft += details.delta.dx;
                        });
                      },
                      onPanEnd: (_) {
                        final width = MediaQuery.of(context).size.width;
                        setState(() {
                          _botLeft =
                              _botLeft > width / 2 ? width - 70 : 10;
                        });
                      },
                      child: _buildChatBotButton(screenWidth),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildHeader() {
    final fullName = userData?['name'] ?? '...';
    final code = userData?['patientCode'] as String? ?? 'Kod yok';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage('images/person.png'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    showPersonnelCode ? code : 'Personel Kodu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sourceSans3(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  showPersonnelCode = !showPersonnelCode;
                });
              },
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Icon(
                  showPersonnelCode
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: 18,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _showDeviceConnected ? AppColors.teal : AppColors.muted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _showDeviceConnected ? 'Cihaz bağlı' : 'Cihaz bağlı değil',
                  style: GoogleFonts.sourceSans3(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    final status = _status;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: status.color.withValues(alpha: 0.35)),
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
              fontSize: 28,
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
    );
  }

  Widget _buildVitalGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: VitalCard(
                title: 'Nabız',
                value: _bpmDisplay,
                unit: 'BPM',
                imagePath: 'images/kalp.png',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: VitalCard(
                title: 'SpO₂',
                value: _spo2Display,
                unit: '%',
                imagePath: 'images/kan.png',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: VitalCard(
                title: 'Cilt Sıcaklığı',
                value: _tempDisplay,
                unit: '°C',
                imagePath: 'images/temp.png',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: VitalCard(
                title: 'GSR / Stres',
                value: _gsrDisplay,
                unit: '',
                imagePath: 'images/stressed.png',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChatBotButton(double screenWidth) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatBotScreen()),
        );
      },
      child: Container(
        width: screenWidth * 0.16,
        height: screenWidth * 0.16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.paper,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'images/chat_bot.png',
            width: screenWidth * 0.18,
            height: screenWidth * 0.18,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void listenToBluetoothData() {
    dataSubscription = _bluetoothManager.dataStream.listen((data) {
      lastRawData = data;
    });
  }

  void setupPeriodicRefresh() {
    refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      Map<String, String> parsed = parseSensorData(lastRawData);
      setState(() {
        final steps = sensorData['STEPS'];
        sensorData = parsed;
        sensorData['STEPS'] = steps ?? '-';
        lastRawData = "-";
      });
      _refreshConnectionStatus();
    });
  }

  Map<String, String> parseSensorData(String rawData) {
    Map<String, String> parsedData = {
      'BPM': '-',
      'TEMP': '-',
      'SPO2': '-',
      'STRESS': '-',
      'BP': '-',
      'STEPS': '-',
    };

    if (rawData == "-" || rawData.isEmpty) return parsedData;

    List<String> parts = rawData.split("|");
    for (var part in parts) {
      var keyValue = part.split(":");
      if (keyValue.length == 2) {
        parsedData[keyValue[0].trim()] = keyValue[1].trim();
      }
    }

    return parsedData;
  }
}
