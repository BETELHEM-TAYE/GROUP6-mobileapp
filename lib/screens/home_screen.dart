import 'package:flutter/material.dart';
import '../models/property.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/property_card.dart';
import 'property_detail_screen.dart';
import 'profile_screen.dart';
import 'new_post_screen.dart';
import 'favorites_screen.dart';
import 'messages_list_screen.dart';
import 'all_properties_screen.dart';
import 'appointments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Color palette
  static const Color primaryDark = Color(0xFF2C2C2C);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);

  // Services
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  // State
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  int _selectedNavIndex = 0;
  List<Property> _allProperties = [];
  List<Property> _filteredProperties = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadProperties();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadUserProfile() async {
    final user = await _authService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _userName = user?.name ?? 'User';
      });
    }
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
          _filteredProperties = properties;
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

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() async {
    final query = _searchController.text.trim();
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Use database search if query is provided, otherwise filter locally
      List<Property> properties;
      if (query.isNotEmpty) {
        properties = await _databaseService.getProperties(searchQuery: query);
      } else {
        properties = _allProperties;
      }

      // Apply local filter
      if (_selectedFilter != 'All') {
        properties = properties.where((property) {
          return (_selectedFilter == 'House' && property.hasGarden) ||
              (_selectedFilter == 'Apartment' && !property.hasGarden);
        }).toList();
      }

      if (mounted) {
        setState(() {
          _filteredProperties = properties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Search failed: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Good Evening ${_userName ?? 'User'} -',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: primaryDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: primaryDark),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Q Search Properties...',
                  hintStyle: TextStyle(color: mediumGray),
                  prefixIcon: Icon(Icons.search, color: mediumGray),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.menu, color: mediumGray),
                    onPressed: () {},
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildFilterPill('All', _selectedFilter == 'All'),
                      const SizedBox(width: 12),
                      _buildFilterPill('House', _selectedFilter == 'House'),
                      const SizedBox(width: 12),
                      _buildFilterPill('Apartment', _selectedFilter == 'Apartment'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildActionPill('Add Post', Icons.add),
                      const SizedBox(width: 12),
                      _buildActionPill('View Appointments', Icons.calendar_today),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Top Properties Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Top Properties',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AllPropertiesScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Properties List
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
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: (index) {
            if (index == 1) {
              // Navigate to Favorites screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            } else if (index == 3) {
              // Navigate to Messages screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MessagesListScreen(),
                ),
              );
            } else if (index == 4) {
              // Navigate to Profile screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            } else {
              setState(() {
                _selectedNavIndex = index;
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryDark,
          unselectedItemColor: mediumGray,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              label: 'Location',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _onFilterSelected(label),
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

  Widget _buildActionPill(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (label == 'Add Post') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NewPostScreen(),
            ),
          );
        } else if (label == 'View Appointments') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AppointmentsScreen(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: mediumGray.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: primaryDark,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: primaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

