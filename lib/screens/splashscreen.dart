import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    await Future.delayed(Duration(seconds: 3));

    String? token = await _secureStorage.read(key: 'access_token'); // Read token from secure storage.

    if (token != null && !JwtDecoder.isExpired(token)) {
      // Token is valid
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      int? userId = decodedToken['data']['user_id'];
      String? name = decodedToken['data']['email'];

      print("User ID: $userId");
      print("Email: $name");

      // Navigate to HomeScreen
      Navigator.pushReplacementNamed(context, '/taxiHome');

    } else {
      // Token is invalid or not present
      Navigator.pushReplacementNamed(context, '/signin');

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centering the content
          children: [
            // Your app logo
            Image.asset(
              'assets/MineTAXILOGO-.png', // Make sure you have the logo in the assets folder
              height: 150,  // Adjust size as needed
              width: 150,
            ),
            SizedBox(height: 20), // Spacing between logo and loading indicator
        Text(
          'MINE TAXI',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        )],
        ),
      ),
    );
  }
}