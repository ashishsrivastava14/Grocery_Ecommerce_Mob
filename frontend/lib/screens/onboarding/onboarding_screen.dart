import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'Easy Online\nGrocery Shopping',
      subtitle: 'Order daily essentials anytime, anywhere',
      icon: Icons.shopping_basket_rounded,
    ),
    _OnboardingData(
      title: 'Fresh Products\nAt Your Door',
      subtitle: 'Get fresh fruits, vegetables and more delivered',
      icon: Icons.local_shipping_rounded,
    ),
    _OnboardingData(
      title: 'Fast & Reliable\nDelivery',
      subtitle: 'Track your order in real-time from store to your door',
      icon: Icons.access_time_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            _buildDots(),
            const SizedBox(height: 32),
            _buildButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero illustration area
          Container(
            width: 280,
            height: 320,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surfacePink.withOpacity(0.5),
                  AppColors.scaffoldBackground,
                ],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: Icon(
                data.icon,
                size: 120,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.primary
                : AppColors.textLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < _pages.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                } else {
                  context.go('/home');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _currentPage < _pages.length - 1 ? 'Next' : 'Start Shopping',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (_currentPage == _pages.length - 1) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text(
                'Already have an account? Sign In',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;

  _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
