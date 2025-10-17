import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:genie_on_call/utils/locale_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:genie_on_call/utils/coords.dart';
import 'package:genie_on_call/screens/user/slot_selection_screen.dart';
import 'package:genie_on_call/widgets/floating_chat_button.dart';

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
  // Fields for description, images, and voice recording
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _pickedImages = [];

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedFilePath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadLocalTranslations();
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
      });
    });
  }

  Locale _appLocale = const Locale('en');
  Map<String, String> _localTranslations = {};

  Future<void> _loadLocalTranslations() async {
    try {
      final tag = localeToTag(_appLocale); // e.g., en or hi-Latn
      final path = 'assets/translations/$tag.json';
      String raw;
      try {
        raw = await rootBundle.loadString(path);
      } catch (e) {
        // fallback to language code only
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
    _descriptionController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  String t(String key, [String? fallback]) {
    return _localTranslations[key] ?? fallback ?? key;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      setState(() {
        _pickedImages.add(image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );
      await _audioRecorder.start(config, path: path);
      setState(() {
        _isRecording = true;
        _recordedFilePath = path;
      });
    }
  }

  Future<void> _stopRecording() async {
    final stoppedPath = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordedFilePath = stoppedPath ?? _recordedFilePath;
    });
  }

  void _removeRecording() {
    setState(() {
      _recordedFilePath = null;
    });
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath != null) {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  void _navigateToSlotSelection() {
    _ensureLocationThenNavigate();
  }

  Future<void> _ensureLocationThenNavigate() async {
    // Show rationale and request permission, then fetch position and save to user doc
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      // If not granted, show rationale first
      // Check whether we've already shown the rationale to this user
      final user = FirebaseAuth.instance.currentUser;
      bool seenRationale = false;
      Map<String, dynamic>? userData;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          userData = doc.data();
          seenRationale = (userData?['seenLocationRationale'] == true);
        }
      }

      if (!seenRationale) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (dctx) => AlertDialog(
            title: const Text('Why we need your location'),
            content: const Text(
              'We use your location to center the map and suggest nearby agents. The app will now request location permission.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dctx).pop(false),
                child: const Text('Continue without location'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dctx).pop(true),
                child: const Text('Allow'),
              ),
            ],
          ),
        );
        if (proceed != true) {
          // Navigate without trying to get location
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SlotSelectionScreen(
                serviceName: widget.serviceName,
                cost: widget.cost,
                description: _descriptionController.text,
                images: _pickedImages.map((x) => x.path).toList(),
                recording: _recordedFilePath,
              ),
            ),
          );
          return;
        }

        // mark that we've shown the rationale so we don't show it again
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'seenLocationRationale': true,
                'lastUpdated': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
      }

      // If user already has coordinates, skip requesting location
      if (userData != null) {
        final double? lat = getLat(userData);
        final double? lon = getLng(userData);
        if (lat != null && lon != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SlotSelectionScreen(
                serviceName: widget.serviceName,
                cost: widget.cost,
                description: _descriptionController.text,
                images: _pickedImages.map((x) => x.path).toList(),
                recording: _recordedFilePath,
              ),
            ),
          );
          return;
        }
      }

      // otherwise, request permission and try to get current position
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (dctx) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Location permission is permanently denied. Please open app settings and grant location permission.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dctx).pop(true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (openSettings == true) await openAppSettings();
        // Navigate either way (user can enable and come back), but don't block navigation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SlotSelectionScreen(
              serviceName: widget.serviceName,
              cost: widget.cost,
              description: _descriptionController.text,
              images: _pickedImages.map((x) => x.path).toList(),
              recording: _recordedFilePath,
            ),
          ),
        );
        return;
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        // Try to fetch current position and save to user doc
        try {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
                  'latitude': pos.latitude,
                  'longitude': pos.longitude,
                  'lastUpdated': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
          }
        } catch (e) {
          // ignore position errors, navigate anyway
        }
      }

      // Finally, navigate to slot selection
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SlotSelectionScreen(
            serviceName: widget.serviceName,
            cost: widget.cost,
            description: _descriptionController.text,
            images: _pickedImages.map((x) => x.path).toList(),
            recording: _recordedFilePath,
          ),
        ),
      );
    } catch (e) {
      // On any unexpected error, navigate without location
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SlotSelectionScreen(
            serviceName: widget.serviceName,
            cost: widget.cost,
            description: _descriptionController.text,
            images: _pickedImages.map((x) => x.path).toList(),
            recording: _recordedFilePath,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: const FloatingChatButton(),
      appBar: AppBar(
        title: Text(
          'Additional Details',
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
              t('additional_details', 'Additional Details'),
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
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: t('service_description', 'Service Description'),
                hintText: t(
                  'describe_requirements',
                  'Describe your requirements...',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(
                  Icons.description,
                  color: Colors.blueAccent,
                ),
                labelStyle: const TextStyle(fontFamily: 'Montserrat'),
                hintStyle: const TextStyle(fontFamily: 'Montserrat'),
              ),
              style: const TextStyle(fontFamily: 'Montserrat'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: Text(
                      t('add_images', 'Add Images'),
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
            if (_pickedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _pickedImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(image.path),
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removeImage(index),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isRecording
                          ? t('stop_recording', 'Stop Recording')
                          : t('start_recording', 'Start Recording'),
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording
                          ? Colors.redAccent
                          : Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
            if (!_isRecording && _recordedFilePath != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.blueAccent,
                    ),
                    onPressed: _playRecording,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('recorded_audio', 'Recorded Audio'),
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _removeRecording,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _navigateToSlotSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Next',
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
