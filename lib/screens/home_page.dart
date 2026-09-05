import 'package:fl_chart/fl_chart.dart';
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
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page.dart';
import '../widgets/app_card.dart';
import '../widgets/metric_tile.dart';

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

  bool showPatientCode = false;
  Map<String, dynamic>? userData;

  double? currentBpm;
  List<double> bpmList = [];
  Timer? bpmTimer;

  double? currentTemp;
  List<double> TempList = [];
  Timer? TempTimer;

  double _botTop = 600;
  double _botLeft = 20;
  final PageController _heartPageController = PageController();
  final PageController _pressurePageController = PageController();

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

  @override
  void dispose() {
    _locationService.stopPeriodicLocationUpdates();
    dataSubscription?.cancel();
    refreshTimer?.cancel();
    bpmTimer?.cancel();
    _heartPageController.dispose();
    _pressurePageController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundImage: AssetImage(
                                  'images/person.png',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  userData?['name'] ?? '...',
                                  style: GoogleFonts.fraunces(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    showPatientCode = !showPatientCode;
                                  });
                                },
                                child: AppCard(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        showPatientCode
                                            ? (userData?['patientCode'] ??
                                                'Kod yok')
                                            : "Hasta Kodu",
                                        style: GoogleFonts.sourceSans3(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        showPatientCode
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        size: 18,
                                        color: AppColors.muted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: screenHeight * 0.3,
                            child: PageView(
                              controller: _heartPageController,
                              children: [
                                _buildHeartCard(screenWidth),
                                _buildHeartGraphCard(
                                  screenHeight,
                                  screenWidth,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: SmoothPageIndicator(
                              controller: _heartPageController,
                              count: 2,
                              effect: const ExpandingDotsEffect(
                                dotHeight: 6,
                                dotWidth: 6,
                                expansionFactor: 3,
                                spacing: 5,
                                activeDotColor: AppColors.forest,
                                dotColor: AppColors.sage,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: screenHeight * 0.3,
                            child: PageView(
                              controller: _pressurePageController,
                              children: [
                                _buildPressureCard(screenWidth),
                                _buildPressureGraphCard(screenWidth),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: SmoothPageIndicator(
                              controller: _pressurePageController,
                              count: 2,
                              effect: const ExpandingDotsEffect(
                                dotHeight: 6,
                                dotWidth: 6,
                                expansionFactor: 3,
                                spacing: 5,
                                activeDotColor: AppColors.forest,
                                dotColor: AppColors.sage,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          MetricTile(
                            title: "Adım Sayısı",
                            imagePath: "images/ayak.png",
                            value: "${sensorData['STEPS']} Adım",
                          ),
                          const MetricTile(
                            title: "Kan Oksijen Seviyesi",
                            imagePath: "images/kan.png",
                            value: "96%",
                          ),
                          const MetricTile(
                            title: "Stres Seviyesi",
                            imagePath: "images/stressed.png",
                            value: "Düşük",
                          ),
                          MetricTile(
                            title: "Vücut Isısı",
                            imagePath: "images/temp.png",
                            value:
                                currentTemp != null
                                    ? "${currentTemp!.toStringAsFixed(1)}°C"
                                    : "-",
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
                        final screenWidth = MediaQuery.of(context).size.width;
                        setState(() {
                          _botLeft =
                              _botLeft > screenWidth / 2
                                  ? screenWidth - 70
                                  : 10;
                        });
                      },
                      child: _buildChatBotButton(screenWidth),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildHeartCard(double screenWidth) {
    return AppCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "bpm",
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  currentBpm != null ? currentBpm!.toStringAsFixed(0) : "-",
                  style: TextStyle(
                    fontSize: screenWidth * 0.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Image.asset("images/kalp.png", height: screenWidth * 0.12),
              ],
            ),
            const SizedBox(height: 16),
            // 📊 Çubuk + iğne
            Stack(
              children: [
                // Renkli çubuk her zaman görünür
                Container(
                  height: 18,
                  width: screenWidth - 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.blue,
                        Colors.green,
                        Colors.yellow,
                        Colors.orange,
                        Colors.red,
                      ],
                    ),
                  ),
                ),
                // İğne sadece veri varsa görünür
                if (currentBpm != null)
                  Positioned(
                    left:
                        ((currentBpm!.clamp(50, 150) - 50) / 100) *
                        (screenWidth - 64),
                    top: 3,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (currentBpm != null)
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Yavaş",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Normal",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Hızlı",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
    );
  }

  Widget _buildHeartGraphCard(double screenHeight, double screenWidth) {
    return AppCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Kalp Ritmi Grafiği",
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 65),
            bpmList.isEmpty
                ? Center(
                  child: Text(
                    "Grafik görüntülenemiyor.\nLütfen cihazınızı bağlayın.",
                    style: TextStyle(
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                )
                : SizedBox(
                  height: screenHeight * 0.18,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots:
                              bpmList
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) => FlSpot(
                                      e.key.toDouble() *
                                          (60 /
                                              bpmList.length), // Zaman aralığı
                                      e.value,
                                    ),
                                  )
                                  .toList(),
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
          ],
        ),
    );
  }

  Widget _buildPressureCard(double screenWidth) {
    return AppCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset("images/tansiyon.png", width: 65, height: 65),
                const SizedBox(width: 8),
                Text(
                  "Tansiyon",
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      "Büyük Tansiyon",
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "-",
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 70,
                  child: VerticalDivider(
                    color: const Color.fromARGB(255, 134, 130, 130),
                    thickness: 3,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "Küçük Tansiyon",
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "-",
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildPressureGraphCard(double screenWidth) {
    return AppCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "1 Mayıs 2025",
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      "Büyük Tansiyon",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("Max   Min"),
                    const SizedBox(height: 8),
                    Text(
                      "-   -",
                      style: TextStyle(
                        fontSize: screenWidth * 0.065,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 100,
                  child: VerticalDivider(
                    color: const Color.fromARGB(255, 134, 130, 130),
                    thickness: 3,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "Küçük Tansiyon",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("Max   Min"),
                    const SizedBox(height: 8),
                    Text(
                      "-   -",
                      style: TextStyle(
                        fontSize: screenWidth * 0.065,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
        width: screenWidth * 0.18,
        height: screenWidth * 0.18,
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
            width: screenWidth * 0.2,
            height: screenWidth * 0.2,
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
        sensorData = parsed;
        lastRawData = "-";
      });
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
