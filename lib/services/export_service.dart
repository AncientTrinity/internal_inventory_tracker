// Update lib/services/export_service.dart with web-compatible export:

import 'dart:html' as html; // For web file download
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';

class ExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');

  // Export assets to CSV (web-compatible)
  static Future<void> exportAssetsToCsv(List<Asset> assets, String fileName) async {
    try {
      // Create CSV data
      final List<List<dynamic>> csvData = [];
      
      csvData.add([
        'Internal ID',
        'Asset Type',
        'Manufacturer',
        'Model',
        'Model Number',
        'Serial Number',
        'Status',
        'Assigned To',
        'Assigned Email',
        'Purchase Date',
        'Last Service',
        'Next Service',
        'Created At',
        'Updated At',
      ]);

      for (final asset in assets) {
        csvData.add([
          asset.internalId,
          asset.typeDisplay,
          asset.manufacturer,
          asset.model,
          asset.modelNumber,
          asset.serialNumber,
          asset.statusDisplay,
          asset.assignedToName ?? 'Not Assigned',
          asset.assignedToEmail ?? '',
          asset.datePurchased != null 
              ? DateFormat('yyyy-MM-dd').format(asset.datePurchased!)
              : '',
          asset.lastServiceDate != null
              ? DateFormat('yyyy-MM-dd').format(asset.lastServiceDate!)
              : '',
          asset.nextServiceDate != null
              ? DateFormat('yyyy-MM-dd').format(asset.nextServiceDate!)
              : '',
          DateFormat('yyyy-MM-dd HH:mm').format(asset.createdAt),
          DateFormat('yyyy-MM-dd HH:mm').format(asset.updatedAt),
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvData);
      
      // Generate filename with timestamp
      final timestamp = _dateFormat.format(DateTime.now());
      final fullFileName = '${fileName}_$timestamp.csv';


      // Web-compatible file download
      _downloadFile(csvString, fullFileName, 'text/csv');

    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  final Map<String, String> _formatOptions = {
    'csv': 'CSV (Excel compatible)',
    'pdf': 'Text Report (Printable)',
  };

  // Export assets to PDF/TXT (web-compatible)
  static Future<void> exportAssetsToPdf(List<Asset> assets, String fileName) async {
    try {
      final StringBuffer content = StringBuffer();
      
      // Report Header
      content.writeln('ASSET INVENTORY REPORT');
      content.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
      content.writeln('Total Assets: ${assets.length}');
      content.writeln('=' * 50);
      content.writeln();

      // Asset data
      for (final asset in assets) {
        content.writeln('Internal ID: ${asset.internalId}');
        content.writeln('Type: ${asset.typeDisplay}');
        content.writeln('Manufacturer: ${asset.manufacturer}');
        content.writeln('Model: ${asset.model}');
        content.writeln('Model Number: ${asset.modelNumber}');
        content.writeln('Serial Number: ${asset.serialNumber}');
        content.writeln('Status: ${asset.statusDisplay}');
        content.writeln('Assigned To: ${asset.assignedToName ?? "Not Assigned"}');
        content.writeln('Assigned Email: ${asset.assignedToEmail ?? ""}');
        
        if (asset.datePurchased != null) {
          content.writeln('Purchase Date: ${DateFormat('yyyy-MM-dd').format(asset.datePurchased!)}');
        }
        
        if (asset.needsService) {
          content.writeln('⚠️ NEEDS SERVICE (Due: ${DateFormat('yyyy-MM-dd').format(asset.nextServiceDate!)})');
        }
        
        content.writeln('-' * 40);
        content.writeln();
      }

      // Generate filename with timestamp
      final timestamp = _dateFormat.format(DateTime.now());
      final fullFileName = '${fileName}_$timestamp.txt';

      // Web-compatible file download
      _downloadFile(content.toString(), fullFileName, 'text/plain');

    } catch (e) {
      throw Exception('Failed to export report: $e');
    }
  }

  // Web-compatible file download
  static void _downloadFile(String content, String fileName, String mimeType) {
    // Create a blob and download link
    final blob = html.Blob([content], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    
    // Clean up
    html.Url.revokeObjectUrl(url);
  }

  // Export filtered assets with current filters applied
  static Future<void> exportFilteredAssets({
    required List<Asset> allAssets,
    required AssetFilters filters,
    required String format, // 'csv' or 'pdf'
    required String fileName,
  }) async {
    // Apply the same filters as the UI
    var filteredAssets = allAssets;

    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final query = filters.searchQuery!.toLowerCase();
      filteredAssets = filteredAssets.where((asset) =>
          asset.internalId.toLowerCase().contains(query) ||
          asset.manufacturer.toLowerCase().contains(query) ||
          asset.model.toLowerCase().contains(query) ||
          asset.serialNumber.toLowerCase().contains(query) ||
          asset.assetType.toLowerCase().contains(query)).toList();
    }

    if (filters.assetType != null && filters.assetType!.isNotEmpty) {
      filteredAssets = filteredAssets.where((asset) => asset.assetType == filters.assetType).toList();
    }

    if (filters.status != null && filters.status!.isNotEmpty) {
      filteredAssets = filteredAssets.where((asset) => asset.status == filters.status).toList();
    }

    if (filters.manufacturer != null && filters.manufacturer!.isNotEmpty) {
      filteredAssets = filteredAssets.where((asset) => asset.manufacturer == filters.manufacturer).toList();
    }

    if (filters.inUseBy != null) {
      filteredAssets = filteredAssets.where((asset) => asset.inUseBy == filters.inUseBy).toList();
    }

    if (filters.needsService == true) {
      filteredAssets = filteredAssets.where((asset) => asset.needsService).toList();
    }

    if (filters.assignmentStatus != null) {
      if (filters.assignmentStatus == 'assigned') {
        filteredAssets = filteredAssets.where((asset) => asset.isAssigned).toList();
      } else if (filters.assignmentStatus == 'unassigned') {
        filteredAssets = filteredAssets.where((asset) => !asset.isAssigned).toList();
      }
    }

    // Export the filtered assets
    if (format == 'csv') {
      await exportAssetsToCsv(filteredAssets, fileName);
    } else {
      await exportAssetsToPdf(filteredAssets, fileName);
    }
  }
}