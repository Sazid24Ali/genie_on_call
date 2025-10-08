import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_selector.dart';

class AgentBookingsScreen extends StatefulWidget {
  const AgentBookingsScreen({super.key, this.initialTab = 'Accepted'});

  final String initialTab;

  @override
  State<AgentBookingsScreen> createState() => _AgentBookingsScreenState();
}

class _AgentBookingsScreenState extends State<AgentBookingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _selectedTab; // 'Accepted', 'Finished'

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _fetchBookingsStream() {
    if (_auth.currentUser == null) {
      return const Stream.empty();
    }

    if (_selectedTab == 'Accepted') {
      return _firestore
          .collection('bookings')
          .where('agentId', isEqualTo: _auth.currentUser!.uid)
          .where('status', whereIn: ['Accepted', 'accepted'])
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      // Finished
      return _firestore
          .collection('bookings')
          .where('agentId', isEqualTo: _auth.currentUser!.uid)
          .where('status', whereIn: ['Finished', 'finished'])
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  Future<void> _finishBooking(String bookingId) async {
    try {
      // First, get the booking details to get the cost
      DocumentSnapshot bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      if (!bookingDoc.exists) {
        throw 'Booking not found';
      }
      Map<String, dynamic> bookingData =
          bookingDoc.data() as Map<String, dynamic>;
      num cost = bookingData['cost'] ?? 0;

      // Update the booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'Finished',
        'finishedAt': FieldValue.serverTimestamp(),
      });

      // Update agent's earnings
      String agentId = _auth.currentUser!.uid;
      await _firestore.collection('agents').doc(agentId).update({
        'totalEarnings': FieldValue.increment(cost),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking marked as finished and earnings updated!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error finishing booking: $e')));
      }
    }
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, String bookingId) {
    final Timestamp bookingTimestamp = booking['bookingDate'] as Timestamp;
    final DateTime bookingDateTime = bookingTimestamp.toDate();
    final String formattedDate = DateFormat(
      'MMM d, yyyy',
    ).format(bookingDateTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking['serviceName'] ?? 'Unknown Service',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedTab != 'Accepted')
              _buildDetailRow(
                Icons.description,
                'Description',
                '${booking['description'] ?? 'N/A'}\nDate: $formattedDate\nTime: ${booking['bookingTime'] ?? 'N/A'}',
              ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.payments_rounded,
              'Payment',
              booking['paymentMethod'] ?? 'N/A',
            ),
            _buildDetailRow(
              Icons.currency_rupee_rounded,
              'Cost',
              '₹${(booking['cost'] as num?)?.toStringAsFixed(0) ?? '0'}',
            ),
            _buildDetailRow(
              Icons.info_outline_rounded,
              'Status',
              booking['status'] ?? 'N/A',
            ),
            const SizedBox(height: 12),
            const Text(
              'User Details:',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            _buildDetailRow(
              Icons.person_rounded,
              'Name',
              booking['userName'] ?? 'N/A',
            ),
            _buildDetailRow(
              Icons.phone_android_rounded,
              'Phone',
              booking['userPhone'] ?? 'N/A',
            ),
            _buildDetailRow(
              Icons.location_on_rounded,
              'Address',
              booking['userAddress'] ?? 'N/A',
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: _selectedTab == 'Accepted'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _finishBooking(bookingId),
                          icon: const Icon(Icons.done, color: Colors.white),
                          label: const Text(
                            'Mark Finished',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () async {
                            final phone = booking['userPhone'];
                            if (phone != null && phone.isNotEmpty) {
                              final String url = 'tel:$phone';
                              if (await canLaunch(url)) {
                                await launch(url);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not launch phone dialer',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.directions,
                            color: Colors.blue,
                          ),
                          onPressed: () async {
                            final lat = booking['userLat'];
                            final lng = booking['userLng'];
                            if (lat == null || lng == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Location not available'),
                                ),
                              );
                              return;
                            }
                            // Get agent's current location
                            Position? agentPosition;
                            try {
                              LocationPermission permission =
                                  await Geolocator.checkPermission();
                              if (permission == LocationPermission.denied) {
                                permission =
                                    await Geolocator.requestPermission();
                                if (permission == LocationPermission.denied ||
                                    permission ==
                                        LocationPermission.deniedForever) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).locationPermissionContent,
                                      ),
                                    ),
                                  );
                                  return;
                                }
                              }
                              agentPosition =
                                  await Geolocator.getCurrentPosition(
                                    desiredAccuracy: LocationAccuracy.high,
                                  );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).errorGettingLocation(e.toString()),
                                  ),
                                ),
                              );
                              return;
                            }
                            // ignore: unnecessary_null_comparison
                            if (agentPosition == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not get current location',
                                  ),
                                ),
                              );
                              return;
                            }
                            // Try Google Maps navigation intent
                            final String mapsUrl =
                                'google.navigation:q=$lat,$lng&saddr=${agentPosition.latitude},${agentPosition.longitude}&mode=d';
                            final Uri mapsUri = Uri.parse(mapsUrl);
                            if (await canLaunchUrl(mapsUri)) {
                              await launchUrl(
                                mapsUri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              // Fallback to web URL
                              final String webUrl =
                                  'https://www.google.com/maps/dir/?api=1&origin=${agentPosition.latitude},${agentPosition.longitude}&destination=$lat,$lng&travelmode=driving';
                              final Uri webUri = Uri.parse(webUrl);
                              if (await canLaunchUrl(webUri)) {
                                await launchUrl(
                                  webUri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      ).couldNotLaunchMaps,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    )
                  : const SizedBox(),
            ),
          ],
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
          'My Jobs',
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
        actions: [LanguageSelector()],
      ),
      body: Column(
        children: [
          // Tab selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text(
                    'Accepted',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                  selected: _selectedTab == 'Accepted',
                  selectedColor: Colors.greenAccent.shade700,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTab = 'Accepted';
                      });
                    }
                  },
                  labelStyle: TextStyle(
                    color: _selectedTab == 'Accepted'
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _selectedTab == 'Accepted'
                          ? Colors.green
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
                ChoiceChip(
                  label: const Text(
                    'Finished',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                  selected: _selectedTab == 'Finished',
                  selectedColor: Colors.greenAccent.shade700,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTab = 'Finished';
                      });
                    }
                  },
                  labelStyle: TextStyle(
                    color: _selectedTab == 'Finished'
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _selectedTab == 'Finished'
                          ? Colors.green
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _fetchBookingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading bookings: ${snapshot.error}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.red,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        _selectedTab == 'Accepted'
                            ? 'No accepted jobs.'
                            : 'No finished jobs.',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.black87,
                        ),
                      ),
                    ),
                  );
                }

                List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings =
                    snapshot.data!.docs;

                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index].data();
                    final bookingId = bookings[index].id;
                    return _buildBookingCard(booking, bookingId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isDark
                ? Colors.black87
                : Colors.grey[600], // Dark icons in dark mode
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight:
                          FontWeight.bold, // More bold white data in dark mode
                      color: isDark ? Colors.white : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
