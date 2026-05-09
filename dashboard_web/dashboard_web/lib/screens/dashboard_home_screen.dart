// lib/checklist/dashboard_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'main_dashboard_screen.dart';
import 'adm_screen.dart';
import 'technical_screen.dart';
import 'managerial_screen.dart';

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  final List<Widget> _screens = const [
    MainDashboardScreen(),
    AdmScreen(),
    TechnicalScreen(),
    ManagerialScreen(),
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoRotation();
  }

  void _startAutoRotation() {
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _screens.length;
        });
      }
    });
  }

  void _next() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _screens.length;
    });
  }

  void _prev() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _screens.length) % _screens.length;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            _next();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _prev();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(seconds: 1),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: _screens[_currentIndex],
              key: ValueKey<int>(_currentIndex),
            ),

            // BOTÃO VOLTAR (menor, mais baixo, canto esquerdo)
            Positioned(
              bottom: 20, // desceu um pouco
              left: 20,
              child: GestureDetector(
                onTap: _prev,
                child: Container(
                  padding: const EdgeInsets.all(7), // menor
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                  ),
                  child: const Text('⬅️', style: TextStyle(fontSize: 16)), // tamanho ajustado
                ),
              ),
            ),

            // BOTÃO AVANÇAR (menor, mais baixo, canto direito)
            Positioned(
              bottom: 20, // desceu um pouco
              right: 20,
              child: GestureDetector(
                onTap: _next,
                child: Container(
                  padding: const EdgeInsets.all(7), // menor
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                  ),
                  child: const Text('➡️', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),

            // INDICADOR DE TELA
            Positioned(
              top: 50,
              right: 50,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${_screens.length}',
                  style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}