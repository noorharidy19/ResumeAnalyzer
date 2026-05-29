import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import 'profile_picture_viewer.dart';
import '../../utils/responsive_helper.dart';

class MyProfileScreen extends StatefulWidget {
  final void Function(String? newName, String? newPicture)? onProfileUpdated;

  const MyProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final Color primary = const Color(0xFF7C8CF8);
  final Color bg = const Color(0xFFF5F7FF);

  String? userName;
  String? userEmail;
  String? phoneNumber;
  String? profilePictureUrl;
  bool isEditing = false;
  bool isLoading = false;

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("user_name") ?? '';
      userEmail = prefs.getString("user_email") ?? '';
      phoneNumber = prefs.getString("phone_number") ?? '';
      profilePictureUrl = prefs.getString("profile_picture");

      nameController.text = userName ?? '';
      emailController.text = userEmail ?? '';
      phoneController.text = phoneNumber ?? '';
    });
  }

  Future<void> _saveProfile() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and phone number cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final token = await SharedPreferences.getInstance().then((prefs) => prefs.getString('access_token'));
      if (token == null) throw Exception('Not authenticated');

      final result = await UserService.updateProfile(
        name: nameController.text,
        email: emailController.text,
        phoneNumber: phoneController.text,
      );

      if (!result.containsKey('error')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', nameController.text);
        await prefs.setString('phone_number', phoneController.text);

        widget.onProfileUpdated?.call(nameController.text, null);

        setState(() {
          userName = nameController.text;
          phoneNumber = phoneController.text;
          isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final profileSize = isMobile ? 100.0 : 120.0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('My Profile'),
        elevation: 0,
        centerTitle: isMobile,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                if (isEditing) {
                  // Reset to original values
                  nameController.text = userName ?? '';
                  phoneController.text = phoneNumber ?? '';
                }
                isEditing = !isEditing;
              });
            },
            tooltip: isEditing ? 'Cancel' : 'Edit',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            Center(
              child: Container(
                width: profileSize,
                height: profileSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(profileSize),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ],
                  image: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(
                            'http://192.168.1.5:8001/${profilePictureUrl!.replaceAll(r'\', '/')}',
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profilePictureUrl == null || profilePictureUrl!.isEmpty
                    ? Icon(
                        Icons.person,
                        size: profileSize * 0.5,
                        color: primary,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  // open picture viewer dialog
                  await showDialog(
                    context: context,
                    builder: (_) => ProfilePictureViewer(
                      profilePictureUrl: profilePictureUrl ?? '',
                      userName: userName ?? '',
                      userEmail: userEmail ?? '',
                      onPictureUpdated: () async {
                        await _loadUserProfile();
                        final prefs = await SharedPreferences.getInstance();
                        final newPic = prefs.getString('profile_picture');
                        widget.onProfileUpdated?.call(null, newPic);
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('Change Picture'),
                style: ElevatedButton.styleFrom(backgroundColor: primary),
              ),
            ),
            SizedBox(height: isMobile ? 20 : 30),

            // Profile Information
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  Text(
                    'Full Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isEditing)
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        userName ?? 'Not set',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Email Field
                  Text(
                    'Email Address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      userEmail ?? 'Not set',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Phone Number Field
                  Text(
                    'Phone Number',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isEditing)
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        phoneNumber ?? 'Not set',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Save Button (only visible in edit mode)
                  if (isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
