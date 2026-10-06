import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../services/profile_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.loadProfile});
  final Future<Map<String, dynamic>> Function()? loadProfile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const roles = ['Student', 'Recruiter'];
  String? selectedRole;
  bool saving = false;
  bool get needsSignIn =>
      widget.loadProfile == null && FirebaseAuth.instance.currentUser == null;
  Uint8List? profileImage;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final birthdayController = TextEditingController();
  final yearController = TextEditingController();
  final facultyController = TextEditingController();
  final districtController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (needsSignIn) return;
    (widget.loadProfile ?? ProfileStorage.load)()
        .then((data) {
          if (!mounted) return;
          nameController.text = data['name'];
          emailController.text = data['email'];
          selectedRole = roles.contains(data['role'])
              ? data['role'] as String
              : null;
          birthdayController.text = data['birthday'];
          yearController.text = data['year'];
          facultyController.text = data['faculty']?.toString() ?? '';
          districtController.text = data['district'];
          setState(() {});
        })
        .catchError((Object error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to load your profile. Please try again.'),
              ),
            );
          }
        });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    birthdayController.dispose();
    yearController.dispose();
    facultyController.dispose();
    districtController.dispose();
    super.dispose();
  }

  Future<void> handlePickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (mounted) setState(() => profileImage = bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the photo picker.')),
        );
      }
    }
  }

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
                    child: ClipOval(
                      child: profileImage == null
                          ? Image.asset(
                              'assets/images/profile_photo.jfif',
                              fit: BoxFit.cover,
                              width: 90,
                              height: 90,
                            )
                          : Image.memory(
                              profileImage!,
                              fit: BoxFit.cover,
                              width: 90,
                              height: 90,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: handlePickImage,
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
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
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Full Name'),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: emailController,
                readOnly: true,
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                key: ValueKey(selectedRole),
                initialValue: selectedRole,
                hint: const Text('Select role'),
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'Student', child: Text('Student')),
                  DropdownMenuItem(
                    value: 'Recruiter',
                    child: Text('Recruiter'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedRole = val);
                },
              ),
              const SizedBox(height: 14),

              TextField(
                controller: birthdayController,
                decoration: const InputDecoration(hintText: 'Birthday'),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: yearController,
                decoration: const InputDecoration(hintText: 'Year'),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: facultyController,
                decoration: const InputDecoration(hintText: 'Faculty'),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: districtController,
                decoration: const InputDecoration(hintText: 'District'),
              ),
              const SizedBox(height: 36),

              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (needsSignIn) {
                          final signedIn = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const LoginScreen(returnAfterSignIn: true),
                            ),
                          );
                          if (!mounted || signedIn != true) return;
                          setState(() {
                            emailController.text =
                                FirebaseAuth.instance.currentUser?.email ?? '';
                          });
                          return;
                        }
                        if (selectedRole == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select your role.'),
                            ),
                          );
                          return;
                        }
                        setState(() => saving = true);
                        try {
                          await ProfileStorage.save({
                            'name': nameController.text,
                            'email': emailController.text,
                            'role': selectedRole!,
                            'birthday': birthdayController.text,
                            'year': yearController.text,
                            'faculty': facultyController.text,
                            'district': districtController.text,
                          }, profileImage);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully!'),
                            ),
                          );
                          Navigator.pop(context, profileImage);
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error is StateError
                                    ? error.message.toString()
                                    : 'Unable to save your profile. Please try again.',
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => saving = false);
                        }
                      },
                child: Text(
                  saving
                      ? 'Saving...'
                      : needsSignIn
                      ? 'Sign in to save profile'
                      : 'Save Profile',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
