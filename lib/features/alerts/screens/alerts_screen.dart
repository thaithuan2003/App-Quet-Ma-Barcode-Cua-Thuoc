import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_error.dart';
import '../models/alert_item.dart';
import '../services/alert_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late final AlertService _service = AlertService(widget.apiClient);
  late Future<List<AlertItem>> _future = _service.alerts();

  void _reload() {
    setState(() => _future = _service.alerts());
  }

  Color _colorFor(String severity) {
    if (severity.contains('Critical')) {
      return Colors.red.shade50;
    }
    if (severity.contains('Warning')) {
      return Colors.orange.shade50;
    }
    return Colors.blue.shade50;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AlertItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return AppError(message: error is ApiException ? error.message : 'Không tải được cảnh báo.', onRetry: _reload);
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Không có cảnh báo đang mở.'));
        }
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                color: _colorFor(item.severity),
                child: ListTile(
                  leading: const Icon(Icons.warning_amber),
                  title: Text(item.title),
                  subtitle: Text('${item.message}\nLoai: ${item.type}'),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
