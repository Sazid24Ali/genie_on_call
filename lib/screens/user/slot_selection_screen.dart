import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:genie_on_call/utils/locale_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:genie_on_call/screens/user/booking_confirmation_screen.dart';
import 'package:genie_on_call/widgets/floating_chat_button.dart';

class SlotSelectionScreen extends StatefulWidget {
  final String serviceName;
  final double cost;
  final String description;
  final List<String> images;
  final String? recording;

  const SlotSelectionScreen({
    super.key,
    required this.serviceName,
    required this.cost,
    required this.description,
    required this.images,
    this.recording,
  });

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
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

  LatLng? _selectedLocation;
  final MapController _mapController = MapController();

  bool _isDataLoaded = false;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchAvailableDates();
    _loadLocalTranslations();
  }

  Locale _appLocale = const Locale('en');
  Map<String, String> _localTranslations = {};

  Future<void> _loadLocalTranslations() async {
    try {
      final tag = localeToTag(_appLocale);
      final path = 'assets/translations/$tag.json';
      String raw;
      try {
        raw = await rootBundle.loadString(path);
      } catch (e) {
        final path2 = 'assets/translations/${_appLocale.languageCode}.json';
        raw = await rootBundle.loadString(path2);
      }
      final Map<String, dynamic> decoded = json.decode(raw);
      setState(() {
        _localTranslations = decoded.map(
          (k, v) => MapEntry(k, v?.toString() ?? ''),
        );
      });
    } catch (e) {
      if (kDebugMode) print('Failed to load local translations: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  _fetchUserData() async {
    if (_currentUser == null) return;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'];
          _nameController.text = _userName ?? '';
        });

        // Use home address and location if available
        if (userDoc.data()!.containsKey('homeLat') &&
            userDoc.data()!.containsKey('homeLng') &&
            userDoc.data()!.containsKey('homeAddress')) {
          final double lat = userDoc.data()!['homeLat'];
          final double lon = userDoc.data()!['homeLng'];
          final String address = userDoc.data()!['homeAddress'];
          setState(() {
            _selectedLocation = LatLng(lat, lon);
            _userAddress = address;
            _addressController.text = address;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _mapController.move(_selectedLocation!, 15.0);
            });
          });
        } else {
          // No home set, leave empty
          setState(() {
            _userAddress = '';
            _addressController.text = '';
            _selectedLocation = null;
          });
        }
        setState(() {
          _isDataLoaded = true;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _isDataLoaded = true; // Even on error, stop loading
      });
    }
  }

  Future<void> _saveHomeLocation() async {
    if (_currentUser == null ||
        _selectedLocation == null ||
        _userAddress == null)
      return;
    try {
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'homeLat': _selectedLocation!.latitude,
        'homeLng': _selectedLocation!.longitude,
        'homeAddress': _userAddress,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving home location: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Getting current location...')),
    );

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _selectedLocation = LatLng(pos.latitude, pos.longitude);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _mapController.move(_selectedLocation!, 15.0);
        });
      });

      // Reverse geocode
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
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
          await _saveHomeLocation();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Location set as home')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Address not found')));
        }
      } catch (e) {
        print("Error reverse geocoding current location: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch address')),
        );
      }
    } catch (e) {
      print("Error getting current location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get current location')),
      );
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

  String t(String key, [String? fallback]) {
    return _localTranslations[key] ?? fallback ?? key;
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

  void _onMapTap(TapPosition tapPosition, LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _isGeocoding = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fetching address...')));

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
        setState(() {
          _userAddress = address;
          _addressController.text = address;
          _isGeocoding = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Address updated')));
      } else {
        setState(() {
          _isGeocoding = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Address not found')));
      }
    } catch (e) {
      print("Error during reverse geocoding on map tap: $e");
      setState(() {
        _isGeocoding = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to fetch address')));
    }
  }

  Future<void> _proceedToConfirmation() async {
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
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'name': _nameController.text,
        'homeAddress': _addressController.text,
        'homeLat': _selectedLocation?.latitude,
        'homeLng': _selectedLocation?.longitude,
        'phoneNumber': _currentUser!.phoneNumber,
        'description': widget.description,
        'images': widget.images,
        'recording': widget.recording,
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
        builder: (_) => BookingConfirmationScreen(
          serviceName: widget.serviceName,
          cost: widget.cost,
          description: widget.description,
          images: widget.images,
          recording: widget.recording,
          name: _nameController.text,
          address: _addressController.text,
          phoneNumber: _currentUser!.phoneNumber ?? '',
          selectedDate: _selectedDate!,
          selectedTimeSlot: _selectedTimeSlot!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t('book_slot', 'Book Your Slot'),
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
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
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
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
                hintText: 'Address will be set from map selection',
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
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _currentUser?.phoneNumber ?? '',
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone, color: Colors.blueAccent),
                labelStyle: const TextStyle(fontFamily: 'Montserrat'),
              ),
              readOnly: true,
              style: const TextStyle(fontFamily: 'Montserrat'),
            ),
            const SizedBox(height: 24),
            if (_isDataLoaded && _selectedLocation != null)
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation!,
                        initialZoom: 15.0,
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: "com.example.genie_on_call",
                        ),
                        MarkerLayer(
                          markers: _selectedLocation != null
                              ? [
                                  Marker(
                                    point: _selectedLocation!,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ]
                              : [],
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: _getCurrentLocation,
                        backgroundColor: Colors.blueAccent,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 200,
                child: const Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 8),
            Text(
              'Latitude: ${_selectedLocation?.latitude?.toStringAsFixed(6) ?? 'N/A'}, Longitude: ${_selectedLocation?.longitude?.toStringAsFixed(6) ?? 'N/A'}',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Date:',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
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
                                : Theme.of(context).brightness ==
                                      Brightness.dark
                                ? Theme.of(context).cardColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Theme.of(context).brightness ==
                                        Brightness.dark
                                  ? Colors.grey.withOpacity(0.6)
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
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).brightness ==
                                        Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
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
                onPressed: _proceedToConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  t('proceed_to_confirmation', 'Proceed to Confirmation'),
                  style: const TextStyle(
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
      floatingActionButton: const FloatingChatButton(),
    );
  }
}
