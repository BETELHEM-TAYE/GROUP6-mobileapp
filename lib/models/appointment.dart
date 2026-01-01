import 'package:flutter/material.dart';

class Appointment {
  final String id;
  final String userId;
  final String propertyId;
  final String landlordId;
  final DateTime appointmentDate;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String? notes;
  final String? bookingReference;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Appointment({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.landlordId,
    required this.appointmentDate,
    this.status = 'pending',
    this.notes,
    this.bookingReference,
    this.createdAt,
    this.updatedAt,
  });

  // Create Appointment from JSON (database)
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      propertyId: json['property_id'] as String,
      landlordId: json['landlord_id'] as String,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      bookingReference: json['booking_reference'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Convert Appointment to JSON for database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'property_id': propertyId,
      'landlord_id': landlordId,
      'appointment_date': appointmentDate.toIso8601String(),
      'status': status,
      if (notes != null) 'notes': notes,
      if (bookingReference != null) 'booking_reference': bookingReference,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Helper methods
  bool isUpcoming() {
    final now = DateTime.now();
    // Normalize both dates to compare only the date portion (yyyy-mm-dd)
    final nowDate = DateTime(now.year, now.month, now.day);
    final appointmentDay = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
    );
    return appointmentDay.isAfter(nowDate) && 
           status != 'cancelled' && 
           status != 'completed';
  }

  bool isPast() {
    final now = DateTime.now();
    // Normalize both dates to compare only the date portion (yyyy-mm-dd)
    final nowDate = DateTime(now.year, now.month, now.day);
    final appointmentDay = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
    );
    return appointmentDay.isBefore(nowDate) || 
           status == 'completed' || 
           status == 'cancelled';
  }

  Color statusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String formattedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDay = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
    );

    if (appointmentDay == today) {
      return 'Today, ${_formatTime(appointmentDate)}';
    } else if (appointmentDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${_formatTime(appointmentDate)}';
    } else if (appointmentDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatTime(appointmentDate)}';
    } else {
      return '${_formatDate(appointmentDate)}, ${_formatTime(appointmentDate)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}
