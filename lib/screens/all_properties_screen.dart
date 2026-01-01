import 'package:flutter/material.dart';
import '../models/property.dart';
import '../services/database_service.dart';
import '../widgets/property_card.dart';
import 'property_detail_screen.dart';

class AllPropertiesScreen extends StatefulWidget {
  const AllPropertiesScreen({super.key});

  @override
  State<AllPropertiesScreen> createState() => _AllPropertiesScreenState();
}

class _AllPropertiesScreenState extends State<AllPropertiesScreen> {
  // Color palette
  static const Color primaryDark = Color(0xFF2C2C2C);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);

  // Services
  final _databaseService = DatabaseService();

  // State
  List<Property> _allProperties = [];
  List<Property> _filteredProperties = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter state
  double _minPrice = 0;
  double _maxPrice = 10000000;
  double _maxPriceLimit = 10000000; // Immutable maximum from loaded properties
  int? _selectedBedrooms;
  bool _hasGarden = false;
  bool _hasParking = false;
  String _sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final properties = await _databaseService.getProperties();
      if (mounted) {
        setState(() {
          _allProperties = properties;
          // Set the immutable maximum price limit from loaded properties
          _maxPriceLimit = properties.isEmpty
              ? 10000000
              : properties.map((p) => p.price).reduce((a, b) => a > b ? a : b);
          // Preserve user's current selection, but ensure it doesn't exceed the limit
          if (_maxPrice > _maxPriceLimit) {
            _maxPrice = _maxPriceLimit;
          }
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load properties: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<Property> filtered = List.from(_allProperties);

    // Price filter
    filtered = filtered.where((property) {
      return property.price >= _minPrice && property.price <= _maxPrice;
    }).toList();

    // Bedrooms filter
    if (_selectedBedrooms != null) {
      filtered = filtered.where((property) {
        if (_selectedBedrooms == 4) {
          return property.bedrooms >= 4;
        }
        return property.bedrooms == _selectedBedrooms;
      }).toList();
    }

    // Garden filter
    if (_hasGarden) {
      filtered = filtered.where((property) => property.hasGarden).toList();
    }

    // Parking filter
    if (_hasParking) {
      filtered = filtered.where((property) => property.hasParking).toList();
    }

    // Sorting
    switch (_sortBy) {
      case 'Price (Low to High)':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price (High to Low)':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Newest':
        filtered.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(2000);
          final bDate = b.createdAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        break;
      case 'Rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    setState(() {
      _filteredProperties = filtered;
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        maxPriceLimit: _maxPriceLimit,
        selectedBedrooms: _selectedBedrooms,
        hasGarden: _hasGarden,
        hasParking: _hasParking,
        onApply: (minPrice, maxPrice, bedrooms, garden, parking) {
          setState(() {
            _minPrice = minPrice;
            _maxPrice = maxPrice;
            _selectedBedrooms = bedrooms;
            _hasGarden = garden;
            _hasParking = parking;
          });
          _applyFilters();
        },
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
          'All Properties',
          style: TextStyle(
            color: primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: primaryDark),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sort dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Sort by: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: mediumGray,
                  ),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(
                      value: 'Newest',
                      child: Text('Newest'),
                    ),
                    DropdownMenuItem(
                      value: 'Price (Low to High)',
                      child: Text('Price (Low to High)'),
                    ),
                    DropdownMenuItem(
                      value: 'Price (High to Low)',
                      child: Text('Price (High to Low)'),
                    ),
                    DropdownMenuItem(
                      value: 'Rating',
                      child: Text('Rating'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                      _applyFilters();
                    }
                  },
                ),
              ],
            ),
          ),
          // Properties list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: mediumGray,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 16,
                                color: mediumGray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProperties,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredProperties.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: mediumGray,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No properties found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: mediumGray,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadProperties,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredProperties.length,
                              itemBuilder: (context, index) {
                                final property = _filteredProperties[index];
                                return PropertyCard(
                                  property: property,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PropertyDetailScreen(property: property),
                                      ),
                                    ).then((_) {
                                      // Refresh when returning from detail screen
                                      _loadProperties();
                                    });
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final double minPrice;
  final double maxPrice;
  final double maxPriceLimit;
  final int? selectedBedrooms;
  final bool hasGarden;
  final bool hasParking;
  final Function(double, double, int?, bool, bool) onApply;

  const _FilterBottomSheet({
    required this.minPrice,
    required this.maxPrice,
    required this.maxPriceLimit,
    required this.selectedBedrooms,
    required this.hasGarden,
    required this.hasParking,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late double _minPrice;
  late double _maxPrice;
  int? _selectedBedrooms;
  bool _hasGarden = false;
  bool _hasParking = false;

  static const Color primaryDark = Color(0xFF2C2C2C);

  @override
  void initState() {
    super.initState();
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;
    _selectedBedrooms = widget.selectedBedrooms;
    _hasGarden = widget.hasGarden;
    _hasParking = widget.hasParking;
  }

  String _formatPrice(double price) {
    final priceStr = price.toStringAsFixed(0);
    final parts = <String>[];
    for (int i = priceStr.length; i > 0; i -= 3) {
      final start = i - 3 < 0 ? 0 : i - 3;
      parts.insert(0, priceStr.substring(start, i));
    }
    return 'ETB ${parts.join(',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryDark,
            ),
          ),
          const SizedBox(height: 20),
          // Price range
          const Text(
            'Price Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatPrice(_minPrice)),
              Text(_formatPrice(_maxPrice)),
            ],
          ),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: widget.maxPriceLimit,
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          const SizedBox(height: 20),
          // Bedrooms
          const Text(
            'Bedrooms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildBedroomChip('All', null),
              _buildBedroomChip('1', 1),
              _buildBedroomChip('2', 2),
              _buildBedroomChip('3', 3),
              _buildBedroomChip('4+', 4),
            ],
          ),
          const SizedBox(height: 20),
          // Features
          const Text(
            'Features',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('Has Garden'),
            value: _hasGarden,
            onChanged: (value) {
              setState(() {
                _hasGarden = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('Has Parking'),
            value: _hasParking,
            onChanged: (value) {
              setState(() {
                _hasParking = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),
          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_minPrice, _maxPrice, _selectedBedrooms, _hasGarden, _hasParking);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBedroomChip(String label, int? value) {
    final isSelected = _selectedBedrooms == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedBedrooms = selected ? value : null;
        });
      },
      selectedColor: primaryDark,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : primaryDark,
      ),
    );
  }
}
