import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import 'reports_page.dart';
import 'settings_page.dart';
import 'history_page.dart';
import 'database_helper.dart';
import 'banner_ad_widget.dart'; // Import Banner Ad Widget

final GlobalKey<HistoryPageState> historyPageKey = GlobalKey<HistoryPageState>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Measurement State
  bool _isForegroundMonitoring = false;

  double _currentDb = 0.0;
  double _minDb = 0.0;
  double _maxDb = 0.0;
  double _avgDb = 0.0;
  double _calibrationOffset = 0.0;
  int _readingCount = 0;
  double _totalDb = 0.0;
  DateTime? _startTime;
  Timer? _timer;
  String _durationText = "00:00";
  String _selectedUnit = 'dB A';

  // Data for Graph and Storage
  List<double> _sessionPoints = [];
  List<FlSpot> _chartSpots = [];
  final int _windowSize = 300;

  // Settings
  bool _saveSession = true;

  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;

  @override
  void initState() {
    super.initState();
    _loadCalibration();
    _loadSaveSetting();
  }

  Future<void> _loadCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _calibrationOffset = prefs.getDouble('db_offset') ?? 0.0;
      _selectedUnit = prefs.getString('unit') ?? 'dB A';
    });
  }

  Future<void> _loadSaveSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _saveSession = prefs.getBool('save_session') ?? true;
    });
  }

  Future<void> _toggleSaveSession(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('save_session', value);
    setState(() {
      _saveSession = value;
    });
  }

  void _startMonitoring() async {
    try {
      _noiseMeter = NoiseMeter();
      _startTime = DateTime.now();
      _sessionPoints.clear();
      _chartSpots.clear();
      _readingCount = 0;
      _totalDb = 0.0;
      _minDb = 0.0;
      _maxDb = 0.0;
      _avgDb = 0.0;

      await _loadCalibration();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        final duration = DateTime.now().difference(_startTime!);
        final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
        setState(() {
          _durationText = "$minutes:$seconds";
        });
      });

      _noiseSubscription = _noiseMeter?.noise.listen(
            (NoiseReading noiseReading) {
          if (!mounted) return;

          double rawDb = noiseReading.meanDecibel;
          double unitOffset = _selectedUnit == 'dB C' ? 2.0 : 0.0;          double adjustedDb = (rawDb + _calibrationOffset + unitOffset).clamp(0.0, 120.0);

          setState(() {
            _currentDb = adjustedDb;
            _sessionPoints.add(adjustedDb);

            int index = _sessionPoints.length;
            _chartSpots.add(FlSpot(index.toDouble(), adjustedDb));
            if (_chartSpots.length > _windowSize) {
              _chartSpots.removeAt(0);
            }

            if (_readingCount == 0) {
              _minDb = adjustedDb;
              _maxDb = adjustedDb;
            } else {
              if (adjustedDb < _minDb) _minDb = adjustedDb;
              if (adjustedDb > _maxDb) _maxDb = adjustedDb;
            }

            _readingCount++;
            _totalDb += adjustedDb;
            _avgDb = _totalDb / _readingCount;
          });
        },
        onError: (Object error) {
          debugPrint('Noise Meter Error: $error');
        },
      );

      setState(() {
        _isForegroundMonitoring = true;
      });
    } catch (e) {
      debugPrint('Failed to start monitoring: $e');
    }
  }

  void _stopMonitoring() async {
    try {
      _noiseSubscription?.cancel();
      _timer?.cancel();

      if (_readingCount > 0) {
        if (_saveSession) {
          int duration = DateTime.now().difference(_startTime!).inSeconds;
          await DatabaseHelper().insertSession({
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'avg_db': _avgDb,
            'max_db': _maxDb,
            'duration': duration,
            'label': 'Manual Recording'
          }, _sessionPoints);

          historyPageKey.currentState?.loadHistory();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session saved to History')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session stopped (not saved)')),
            );
          }
        }
      }

      setState(() {
        _isForegroundMonitoring = false;
        _durationText = "00:00";
      });
    } catch (e) {
      debugPrint('Failed to stop monitoring: $e');
    }
  }

  Color _getStatusColor(double db) {
    if (db < 60) return Colors.green;
    if (db < 85) return Colors.amber;
    return Colors.red;
  }

  String _getStatusLabel(double db) {
    if (db < 60) return "Safe";
    if (db < 85) return "Moderate";
    return "Dangerous";
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      _loadCalibration();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _stopMonitoring();
    super.dispose();
  }

  Widget _buildLiveMeter() {
    Color statusColor = _getStatusColor(_currentDb);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Recording Timer Indicator
                if (_isForegroundMonitoring)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          "Recording: $_durationText",
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                // Gauge
                Expanded(
                  flex: 3,
                  child: SfRadialGauge(
                    axes: <RadialAxis>[
                      RadialAxis(
                        minimum: 0,
                        maximum: 120,
                        startAngle: 180,
                        endAngle: 0,
                        showLabels: true,
                        showTicks: true,
                        interval: 20,
                        axisLineStyle: const AxisLineStyle(
                          thickness: 10,
                          cornerStyle: CornerStyle.bothCurve,
                          color: Color.fromARGB(30, 150, 150, 150),
                        ),
                        ranges: <GaugeRange>[
                          GaugeRange(startValue: 0, endValue: 60, color: Colors.green, startWidth: 10, endWidth: 10),
                          GaugeRange(startValue: 60, endValue: 85, color: Colors.amber, startWidth: 10, endWidth: 10),
                          GaugeRange(startValue: 85, endValue: 120, color: Colors.red, startWidth: 10, endWidth: 10),
                        ],
                        pointers: <GaugePointer>[
                          NeedlePointer(
                            value: _currentDb,
                            needleColor: statusColor,
                            needleLength: 0.8,
                            knobStyle: const KnobStyle(color: Colors.white),
                          )
                        ],
                        annotations: <GaugeAnnotation>[
                          GaugeAnnotation(
                            positionFactor: 0.5,
                            angle: 90,
                            widget: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentDb.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                Text(
                                  _selectedUnit,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: statusColor,
                                  ),
                                ),
                                Text(
                                  _getStatusLabel(_currentDb),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),

                // Graph
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10, top: 10),
                    padding: const EdgeInsets.only(right: 16, top: 10),
                    child: LineChart(
                      LineChartData(
                        clipData: const FlClipData.all(),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.black.withOpacity(0.8),
                            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                              return touchedBarSpots.map((barSpot) {
                                return LineTooltipItem(
                                  barSpot.y.toStringAsFixed(1),
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          getDrawingHorizontalLine: (value) => FlLine(
                              color: Theme.of(context).dividerColor.withOpacity(0.5), strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 40,
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
                              ),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: Theme.of(context).dividerColor)),
                        minY: 0,
                        maxY: 120,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _chartSpots,
                            isCurved: true,
                            color: Colors.blueAccent,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Save Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Save Recording to History", style: TextStyle(fontWeight: FontWeight.bold)),
                    Switch(
                      value: _saveSession,
                      onChanged: _toggleSaveSession,
                    ),
                  ],
                ),

                // Stats
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("Min", _minDb),
                      Container(width: 1, height: 30, color: Theme.of(context).dividerColor),
                      _buildStatItem("Avg", _avgDb),
                      Container(width: 1, height: 30, color: Theme.of(context).dividerColor),
                      _buildStatItem("Peak", _maxDb),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Start Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isForegroundMonitoring ? _stopMonitoring : _startMonitoring,
                    icon: Icon(_isForegroundMonitoring ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      _isForegroundMonitoring ? "STOP" : "START",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isForegroundMonitoring ? Colors.redAccent : Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isRecording = _isForegroundMonitoring;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NoiseSense'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.circle,
              color: isRecording ? Colors.green : Colors.grey,
              size: 16,
            ),
            onPressed: null,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                _selectedIndex = 3;
              });
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildLiveMeter(),
          HistoryPage(key: historyPageKey),
          const ReportsPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.mic),
                label: 'Meter',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        ],
      ),
    );
  }
}
