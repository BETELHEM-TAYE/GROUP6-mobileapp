import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/form_card.dart';
import '../widgets/custom_button.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../models/property.dart';

class PropertyEditScreen extends StatefulWidget {
  final Property property;
  final List<File>? newImages;

  const PropertyEditScreen({
    super.key,
    required this.property,
    this.newImages,
  });

  @override
  State<PropertyEditScreen> createState() => _PropertyEditScreenState();
}

class _PropertyEditScreenState extends State<PropertyEditScreen> {
  // Color palette
  static const Color primaryDark = Color(0xFF2C2C2C);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);

  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _bedroomsController = TextEditingController();

  // Services
  final _databaseService = DatabaseService();
  final _storageService = StorageService();
  final _authService = AuthService();

  // State
  bool _isUploading = false;
  bool _hasGarden = false;
  bool _hasParking = false;
  List<String> _existingImageUrls = [];
  List<File> _newImages = [];
  Set<int> _removedImageIndices = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Pre-fill form fields
    _nameController.text = widget.property.name;
    _priceController.text = widget.property.price.toString();
    _addressController.text = widget.property.address;
    _descriptionController.text = widget.property.description;
    _areaController.text = widget.property.area.toString();
    _bedroomsController.text = widget.property.bedrooms.toString();
    _hasGarden = widget.property.hasGarden;
    _hasParking = widget.property.hasParking;
    _existingImageUrls = List<String>.from(widget.property.imageUrls);
    _newImages = widget.newImages ?? [];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _newImages.addAll(pickedFiles.map((xfile) => File(xfile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _removedImageIndices.add(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  String _extractStoragePath(String publicUrl) {
    try {
      // Parse Supabase storage URL format:
      // https://.../storage/v1/object/public/property_images/userId/fileName
      final uri = Uri.parse(publicUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the index of 'property_images' in the path
      final bucketIndex = pathSegments.indexOf('property_images');
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 2) {
        // Extract userId/fileName portion
        final userId = pathSegments[bucketIndex + 1];
        final fileName = pathSegments.sublist(bucketIndex + 2).join('/');
        return '$userId/$fileName';
      }
      
      // Fallback: try to extract from the end of the path
      if (pathSegments.length >= 2) {
        return pathSegments.sublist(pathSegments.length - 2).join('/');
      }
      
      return publicUrl;
    } catch (e) {
      debugPrint("Error extracting storage path from URL: $e");
      return publicUrl;
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate area and bedrooms
    if (_areaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the area (sqft)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_bedroomsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the number of bedrooms'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Get current user
      final user = _authService.getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload new images to Supabase Storage
      List<String> newImageUrls = [];
      if (_newImages.isNotEmpty) {
        for (int i = 0; i < _newImages.length; i++) {
          final file = _newImages[i];
          final bytes = await file.readAsBytes();
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_$i.${file.path.split('.').last}';

          final imageUrl = await _storageService.uploadPropertyImage(
            bytes: bytes,
            fileName: fileName,
            userId: user.id,
          );
          newImageUrls.add(imageUrl);
        }
      }

      // Delete removed images from storage
      if (_removedImageIndices.isNotEmpty) {
        for (final index in _removedImageIndices) {
          if (index >= 0 && index < _existingImageUrls.length) {
            try {
              final imageUrl = _existingImageUrls[index];
              final storagePath = _extractStoragePath(imageUrl);
              await _storageService.deleteImage(
                bucket: 'property_images',
                filePath: storagePath,
              );
            } catch (e) {
              debugPrint("Error deleting removed image at index $index: $e");
              // Continue with update even if deletion fails
            }
          }
        }
      }

      // Combine existing image URLs (not removed) with new uploaded URLs
      final List<String> finalImageUrls = [];
      for (int i = 0; i < _existingImageUrls.length; i++) {
        if (!_removedImageIndices.contains(i)) {
          finalImageUrls.add(_existingImageUrls[i]);
        }
      }
      finalImageUrls.addAll(newImageUrls);

      // Create updated property object
      final updatedProperty = Property(
        id: widget.property.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        area: int.parse(_areaController.text.trim()),
        bedrooms: int.parse(_bedroomsController.text.trim()),
        hasGarden: _hasGarden,
        hasParking: _hasParking,
        imageUrls: finalImageUrls,
        landlordId: widget.property.landlordId,
        status: widget.property.status,
        isAvailable: widget.property.isAvailable,
      );

      // Update property in database
      await _databaseService.updateProperty(updatedProperty);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating property: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  List<Widget> _buildImageList() {
    final List<Widget> images = [];

    // Add existing images (not removed)
    for (int i = 0; i < _existingImageUrls.length; i++) {
      if (!_removedImageIndices.contains(i)) {
        images.add(
          Stack(
            children: [
              Image.network(
                _existingImageUrls[i],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: lightGray,
                    child: Icon(
                      Icons.image_not_supported,
                      color: mediumGray,
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeExistingImage(i),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    // Add new images
    for (int i = 0; i < _newImages.length; i++) {
      images.add(
        Stack(
          children: [
            Image.file(
              _newImages[i],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeNewImage(i),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return images;
  }

  @override
  Widget build(BuildContext context) {
    final allImages = _buildImageList();

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
          'Edit Property',
          style: TextStyle(
            color: primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Carousel
              if (allImages.isNotEmpty)
                Container(
                  height: 250,
                  width: double.infinity,
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
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: allImages.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return allImages[index];
                          },
                        ),
                        // Dots Indicator
                        if (allImages.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                allImages.length,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Add Image Button
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton.small(
                            onPressed: _pickImages,
                            backgroundColor: primaryDark,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: mediumGray.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 64,
                          color: mediumGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Add Images',
                          style: TextStyle(
                            color: mediumGray,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Form Fields
              FormCard(
                backgroundColor: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name',
                      hint: 'Real-estate name',
                      icon: Icons.home,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _priceController,
                      label: 'Price',
                      hint: 'Real-estate price',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _areaController,
                      label: 'Area (sqft)',
                      hint: 'Area in square feet',
                      icon: Icons.square_foot,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _bedroomsController,
                      label: 'Bedrooms',
                      hint: 'Number of bedrooms',
                      icon: Icons.bed,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Real-estate address',
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Description',
                      icon: Icons.description,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Feature Tags
              const Text(
                'Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFeatureTag('Garden', _hasGarden, () {
                    setState(() {
                      _hasGarden = !_hasGarden;
                    });
                  }),
                  const SizedBox(width: 12),
                  _buildFeatureTag('Parking', _hasParking, () {
                    setState(() {
                      _hasParking = !_hasParking;
                    });
                  }),
                ],
              ),

              const SizedBox(height: 32),

              // Update Button
              CustomButton(
                text: _isUploading ? 'Updating...' : 'Update',
                onPressed: _isUploading
                    ? () {}
                    : () {
                        _handleUpdate();
                      },
                backgroundColor: primaryDark,
                borderRadius: 15,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: mediumGray.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: primaryDark,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: lightGray,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildFeatureTag(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? primaryDark : mediumGray.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : primaryDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
