class Property {
  final String id;
  final String name;
  final String address;
  final double price;
  final int area; // in sqft
  final int bedrooms;
  final bool hasGarden;
  final bool hasParking;
  final String description;
  final List<String> imageUrls;
  final String landlordId;
  final String status; // 'pending', 'approved', 'rejected'
  final double rating;
  final int ratingCount;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Property({
    required this.id,
    required this.name,
    required this.address,
    required this.price,
    required this.area,
    required this.bedrooms,
    this.hasGarden = false,
    this.hasParking = false,
    required this.description,
    required this.imageUrls,
    required this.landlordId,
    this.status = 'approved',
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isAvailable = true,
    this.createdAt,
    this.updatedAt,
  });

  // Get first image URL for backward compatibility
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  // Format price as "ETB 735,000" style
  String get formattedPrice {
    final priceStr = price.toStringAsFixed(0);
    final parts = <String>[];
    for (int i = priceStr.length; i > 0; i -= 3) {
      final start = i - 3 < 0 ? 0 : i - 3;
      parts.insert(0, priceStr.substring(start, i));
    }
    return 'ETB ${parts.join(',')}';
  }

  // Create Property from JSON (database)
  factory Property.fromJson(Map<String, dynamic> json) {
    // Handle image_urls - can be array or single string
    List<String> imageUrlsList = [];
    if (json['image_urls'] != null) {
      if (json['image_urls'] is List) {
        imageUrlsList = List<String>.from(json['image_urls']);
      } else if (json['image_urls'] is String) {
        imageUrlsList = [json['image_urls']];
      }
    }

    // Handle rating - can come from view or be null
    final rating = (json['average_rating'] ?? 0.0) is double
        ? json['average_rating'] as double
        : (json['average_rating'] ?? 0.0).toDouble();

    final ratingCount = json['rating_count'] ?? 0;

    return Property(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      area: json['area'] as int? ?? 0,
      bedrooms: json['bedrooms'] as int? ?? 0,
      hasGarden: json['has_garden'] as bool? ?? false,
      hasParking: json['has_parking'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      imageUrls: imageUrlsList,
      landlordId: json['landlord_id'] as String? ?? '',
      status: json['status'] as String? ?? 'approved',
      rating: rating,
      ratingCount: ratingCount is int ? ratingCount : (ratingCount as num).toInt(),
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Convert Property to JSON for database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
      'price': price,
      'area': area,
      'bedrooms': bedrooms,
      'has_garden': hasGarden,
      'has_parking': hasParking,
      'image_urls': imageUrls,
      'landlord_id': landlordId,
      'status': status,
      'is_available': isAvailable,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}

