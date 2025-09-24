import 'package:flutter/material.dart';
import 'carwash_services.dart';

class NearbyCarwashPage extends StatelessWidget {
  final List<Map<String, String>> cart; // accept shared cart
  const NearbyCarwashPage({super.key, required this.cart});

  final List<Map<String, String>> carwashes = const [
    {'name': 'Shiny Clean Carwash', 'address': '123 Main St, Nairobi', 'distance': '2.3 km'},
    {'name': 'Sparkle Auto Spa', 'address': '45 Riverside, Nairobi', 'distance': '3.1 km'},
    {'name': 'Quick Wash', 'address': '78 Park Rd, Nairobi', 'distance': '4.5 km'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: carwashes.length,
      itemBuilder: (context, index) {
        final carwash = carwashes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(carwash['name']!),
            subtitle: Text('${carwash['address']} • ${carwash['distance']}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CarwashServicesPage(
                    carwashName: carwash['name']!,
                    cart: cart, // pass the shared cart
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
