import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppPage extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final bool showMark;
  final bool resizeToAvoidBottomInset;

  const AppPage({
    super.key,
    required this.child,
    this.appBar,
    this.showMark = true,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF3F8F5),
                    AppColors.canvas,
                    AppColors.canvasDeep,
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -90,
            left: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mint.withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sage.withValues(alpha: 0.35),
              ),
            ),
          ),
          if (showMark)
            Positioned(
              right: -28,
              top: 36,
              child: Opacity(
                opacity: 0.08,
                child: Image.asset('images/adsiz_tasarim_14.png', width: 220),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
