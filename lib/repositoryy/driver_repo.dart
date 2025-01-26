import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../model/driver_model.dart';
import '../widget/urlendpoints.dart';

class DriverBookingRepository {
  final String apiUrl = driver_booking;
  final String fetch = driver_fetch;
  final String updateurl = UpdateUrl;
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  String? accessToken;

  // Fetch token from secure storage if not already loaded
  Future<void> _ensureTokenLoaded() async {
    if (accessToken == null) {
      print("Access token not loaded. Fetching from secure storage...");
      accessToken = await secureStorage.read(key: 'access_token');
      if (accessToken != null) {
        print("Access token loaded successfully: $accessToken");
      } else {
        print("No access token found in secure storage.");
      }
    }
  }

  Future<bool> createBooking({
    required String pickupLocation,
    required double pickupLatitude,
    required double pickupLongitude,
    required String dropLocation,
    required double dropLatitude,
    required double dropLongitude,
    required double totalKm,
    required double totalAmount,
  }) async {
    try {
      // Ensure token is loaded
      await _ensureTokenLoaded();

      if (accessToken == null) {
        print("Error: Access token is null. Cannot proceed with booking.");
        return false;
      }

      // Send booking request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'pickup_location': pickupLocation,
          'pickup_latitude': pickupLatitude,
          'pickup_longitude': pickupLongitude,
          'drop_location': dropLocation,
          'drop_latitude': dropLatitude,
          'drop_longitude': dropLongitude,
          'total_km': totalKm,
          'total_amount': totalAmount,
        }),
      );

      print("API Request Sent:");
      print("Authorization Token: $accessToken");
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        print("Booking successful.");
        return true;
      } else {
        print("Booking failed. Error: ${responseData['message']}");
        return false;
      }
    } catch (e) {
      print("Error during booking: $e");
      return false;
    }
  }

  // Fetch all bookings
  Future<DriverBooking?> fetchBookings() async { // Returning a single booking (DriverBooking?)
    await _ensureTokenLoaded();
    print("Fetching bookings...");
    print("API Endpoint: $fetch");
    print("Access Token: $accessToken");

    try {
      final response = await http.get(
        Uri.parse(fetch),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("Decoded Response Data: $responseData");

        // Check success and extract 'data'
        if (responseData['success'] == true) {
          var bookingData = responseData['data'];

          // Ensure that the 'data' is an object (not a list)
          if (bookingData is Map<String, dynamic>) {
            // Return the single booking object
            return DriverBooking.fromJson(bookingData);
          } else {
            print("Expected a single booking object, but got: $bookingData");
            return null;
          }
        } else {
          print("Error in response: ${responseData['message']}");
          throw Exception(responseData['message']);
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
        throw Exception("Failed to fetch bookings: ${response.statusCode}");
      }
    } catch (e) {
      print("Error occurred while fetching bookings: $e");
      rethrow;
    }
  }

  /// update

  Future<bool> updateBookingStatus(String bookingId, String status) async {
    await _ensureTokenLoaded();
    print("Updating booking status...");

    try {
      final response = await http.put(
        Uri.parse("$updateurl?type=update_status"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'id': bookingId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print("Booking status updated successfully.");
          return true;
        } else {
          print("Failed to update booking status: ${responseData['message']}");
          return false;
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error updating booking status: $e");
      return false;
    }
  }



}
