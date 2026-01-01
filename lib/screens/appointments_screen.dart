import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/property.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/appointment_card.dart';
import 'property_detail_screen.dart';
import 'booking_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  // Color palette
  static const Color primaryDark = Color(0xFF2C2C2C);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);

  // Services
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  // State
  late TabController _tabController;
  List<Appointment> _upcomingAppointments = [];
  List<Appointment> _pastAppointments = [];
  Map<String, Property> _propertyMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final appointmentsData = await _databaseService.getUserAppointments(user.id);

      final appointments = <Appointment>[];
      final propertyMap = <String, Property>{};

      for (final data in appointmentsData) {
        try {
          final appointment = Appointment.fromJson(data);
          appointments.add(appointment);

          // Extract property data
          if (data['property'] != null) {
            final propertyData = data['property'] as Map<String, dynamic>;
            final property = Property.fromJson(propertyData);
            propertyMap[appointment.propertyId] = property;
          }
        } catch (e) {
          debugPrint("Error parsing appointment: $e");
        }
      }

      // Separate into upcoming and past
      final upcoming = <Appointment>[];
      final past = <Appointment>[];

      for (final appointment in appointments) {
        if (appointment.isUpcoming()) {
          upcoming.add(appointment);
        } else {
          past.add(appointment);
        }
      }

      // Sort upcoming by date ascending (soonest first)
      upcoming.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      // Sort past by date descending (most recent first)
      past.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

      if (mounted) {
        setState(() {
          _upcomingAppointments = upcoming;
          _pastAppointments = past;
          _propertyMap = propertyMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading appointments: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _databaseService.updateAppointmentStatus(appointment.id, 'cancelled');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rebookAppointment(Appointment appointment) {
    final property = _propertyMap[appointment.propertyId];
    if (property == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingScreen(property: property),
      ),
    ).then((_) {
      _loadAppointments();
    });
  }

  void _viewProperty(Appointment appointment) {
    final property = _propertyMap[appointment.propertyId];
    if (property == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(property: property),
      ),
    );
  }

  Widget _buildAppointmentsList(List<Appointment> appointments) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No appointments',
              style: TextStyle(
                fontSize: 16,
                color: mediumGray,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          final property = _propertyMap[appointment.propertyId];

          if (property == null) {
            return const SizedBox.shrink();
          }

          return AppointmentCard(
            appointment: appointment,
            property: property,
            onCancel: appointment.isUpcoming()
                ? () => _cancelAppointment(appointment)
                : null,
            onRebook: appointment.isPast()
                ? () => _rebookAppointment(appointment)
                : null,
            onViewProperty: () => _viewProperty(appointment),
          );
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
          'My Appointments',
          style: TextStyle(
            color: primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryDark,
          unselectedLabelColor: mediumGray,
          indicatorColor: primaryDark,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList(_upcomingAppointments),
                _buildAppointmentsList(_pastAppointments),
              ],
            ),
    );
  }
}
