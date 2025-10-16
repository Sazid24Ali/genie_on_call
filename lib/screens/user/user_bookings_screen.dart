import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import 'package:genie_on_call/providers/theme_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:genie_on_call/widgets/floating_chat_button.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'Pending'; // 'Pending' or 'All'
  String? _userName; // Added to store the user's name
  String? _userPhone; // Added to store the user's phone

  User? get _currentUser => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data including name and phone
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['userName']; // Get the name from Firestore
            _userPhone = userDoc['userPhone']; // Get the phone from Firestore
          });
        }
      } catch (e) {
        print("Error fetching user data in UserBookingsScreen: $e");
      }
    }
  }

  // Function to get the stream of bookings based on the selected filter
  Stream<QuerySnapshot<Map<String, dynamic>>> _fetchBookingsStream() {
    if (_currentUser == null) {
      return const Stream.empty();
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('createdAt', descending: true); // Order by creation time

    if (_selectedFilter == 'Pending') {
      query = query.where('status', isEqualTo: 'Pending');
    }
    // If 'All' is selected, no additional status filter is applied.

    return query.snapshots();
  }

  // Removed _showLogoutConfirmationDialog as it's now in HomeScreen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: const FloatingChatButton(),
      appBar: AppBar(
        title: const Text(
          'My Bookings', // Changed title to reflect its new focus
          style: TextStyle(
            fontFamily: 'Montserrat',
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
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Account',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Display name if available, otherwise just mobile number
                    if (_userName != null && _userName!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.person_rounded,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Name: ',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextSpan(
                                  text: _userName,
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_rounded,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Mobile Number: ',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              TextSpan(
                                text: _userPhone ?? 'N/A',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // You can add more user details here if available in Firestore
                    // e.g., Address
                  ],
                ),
              ),
            ),
            const Text(
              'Your Bookings',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // Filter options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text(
                    'Pending',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                  selected: _selectedFilter == 'Pending',
                  selectedColor: Colors.blueAccent,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = 'Pending';
                      });
                    }
                  },
                  labelStyle: TextStyle(
                    color: _selectedFilter == 'Pending'
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _selectedFilter == 'Pending'
                          ? Colors.blueAccent
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
                ChoiceChip(
                  label: const Text(
                    'All Bookings',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                  selected: _selectedFilter == 'All',
                  selectedColor: Colors.blueAccent,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = 'All';
                      });
                    }
                  },
                  labelStyle: TextStyle(
                    color: _selectedFilter == 'All'
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _selectedFilter == 'All'
                          ? Colors.blueAccent
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                        _selectedFilter == 'Pending'
                            ? 'No pending bookings found.'
                            : 'No bookings yet.',
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

                List<QueryDocumentSnapshot<Map<String, dynamic>>>
                sortedBookings = List.from(snapshot.data!.docs);

                if (_selectedFilter == 'All') {
                  // Sort for 'All': Finished first (Finished), then Pending, then others, within each by createdAt descending
                  sortedBookings.sort((a, b) {
                    final aData = a.data();
                    final bData = b.data();
                    final aStatus = aData['status'] ?? '';
                    final bStatus = bData['status'] ?? '';

                    // Priority: Finished (0), Pending (1), others (2)
                    int aPriority = 2;
                    if (aStatus == 'Finished') {
                      aPriority = 0;
                    } else if (aStatus == 'Pending')
                      aPriority = 1;

                    int bPriority = 2;
                    if (bStatus == 'Finished') {
                      bPriority = 0;
                    } else if (bStatus == 'Pending')
                      bPriority = 1;

                    if (aPriority != bPriority) {
                      return aPriority.compareTo(
                        bPriority,
                      ); // Lower priority first
                    }

                    // Same priority, sort by createdAt descending
                    final aCreatedAt =
                        aData['createdAt'] as Timestamp? ?? Timestamp.now();
                    final bCreatedAt =
                        bData['createdAt'] as Timestamp? ?? Timestamp.now();
                    return bCreatedAt.compareTo(aCreatedAt);
                  });
                } // For 'Pending', already filtered and ordered by createdAt desc in stream

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedBookings.length,
                  itemBuilder: (context, index) {
                    final booking = sortedBookings[index].data();
                    final Timestamp bookingTimestamp =
                        booking['bookingDate'] as Timestamp;
                    final DateTime bookingDateTime = bookingTimestamp.toDate();
                    final String formattedDate = DateFormat(
                      'MMM d, yyyy',
                    ).format(bookingDateTime);

                    final String agentId = booking['agentId'] ?? '';
                    final String serviceProviderName =
                        booking['serviceProviderName'] ?? 'Not Assigned';
                    final String serviceProviderPhone =
                        booking['serviceProviderPhone'] ?? 'N/A';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                            _buildDetailRow(
                              Icons.calendar_today_rounded,
                              'Date',
                              formattedDate,
                            ),
                            _buildDetailRow(
                              Icons.access_time_rounded,
                              'Time',
                              booking['bookingTime'] ?? 'N/A',
                            ),
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
                              'Service Provider:',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (agentId.isNotEmpty)
                              FutureBuilder<DocumentSnapshot>(
                                future: _firestore
                                    .collection('agents')
                                    .doc(agentId)
                                    .get(),
                                builder: (context, agentSnapshot) {
                                  if (agentSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (agentSnapshot.hasData &&
                                      agentSnapshot.data!.exists) {
                                    final agentData =
                                        agentSnapshot.data!.data()
                                            as Map<String, dynamic>;
                                    final agentName =
                                        agentData['name'] ?? 'Unknown Agent';
                                    final agentPhone =
                                        agentData['phone'] ?? 'N/A';
                                    return Column(
                                      children: [
                                        _buildDetailRow(
                                          Icons.person_rounded,
                                          'Name',
                                          agentName,
                                        ),
                                        _buildDetailRow(
                                          Icons.phone_android_rounded,
                                          'Phone',
                                          agentPhone,
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Column(
                                      children: [
                                        _buildDetailRow(
                                          Icons.person_rounded,
                                          'Name',
                                          'Agent not found',
                                        ),
                                        _buildDetailRow(
                                          Icons.phone_android_rounded,
                                          'Phone',
                                          'N/A',
                                        ),
                                      ],
                                    );
                                  }
                                },
                              )
                            else
                              Column(
                                children: [
                                  _buildDetailRow(
                                    Icons.person_rounded,
                                    'Name',
                                    serviceProviderName,
                                  ),
                                  _buildDetailRow(
                                    Icons.phone_android_rounded,
                                    'Phone',
                                    serviceProviderPhone,
                                  ),
                                ],
                              ),
                            // Action buttons based on status
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (booking['status'] == 'Pending')
                                    TextButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) => AlertDialog(
                                            title: const Text(
                                              'Cancel Booking',
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: const Text(
                                              'Are you sure you want to cancel this booking? This action cannot be undone.',
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  dialogContext,
                                                ).pop(),
                                                child: const Text(
                                                  'No',
                                                  style: TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop(); // Dismiss dialog
                                                  try {
                                                    await _firestore
                                                        .collection('bookings')
                                                        .doc(
                                                          sortedBookings[index]
                                                              .id,
                                                        )
                                                        .update({
                                                          'status': 'Cancelled',
                                                        });
                                                    if (mounted) {
                                                      showDialog(
                                                        context: context,
                                                        builder: (innerDialogContext) => AlertDialog(
                                                          title: const Text(
                                                            'Cancelled',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Montserrat',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          content: const Text(
                                                            'Booking has been cancelled.',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Montserrat',
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    innerDialogContext,
                                                                  ).pop(),
                                                              child: const Text(
                                                                'OK',
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Montserrat',
                                                                  color: Colors
                                                                      .blueAccent,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    print(
                                                      "Error cancelling booking: $e",
                                                    );
                                                    if (mounted) {
                                                      showDialog(
                                                        context: context,
                                                        builder: (innerDialogContext) => AlertDialog(
                                                          title: const Text(
                                                            'Error',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Montserrat',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          content: Text(
                                                            'Failed to cancel booking: $e',
                                                            style: const TextStyle(
                                                              fontFamily:
                                                                  'Montserrat',
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    innerDialogContext,
                                                                  ).pop(),
                                                              child: const Text(
                                                                'OK',
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Montserrat',
                                                                  color: Colors
                                                                      .blueAccent,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                ),
                                                child: const Text(
                                                  'Yes, Cancel',
                                                  style: TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.cancel_rounded,
                                        color: Colors.redAccent,
                                      ),
                                      label: const Text(
                                        'Cancel Booking',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (booking['status'] == 'Cancelled')
                                    TextButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) => AlertDialog(
                                            title: const Text(
                                              'Remove Booking',
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: const Text(
                                              'Are you sure you want to permanently remove this cancelled booking from your list? This action cannot be undone.',
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  dialogContext,
                                                ).pop(),
                                                child: const Text(
                                                  'No',
                                                  style: TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop(); // Dismiss dialog
                                                  try {
                                                    await _firestore
                                                        .collection('bookings')
                                                        .doc(
                                                          sortedBookings[index]
                                                              .id,
                                                        )
                                                        .delete(); // Permanently delete
                                                    if (mounted) {
                                                      showDialog(
                                                        context: context,
                                                        builder: (innerDialogContext) => AlertDialog(
                                                          title: const Text(
                                                            'Removed',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Montserrat',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          content: const Text(
                                                            'Cancelled booking has been permanently removed.',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Montserrat',
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    innerDialogContext,
                                                                  ).pop(),
                                                              child: const Text(
                                                                'OK',
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Montserrat',
                                                                  color: Colors
                                                                      .blueAccent,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    print(
                                                      "Error removing booking: $e",
                                                    );
                                                    if (mounted) {
                                                      showDialog(
                                                        context: context,
                                                        builder: (innerDialogContext) => AlertDialog(
                                                          title: const Text(
                                                            'Error',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Montserrat',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          content: Text(
                                                            'Failed to remove booking: $e',
                                                            style: const TextStyle(
                                                              fontFamily:
                                                                  'Montserrat',
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    innerDialogContext,
                                                                  ).pop(),
                                                              child: const Text(
                                                                'OK',
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Montserrat',
                                                                  color: Colors
                                                                      .blueAccent,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red.shade700,
                                                ),
                                                child: const Text(
                                                  'Yes, Remove',
                                                  style: TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.delete_forever_rounded,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        'Remove Permanently',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // Removed the Logout button from here
          ],
        ),
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
