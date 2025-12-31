import 'package:flutter/material.dart';
import '../models/property.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
  });

  // Color palette
  static const Color primaryDark = Color(0xFF2C2C2C);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image with badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Image.network(
                    property.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: lightGray,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: mediumGray,
                        ),
                      );
                    },
                  ),
                ),
                // "For Sale" badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'for sale',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Heart icon
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            // Property Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Name
                  Text(
                    property.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: mediumGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_upward,
                        size: 16,
                        color: mediumGray,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Price
                  Text(
                    property.formattedPrice,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Feature Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFeatureTag('${property.bedrooms} bed'),
                      if (property.hasParking)
                        _buildFeatureTag('2 Car'),
                      if (property.hasGarden)
                        _buildFeatureTag('Garden'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: primaryDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

