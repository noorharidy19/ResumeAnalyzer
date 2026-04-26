import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePictureViewer extends StatefulWidget {
  final String profilePictureUrl;
  final String userName;
  final String userEmail;
  final VoidCallback onPictureUpdated;

  const ProfilePictureViewer({
    super.key,
    required this.profilePictureUrl,
    required this.userName,
    required this.userEmail,
    required this.onPictureUpdated,
  });

  @override
  State<ProfilePictureViewer> createState() => _ProfilePictureViewerState();
}

class _ProfilePictureViewerState extends State<ProfilePictureViewer> {
  late String currentImageUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentImageUrl = widget.profilePictureUrl;
  }

  Future<void> _uploadNewPicture() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          isLoading = true;
        });

        final bytes = await image.readAsBytes();
        final result = await UserService.uploadProfilePicture(bytes, image.name);

        if (!mounted) return;

        if (!result.containsKey('error')) {
          final profilePicture = result['profile_picture'] as String?;

          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          if (profilePicture != null) {
            await prefs.setString('profile_picture', profilePicture);
          }

          setState(() {
            currentImageUrl = profilePicture ?? widget.profilePictureUrl;
            isLoading = false;
          });

          widget.onPictureUpdated();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated! ✓'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          setState(() {
            isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${result['error']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF7C8CF8);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.userEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Profile Picture
            Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      'http://localhost:8001/${currentImageUrl}',
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            color: primary,
                            size: 60,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: primary,
                            ),
                          ),
                        );
                      },
                    ),
                    if (isLoading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _uploadNewPicture,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Change Picture'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
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
