import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/property.dart';
import 'book_completion_screen.dart';

class BookingScreen extends StatefulWidget {
  final Property property;

  const BookingScreen({
    super.key,
    required this.property,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Color palette
  static const Color primaryDark = Color(0xFF2C2C2C);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);

  String? _selectedPaymentMethod;
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();

  // Price breakdown (based on wireframe)
  double get basePrice => widget.property.price * 0.85; // ETB 624,750
  double get tax => widget.property.price * 0.15; // ETB 110,250
  double get total => widget.property.price; // ETB 735,000

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yy').format(picked);
      });
    }
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

  String _generateBookingReference() {
    // Generate a random 6-character booking reference
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final ref = StringBuffer();
    for (int i = 0; i < 6; i++) {
      ref.write(chars[(random + i) % chars.length]);
    }
    return ref.toString();
  }

  void _handleConfirmBooking() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an appointment date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Generate booking reference and date
    final bookingReference = _generateBookingReference();
    final bookingDate = DateFormat('dd/MM/yy').format(_selectedDate!);

    // Navigate to book completion screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => BookCompletionScreen(
          property: widget.property,
          bookingReference: bookingReference,
          bookingDate: bookingDate,
        ),
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
          'Book Now',
          style: TextStyle(
            color: primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.property.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.property.address,
                    style: TextStyle(
                      fontSize: 14,
                      color: mediumGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '4.7',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Price Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildPriceRow('Price', _formatPrice(basePrice)),
                  const SizedBox(height: 12),
                  _buildPriceRow('Tax', _formatPrice(tax)),
                  const Divider(height: 24),
                  _buildPriceRow(
                    'Total',
                    _formatPrice(total),
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Appointment Date
            const Text(
              'Appointment Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: InputDecoration(
                hintText: 'DD/MM/YY',
                hintStyle: TextStyle(color: mediumGray),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: mediumGray.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: mediumGray.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: primaryDark, width: 2),
                ),
                suffixIcon: Icon(Icons.calendar_today, color: mediumGray),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Payment Method
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildPaymentOption('CBE'),
                  const Divider(),
                  _buildPaymentOption('BANK OF ABYSSINIA'),
                  const Divider(),
                  _buildPaymentOption('VISA'),
                  const Divider(),
                  _buildPaymentOption('PayPal'),
                  const Divider(),
                  _buildPaymentOption('Pay later', isSmall: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Privacy Policy Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: mediumGray,
                    height: 1.5,
                  ),
                  children: const [
                    TextSpan(
                      text:
                          "We'll call or text you to confirm your number. Standard message and data rates apply. ",
                    ),
                    TextSpan(
                      text: 'Privacy policy',
                      style: TextStyle(
                        color: primaryDark,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      // Confirm Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
        child: ElevatedButton(
          onPressed: _handleConfirmBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            'Confirm Booking',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: primaryDark,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String label, {bool isSmall = false}) {
    final isSelected = _selectedPaymentMethod == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = label;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 14 : 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

