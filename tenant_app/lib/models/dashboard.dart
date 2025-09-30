class QuickStats {
  final int totalBookings;
  final int completedWashes;
  final int pendingRequests;
  final double revenue;

  QuickStats({
    required this.totalBookings,
    required this.completedWashes,
    required this.pendingRequests,
    required this.revenue,
  });

  factory QuickStats.fromJson(Map<String, dynamic> json) {
    return QuickStats(
      totalBookings: json['total_bookings'] ?? 0,
      completedWashes: json['completed_washes'] ?? 0,
      pendingRequests: json['pending_requests'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class Booking {
  final int id;
  final String customerName;
  final String serviceName;
  final String status;
  final double amount;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.status,
    required this.amount,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      customerName: json['customer__username'],
      serviceName: json['service__name'],
      status: json['status'],
      amount: (json['amount'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class DashboardData {
  final QuickStats quickStats;
  final List<Booking> bookings;

  DashboardData({required this.quickStats, required this.bookings});

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      quickStats: QuickStats.fromJson(json['quick_stats']),
      bookings: (json['recent_activity']['bookings'] as List)
          .map((b) => Booking.fromJson(b))
          .toList(),
    );
  }
}
