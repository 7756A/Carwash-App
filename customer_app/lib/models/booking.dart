class Booking {
  final int id;
  final String carwashName;
  final String serviceName;
  final DateTime timeSlot;
  final String amount;
  final String status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.carwashName,
    required this.serviceName,
    required this.timeSlot,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      carwashName: json['carwash_name'],
      serviceName: json['service_name'],
      timeSlot: DateTime.parse(json['time_slot']),
      amount: json['amount'].toString(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
