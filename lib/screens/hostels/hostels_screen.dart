import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class HostelsScreen extends StatelessWidget {
  const HostelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hostels'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search hostels by location...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildHostelCard(
                name: 'Girls Hostel A',
                location: 'Kaduwela Road, Malabe',
                availableRooms: 80,
                price: 'Rs. 12,000 / month',
                context: context,
              ),
              const SizedBox(height: 14),
              _buildHostelCard(
                name: 'UniResidence Boys Lodge',
                location: 'New Town, Ratmalana',
                availableRooms: 14,
                price: 'Rs. 15,000 / month',
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHostelCard({
    required String name,
    required String location,
    required int availableRooms,
    required String price,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.apartment, size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(location, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$availableRooms Rooms Available', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 12)),
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Inquiry sent for $name!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Contact Hostel'),
          ),
        ],
      ),
    );
  }
}
