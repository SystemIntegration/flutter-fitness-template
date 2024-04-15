import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:pedometer/pedometer.dart';
import 'package:geolocator/geolocator.dart';


class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool _isRunning = false;
  int _stepCount = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  Position? _previousLocation;
  StreamSubscription<Position>? _locationStream;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  void _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
    }

    startListening();
  }

  void startListening() {
    _locationStream = Geolocator.getPositionStream().listen(_handleLocation);
  }

  void _handleLocation(Position position) {
    if (_previousLocation != null) {
      // Calculate distance between current and previous location
      double distanceInMeters = Geolocator.distanceBetween(
          _previousLocation!.latitude,
          _previousLocation!.longitude,
          position.latitude,
          position.longitude);



      // Calculate time difference between current and previous location
      double timeInSeconds = (position.timestamp!.difference(_previousLocation!.timestamp!)).inSeconds.toDouble();

      // Calculate speed in meters per second
      double speed = distanceInMeters / timeInSeconds;

      // Ignore movements above a certain speed threshold (e.g., 10 m/s)
      // and movements with distance traveled below a threshold (e.g., 0.5 meters)
      if (speed <= 10.0 && distanceInMeters >= 0.5) { // Adjust the thresholds as needed
        // Assuming average stride length of 0.75 meters
        double steps = distanceInMeters / 0.75;

        // Increment step count
        setState(() {
          _stepCount += steps.toInt();
        });
      }
    }

    _previousLocation = position;
  }

  @override
  void dispose() {
    _locationStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                if (!_isRunning) {
                  _startWorkout();
                } else {
                  _stopWorkout();
                }
              },
              child: Text(
                _isRunning ? 'Stop' : 'Start',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Time Elapsed: ${_formatTime(_elapsedSeconds)}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              'Step Count: $_stepCount',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add functionality to end workout and navigate back
                Navigator.pop(context);
              },
              child: const Text(
                'End Workout',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }

  void _startWorkout() {
    setState(() {
      _isRunning = true;
      _elapsedSeconds = 0;
    });

    // Start the timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopWorkout() {
    setState(() {
      _isRunning = false;
      _timer?.cancel();
    });
  }
}