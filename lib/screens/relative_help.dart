import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class RelativeHelp extends StatelessWidget {
  RelativeHelp({super.key});

  final PageController _pageController = PageController();

  final List<_HelpInfo> helpItems = [
    _HelpInfo(
      color: const Color(0xFF2F6B4F),
      icon: Icons.watch,
      title: "Giyilebilir Fizyolojik İzleme",
      description:
          "Bağlı personelin pazuband verileri nabız, SpO₂, cilt sıcaklığı ve GSR olarak izlenir.",
    ),
    _HelpInfo(
      color: const Color(0xFF3A6E7A),
      icon: Icons.monitor_heart_outlined,
      title: "Komuta Seviyesinde Farkındalık",
      description:
          "Personelin fizyolojik durumu ve acil bildirimleri bu hesaptan takip edilir.",
    ),
    _HelpInfo(
      color: const Color(0xFF44555A),
      icon: Icons.notifications_active_outlined,
      title: "Alarm Bildirimleri",
      description:
          "Sarı ve kırmızı alarm bildirimleri kayıtlı komuta hesabına iletilir.",
    ),
    _HelpInfo(
      color: const Color(0xFF8C3A36),
      icon: Icons.emergency,
      title: "Konum ve Acil Durum",
      description:
          "Harita, bağlı personelin son konumunu gösterir. 112 çağrısı personel cihazından yapılır.",
    ),
    _HelpInfo(
      color: const Color(0xFF5A6B3A),
      icon: Icons.smart_toy,
      title: "Saha Sağlık Asistanı",
      description:
          "Ölçüm aralıkları hakkında bilgi alın. Asistan teşhis koymaz.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: helpItems.length,
            itemBuilder: (context, index) {
              final item = helpItems[index];
              return Container(
                color: item.color,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(item.icon, size: 42, color: Colors.white),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sourceSans3(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: helpItems.length,
                effect: const ExpandingDotsEffect(
                  dotHeight: 7,
                  dotWidth: 7,
                  expansionFactor: 3,
                  spacing: 6,
                  activeDotColor: Colors.white,
                  dotColor: Color(0x66FFFFFF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpInfo {
  final Color color;
  final IconData icon;
  final String title;
  final String description;

  const _HelpInfo({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
  });
}
