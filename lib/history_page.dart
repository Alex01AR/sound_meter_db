import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; 
import 'database_helper.dart';
import 'session_detail_page.dart'; 

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  HistoryPageState createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final data = await DatabaseHelper().getSessions();
    if (mounted) {
      setState(() {
        _sessions = data;
        _isLoading = false;
        if (_isSelectionMode) {
           _selectedIds.removeWhere((id) => !data.any((element) => element['id'] == id));
           if (_selectedIds.isEmpty) {
             _isSelectionMode = false;
           }
        }
      });
    }
  }

  Future<void> _deleteSession(int id) async {
    await DatabaseHelper().deleteSession(id);
    loadHistory();
  }

  Future<void> _deleteSelectedSessions() async {
    for (int id in _selectedIds) {
      await DatabaseHelper().deleteSession(id);
    }
    _exitSelectionMode();
    loadHistory();
  }

  Future<void> _deleteAllSessions() async {
    if (_sessions.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All History'),
        content: const Text('Are you sure you want to delete ALL recordings? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper().clearAll();
      loadHistory();
      _exitSelectionMode();
    }
  }

  // Made public so SettingsPage can call it
  Future<void> exportCsv() async {
    List<Map<String, dynamic>> sessionsToExport;
    String exportMessage;

    if (_isSelectionMode && _selectedIds.isNotEmpty) {
      sessionsToExport = _sessions.where((s) => _selectedIds.contains(s['id'])).toList();
      exportMessage = 'NoiseSense Export (${sessionsToExport.length} selected)';
    } else {
      sessionsToExport = _sessions;
      exportMessage = 'NoiseSense Data Export (All)';
    }

    if (sessionsToExport.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('No data to export')),
        );
      }
      return;
    }

    List<List<dynamic>> rows = [];
    rows.add(["ID", "Timestamp", "Date", "Avg dB", "Max dB", "Duration (sec)", "Label"]);

    for (var session in sessionsToExport) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(session['timestamp']);
      rows.add([
        session['id'],
        session['timestamp'],
        DateFormat('yyyy-MM-dd HH:mm:ss').format(date),
        session['avg_db'],
        session['max_db'],
        session['duration'],
        session['label'] ?? ''
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/sound_history.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(file.path)], text: exportMessage);

    if (_isSelectionMode) {
      _exitSelectionMode();
    }
  }

  void _onLongPress(int id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _onTap(int id, Map<String, dynamic> session) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
          if (_selectedIds.isEmpty) {
            _isSelectionMode = false;
          }
        } else {
          _selectedIds.add(id);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionDetailPage(
            sessionId: session['id'],
            sessionData: session,
          ),
        ),
      );
    }
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          _exitSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _isSelectionMode
              ? IconButton(icon: const Icon(Icons.close), onPressed: _exitSelectionMode)
              : null,
          title: Text(_isSelectionMode ? '${_selectedIds.length} Selected' : 'History'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share), 
              onPressed: exportCsv, // Updated to use public method
              tooltip: _isSelectionMode ? 'Share Selected' : 'Share All',
            ),
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelectedSessions,
                tooltip: 'Delete Selected',
              )
            else
              IconButton( // Always show, disable if empty
                icon: const Icon(Icons.delete_forever),
                onPressed: _sessions.isNotEmpty ? _deleteAllSessions : null,
                tooltip: 'Delete All',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (!_isSelectionMode && _sessions.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: true, border: Border.all(color: Theme.of(context).dividerColor)),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _sessions.asMap().entries.map((e) {
                                  return FlSpot(e.key.toDouble(), e.value['avg_db']);
                                }).toList(),
                                isCurved: true,
                                color: Theme.of(context).primaryColor,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Theme.of(context).primaryColor.withAlpha(51), // withOpacity(0.2)
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  Expanded(
                    child: _sessions.isEmpty
                        ? const Center(child: Text('No history found.'))
                        : ListView.builder(
                            itemCount: _sessions.length,
                            itemBuilder: (context, index) {
                              final session = _sessions[index];
                              final DateTime date = DateTime.fromMillisecondsSinceEpoch(session['timestamp']);
                              final bool isSelected = _selectedIds.contains(session['id']);

                              Widget listItem = ListTile(
                                  leading: _isSelectionMode
                                      ? Icon(
                                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                                        )
                                      : CircleAvatar(
                                          backgroundColor: session['avg_db'] > 85 ? Colors.red : (session['avg_db'] > 60 ? Colors.amber : Colors.green),
                                          child: Text(
                                            session['avg_db'].round().toString(),
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                  title: Text(DateFormat('MMM dd, yyyy - HH:mm').format(date)),
                                  subtitle: Text('Max: ${session['max_db']} dB | Duration: ${session['duration']}s'),
                                  trailing: _isSelectionMode ? null : const Icon(Icons.chevron_right),
                                  selected: isSelected,
                                  selectedTileColor: Theme.of(context).primaryColor.withAlpha(25), // withOpacity(0.1)
                                  onLongPress: () => _onLongPress(session['id']),
                                  onTap: () => _onTap(session['id'], session),
                                );

                              if (_isSelectionMode) {
                                return listItem;
                              } else {
                                return Dismissible(
                                  key: Key(session['id'].toString()),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) {
                                    _deleteSession(session['id']);
                                  },
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  child: listItem,
                                );
                              }
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
