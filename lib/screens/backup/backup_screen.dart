import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../state/customers_controller.dart';
import '../../state/orders_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/backup_service.dart';
import '../../utils/csv_export.dart';
import '../../widgets/cut_card.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _service = BackupService();
  final _csvService = CsvExportService();
  bool _working = false;

  Future<void> _backup() async {
    setState(() => _working = true);
    try {
      final zipPath = await _service.createBackupZip();
      await Share.shareXFiles([XFile(zipPath)], text: 'Tessy Creations backup');
    } catch (e) {
      _showError('Couldn\'t create backup: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _exportCsv() async {
    final customersController = context.read<CustomersController>();
    final ordersController = context.read<OrdersController>();

    setState(() => _working = true);
    try {
      final paths = await _csvService.exportCsvFiles(
        customers: customersController.customers,
        orders: ordersController.orders,
        customerName: (id) => customersController.byId(id)?.name ?? 'Unknown',
      );
      await Share.shareXFiles(
        [for (final p in paths) XFile(p)],
        text: 'Tessy Creations data export',
      );
    } catch (e) {
      _showError('Couldn\'t export CSV: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _restore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: const Text(
          'This replaces every customer, order, and payment currently in the '
          'app with what\'s in this backup file. This can\'t be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Restore', style: TextStyle(color: AppColors.pin)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final customersController = context.read<CustomersController>();
    final ordersController = context.read<OrdersController>();

    setState(() => _working = true);
    try {
      await _service.restoreFromZip(path);
      await customersController.load();
      await ordersController.load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Backup restored.')));
    } on InvalidBackupException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Couldn\'t restore backup: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.pin),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: AbsorbPointer(
        absorbing: _working,
        child: Opacity(
          opacity: _working ? 0.6 : 1,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CutCard(
                accent: AppColors.thread,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Backup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text(
                      'Bundles every customer, order, payment, and photo into one file. '
                      'Save it to Google Drive, email it to yourself, or copy it to a '
                      'computer — anywhere you like, so it survives losing this phone.',
                      style: TextStyle(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _working ? null : _backup,
                      icon: const Icon(Icons.backup_outlined),
                      label: const Text('Create backup'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.thread),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CutCard(
                accent: AppColors.gold,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Restore', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text(
                      'Pick a backup file (e.g. on a new phone) to bring everything back. '
                      'This replaces all current data in the app.',
                      style: TextStyle(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _working ? null : _restore,
                      icon: const Icon(Icons.restore_outlined),
                      label: const Text('Choose backup file'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CutCard(
                accent: AppColors.dashedBorder,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export as spreadsheet',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Plain CSV files (customers, orders, payments) you can open in Excel, '
                      'Google Sheets, or send to an accountant. This is for reading your data '
                      'elsewhere, not for restoring the app — use Backup for that.',
                      style: TextStyle(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _working ? null : _exportCsv,
                      icon: const Icon(Icons.table_chart_outlined),
                      label: const Text('Export CSV'),
                    ),
                  ],
                ),
              ),
              if (_working) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
