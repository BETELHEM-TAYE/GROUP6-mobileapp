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
  final String imageUrl;
  final double rating;
  final int ratingCount;
  final bool isAvailable;

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
    required this.imageUrl,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isAvailable = true,
  });

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

  // Generate sample properties for testing
  static List<Property> getSampleProperties() {
    return [
      Property(
        id: '1',
        name: 'Glass Horizon',
        address: 'Arba Meter Rd, Bahir Dar, Ethiopia',
        price: 735000,
        area: 750,
        bedrooms: 3,
        hasGarden: true,
        hasParking: true,
        description:
            'Step into comfort with this 750 sqft gem featuring three cozy bedrooms and a peaceful garden perfect for morning coffee, weekend gatherings, and creating lasting memories. The modern design seamlessly blends functionality with style, offering ample natural light and contemporary finishes throughout.',
        imageUrl: 'https://placehold.co/600x400/9E9E9E/FFFFFF?text=Glass+Horizon',
        rating: 4.7,
        ratingCount: 24,
        isAvailable: true,
      ),
      Property(
        id: '2',
        name: 'Sunset Villa',
        address: 'Lake Tana Blvd, Bahir Dar',
        price: 850000,
        area: 900,
        bedrooms: 4,
        hasGarden: true,
        hasParking: true,
        description:
            'A stunning villa with breathtaking views of Lake Tana. Features four spacious bedrooms, modern kitchen, and a beautiful garden perfect for entertaining.',
        imageUrl: 'https://placehold.co/600x400/9E9E9E/FFFFFF?text=Sunset+Villa',
        rating: 4.5,
        ratingCount: 18,
        isAvailable: true,
      ),
      Property(
        id: '3',
        name: 'Urban Loft',
        address: 'City Center, Addis Ababa',
        price: 620000,
        area: 650,
        bedrooms: 2,
        hasGarden: false,
        hasParking: true,
        description:
            'Modern urban living in the heart of the city. This stylish loft features two bedrooms, open-plan living, and premium finishes.',
        imageUrl: 'https://placehold.co/600x400/9E9E9E/FFFFFF?text=Urban+Loft',
        rating: 4.3,
        ratingCount: 15,
        isAvailable: true,
      ),
      Property(
        id: '4',
        name: 'Garden View Apartment',
        address: 'Peaceful Street, Gondar',
        price: 580000,
        area: 700,
        bedrooms: 3,
        hasGarden: true,
        hasParking: false,
        description:
            'Charming apartment with garden views. Three bedrooms, cozy living space, and a shared garden area for residents.',
        imageUrl: 'https://placehold.co/600x400/9E9E9E/FFFFFF?text=Garden+View',
        rating: 4.6,
        ratingCount: 22,
        isAvailable: true,
      ),
    ];
  }
}

