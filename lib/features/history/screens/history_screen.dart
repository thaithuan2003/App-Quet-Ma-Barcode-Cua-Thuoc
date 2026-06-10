import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_error.dart';
import '../../medicine/services/medicine_service.dart';
import '../../medicine/screens/medicine_detail_screen.dart';
import '../models/scan_result.dart';
import '../services/scan_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final ScanService _scanService = ScanService(widget.apiClient);
  late final MedicineService _medicineService = MedicineService(widget.apiClient);
  late Future<List<ScanResult>> _future = _scanService.history();

  void _reload() {
    setState(() => _future = _scanService.history());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ScanResult>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return AppError(message: error is ApiException ? error.message : 'Khong tai duoc lich su.', onRetry: _reload);
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Chua co lich su quet.'));
        }
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final medicine = item.medicine;
              return Card(
                child: ListTile(
                  leading: Icon(item.found ? Icons.check_circle_outline : Icons.help_outline),
                  title: Text(medicine?.name ?? 'Barcode khong tim thay'),
                  subtitle: Text(medicine?.barcode ?? item.message),
                  trailing: medicine == null ? null : const Icon(Icons.chevron_right),
                  onTap: medicine == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MedicineDetailScreen(medicine: medicine, service: _medicineService),
                            ),
                          );
                        },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
