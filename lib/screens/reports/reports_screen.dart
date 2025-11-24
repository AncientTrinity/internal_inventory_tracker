// filename: lib/screens/reports/reports_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:html' as html; // Add this for web
import 'package:flutter/foundation.dart'; // For kIsWeb

import '../../providers/reports_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/report.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _initialLoadComplete = false;
  bool _showDebugInfo = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReportData();
    });
  }

  Future<void> _loadReportData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);

    if (authProvider.authData != null) {
      await reportsProvider.loadReportData(authProvider.authData!.token);
      if (mounted) {
        setState(() {
          _initialLoadComplete = true;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);

    if (authProvider.authData != null) {
      await reportsProvider.loadReportData(authProvider.authData!.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = Provider.of<ReportsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final reportData = reportsProvider.reportData;

    return Scaffold(
      appBar: _ReportsAppBar(
        onFilter: () => _showFilterDialog(reportsProvider),
        onExport: reportsProvider.isLoading ? null : _exportReport,
        onRefresh: reportsProvider.isLoading ? null : _refreshData,
        onDebug: () => setState(() => _showDebugInfo = !_showDebugInfo),
        showDebug: _showDebugInfo,
         isExporting: _isExporting,
      ),
      body: _buildBody(reportsProvider, authProvider, reportData),
    );
  }

  Widget _buildBody(ReportsProvider reportsProvider, AuthProvider authProvider, ReportData? reportData) {
    if (!_initialLoadComplete && reportsProvider.isLoading) {
      return _buildLoadingState('Loading report data...');
    }

    if (authProvider.authData == null) {
      return _buildErrorState('Authentication Required', 'Please login to view reports', Icons.login);
    }

    if (reportsProvider.error != null) {
      return _buildErrorState('Error Loading Reports', reportsProvider.error!, Icons.error);
    }

    if (reportsProvider.isLoading) {
      return Stack(
        children: [
          _buildContent(reportData),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    return _buildContent(reportData);
  }

  Widget _buildContent(ReportData? reportData) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDebugInfo(),
            _buildFilterSummary(context.watch<ReportsProvider>()),
            const SizedBox(height: 20),
            _buildKeyMetrics(context.watch<ReportsProvider>()),
            const SizedBox(height: 20),
            if (reportData != null) ...[
              _buildTicketStatusChart(reportData),
              const SizedBox(height: 20),
              _buildAssetUtilizationChart(reportData),
              const SizedBox(height: 20),
              _buildTicketTrendsChart(reportData),
              const SizedBox(height: 20),
              _buildPriorityDistributionChart(reportData),
            ],
            if (reportData == null && _initialLoadComplete) 
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    final reportsProvider = context.watch<ReportsProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (!_showDebugInfo) return const SizedBox();

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔍 Debug Information', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Initial Load Complete: $_initialLoadComplete'),
            Text('Loading: ${reportsProvider.isLoading}'),
            Text('Error: ${reportsProvider.error ?? "None"}'),
            Text('Report Data: ${reportsProvider.reportData != null ? "Available" : "Null"}'),
            Text('Auth Data: ${authProvider.authData != null ? "Available" : "Null"}'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSummary(ReportsProvider provider) {
    final filter = provider.currentFilter;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Period',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_formatDate(filter.startDate)} - ${_formatDate(filter.endDate)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (filter.assetType != null || filter.ticketType != null || filter.priority != null)
                    Text(
                      _buildActiveFilters(filter),
                      style: TextStyle(color: Colors.blue[600], fontSize: 12),
                    ),
                ],
              ),
            ),
            Chip(
              label: Text('${_calculateDays(filter)} days'),
              backgroundColor: Colors.blue[50],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(ReportsProvider provider) {
    final stats = provider.computedStats;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard(
          'Ticket Resolution Rate',
          '${stats['ticket_resolution_rate']?.toStringAsFixed(1) ?? '0'}%',
          Icons.check_circle,
          Colors.green,
        ),
        _buildMetricCard(
          'Asset Utilization',
          '${stats['asset_utilization_rate']?.toStringAsFixed(1) ?? '0'}%',
          Icons.computer,
          Colors.blue,
        ),
        _buildMetricCard(
          'Avg. Resolution Time',
          '${stats['avg_ticket_resolution_time']?.toStringAsFixed(1) ?? '0'}h',
          Icons.access_time,
          Colors.orange,
        ),
        _buildMetricCard(
          'Critical Tickets',
          '${stats['critical_ticket_percentage']?.toStringAsFixed(1) ?? '0'}%',
          Icons.warning,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildTicketStatusChart(ReportData reportData) {
    final ticketStats = reportData.ticketStats;
    final sections = [
      _ChartSection('Open', ticketStats['open'] ?? 0, Colors.orange, Icons.circle),
      _ChartSection('In Progress', ticketStats['in_progress'] ?? 0, Colors.blue, Icons.autorenew),
      _ChartSection('Resolved', ticketStats['resolved'] ?? 0, Colors.green, Icons.check),
      _ChartSection('Closed', ticketStats['closed'] ?? 0, Colors.grey, Icons.lock),
    ];

    return _buildChartCard(
      'Ticket Status Distribution',
      Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(sections),
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend(sections),
        ],
      ),
    );
  }

  Widget _buildAssetUtilizationChart(ReportData reportData) {
    final assetStats = reportData.assetStats;
    final sections = [
      _ChartSection('In Use', assetStats['in_use'] ?? 0, Colors.blue, Icons.computer),
      _ChartSection('In Storage', assetStats['in_storage'] ?? 0, Colors.green, Icons.storage),
      _ChartSection('In Repair', assetStats['in_repair'] ?? 0, Colors.orange, Icons.build),
      _ChartSection('Retired', assetStats['retired'] ?? 0, Colors.red, Icons.delete),
    ];

    return _buildChartCard(
      'Asset Utilization',
      Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(sections),
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend(sections),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(List<_ChartSection> sections) {
    final total = sections.fold(0, (sum, section) => sum + section.value);
    
    return sections.map((section) {
      final percentage = total > 0 ? (section.value / total * 100) : 0;
      
      return PieChartSectionData(
        color: section.color,
        value: section.value.toDouble(),
        title: section.value > 0 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildTicketTrendsChart(ReportData reportData) {
    final trends = reportData.ticketTrends;
    final spots = trends.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['count'] ?? 0).toDouble(),
      );
    }).toList();

    final resolvedSpots = trends.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['resolved_count'] ?? 0).toDouble(),
      );
    }).toList();

    return _buildChartCard(
      'Ticket Trends (Last 30 Days)',
      Column(
        children: [
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: spots.isNotEmpty ? spots.length - 1.toDouble() : 10,
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
                  ),
                  LineChartBarData(
                    spots: resolvedSpots,
                    isCurved: true,
                    color: Colors.green,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLineChartLegend(),
        ],
      ),
    );
  }

  Widget _buildPriorityDistributionChart(ReportData reportData) {
    final ticketStats = reportData.ticketStats;
    final sections = [
      _ChartSection('Critical', ticketStats['critical'] ?? 0, Colors.red, Icons.warning),
      _ChartSection('High', ticketStats['high'] ?? 0, Colors.orange, Icons.error),
      _ChartSection('Normal', ticketStats['normal'] ?? 0, Colors.blue, Icons.info),
      _ChartSection('Low', ticketStats['low'] ?? 0, Colors.green, Icons.low_priority),
    ];

    final maxY = sections.fold(0, (max, section) => section.value > max ? section.value : max).toDouble();

    return _buildChartCard(
      'Ticket Priority Distribution',
      Column(
        children: [
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY > 0 ? maxY * 1.1 : 10,
                barGroups: sections.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        color: entry.value.color,
                        width: 20,
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sections.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              sections[index].label,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend(sections),
        ],
      ),
    );
  }

  Widget _buildChartLegend(List<_ChartSection> sections) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: sections.map((section) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: section.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${section.label} (${section.value})',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLineChartLegend() {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 3,
              color: Colors.blue,
            ),
            const SizedBox(width: 6),
            const Text(
              'Total Tickets',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 3,
              color: Colors.green,
            ),
            const SizedBox(width: 6),
            const Text(
              'Resolved Tickets',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            chart,
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildErrorState(String title, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReportData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Report Data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adjust your filters or generate some activity to see analytics',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReportData,
            child: const Text('Load Data'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(ReportsProvider provider) {
    final currentFilter = provider.currentFilter;
    DateTime startDate = currentFilter.startDate;
    DateTime endDate = currentFilter.endDate;
    String? selectedAssetType = currentFilter.assetType;
    String? selectedTicketType = currentFilter.ticketType;
    String? selectedPriority = currentFilter.priority;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Reports'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDateRangeField(startDate, endDate, setState),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    'Asset Type',
                    selectedAssetType,
                    ['PC', 'Monitor', 'Headset', 'Keyboard', 'Mouse', 'UPS'],
                    (value) => setState(() => selectedAssetType = value),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    'Ticket Type',
                    selectedTicketType,
                    ['it_help', 'activation', 'deactivation', 'transition'],
                    (value) => setState(() => selectedTicketType = value),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    'Priority',
                    selectedPriority,
                    ['low', 'normal', 'high', 'critical'],
                    (value) => setState(() => selectedPriority = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  provider.clearFilters();
                  _loadReportData();
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newFilter = ReportFilter(
                    startDate: startDate,
                    endDate: endDate,
                    assetType: selectedAssetType,
                    ticketType: selectedTicketType,
                    priority: selectedPriority,
                  );
                  provider.updateFilter(newFilter);
                  _loadReportData();
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateRangeField(DateTime startDate, DateTime endDate, Function setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => startDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_formatDate(startDate)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: startDate,
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => endDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_formatDate(endDate)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'All',
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('All')),
            ...options.map((option) => DropdownMenuItem(
              value: option,
              child: Text(StringCasingExtension(option.replaceAll('_', ' ')).toTitleCase()),
            )),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _exportReport() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);

    if (_isExporting) return;

    setState(() { _isExporting = true; });

    try {
      final csvData = await reportsProvider.exportReport(authProvider.authData!.token);
      final fileName = 'inventory_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final fileData = utf8.encode(csvData);

      // For web - use browser download
      if (kIsWeb) {
        _downloadFileWeb(fileName, fileData);
      } else {
        // For mobile - save to documents
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(fileData);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report exported as $fileName'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() { _isExporting = false; });
      }
    }
  }

// Separate method for web download
  void _downloadFileWeb(String fileName, List<int> bytes) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;

    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  String _buildActiveFilters(ReportFilter filter) {
    List<String> activeFilters = [];
    if (filter.assetType != null) activeFilters.add('Asset: ${StringCasingExtension(filter.assetType!.replaceAll('_', ' ')).toTitleCase()}');
    if (filter.ticketType != null) activeFilters.add('Ticket: ${StringCasingExtension(filter.ticketType!.replaceAll('_', ' ')).toTitleCase()}');
    if (filter.priority != null) activeFilters.add('Priority: ${StringCasingExtension(filter.priority!).toTitleCase()}');
    return activeFilters.join(', ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _calculateDays(ReportFilter filter) {
    return filter.endDate.difference(filter.startDate).inDays;
  }
}

class _ReportsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onFilter;
  final VoidCallback? onExport;
  final VoidCallback? onRefresh;
  final VoidCallback? onDebug;
  final bool showDebug;
  final bool isExporting;

  const _ReportsAppBar({
    this.onFilter,
    this.onExport,
    this.onRefresh,
    this.onDebug,
    this.showDebug = false,
    this.isExporting = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Reports & Analytics'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      actions: [
        if (onDebug != null)
          IconButton(
            icon: Icon(showDebug ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: onDebug,
            tooltip: 'Toggle Debug Info',
          ),
        if (onFilter != null)
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: onFilter,
            tooltip: 'Filter Reports',
          ),
       if (onExport != null)
          IconButton(
            icon: isExporting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: isExporting ? null : onExport,
            tooltip: 'Export Report',
          ),
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
            tooltip: 'Refresh Data',
          ),
      ],
    );
  }
}

class _ChartSection {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  _ChartSection(this.label, this.value, this.color, this.icon);
}

extension StringCasingExtension on String {
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}' : '')
      .join(' ');
}