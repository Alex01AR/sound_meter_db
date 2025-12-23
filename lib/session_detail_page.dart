import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'database_helper.dart';

class SessionDetailPage extends StatefulWidget {
  final int sessionId;
  final Map<String, dynamic> sessionData;

  const SessionDetailPage({super.key, required this.sessionId, required this.sessionData});

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  List<FlSpot> _sessionSpots = [];
  bool _isLoading = true;
  double _minDb = 0.0;
  double _maxDb = 0.0;
  double _totalDuration = 0.0;

  // Graph control
  double _sliderValue = 0.0;
  double _visibleSeconds = 10.0; // Initial visible window
  double _maxSliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSessionDetails();
  }

  Future<void> _loadSessionDetails() async {
    final points = await DatabaseHelper().getSessionPoints(widget.sessionId);
    if (points.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    double min = 120.0, max = 0.0;
    List<FlSpot> spots = [];
    _totalDuration = widget.sessionData['duration'].toDouble();

    for (int i = 0; i < points.length; i++) {
      double decibel = points[i]['decibel'];
      if (decibel < min) min = decibel;
      if (decibel > max) max = decibel;
      double timeX = (i / (points.length - 1)) * _totalDuration;
      spots.add(FlSpot(timeX, decibel));
    }

    if (mounted) {
      setState(() {
        _sessionSpots = spots;
        _minDb = min;
        _maxDb = max;
        _updateSlider();
        _isLoading = false;
      });
    }
  }

  void _updateSlider() {
    _maxSliderValue = _totalDuration > _visibleSeconds ? _totalDuration - _visibleSeconds : 0.0;
    _sliderValue = min(_sliderValue, _maxSliderValue);
  }

  // Zoom In: DECREASE visible time (more detail)
  void _zoomIn() {
    setState(() {
      _visibleSeconds = max(2.0, _visibleSeconds / 1.5); 
      _updateSlider();
    });
  }

  // Zoom Out: INCREASE visible time (less detail)
  void _zoomOut() {
    setState(() {
      _visibleSeconds = min(_totalDuration, _visibleSeconds * 1.5);
      _updateSlider();
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(widget.sessionData['timestamp']);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMM dd, yyyy - HH:mm').format(date)),
        actions: [
          // Swap icons to match intuitive logic
          IconButton(icon: const Icon(Icons.zoom_in), onPressed: _zoomIn), 
          IconButton(icon: const Icon(Icons.zoom_out), onPressed: _zoomOut),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessionSpots.isEmpty
              ? const Center(child: Text('No detailed data found for this session.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Cards
                      Row(
                        children: [
                          _buildStatCard('Min', _minDb.toStringAsFixed(1), Colors.blue),
                          const SizedBox(width: 10),
                          _buildStatCard('Avg', widget.sessionData['avg_db'].toStringAsFixed(1), Colors.green),
                          const SizedBox(width: 10),
                          _buildStatCard('Max', _maxDb.toStringAsFixed(1), Colors.red),
                          const SizedBox(width: 10),
                          _buildStatCard('Time', '${widget.sessionData['duration']}s', Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Full Graph
                      const Text(
                        'Noise Level Over Time',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 220, // Keep the height you liked
                        child: LineChart(
                          LineChartData(
                            clipData: const FlClipData.all(),
                            minX: _sliderValue,
                            maxX: _sliderValue + _visibleSeconds,
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                tooltipBgColor: Colors.black.withAlpha(204), // withOpacity(0.8)
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      '${spot.y.toStringAsFixed(1)} dB', 
                                      const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withAlpha(51), strokeWidth: 1), // withOpacity(0.2)
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 20,
                                  getTitlesWidget: (value, meta) => Text('${value.toInt()} dB', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) => Text('${value.toInt()}s', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  interval: max(1.0, (_visibleSeconds / 5).floorToDouble()), 
                                  reservedSize: 22,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                            minY: 0,
                            maxY: 120,
                            lineBarsData: [
                              LineChartBarData(
                                spots: _sessionSpots,
                                isCurved: false,
                                gradient: const LinearGradient(
                                  colors: [Colors.green, Colors.yellow, Colors.red],
                                  stops: [0.0, 0.5, 1.0],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Scrollbar Slider
                      if (_maxSliderValue > 0)
                        Slider(
                          value: _sliderValue,
                          min: 0,
                          max: _maxSliderValue,
                          label: '${_sliderValue.toStringAsFixed(1)}s',
                          onChanged: (value) {
                            setState(() {
                              _sliderValue = value;
                            });
                          },
                        ),
                       // To fill remaining space if slider is not present
                      if (_maxSliderValue <= 0) const Spacer(), 
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(25), // withOpacity(0.1)
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(128)), // withOpacity(0.5)
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
