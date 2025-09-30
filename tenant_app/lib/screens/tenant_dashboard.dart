import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tenant_app/widgets/dashboard_card.dart';

class TenantDashboardPage extends StatefulWidget {
  const TenantDashboardPage({super.key});

  @override
  State<TenantDashboardPage> createState() => _TenantDashboardPageState();
}

class _TenantDashboardPageState extends State<TenantDashboardPage> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:8000/api/tenant/dashboard/"), // your API
        headers: {
          "Authorization": "Bearer YOUR_TOKEN_HERE", // TODO: pull from storage
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          dashboardData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quickStats = dashboardData?['quick_stats'];
    final bookings = dashboardData?['recent_activity']?['bookings'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tenant Dashboard"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  if (quickStats != null) ...[
                    Text("Quick Stats",
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        DashboardCard(
                          title:
                              "Bookings (${quickStats['total_bookings'] ?? 0})",
                          icon: Icons.calendar_today,
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pushNamed(context, '/booking-list');
                          },
                        ),
                        DashboardCard(
                          title:
                              "Completed (${quickStats['completed_washes'] ?? 0})",
                          icon: Icons.check_circle,
                          color: Colors.green,
                          onTap: () {},
                        ),
                        DashboardCard(
                          title:
                              "Pending (${quickStats['pending_requests'] ?? 0})",
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                          onTap: () {},
                        ),
                        DashboardCard(
                          title: "Revenue: ${quickStats['revenue'] ?? 0}",
                          icon: Icons.attach_money,
                          color: Colors.purple,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Recent Activity
                  Text("Recent Activity",
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.local_car_wash),
                          title: Text(
                              "${booking['customer__username']} - ${booking['service__name']}"),
                          subtitle: Text(
                              "Status: ${booking['status']} • Amount: ${booking['amount']}"),
                          trailing: Text(
                            DateTime.parse(booking['created_at'])
                                .toLocal()
                                .toString()
                                .split('.')[0], // formatted datetime
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Navigation Shortcuts
                  Text("Navigation",
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      DashboardCard(
                        title: "Bookings",
                        icon: Icons.calendar_today,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pushNamed(context, '/booking-list');
                        },
                      ),
                      DashboardCard(
                        title: "Carwashes",
                        icon: Icons.local_car_wash,
                        color: Colors.green,
                        onTap: () {
                          Navigator.pushNamed(context, '/carwash-list');
                        },
                      ),
                      DashboardCard(
                        title: "Reports",
                        icon: Icons.bar_chart,
                        color: Colors.purple,
                        onTap: () {
                          // TODO: Reports page
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
