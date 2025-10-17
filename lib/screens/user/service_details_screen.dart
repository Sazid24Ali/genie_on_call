import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_slot_screen.dart';
import 'package:genie_on_call/widgets/floating_chat_button.dart';

// Helper to map icon string to IconData (ensure this function is also in home_screen.dart or a common utility file)
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

// Helper function to get cost from an array of maps
double getCostFromArrayOfMaps(List<dynamic> costsArray, String key) {
  try {
    final costMap = costsArray.firstWhere(
      (element) => element is Map && element.containsKey(key),
      orElse: () => null,
    );
    return (costMap?[key] as num?)?.toDouble() ?? 0.0;
  } catch (e) {
    print("Error getting cost for key $key from array: $e");
    return 0.0;
  }
}

class ServiceDetailsScreen extends StatelessWidget {
  final String serviceName;
  const ServiceDetailsScreen({super.key, required this.serviceName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: const FloatingChatButton(),
      appBar: AppBar(
        title: Text(
          serviceName,
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('name', isEqualTo: serviceName)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No sub-services found for this service."),
            );
          }

          final serviceDoc = snapshot.data!.docs.first;
          final subServices = List<Map<String, dynamic>>.from(
            serviceDoc['subServices'] ?? [],
          );

          if (subServices.isEmpty) {
            return const Center(
              child: Text("No sub-services defined for this service."),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: subServices.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final sub = subServices[index];
                final subServiceName = sub['name'] ?? 'Unknown Sub-Service';
                final subServiceIconName = sub['icon'] ?? '';

                // Retrieve bhkCosts as a List<dynamic>
                final List<dynamic> bhkCostsArray =
                    (sub['bhkCosts'] as List<dynamic>?) ?? [];

                // For non-painting services or 'Few Walls Painting', use the direct 'cost' field
                // For 'Full Home Painting', the cost displayed on the card will be for 1BHK by default
                final double displayCost =
                    (subServiceName == 'Full Home Painting' &&
                        bhkCostsArray.isNotEmpty)
                    ? getCostFromArrayOfMaps(bhkCostsArray, '1BHK')
                    : (sub['cost'] as num?)?.toDouble() ?? 0.0;

                return GestureDetector(
                  onTap: () {
                    // Special handling for Painting
                    if (serviceName == 'Painting' &&
                        subServiceName == 'Full Home Painting') {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return SimpleDialog(
                            title: const Text(
                              'Select BHK',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: [
                              SimpleDialogOption(
                                child: const Text(
                                  '1 BHK',
                                  style: TextStyle(fontFamily: 'Montserrat'),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingSlotScreen(
                                        serviceName:
                                            '$serviceName - $subServiceName (1 BHK)',
                                        cost: getCostFromArrayOfMaps(
                                          bhkCostsArray,
                                          '1BHK',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SimpleDialogOption(
                                child: const Text(
                                  '2 BHK',
                                  style: TextStyle(fontFamily: 'Montserrat'),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingSlotScreen(
                                        serviceName:
                                            '$serviceName - $subServiceName (2 BHK)',
                                        cost: getCostFromArrayOfMaps(
                                          bhkCostsArray,
                                          '2BHK',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SimpleDialogOption(
                                child: const Text(
                                  '3 BHK',
                                  style: TextStyle(fontFamily: 'Montserrat'),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingSlotScreen(
                                        serviceName:
                                            '$serviceName - $subServiceName (3 BHK)',
                                        cost: getCostFromArrayOfMaps(
                                          bhkCostsArray,
                                          '3BHK',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else if (serviceName == 'Painting' &&
                        subServiceName == 'Few Walls Painting') {
                      showDialog(
                        context: context,
                        builder: (context) {
                          final wallController = TextEditingController();
                          final double costPerWall =
                              (sub['cost'] as num?)?.toDouble() ?? 0.0;

                          return AlertDialog(
                            title: const Text(
                              'Enter number of walls',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: TextField(
                              controller: wallController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Number of walls',
                                hintStyle: TextStyle(fontFamily: 'Montserrat'),
                              ),
                              style: const TextStyle(fontFamily: 'Montserrat'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final walls = int.tryParse(
                                    wallController.text,
                                  );
                                  if (walls != null && walls > 0) {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BookingSlotScreen(
                                          serviceName:
                                              '$serviceName - $subServiceName ($walls walls)',
                                          cost: costPerWall * walls,
                                        ),
                                      ),
                                    );
                                  } else {
                                    // Replaced SnackBar with AlertDialog
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text(
                                          'Invalid Input',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: const Text(
                                          'Please enter a valid number of walls.',
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
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                ),
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      final double subServiceCost =
                          (sub['cost'] as num?)?.toDouble() ?? 0.0;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingSlotScreen(
                            serviceName: '$serviceName - $subServiceName',
                            cost: subServiceCost,
                          ),
                        ),
                      );
                    }
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 4,
                    shadowColor: Colors.blueAccent.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blueAccent.withOpacity(
                              0.08,
                            ),
                            radius: 28,
                            child: Icon(
                              getIconData(subServiceIconName),
                              size: 32,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            subServiceName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹${displayCost.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
