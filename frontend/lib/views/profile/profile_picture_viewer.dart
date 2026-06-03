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

  String _buildImageUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  // Normalize: strip any leading slashes, then add exactly one
  return 'http://192.168.1.28:8001/${path.replaceFirst(RegExp(r'^/+'), '')}';
}

  Future<void> _uploadNewPicture() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source:    ImageSource.gallery,
        maxWidth:  1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() => isLoading = true);

        final bytes  = await image.readAsBytes();
        final result =
            await UserService.uploadProfilePicture(bytes, image.name);

        if (!mounted) return;

        if (!result.containsKey('error')) {
          final profilePicture = result['profile_picture'] as String?;

          final prefs = await SharedPreferences.getInstance();
          if (profilePicture != null) {
            await prefs.setString('profile_picture', profilePicture);
          }

          setState(() {
            currentImageUrl = profilePicture ?? widget.profilePictureUrl;
            isLoading       = false;
          });

          widget.onPictureUpdated();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:         Text('Profile picture updated! ✓'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          setState(() => isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:         Text('Error: ${result['error']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary      = Theme.of(context).primaryColor;
    final cardColor    = Theme.of(context).cardColor;
    final hintColor    = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;
    final screenWidth  = MediaQuery.of(context).size.width;
    final double imgSize =
        screenWidth * 0.8 > 360 ? 360 : screenWidth * 0.8;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color:        cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────────────────────────
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
                          fontSize:   18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.userEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color:    hintColor,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: hintColor, size: 24),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Profile picture ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      _buildImageUrl(currentImageUrl),
                      width:  imgSize,
                      height: imgSize,
                      fit:    BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width:  imgSize,
                          height: imgSize,
                          decoration: BoxDecoration(
                            color:        primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            color: primary,
                            size:  imgSize * 0.18,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width:  imgSize,
                          height: imgSize,
                          decoration: BoxDecoration(
                            color:        dividerColor,
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
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Action buttons ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                final buttonSpacing = SizedBox(
                    width:  isNarrow ? 0 : 12,
                    height: isNarrow ? 12 : 0);

                final changeBtn = ElevatedButton.icon(
                  onPressed: isLoading ? null : _uploadNewPicture,
                  icon:      const Icon(Icons.cloud_upload),
                  label:     const Text('Change Picture'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                );

                final deleteBtn = OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          final result =
                              await UserService.deleteProfilePicture();
                          if (!mounted) return;
                          setState(() => isLoading = false);

                          if (!result.containsKey('error')) {
                            final prefs =
                                await SharedPreferences.getInstance();
                            await prefs.remove('profile_picture');
                            widget.onPictureUpdated();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile picture deleted'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Error: ${result['error']}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  icon:  const Icon(Icons.delete_forever),
                  label: const Text('Delete'),
                );

                final closeBtn = OutlinedButton.icon(
                  onPressed:
                      isLoading ? null : () => Navigator.pop(context),
                  icon:  const Icon(Icons.close),
                  label: const Text('Close'),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      SizedBox(width: double.infinity, child: changeBtn),
                      buttonSpacing,
                      SizedBox(width: double.infinity, child: deleteBtn),
                      buttonSpacing,
                      SizedBox(width: double.infinity, child: closeBtn),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(child: changeBtn),
                    buttonSpacing,
                    Flexible(child: deleteBtn),
                    buttonSpacing,
                    Flexible(child: closeBtn),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}