class Booking {
  final String serviceName;
  final DateTime dateTime;
  final String paymentMethod;
  final String paymentDetails;
  String status; // mutable, tenant can update

  Booking({
    required this.serviceName,
    required this.dateTime,
    required this.paymentMethod,
    required this.paymentDetails,
    this.status = "Pending",
  });
}
