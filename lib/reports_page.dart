import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart'; 

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTimeRange? _selectedDateRange;
  String _reportType = 'Summary'; // 'Summary' or 'Detailed'

  @override
  void initState() {
    super.initState();
    // Default to last 7 days
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _generatePdf() async {
    // 1. Fetch Real Data from Database
    final allSessions = await DatabaseHelper().getSessions();
    
    // 2. Filter by Date Range
    final filteredSessions = allSessions.where((session) {
      final date = DateTime.fromMillisecondsSinceEpoch(session['timestamp']);
      return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
             date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
    }).toList();

    if (filteredSessions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('No data found for selected range.')),
        );
      }
      return;
    }

    // 3. Calculate Stats
    double totalAvg = 0;
    double maxPeak = 0;
    double minNoise = 120;
    int totalDuration = 0;

    for (var session in filteredSessions) {
      totalAvg += session['avg_db'];
      if (session['max_db'] > maxPeak) maxPeak = session['max_db'];
      // Note: 'history' table doesn't store min_db per session, only avg/max.
      // We can approximate or just track global min of avgs, 
      // OR we would need to query 'measurements' table for exact min which is expensive for reports.
      // For now, let's use the lowest avg as a proxy or just keep global min logic.
      if (session['avg_db'] < minNoise) minNoise = session['avg_db']; 
      totalDuration += (session['duration'] as int);
    }
    double overallAvg = totalAvg / filteredSessions.length;
    if (minNoise == 120) minNoise = 0; 

    final String startDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
    final String endDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
    
    final pdf = pw.Document();

    // 4. Create PDF Content
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NoiseSense Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Generated: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Report Type: $_reportType', style: const pw.TextStyle(fontSize: 18)),
              pw.Text('Period: $startDate to $endDate', style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 30),
              
              pw.Text('Summary Statistics', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Metric', 'Value'],
                  <String>['Average Noise Level', '${overallAvg.toStringAsFixed(1)} dB'],
                  <String>['Peak Noise Level', '${maxPeak.toStringAsFixed(1)} dB'],
                  <String>['Lowest Average', '${minNoise.toStringAsFixed(1)} dB'],
                  <String>['Total Duration', '${(totalDuration / 60).toStringAsFixed(1)} min'],
                  <String>['Total Sessions', '${filteredSessions.length}'],
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              if (_reportType == 'Detailed') ...[
                pw.Text('Session Log', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  context: context,
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  data: <List<String>>[
                    <String>['Date', 'Time', 'Avg (dB)', 'Max (dB)', 'Duration'],
                    ...filteredSessions.map((session) {
                      final date = DateTime.fromMillisecondsSinceEpoch(session['timestamp']);
                      return <String>[
                        DateFormat('yyyy-MM-dd').format(date),
                        DateFormat('HH:mm').format(date),
                        session['avg_db'].toStringAsFixed(1),
                        session['max_db'].toStringAsFixed(1),
                        '${session['duration']}s',
                      ];
                    }).toList(),
                  ],
                ),
              ],
              
              pw.SizedBox(height: 40),
              pw.Footer(
                title: pw.Text('Generated by NoiseSense App', style: const pw.TextStyle(color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    // Save and Share/Open
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Report')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a Noise Report',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate a PDF report for compliance or record keeping.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              
              // Date Range Selector
              const Text('Date Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _selectDateRange(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.blueAccent),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Report Type Selector
              const Text('Report Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Summary'),
                      value: 'Summary',
                      groupValue: _reportType,
                      onChanged: (value) {
                        setState(() {
                          _reportType = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Detailed'),
                      value: 'Detailed',
                      groupValue: _reportType,
                      onChanged: (value) {
                        setState(() {
                          _reportType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 50),
              
              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _generatePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text(
                    'Generate & Share PDF',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
