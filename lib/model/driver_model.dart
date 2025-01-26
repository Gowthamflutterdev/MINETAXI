class DriverBooking {
  final int id;
  final int userId;
  final String email;
  final String pickupLocation;
  final double pickupLatitude;
  final double pickupLongitude;
  final String dropLocation;
  final double dropLatitude;
  final double dropLongitude;
  final double totalKm;
  final double totalAmount;
  final String status;

  DriverBooking({
    required this.id,
    required this.userId,
    required this.email,
    required this.pickupLocation,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropLocation,
    required this.dropLatitude,
    required this.dropLongitude,
    required this.totalKm,
    required this.totalAmount,
    required this.status,
  });

  factory DriverBooking.fromJson(Map<String, dynamic> json) {
    return DriverBooking(
      id: json['id'],
      userId: json['userid'],
      email: json['email'],
      pickupLocation: json['pickup_location'],
      pickupLatitude: json['pickup_latitude'].toDouble(),
      pickupLongitude: json['pickup_longitude'].toDouble(),
      dropLocation: json['drop_location'],
      dropLatitude: json['drop_latitude'].toDouble(),
      dropLongitude: json['drop_longitude'].toDouble(),
      totalKm: json['total_km'].toDouble(),
      totalAmount: json['total_amount'].toDouble(),
      status: json['status'],
    );
  }
}
