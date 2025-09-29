import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:geocoding/geocoding.dart'; // Import geocoding package
import 'package:genie_on_call/screens/payment_screen.dart'; // Import the new PaymentScreen

class BookingSlotScreen extends StatefulWidget {
  final String serviceName;
  final double cost;

  const BookingSlotScreen({
    super.key,
    required this.serviceName,
    required this.cost,
  });

  @override
  State<BookingSlotScreen> createState() => _BookingSlotScreenState();
}

class _BookingSlotScreenState extends State<BookingSlotScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  List<String> _availableTimeSlotsForSelectedDate = [];

  String? _userName;
  String? _userAddress;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  List<DateTime> _datesWithAvailableSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchAvailableDates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) return;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'];
          _userAddress = userDoc['address'];
          _nameController.text = _userName ?? '';
          _addressController.text = _userAddress ?? '';
        });

        if ((_userAddress == null || _userAddress!.isEmpty) &&
            userDoc.data()!.containsKey('latitude') &&
            userDoc.data()!.containsKey('longitude')) {
          final double lat = userDoc.data()!['latitude'];
          final double lon = userDoc.data()!['longitude'];
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              lat,
              lon,
            );
            if (placemarks.isNotEmpty) {
              final Placemark place = placemarks.first;
              final String address =
                  [
                        place.street,
                        place.subLocality,
                        place.locality,
                        place.administrativeArea,
                        place.postalCode,
                        place.country,
                      ]
                      .where((element) => element != null && element.isNotEmpty)
                      .join(', ');
              setState(() {
                _userAddress = address;
                _addressController.text = address;
              });
              await _firestore.collection('users').doc(_currentUser.uid).set({
                'address': address,
                'lastUpdated': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
          } catch (e) {
            print("Error during reverse geocoding: $e");
          }
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _fetchAvailableDates() async {
    try {
      final querySnapshot = await _firestore
          .collection('available_slots')
          .get();
      final List<DateTime> dates = [];
      for (var doc in querySnapshot.docs) {
        try {
          final dateString = doc.id;
          final date = DateFormat('yyyy-MM-dd').parse(dateString);
          if (date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
            dates.add(date);
          }
        } catch (e) {
          print("Error parsing date from document ID ${doc.id}: $e");
        }
      }
      dates.sort((a, b) => a.compareTo(b));
      setState(() {
        _datesWithAvailableSlots = dates;
      });
    } catch (e) {
      print("Error fetching available dates: $e");
    }
  }

  Future<void> _fetchTimeSlotsForDate(DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    try {
      final doc = await _firestore
          .collection('available_slots')
          .doc(dateString)
          .get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _availableTimeSlotsForSelectedDate = List<String>.from(
            doc.data()!['slots'] ?? [],
          );
          _selectedTimeSlot = null;
        });
      } else {
        setState(() {
          _availableTimeSlotsForSelectedDate = [];
          _selectedTimeSlot = null;
        });
      }
    } catch (e) {
      print("Error fetching time slots for $dateString: $e");
      setState(() {
        _availableTimeSlotsForSelectedDate = [];
        _selectedTimeSlot = null;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          (_datesWithAvailableSlots.isNotEmpty
              ? _datesWithAvailableSlots.first
              : DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime day) {
        return _datesWithAvailableSlots.any(
          (availableDay) =>
              availableDay.year == day.year &&
              availableDay.month == day.month &&
              availableDay.day == day.day,
        );
      },
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                textStyle: const TextStyle(fontFamily: 'Montserrat'),
              ),
            ),
            textTheme: const TextTheme(
              titleLarge: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
              bodyLarge: TextStyle(fontFamily: 'Montserrat'),
              bodyMedium: TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchTimeSlotsForDate(picked);
    }
  }

  Future<void> _proceedToPayment() async {
    if (_currentUser == null) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Login Required',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'You must be logged in to book a service.',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Missing Details',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Please enter your name and address.',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }
    if (_selectedDate == null || _selectedTimeSlot == null) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Selection Required',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Please select a date and time slot.',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    try {
      await _firestore.collection('users').doc(_currentUser.uid).set({
        'name': _nameController.text,
        'address': _addressController.text,
        'phoneNumber': _currentUser.phoneNumber,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Error Updating Details',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Failed to update user details: $e',
            style: const TextStyle(fontFamily: 'Montserrat'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        ),
      );
      print("User update error before payment: $e");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          serviceName: widget.serviceName,
          cost: widget.cost,
          selectedDate: _selectedDate!,
          selectedTimeSlot: _selectedTimeSlot!,
          userName: _nameController.text,
          userAddress: _addressController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Book Your Slot',
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service: ${widget.serviceName}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cost: ₹${widget.cost.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Details:',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your full name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(
                  Icons.person_rounded,
                  color: Colors.blueAccent,
                ),
                labelStyle: const TextStyle(fontFamily: 'Montserrat'),
                hintStyle: const TextStyle(fontFamily: 'Montserrat'),
              ),
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Service Address',
                hintText: 'Enter your service address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.blueAccent,
                ),
                labelStyle: const TextStyle(fontFamily: 'Montserrat'),
                hintStyle: const TextStyle(fontFamily: 'Montserrat'),
              ),
              style: const TextStyle(fontFamily: 'Montserrat'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Text(
              'Select Date:',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _datesWithAvailableSlots.isEmpty
                  ? null
                  : () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? (_datesWithAvailableSlots.isEmpty
                                ? 'No dates available'
                                : 'Choose Date')
                          : DateFormat(
                              'EEEE, MMM d, yyyy',
                            ).format(_selectedDate!),
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        color: _selectedDate == null
                            ? Colors.grey[600]
                            : Colors.black87,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      color: _datesWithAvailableSlots.isEmpty
                          ? Colors.grey
                          : Colors.blueAccent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Time Slot:',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            _availableTimeSlotsForSelectedDate.isEmpty
                ? Center(
                    child: Text(
                      _selectedDate == null
                          ? 'Please select a date first.'
                          : 'No time slots available for this date.',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: _availableTimeSlotsForSelectedDate.length,
                    itemBuilder: (context, index) {
                      final timeSlot =
                          _availableTimeSlotsForSelectedDate[index];
                      final isSelected = _selectedTimeSlot == timeSlot;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTimeSlot = timeSlot;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.grey.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.2),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: Text(
                            timeSlot,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Proceed to Payment',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
