import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class CalibrationPage extends StatefulWidget {
  const CalibrationPage({super.key});

  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  double _currentDecibel = 0.0;
  double _offset = 0.0;
  bool _isRecording = false;
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;

  @override
  void initState() {
    super.initState();
    _startRecording();
    _loadPreviousOffset();
  }

  Future<void> _loadPreviousOffset() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _offset = prefs.getDouble('db_offset') ?? 0.0;
    });
  }

  void _startRecording() async {
    try {
      _noiseMeter = NoiseMeter();
      _noiseSubscription = _noiseMeter?.noise.listen(
        (NoiseReading noiseReading) {
          if (!mounted) return;
          setState(() {
            _currentDecibel = noiseReading.meanDecibel;
          });
        },
        onError: (Object error) {
          debugPrint('Noise Meter Error: $error');
        },
      );
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      debugPrint('Failed to start recording: $e');
    }
  }

  void _stopRecording() {
    try {
      _noiseSubscription?.cancel();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
    }
  }

  Future<void> _saveAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('db_offset', _offset);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _stopRecording();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double adjustedDb = (_currentDecibel + _offset).clamp(0.0, 120.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Calibration')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Adjust Accuracy',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use the slider to match the reading with a known reference.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24), // Reduced spacing
        
              // Current Reading Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent, width: 4),
                ),
                child: Column(
                  children: [
                    Text(
                      adjustedDb.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 40, // Slightly smaller font
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const Text(
                      'dB',
                      style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Raw: ${_currentDecibel.toStringAsFixed(1)} dB | Offset: ${_offset > 0 ? "+" : ""}${_offset.toStringAsFixed(1)} dB',
                style: const TextStyle(color: Colors.grey),
              ),
        
              const SizedBox(height: 24), // Reduced spacing
        
              // Slider for Offset
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Calibration Offset', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Slider(
                value: _offset,
                min: -20.0,
                max: 20.0,
                divisions: 80, // 0.5 steps
                label: '${_offset.toStringAsFixed(1)} dB',
                onChanged: (value) {
                  setState(() {
                    _offset = value;
                  });
                },
              ),
        
              const SizedBox(height: 16),
        
              // Reference Guide
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant, 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reference Guide:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildReferenceRow('Breathing / Rustling', '10 - 20 dB'),
                    const Divider(height: 12),
                    _buildReferenceRow('Quiet Library / Whisper', '30 - 40 dB'),
                    const Divider(height: 12),
                    _buildReferenceRow('Normal Conversation', '60 - 65 dB'),
                    const Divider(height: 12),
                    _buildReferenceRow('Vacuum / Busy Traffic', '70 - 80 dB'),
                    const Divider(height: 12),
                    _buildReferenceRow('Hair Dryer / Blender', '80 - 90 dB'),
                    const Divider(height: 12),
                    _buildReferenceRow('Car Horn / Rock Concert', '100 - 110 dB'),
                  ],
                ),
              ),
        
              const SizedBox(height: 20), // Reduced spacing before buttons
        
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const HomePage()),
                        );
                      },
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save Calibration'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
