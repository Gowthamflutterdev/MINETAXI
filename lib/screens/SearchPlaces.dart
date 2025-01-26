import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../dashboard/homepagetaxi.dart';
import '../repositoryy/driver_repo.dart';
import '../widget/button.dart';
import '../widget/urlendpoints.dart';
import '../widget/utills.dart';


final googleMapsPlaces = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class SearchPlaces extends StatefulWidget {
  @override
  State<SearchPlaces> createState() => _SearchPlacesState();
}

class _SearchPlacesState extends State<SearchPlaces> {
  /// variable dclartion
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  LatLng? _fromLatLng;
  LatLng? _destinationLatLng;
  String _amountText = '';
  double _fare = 0.0; // Store the calculated fare
  List<String> _searchHistory = [];
  List<LatLng> _polylineCoordinates = [];
  bool _isLoadingRoute = false;
  GoogleMapController? _controller;
  final double pricePerKm = 10.0; // Example price per km (adjust as needed)
 // class declarable
  DriverBookingRepository repository = DriverBookingRepository();



  @override
  void dispose() {
    _fromController.dispose();
    _destinationController.dispose();
    super.dispose();
  }






/// function for km and rate
  Future<void> _calculateDistanceAndDrawRoute() async {
    if (_fromLatLng == null || _destinationLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select both pickup and drop locations.")),
      );
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final result = await calculateDistanceAndDrawRoute(
        fromLatLng: _fromLatLng!,
        destinationLatLng: _destinationLatLng!,
        pricePerKm: pricePerKm,
        onUpdateRoute: (route) {
          setState(() {
            _polylineCoordinates = route;
          });
        },
        googleApiKey: kGoogleApiKey,
      );

      setState(() {
        _amountText = "${result['distanceInKm'].toStringAsFixed(2)} km";
        _fare = result['calculatedFare'];
      });

      LatLngBounds bounds = getLatLngBounds(_fromLatLng!, _destinationLatLng!);
      _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error calculating route: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/taxiHome');
                // Notification icon action
              },
              tooltip: "Notifications",
            ),
            // const Icon(
            //   Icons.local_taxi,
            //   color: Colors.white,
            //   size: 24,
            // ),
            const SizedBox(width: 8),
            Text(
              'MINE TAXI',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
            ),
            onPressed: () {
              // Notification icon action
            },
            tooltip: "Notifications",
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle,
              color: Colors.white,
            ),
            onPressed: () {
              // Profile icon action
            },
            tooltip: "Profile",
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),

      body:  Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Card(
                        color: Colors.white,
                        elevation: 4,
                        child: Column(
                          children: [
                            SizedBox(
                              width: screenWidth * 0.8,
                              child: TypeAheadFormField<Prediction>(
                                textFieldConfiguration: TextFieldConfiguration(
                                  onTap: () {
                                    // Automatically select all text in the controller
                                    _fromController.selection = TextSelection(
                                      baseOffset: 0,
                                      extentOffset: _fromController.text.length,
                                    );
                                  },
                                  controller: _fromController,
                                  decoration: InputDecoration(
                                    hintText: 'Pickup Location',
                                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                                    prefixIcon: Icon(
                                      Icons.room_rounded,
                                      color: Colors.black,
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFF00AB66), width: 1.0),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                  ),
                                ),
                                suggestionsCallback: (query) => fetchSuggestions(query, _searchHistory),
                                itemBuilder: (context, suggestion) {
                                  // Check if the suggestion is from search history
                                  bool isHistory = _searchHistory.contains(suggestion.description);
                                  return Container(
                                    color: Colors.white, // Set background to white
                                    child: ListTile(
                                      leading: isHistory
                                          ? const Icon(Icons.history, color: Colors.grey)
                                          : const Icon(Icons.location_on, color: Colors.blue),
                                      title: Text(suggestion.description ?? ""),
                                    ),
                                  );
                                },
                                onSuggestionSelected: (suggestion) async {
                                  await selectSuggestion(
                                    suggestion,
                                    true,
                                    _fromController,
                                        (location) => setState(() => _fromLatLng = location),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 10,),

                            SizedBox(
                              width: screenWidth * 0.8,
                              child: TypeAheadFormField<Prediction>(
                                textFieldConfiguration: TextFieldConfiguration(
                                  onTap: () {
                                    // Automatically select all text in the controller
                                    _destinationController.selection = TextSelection(
                                      baseOffset: 0,
                                      extentOffset: _destinationController.text.length,
                                    );
                                  },
                                  controller: _destinationController,
                                  decoration: InputDecoration(
                                    hintText: 'Drop Location',
                                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                                    prefixIcon: Icon(
                                      Icons.room_rounded,
                                      color: Colors.black,
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(5), // Adjust this value for corner rounding
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15), // Add some padding
                                  ),
                                  onChanged: (value) {
                                    // Trigger the calculation when a destination is picked or text is changed
                                    if (_destinationLatLng != null) {
                                      _calculateDistanceAndDrawRoute();
                                    }
                                    setState(() {
                                      double pickupLat = _fromLatLng?.latitude ?? 0.0;
                                      double pickupLng = _fromLatLng?.longitude ?? 0.0;
                                    });
                                  },
                                ),
                                suggestionsCallback: (query) => fetchSuggestions(query, _searchHistory),
                                itemBuilder: (context, suggestion) {
                                  // Check if the suggestion is from search history
                                  bool isHistory = _searchHistory.contains(suggestion.description);
                                  return Container(
                                    color: Colors.white, // Set background to white
                                    child: ListTile(
                                      leading: isHistory
                                          ? const Icon(Icons.history, color: Colors.grey)
                                          : const Icon(Icons.location_on, color: Colors.blue),
                                      title: Text(suggestion.description ?? ""),
                                    ),
                                  );
                                },
                                onSuggestionSelected: (suggestion) async {
                                  await selectSuggestion(
                                    suggestion,
                                    false,
                                    _destinationController,
                                        (location) => setState(() => _destinationLatLng = location),
                                  );

                                  // Trigger the calculation of the route
                                  if (_destinationLatLng != null) {
                                    _calculateDistanceAndDrawRoute();
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                _amountText.isNotEmpty ?
                Container(
                  width: screenWidth * 0.6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                    border: Border.all(
                      color: Colors.yellow.shade700,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/nr_car.png',
                            width: 60,
                            height: 60,
                          ),
                          Text(
                            "Km: ₹${_amountText}",

                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                          Text(
                            "Fare: ₹${_fare.toStringAsFixed(2)}",
                            style: TextStyle(fontSize: 14, color: Colors.green),
                          ),

                        ],
                      ),
                    ),
                  ),
                ): Container(),
                Spacer(),
                if (_amountText.isNotEmpty)
                  CustomButton(
                    text: 'Confirm Booking',
                    onPressed: () async {
                      if (_fromLatLng == null || _destinationLatLng == null) {
                        print('Error: Pickup or Drop location is null.');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please select both pickup and drop locations.")),
                        );
                        return;
                      }

                      try {
                        double totalKm = 0.0;
                        try {
                          totalKm = double.parse(_amountText.split(' ')[0]);
                        } catch (e) {
                          print("Error parsing distance: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Invalid distance format.")),
                          );
                          return;
                        }


                        final success = await repository.createBooking(
                          pickupLocation: _fromController.text,
                          pickupLatitude: _fromLatLng!.latitude,
                          pickupLongitude: _fromLatLng!.longitude,
                          dropLocation: _destinationController.text,
                          dropLatitude: _destinationLatLng!.latitude,
                          dropLongitude: _destinationLatLng!.longitude,
                          totalKm: totalKm,
                          totalAmount: _fare,
                        );

                        if (success) {
                          print('Booking successful!');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Booking confirmed successfully.")),
                          );
                          // Navigate to TaxiHome screen after booking
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TaxiHome()),
                          );
                        } else {
                          print('Booking failed: API returned an error.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Booking failed. Please try again.")),
                          );
                        }
                      } catch (e) {
                        print('Error during booking: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Booking failed. Please try again.")),
                        );
                      }
                    },
                  ),


                SizedBox(height: 10,)



            ])
          ),
        ],
      ),
    );
  }
}
