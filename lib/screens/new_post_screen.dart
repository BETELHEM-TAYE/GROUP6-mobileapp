import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'post_details_screen.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  // Color palette
  static const Color primaryDark = Color(0xFF2C2C2C);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);

  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  String _selectionMode = 'Recent'; // 'Recent' or 'Select Multiple'

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          if (_selectionMode == 'Select Multiple') {
            _selectedImages.addAll(pickedFiles.map((xfile) => File(xfile.path)));
          } else {
            // Recent mode - replace selection with first picked image
            _selectedImages = [File(pickedFiles.first.path)];
          }
        });
      }
    } catch (e) {
      // Handle error (permission denied, etc.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  void _handleNext() {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostDetailsScreen(images: _selectedImages),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New Post',
          style: TextStyle(
            color: primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _handleNext,
            child: const Text(
              'Next',
              style: TextStyle(
                color: primaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image Preview Area
          if (_selectedImages.isNotEmpty)
            Container(
              height: 300,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _selectedImages.length == 1
                    ? Image.file(
                        _selectedImages.first,
                        fit: BoxFit.cover,
                      )
                    : PageView.builder(
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Image.file(
                            _selectedImages[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
              ),
            )
          else
            Container(
              height: 300,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: mediumGray.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: mediumGray,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No images selected',
                      style: TextStyle(
                        color: mediumGray,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Selection Mode Radio Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildRadioOption('Recent', _selectionMode == 'Recent'),
                const SizedBox(width: 24),
                _buildRadioOption('Select Multiple', _selectionMode == 'Select Multiple'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Image Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 9, // 3x3 grid
                itemBuilder: (context, index) {
                  // Show selected images first, then placeholder squares
                  if (index < _selectedImages.length) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImages[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: primaryDark,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: mediumGray.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          color: mediumGray,
                          size: 32,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          // Bottom Navigation
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: primaryDark),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectionMode = label;
          if (label == 'Recent' && _selectedImages.length > 1) {
            // Keep only first image in Recent mode
            _selectedImages = _selectedImages.take(1).toList();
          }
        });
      },
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? primaryDark : mediumGray,
                width: 2,
              ),
              color: isSelected ? primaryDark : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryDark : mediumGray,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

