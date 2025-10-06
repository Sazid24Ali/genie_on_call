import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Helper function to map icon strings from Firestore to IconData
IconData getIconData(String iconName) {
  switch (iconName) {
    case 'ac_unit_rounded':
      return Icons.ac_unit_rounded;
    case 'cleaning_services_rounded':
      return Icons.cleaning_services_rounded;
    case 'bolt_rounded':
      return Icons.bolt_rounded;
    case 'handyman_rounded':
      return Icons.handyman_rounded;
    case 'plumbing_rounded':
      return Icons.plumbing_rounded;
    case 'flash_on_rounded':
      return Icons.flash_on_rounded;
    case 'format_paint_rounded':
      return Icons.format_paint_rounded;
    case 'chair_alt_rounded':
      return Icons.chair_alt_rounded;
    case 'door_front_rounded':
      return Icons.door_front_door_rounded;
    case 'build_rounded':
      return Icons.build_rounded;
    case 'water_drop_rounded':
      return Icons.water_drop_rounded;
    case 'electrical_services_rounded':
      return Icons.electrical_services_rounded;
    case 'power_rounded':
      return Icons.power_rounded;
    case 'add_circle_rounded':
      return Icons.add_circle_rounded;
    case 'format_color_fill_rounded':
      return Icons.format_color_fill_rounded;
    case 'brush_rounded':
      return Icons.brush_rounded;
    case 'local_gas_station_rounded':
      return Icons.local_gas_station_rounded;
    default:
      return Icons.miscellaneous_services_rounded;
  }
}

class AgentEarningsScreen extends StatefulWidget {
  const AgentEarningsScreen({super.key});

  @override
  State<AgentEarningsScreen> createState() => _AgentEarningsScreenState();
}

class _AgentEarningsScreenState extends State<AgentEarningsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double _totalEarnings = 0.0;
  List<Map<String, dynamic>> _finishedBookings = [];

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final query = await _firestore
            .collection('bookings')
            .where('agentId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'Finished')
            .get();

        double total = 0.0;
        List<Map<String, dynamic>> bookings = [];
        for (var doc in query.docs) {
          final data = doc.data();
          final cost = (data['cost'] as num?)?.toDouble() ?? 0.0;
          total += cost;
          bookings.add({
            'id': doc.id,
            'serviceName': data['serviceName'] ?? 'Unknown',
            'cost': cost,
            'date': (data['bookingDate'] as Timestamp).toDate(),
            'userName': data['userName'] ?? 'Customer',
            'icon': data['icon'] ?? '',
          });
        }
        setState(() {
          _totalEarnings = total;
          _finishedBookings = bookings;
        });
      } catch (e) {
        print("Error fetching earnings: $e");
        // Optionally show a snackbar or dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching earnings: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Earnings',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.attach_money,
                      size: 32,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ₹${_totalEarnings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _finishedBookings.isEmpty
                  ? const Center(child: Text('No earnings yet.'))
                  : ListView.builder(
                      itemCount: _finishedBookings.length,
                      itemBuilder: (context, index) {
                        final booking = _finishedBookings[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Icon(
                              getIconData(booking['icon']),
                              color: Colors.green,
                            ),
                            title: Text(
                              booking['serviceName'],
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${booking['userName']} - ${DateFormat('MMM d, yyyy').format(booking['date'])}',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: Text(
                              '₹${booking['cost'].toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
