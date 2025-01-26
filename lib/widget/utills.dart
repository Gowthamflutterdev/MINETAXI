import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as po;

import 'urlendpoints.dart';
/// Api key
final googleMapsPlaces = GoogleMapsPlaces(apiKey: kGoogleApiKey);
/// Suggestion listo out from using Api cloyd console should enable places api
Future<List<Prediction>> fetchSuggestions(String query, List<String> searchHistory) async {
  List<Prediction> apiSuggestions = [];
  if (query.isNotEmpty) {
    final response = await googleMapsPlaces.autocomplete(
      query,
      language: 'en',
      components: [Component(Component.country, "in")],
    );
    apiSuggestions = response.isOkay ? response.predictions : [];
  }

  List<Prediction> historySuggestions = searchHistory
      .where((history) => history.toLowerCase().contains(query.toLowerCase()))
      .map((history) => Prediction(description: history, placeId: null))
      .toList();

  final combinedSuggestions = [
    Prediction(description: "Use My Current Location", placeId: null),
    ...historySuggestions,
    ...apiSuggestions,
  ];

  final uniqueSuggestions = {
    for (var suggestion in combinedSuggestions) suggestion.description: suggestion
  }.values.toList();

  return uniqueSuggestions;
}

/// suggestion selt latiude and longitude
Future<void> selectSuggestion(
    Prediction suggestion,
    bool isFrom,
    TextEditingController controller,
    Function(LatLng) updateLatLng,
    ) async {
  if (suggestion.description == "Use My Current Location") {
    LatLng currentLocation = await getCurrentLocation();
    controller.text = "Current Location";
    updateLatLng(currentLocation);
  } else {
    final details = await googleMapsPlaces.getDetailsByPlaceId(suggestion.placeId!);
    LatLng location = LatLng(details.result.geometry!.location.lat, details.result.geometry!.location.lng);
    controller.text = details.result.name ?? '';
    updateLatLng(location);
  }
}

/// current location get
Future<LatLng> getCurrentLocation() async {
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  return LatLng(position.latitude, position.longitude);
}

LatLngBounds getLatLngBounds(LatLng start, LatLng end) {
  return LatLngBounds(
    southwest: LatLng(
      start.latitude < end.latitude ? start.latitude : end.latitude,
      start.longitude < end.longitude ? start.longitude : end.longitude,
    ),
    northeast: LatLng(
      start.latitude > end.latitude ? start.latitude : end.latitude,
      start.longitude > end.longitude ? start.longitude : end.longitude,
    ),
  );
}


/// use polyline calcutae a distance
Future<Map<String, dynamic>> calculateDistanceAndDrawRoute({
  required LatLng fromLatLng,
  required LatLng destinationLatLng,
  required double pricePerKm,
  required Function(List<LatLng>) onUpdateRoute,
  required String googleApiKey,
}) async {
  po.PolylinePoints polylinePoints = po.PolylinePoints();

  final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: kGoogleApiKey,

    request: po.PolylineRequest(
      origin: po.PointLatLng(fromLatLng.latitude, fromLatLng.longitude),
      destination: po.PointLatLng(destinationLatLng.latitude, destinationLatLng.longitude),
      mode: po.TravelMode.driving,
    ),
  );

  if (result.points.isEmpty) {
    throw Exception("No route found between the selected locations.");
  }

  double totalDistance = 0.0;
  for (int i = 0; i < result.points.length - 1; i++) {
    totalDistance += Geolocator.distanceBetween(
      result.points[i].latitude,
      result.points[i].longitude,
      result.points[i + 1].latitude,
      result.points[i + 1].longitude,
    );
  }

  double distanceInKm = totalDistance / 1000;
  double calculatedFare = distanceInKm * pricePerKm;

  List<LatLng> polylineCoordinates = result.points.map((point) => LatLng(point.latitude, point.longitude)).toList();
  onUpdateRoute(polylineCoordinates);

  return {
    "distanceInKm": distanceInKm,
    "calculatedFare": calculatedFare,
    "polylineCoordinates": polylineCoordinates,
  };
}
