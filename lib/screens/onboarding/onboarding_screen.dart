import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Masak Gak Pake Ribet!',
      description:
          'Dari yang gampang sampe yang fancy, temukan resep yang pas buat mood masakmu hari ini.',
      buttonText: 'Mulai',
      imagePath: 'assets/img/image_onboarding_one.png',
    ),
    OnboardingData(
      title: 'Temukan Resep!',
      description:
          'Temukan ribuan resep lezat dari dapur rumahan hingga rasa restoran. Mulai petualangan memasakmu hari ini!',
      buttonText: 'Lanjut',
      imagePath: 'assets/img/image_onboarding_two.png',
    ),
    OnboardingData(
      title: 'Simak dan Simpan Favoritmu',
      description:
          'Bookmark resep favorit dan ikuti langkah masaknya dengan panduan visual yang jelas.',
      buttonText: 'Lanjut',
      imagePath: 'assets/img/image_onboarding_three.png',
    ),
    OnboardingData(
      title: 'Resep Sesuai Selera',
      description:
          'Kami rekomendasi resep berdasarkan bahan yang kamu punya dan rasa favoritmu. Masak jadi lebih mudah!',
      buttonText: 'Selesai',
      imagePath: 'assets/img/image_onboarding_four.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to login screen instead of home
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5F6F4),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          return OnboardingPage(
            data: _pages[index],
            isLastPage: index == _pages.length - 1,
            onNextPressed: _onNextPage,
          );
        },
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String buttonText;
  final String imagePath;

  OnboardingData({
    required this.title,
    required this.description,
    required this.buttonText,
    required this.imagePath,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final bool isLastPage;
  final VoidCallback onNextPressed;

  const OnboardingPage({
    Key? key,
    required this.data,
    required this.isLastPage,
    required this.onNextPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    data.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Container(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 180,
                    left: 0,
                    right: 0,
                    child: Text(
                      'SENDOK GARPU',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(2.0, 2.0),
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                data.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onNextPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7FBFB6),
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  data.buttonText,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
