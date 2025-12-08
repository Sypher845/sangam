import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:sangam/constants/app_colors.dart';
import 'package:sangam/constants/app_assets.dart';
import 'package:sangam/constants/app_strings.dart';
import 'citizen_login_screen.dart';

class GettingStartedScreen extends StatefulWidget {
  const GettingStartedScreen({super.key});

  @override
  State<GettingStartedScreen> createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  bool _imagesPrecached = false;

  final List<String> _slideImages = AppAssets.sliderImages;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      _precacheImages();
      _imagesPrecached = true;
    }
  }

  void _precacheImages() {
    for (var imagePath in _slideImages) {
      precacheImage(AssetImage(imagePath), context);
    }
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < _slideImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.background),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Top logos container
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // INCOIS logo
                          Image.asset(
                            AppAssets.incoisLogo,
                            height: 45,
                            fit: BoxFit.contain,
                          ),
                          // Bharat Sarkar logo
                          Image.asset(
                            AppAssets.bharatSarkarLogo,
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                    // Layered SVG Illustration (smaller, centered)
                    SizedBox(
                      height: 140,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Background layer (home2) - blue base
                          Positioned(
                            bottom: 0,
                            left: constraints.maxWidth * 0.15,
                            child: SvgPicture.asset(
                              'assets/homeScreen/home2.svg',
                              width: constraints.maxWidth * 0.45,
                              fit: BoxFit.contain,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF3498DB),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          // Foreground layer (home1) - dark overlay (centered)
                          Positioned(
                            bottom: 0,
                            child: SvgPicture.asset(
                              'assets/homeScreen/home1.svg',
                              width: constraints.maxWidth * 0.60,
                              fit: BoxFit.contain,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF2C3E50),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                // Spacer to push content to center
                const Spacer(),
                // Sangam Logo
                Image.asset(
                  AppAssets.sangamLogo,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                // Tagline
                Text(
                  AppStrings.gettingStartedTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                    const Spacer(),
                    // Auto-sliding Image Carousel
                    SizedBox(
                      height: constraints.maxHeight * 0.27,
                      child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              itemCount: _slideImages.length,
                              itemBuilder: (context, index) {
                                return
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image(
                                    image: AssetImage(_slideImages[index]),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.greyLight,
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                            color: AppColors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                              },
                            ),
                          ),
                const SizedBox(height: 16),
                // Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slideImages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CitizenLoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      child: Text(
                        AppStrings.getStartedButton,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
                ],
              );
            },
          ),
        ),
      ),
      ),
    );
  }

}
