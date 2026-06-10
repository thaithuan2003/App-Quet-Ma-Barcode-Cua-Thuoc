import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_error.dart';
import '../models/report_summary.dart';
import '../services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportService _service = ReportService(widget.apiClient);
  late Future<ReportSummary> _future = _service.summary();

  void _reload() {
    setState(() => _future = _service.summary());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReportSummary>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return AppError(message: error is ApiException ? error.message : 'Khong tai duoc bao cao.', onRetry: _reload);
        }
        final report = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: GridView.count(
            padding: const EdgeInsets.all(12),
            crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
            childAspectRatio: 1.25,
            children: [
              _ReportCard(title: 'Thuoc', value: report.medicineCount.toString(), icon: Icons.medication_outlined),
              _ReportCard(title: 'Lo thuoc', value: report.batchCount.toString(), icon: Icons.numbers),
              _ReportCard(title: 'Tong ton', value: report.totalInventoryQuantity.toString(), icon: Icons.inventory_2_outlined),
              _ReportCard(title: 'Ton thap', value: report.lowStockCount.toString(), icon: Icons.warning_amber),
              _ReportCard(title: 'Da het han', value: report.expiredBatchCount.toString(), icon: Icons.event_busy),
              _ReportCard(title: 'Sap het han', value: report.nearExpiryBatchCount.toString(), icon: Icons.event),
              _ReportCard(title: 'Quet hom nay', value: report.todayScanCount.toString(), icon: Icons.qr_code_scanner),
              _ReportCard(title: 'Ban hom nay', value: report.todaySaleQuantity.toString(), icon: Icons.point_of_sale),
            ],
          ),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
