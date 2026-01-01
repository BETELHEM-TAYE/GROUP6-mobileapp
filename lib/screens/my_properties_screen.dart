import 'package:flutter/material.dart';
import '../models/property.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../widgets/property_card.dart';
import 'property_detail_screen.dart';
import 'property_edit_screen.dart';
import 'new_post_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  // Color palette
  static const Color primaryDark = Color(0xFF2C2C2C);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);

  // Services
  final _databaseService = DatabaseService();
  final _storageService = StorageService();
  final _authService = AuthService();

  // State
  List<Property> _properties = [];
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to view your properties'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      final properties = await _databaseService.getPropertiesByLandlord(user.id);
      if (mounted) {
        setState(() {
          _properties = properties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading properties: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _handleDeleteProperty(Property property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Property'),
          content: Text(
            'Are you sure you want to delete ${property.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (_isDeleting) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      // Delete images from storage
      if (property.imageUrls.isNotEmpty) {
        for (final imageUrl in property.imageUrls) {
          try {
            final storagePath = _extractStoragePath(imageUrl);
            await _storageService.deleteImage(
              bucket: 'property_images',
              filePath: storagePath,
            );
          } catch (e) {
            debugPrint("Error deleting image $imageUrl: $e");
            // Continue with deletion even if some images fail
          }
        }
      }

      // Delete property from database
      await _databaseService.deleteProperty(property.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh properties list
        _loadProperties();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting property: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _navigateToEdit(Property property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PropertyEditScreen(property: property),
      ),
    ).then((_) {
      // Refresh properties after editing
      _loadProperties();
    });
  }

  void _navigateToDetails(Property property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(property: property),
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
          'My Properties',
          style: TextStyle(
            color: primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _properties.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_work_outlined,
                        size: 64,
                        color: mediumGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No properties yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first property listing',
                        style: TextStyle(
                          fontSize: 14,
                          color: mediumGray,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const NewPostScreen(),
                            ),
                          ).then((_) {
                            _loadProperties();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Create Property'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProperties,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _properties.length,
                    itemBuilder: (context, index) {
                      final property = _properties[index];
                      return PropertyCard(
                        property: property,
                        showActions: true,
                        onEdit: () => _navigateToEdit(property),
                        onDelete: () => _handleDeleteProperty(property),
                        onTap: () => _navigateToDetails(property),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NewPostScreen(),
            ),
          ).then((_) {
            _loadProperties();
          });
        },
        backgroundColor: primaryDark,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
