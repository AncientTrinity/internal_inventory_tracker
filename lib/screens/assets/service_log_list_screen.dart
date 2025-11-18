// filename: lib/screens/assets/service_log_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/service_log.dart';
import '../../models/asset.dart';
import '../../providers/service_log_provider.dart';
import '../../providers/auth_provider.dart';
import 'service_log_form_screen.dart';

class ServiceLogListScreen extends StatefulWidget {
  final Asset asset;

  const ServiceLogListScreen({super.key, required this.asset});

  @override
  State<ServiceLogListScreen> createState() => _ServiceLogListScreenState();
}

class _ServiceLogListScreenState extends State<ServiceLogListScreen> {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _loadServiceLogs();
  }

  Future<void> _loadServiceLogs() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serviceLogProvider =
        Provider.of<ServiceLogProvider>(context, listen: false);

    if (authProvider.authData != null) {
      await serviceLogProvider.loadServiceLogsForAsset(
        widget.asset.id,
        authProvider.authData!.token,
      );
    }
  }

  Future<void> _refreshServiceLogs() async {
    await _loadServiceLogs();
  }

  void _showServiceLogActions(ServiceLog serviceLog) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              _showServiceLogDetails(serviceLog);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Log'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceLogFormScreen(
                    asset: widget.asset,
                    existingServiceLog: serviceLog,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title:
                const Text('Delete Log', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteDialog(serviceLog);
            },
          ),
        ],
      ),
    );
  }

  void _showServiceLogDetails(ServiceLog serviceLog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(serviceLog.serviceTypeDisplay),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem(
                  'Service Date', _dateFormat.format(serviceLog.serviceDate)),
              _buildDetailItem('Description', serviceLog.descriptionDisplay),
              _buildDetailItem('Performed By', serviceLog.performedBy.toString()), // Add .toString()
              if (serviceLog.cost != null)
                _buildDetailItem(
                    'Cost', '\$${serviceLog.cost!.toStringAsFixed(2)}'),
              if (serviceLog.notes != null && serviceLog.notes!.isNotEmpty)
                _buildDetailItem('Notes', serviceLog.notes!),
              _buildDetailItem(
                  'Created', _dateFormat.format(serviceLog.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showDeleteDialog(ServiceLog serviceLog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service Log'),
        content: Text(
          'Are you sure you want to delete this ${serviceLog.serviceTypeDisplay.toLowerCase()} record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteServiceLog(serviceLog);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteServiceLog(ServiceLog serviceLog) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final serviceLogProvider =
          Provider.of<ServiceLogProvider>(context, listen: false);

      await serviceLogProvider.deleteServiceLog(
        serviceLog.id,
        authProvider.authData!.token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service log deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete service log: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNotImplementedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature will be implemented in the next phase'),
        backgroundColor: Colors.blue,
      ),
    );
  }

Widget _buildServiceLogItem(ServiceLog serviceLog) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: serviceLog.serviceTypeColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getServiceTypeIcon(serviceLog.serviceType),
          color: serviceLog.serviceTypeColor,
        ),
      ),
      title: Text(
        serviceLog.serviceTypeDisplay,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(serviceLog.descriptionDisplay), // FIXED: Use descriptionDisplay
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                serviceLog.performedBy.toString(), // FIXED: Add .toString()
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _dateFormat.format(serviceLog.serviceDate),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          if (serviceLog.cost != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 12, color: Colors.green[600]),
                const SizedBox(width: 4),
                Text(
                  '\$${serviceLog.cost!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.more_vert),
      onTap: () => _showServiceLogDetails(serviceLog),
      onLongPress: () => _showServiceLogActions(serviceLog),
    ),
  );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Service History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No service records found for this asset.\nAdd the first service log to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ServiceLogFormScreen(asset: widget.asset),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Service Log'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final serviceLogProvider = Provider.of<ServiceLogProvider>(context);
    final logs = serviceLogProvider.serviceLogs;

    if (logs.isEmpty) return const SizedBox();

    final totalCost = logs.fold(0.0, (sum, log) => sum + (log.cost ?? 0));
    final recentLogs = logs
        .where((log) => log.serviceDate
            .isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Services', logs.length.toString()),
            _buildStatItem('Recent (30d)', recentLogs.toString()),
            _buildStatItem('Total Cost', '\$${totalCost.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  IconData _getServiceTypeIcon(String serviceType) {
    switch (serviceType) {
      case 'PREVENTIVE_MAINTENANCE':
        return Icons.build_circle;
      case 'REPAIR':
        return Icons.handyman;
      case 'INSPECTION':
        return Icons.search;
      case 'CALIBRATION':
        return Icons.tune;
      default:
        return Icons.construction;
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceLogProvider = Provider.of<ServiceLogProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Service History - ${widget.asset.internalId}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                serviceLogProvider.isLoading ? null : _refreshServiceLogs,
            tooltip: 'Refresh',
          ),
         IconButton(
  icon: const Icon(Icons.add),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceLogFormScreen(asset: widget.asset),
      ),
    );
  },
  tooltip: 'Add Service Log',
),
        ],
      ),
      body: serviceLogProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshServiceLogs,
              child: Column(
                children: [
                  // Statistics
                  _buildStatistics(),

                  // Service Logs List
                  Expanded(
                    child: serviceLogProvider.serviceLogs.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: serviceLogProvider.serviceLogs.length,
                            itemBuilder: (context, index) {
                              final serviceLog =
                                  serviceLogProvider.serviceLogs[index];
                              return _buildServiceLogItem(serviceLog);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
