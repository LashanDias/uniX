import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String selectedRole = 'Student';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAlignment.center,
            children: [
              // Avatar edit matching Android compact screen in Figma
              Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 55, color: AppColors.primary),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: TextEditingController(text: 'Olina Tottere'),
                decoration: const InputDecoration(hintText: 'Full Name'),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: TextEditingController(text: 'olina.tottere@sltc.ac.lk'),
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'Student', child: Text('Student')),
                  DropdownMenuItem(value: 'Recruiter', child: Text('Recruiter')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedRole = val);
                },
              ),
              const SizedBox(height: 14),

              TextField(
                controller: TextEditingController(text: 'Born on July 15, 1995'),
                decoration: const InputDecoration(hintText: 'Birthday'),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: TextEditingController(text: '3rd Year'),
                decoration: const InputDecoration(hintText: 'Year'),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: TextEditingController(text: 'Gampaha'),
                decoration: const InputDecoration(hintText: 'District'),
              ),
              const SizedBox(height: 36),

              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
