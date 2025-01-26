import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widget/urlendpoints.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final String signInUrl = LoginUrl;
  final String signUpUrl = InsertUrl;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Generic function to handle token storage
  Future<void> _storeToken(String token) async {
    print("Storing token: $token");
    await _secureStorage.write(key: 'access_token', value: token);
    print("Token successfully stored.");
  }

  // Generic function to fetch stored token
  Future<String?> getToken() async {
    print("Fetching token from secure storage...");
    final token = await _secureStorage.read(key: 'access_token');
    if (token != null) {
      print("Token retrieved: $token");
    } else {
      print("No token found in secure storage.");
    }
    return token;
  }

  // Sign-in function
  Future<String> signIn(String email, String password) async {
    print("Attempting to sign in with email: $email");
    try {
      final response = await http.post(
        Uri.parse(signInUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print("Sign-in HTTP response status: ${response.statusCode}");
      print("Sign-in HTTP response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (responseBody['status'] == 'success') {
          final token = responseBody['token'];
          print("Sign-in successful. Token: $token");
          await _storeToken(token); // Store token securely
          return token;
        } else {
          final errorMessage = responseBody['message'];
          print("Sign-in failed: $errorMessage");
          throw Exception(errorMessage);
        }
      } else {
        print("Sign-in failed with status code: ${response.statusCode}");
        throw Exception("Failed to sign in. Please try again.");
      }
    } catch (e) {
      print("Error during sign-in: $e");
      throw Exception("Error during sign-in: $e");
    }
  }

  // Sign-up function
  Future<String> signUp(String email, String password) async {
    print("Attempting to sign up with email: $email");
    try {
      final response = await http.post(
        Uri.parse(signUpUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print("Sign-up HTTP response status: ${response.statusCode}");
      print("Sign-up HTTP response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (responseBody['status'] == 'success') {
          final token = responseBody['token'];
          print("Sign-up successful. Token: $token");
          await _storeToken(token); // Store token securely
          return token;
        } else {
          final errorMessage = responseBody['message'];
          print("Sign-up failed: $errorMessage");
          throw Exception(errorMessage);
        }
      } else {
        print("Sign-up failed with status code: ${response.statusCode}");
        throw Exception("Failed to sign up. Please try again.");
      }
    } catch (e) {
      print("Error during sign-up: $e");
      throw Exception("Error during sign-up: $e");
    }
  }

  // Logout function
  Future<void> logout(BuildContext context) async {
    print("Logging out...");
    await _secureStorage.delete(key: 'access_token');
    print("Token deleted successfully.");

    // Navigate to the signup screen
    Navigator.pushReplacementNamed(context, '/signup');
  }
}
