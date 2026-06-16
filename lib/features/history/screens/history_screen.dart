import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_error.dart';
import '../../medicine/screens/medicine_detail_screen.dart';
import '../../medicine/services/medicine_service.dart';
import '../models/scan_result.dart';
import '../services/scan_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final ScanService _service = ScanService(widget.apiClient);
  late final MedicineService _medicineService = MedicineService(widget.apiClient);
  late Future<List<ScanResult>> _future = _service.history();

  void _reload() {
    setState(() => _future = _service.history());
  }

  String _formatDateTime(String value) {
    if (value.isEmpty) return 'Chưa có thời gian';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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
          return AppError(message: error is ApiException ? error.message : 'Không tải được lịch sử quét.', onRetry: _reload);
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Chưa có lịch sử quét mã thuốc.'));
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
                  leading: Icon(
                    item.found ? Icons.qr_code_2_outlined : Icons.error_outline,
                    color: item.found ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                  ),
                  title: Text(medicine?.name ?? 'Không tìm thấy thuốc'),
                  subtitle: Text(
                    'Mã vạch: ${item.barcode.isEmpty ? medicine?.barcode ?? 'Không có' : item.barcode}\n'
                    'Thời gian quét: ${_formatDateTime(item.createdAt)}'
                    '${medicine == null ? '\n${item.message}' : '\nTồn: ${medicine.totalQuantity} - Giá: ${medicine.salePrice.toStringAsFixed(0)} VND'}',
                  ),
                  isThreeLine: true,
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
