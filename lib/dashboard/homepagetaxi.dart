import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../repositoryy/driver_repo.dart';
import '../regesitration/bloc/login_repository.dart';
import '../model/driver_model.dart';
import '../widget/urlendpoints.dart';

class TaxiHome extends StatefulWidget {
  const TaxiHome({super.key});

  @override
  State<TaxiHome> createState() => _TaxiHomeState();
}

class _TaxiHomeState extends State<TaxiHome> {
  GoogleMapController? _controller;
  LatLng? _currentLatLng;
  StreamSubscription<Position>? _positionStream;
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  String? accessToken;
  DriverBooking? lastActiveBooking;
  List<LatLng> _polylineCoordinates = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  final AuthRepository authRepository = AuthRepository();
  final DriverBookingRepository bookingRepository = DriverBookingRepository();

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _loadToken();
    _fetchLastActiveBooking();
    _startTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadToken() async {
    String? token = await secureStorage.read(key: 'access_token');
    setState(() {
      accessToken = token;
    });

    if (accessToken != null) {
      print("Access token loaded: $accessToken");
      Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken!);
      int? userId = decodedToken['data']['user_id'];
      String? name = decodedToken['data']['email'];

      print("User ID: $userId");
      print("Driver Email: $name");
    } else {
      print("No access token found in secure storage.");
    }
  }

  Future<void> _fetchLastActiveBooking() async {
    try {
      print("Fetching last active booking...");
      DriverBooking? booking = await bookingRepository.fetchBookings();

      if (booking != null) {
        setState(() {
          lastActiveBooking = booking;

          // Add pickup and drop-off markers
          _markers.add(
            Marker(
              markerId: const MarkerId("pickupLocation"),
              position: LatLng(lastActiveBooking!.pickupLatitude, lastActiveBooking!.pickupLongitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: const InfoWindow(title: "Pickup Location"),
            ),
          );

          _markers.add(
            Marker(
              markerId: const MarkerId("dropLocation"),
              position: LatLng(lastActiveBooking!.dropLatitude, lastActiveBooking!.dropLongitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: const InfoWindow(title: "Drop-Off Location"),
            ),
          );

          // Draw polyline between pickup and drop-off locations
          _drawPolyline(
            LatLng(lastActiveBooking!.pickupLatitude, lastActiveBooking!.pickupLongitude),
            LatLng(lastActiveBooking!.dropLatitude, lastActiveBooking!.dropLongitude),
          );
        });
      } else {
        print("No active bookings found for this user.");
      }
    } catch (e) {
      print("Error fetching last active booking: $e");
    }
  }


  Future<void> _fetchCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLatLng = LatLng(position.latitude, position.longitude);
      if (_controller != null) {
        _controller!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentLatLng!,
              zoom: 15,
            ),
          ),
        );
      }
    });
  }

  Future<void> _startTracking() async {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Fetch updates every 5 meters
      ),
    ).listen((Position position) {
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLatLng = currentLatLng;

        // Update driver's location marker
        _markers.removeWhere((marker) => marker.markerId == const MarkerId("driver"));
        _markers.add(
          Marker(
            markerId: const MarkerId("driver"),
            position: currentLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );

        // Optionally redraw polyline to drop-off location if needed
        if (lastActiveBooking != null) {
          _drawPolyline(
            currentLatLng,
            LatLng(lastActiveBooking!.dropLatitude, lastActiveBooking!.dropLongitude),
          );
        }
      });
    });
  }
  Future<void> _drawPolyline(LatLng start, LatLng end) async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: kGoogleApiKey,
      request: PolylineRequest(
        origin: PointLatLng(start.latitude, start.longitude),
        destination: PointLatLng(end.latitude, end.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      setState(() {
        _polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        _polylines = {
          Polyline(
            polylineId: const PolylineId("route"),
            color: Colors.blue,
            width: 6,
            points: _polylineCoordinates,
          ),
        };
      });
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Confirm Logout",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Are you sure you want to log out?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                authRepository.logout(context); // Call the logout function
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Yes", style: TextStyle(
                color: Colors.white
              ),),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showEndTripDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "End Trip",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Do you want to end your trip?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Close dialog with "No"
              },
              child: const Text(
                "No",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Close dialog with "Yes"
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TaxiHome()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Yes", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: lastActiveBooking != null
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${lastActiveBooking!.pickupLocation} → ${lastActiveBooking!.dropLocation}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              "Km: ${lastActiveBooking!.totalKm} / ₹${lastActiveBooking!.totalAmount.toString().substring(0, 5)}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        )
            : const Text(
          'MINE TAXI',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Logout",
          ),
        ],
        elevation: 5,
        shadowColor: Colors.black54,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),

      body: Stack(
        children: [
          _currentLatLng == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLatLng!,
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            polylines: _polylines,
           // zoomGesturesEnabled: false,
            zoomControlsEnabled: false,


          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/SearchPlaces');
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.directions, color: Colors.white),
            ),
          ),
          if(lastActiveBooking != null)
            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton(
                onPressed: () async {
                  if (lastActiveBooking != null) {
                    // Show confirmation dialog before marking the trip as completed
                    bool? shouldComplete = await _showEndTripDialog(context);

                    if (shouldComplete ?? false) {
                      bool success = await bookingRepository.updateBookingStatus(
                        lastActiveBooking!.id.toString(),
                        "completed",
                      );

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Booking status updated to completed.')),
                        );
                        // Perform any additional UI updates or navigation here
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update booking status.')),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No active booking to cancel.')),
                    );
                  }
                },
                backgroundColor: Colors.red,
                child: const Icon(Icons.cancel, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
