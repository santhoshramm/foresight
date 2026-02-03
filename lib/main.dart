import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const ForeSightApp());
}

class ForeSightApp extends StatelessWidget {
  const ForeSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ForeSight',
      theme: ThemeData.dark(),
      home: const ForeSightMapScreen(),
    );
  }
}

class ForeSightMapScreen extends StatefulWidget {
  const ForeSightMapScreen({super.key});

  @override
  State<ForeSightMapScreen> createState() => _ForeSightMapScreenState();
}

class _ForeSightMapScreenState extends State<ForeSightMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? currentLocation;

  bool isScanning = false;
  SafetyResult? result;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    await Geolocator.requestPermission();
    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      currentLocation = LatLng(pos.latitude, pos.longitude);
    });
  }

  // ---------------- FORESIGHT ENGINE (Mock but Innovative) ----------------
  SafetyResult calculateSafetyFriction() {
    int lightingScore = 25; // assume moderate lighting
    int crowdScore = 20;    // sparse crowd
    int helpPointScore = 15; // few help points
    int timeRisk = 20;      // late evening

    int total = lightingScore + crowdScore + helpPointScore + timeRisk;

    if (total < 40) {
      return SafetyResult(
        level: SafetyLevel.safe,
        message: "Area appears calm and well-supported.",
        suggestion: "You can proceed normally.",
      );
    } else if (total < 70) {
      return SafetyResult(
        level: SafetyLevel.caution,
        message: "Some risk factors detected nearby.",
        suggestion: "Stay alert and prefer well-lit paths.",
      );
    } else {
      return SafetyResult(
        level: SafetyLevel.risky,
        message: "Multiple risk indicators detected.",
        suggestion: "Avoid lingering. Move toward populated or familiar areas.",
      );
    }
  }

  Future<void> runForeSightScan() async {
    setState(() {
      isScanning = true;
      result = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      result = calculateSafetyFriction();
      isScanning = false;
    });
  }

  Color getLevelColor(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.safe:
        return Colors.green;
      case SafetyLevel.caution:
        return Colors.orange;
      case SafetyLevel.risky:
        return Colors.red;
    }
  }

  IconData getLevelIcon(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.safe:
        return Icons.check_circle;
      case SafetyLevel.caution:
        return Icons.warning_amber_rounded;
      case SafetyLevel.risky:
        return Icons.dangerous;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("ForeSight"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentLocation!,
              zoom: 14,
            ),
            myLocationEnabled: true,
            onMapCreated: (controller) {
              _controller.complete(controller);
            },
          ),

          // ---------- RESULT PANEL ----------
          if (result != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 90,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: getLevelColor(result!.level)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getLevelIcon(result!.level),
                      size: 40,
                      color: getLevelColor(result!.level),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result!.level.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: getLevelColor(result!.level),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result!.message,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Suggestion: ${result!.suggestion}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: isScanning ? null : runForeSightScan,
        icon: isScanning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.visibility),
        label: const Text("Scan Area Safety"),
      ),
    );
  }
}

// ---------------- MODELS ----------------

enum SafetyLevel { safe, caution, risky }

class SafetyResult {
  final SafetyLevel level;
  final String message;
  final String suggestion;

  SafetyResult({
    required this.level,
    required this.message,
    required this.suggestion,
  });
}
