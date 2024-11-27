import 'package:flutter/material.dart';
import 'package:luminous_face_yoga/webview_screen.dart';

  class LoadingScreen extends StatefulWidget {
    @override
    _LoadingScreenState createState() => _LoadingScreenState();
  }

  class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
    late List<AnimationController> _controllers;
    final int numberOfDots = 5;

    @override
    void initState() {
      super.initState();
      print('Initializing loading screen...');
      _controllers = List.generate(
        numberOfDots,
        (index) => AnimationController(
          duration: Duration(milliseconds: 300),
          vsync: this,
        )..repeat(reverse: true),
      );

      for (var i = 0; i < numberOfDots; i++) {
        Future.delayed(Duration(milliseconds: i * 120), () {
          if (mounted) _controllers[i].forward();
        });
      }

      // Navigate to main screen after 2 second
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WebviewScreen()),
        );
      });
    }

    @override
    Widget build(BuildContext context) {
      print('Building loading screen...');
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/loader_logo.png',
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return Container(
                    width: 150,
                    height: 150,
                    color: Colors.grey[200],
                  );
                },
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  numberOfDots,
                  (index) => AnimatedBuilder(
                    animation: _controllers[index],
                    builder: (context, child) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        height: 8 + (_controllers[index].value * 8),
                        width: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.lerp(
                            Color(0xFF748395),
                            Color(0xFF465A72),
                            _controllers[index].value,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    @override
    void dispose() {
      for (var controller in _controllers) {
        controller.dispose();
      }
      super.dispose();
    }
  }