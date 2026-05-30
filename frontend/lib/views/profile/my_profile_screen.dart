import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import 'profile_picture_viewer.dart';
import '../../utils/responsive_helper.dart';
import '../../providers/app_providers.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  final void Function(String? newName, String? newPicture)? onProfileUpdated;

  const MyProfileScreen({super.key, this.onProfileUpdated});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  final Color primary = const Color(0xFF7C8CF8);
  final Color bg      = const Color(0xFFF5F7FF);

  // phoneNumber stays local — authProvider doesn't store it
  String? phoneNumber;
  bool isEditing = false;
  bool isLoading = false;

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController  = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();

    // Read name and email synchronously from authProvider — no async needed
    final auth = ref.read(authProvider);
    nameController.text  = auth.userName  ?? '';
    emailController.text = auth.userEmail ?? '';

    // Only phone still needs a SharedPreferences read
    _loadPhoneNumber();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      phoneNumber          = prefs.getString("phone_number") ?? '';
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

    setState(() => isLoading = true);

    try {
      // Read token from authProvider instead of SharedPreferences
      final token = ref.read(authProvider).token;
      if (token == null) throw Exception('Not authenticated');

      final result = await UserService.updateProfile(
        name:        nameController.text,
        email:       emailController.text,
        phoneNumber: phoneController.text,
      );

      if (!mounted) return;

      if (!result.containsKey('error')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name',    nameController.text);
        await prefs.setString('phone_number', phoneController.text);

        if (!mounted) return;

        // Update authProvider so dashboard name updates instantly everywhere
        ref.read(authProvider.notifier).updateUserName(nameController.text);

        widget.onProfileUpdated?.call(nameController.text, null);

        setState(() {
          phoneNumber = phoneController.text;
          isEditing   = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch — rebuilds whenever name or picture changes from anywhere
    final auth = ref.watch(authProvider);

    final isMobile    = ResponsiveHelper.isMobile(context);
    final padding     = ResponsiveHelper.getResponsivePadding(context);
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
                  nameController.text  = auth.userName ?? '';
                  phoneController.text = phoneNumber   ?? '';
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
                width:  profileSize,
                height: profileSize,
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(profileSize),
                  boxShadow: [
                    BoxShadow(
                      color:      Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset:     const Offset(0, 2),
                    )
                  ],
                  // reads from authProvider instead of local variable
                  image: auth.profilePicture != null &&
                          auth.profilePicture!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(
                            // URL kept exactly as teammate had it
                            'http://localhost:8001/${auth.profilePicture!.replaceAll(r'\', '/')}',
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: auth.profilePicture == null ||
                        auth.profilePicture!.isEmpty
                    ? Icon(Icons.person,
                        size: profileSize * 0.5, color: primary)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => ProfilePictureViewer(
                      profilePictureUrl: auth.profilePicture ?? '',
                      userName:          auth.userName       ?? '',
                      userEmail:         auth.userEmail      ?? '',
                      onPictureUpdated: () async {
                        final prefs = await SharedPreferences.getInstance();
                        if (!mounted) return;
                        final newPic = prefs.getString('profile_picture');
                        if (newPic != null) {
                          // Update authProvider so picture refreshes everywhere
                          ref.read(authProvider.notifier)
                              .updateProfilePicture(newPic);
                        }
                        widget.onProfileUpdated?.call(null, newPic);
                      },
                    ),
                  );
                },
                icon:  const Icon(Icons.photo_library),
                label: const Text('Change Picture'),
                style: ElevatedButton.styleFrom(backgroundColor: primary),
              ),
            ),
            SizedBox(height: isMobile ? 20 : 30),

            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset:     const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  _fieldLabel('Full Name'),
                  const SizedBox(height: 8),
                  if (isEditing)
                    _editField(nameController, 'Enter your full name')
                  else
                    _readonlyBox(auth.userName ?? 'Not set'),
                  const SizedBox(height: 20),

                  // Email — always read-only
                  _fieldLabel('Email Address'),
                  const SizedBox(height: 8),
                  _readonlyBox(auth.userEmail ?? 'Not set'),
                  const SizedBox(height: 20),

                  // Phone
                  _fieldLabel('Phone Number'),
                  const SizedBox(height: 8),
                  if (isEditing)
                    TextField(
                      controller:   phoneController,
                      keyboardType: TextInputType.phone,
                      decoration:   _editDecoration('Enter your phone number'),
                    )
                  else
                    _readonlyBox(phoneNumber ?? 'Not set'),
                  const SizedBox(height: 20),

                  // Save Button
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
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width:  20,
                                child:  CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Save Changes',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
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

  Widget _fieldLabel(String label) => Text(
        label,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color:      Colors.grey[700],
            fontSize:   12),
      );

  Widget _readonlyBox(String text) => Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:        Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: Colors.grey[200]!),
        ),
        child: Text(text,
            style: TextStyle(color: Colors.grey[800], fontSize: 16)),
      );

  Widget _editField(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        decoration: _editDecoration(hint),
      );

  InputDecoration _editDecoration(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide(color: primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
}