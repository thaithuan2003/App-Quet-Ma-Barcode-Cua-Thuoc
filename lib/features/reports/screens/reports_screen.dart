import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/app_error.dart';
import '../../inventory/models/batch.dart';
import '../../medicine/models/medicine.dart';
import '../../medicine/screens/medicine_detail_screen.dart';
import '../../medicine/services/medicine_service.dart';
import '../models/report_scan.dart';
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
  late final MedicineService _medicineService = MedicineService(widget.apiClient);
  late Future<ReportSummary> _future = _service.summary();

  void _reload() {
    setState(() => _future = _service.summary());
  }

  void _openDetails(_ReportType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ReportDetailScreen(
          type: type,
          reportService: _service,
          medicineService: _medicineService,
        ),
      ),
    );
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
          return AppError(message: error is ApiException ? error.message : 'Không tải được báo cáo.', onRetry: _reload);
        }
        final report = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: GridView.count(
            padding: const EdgeInsets.all(12),
            crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
            childAspectRatio: 1.15,
            children: [
              _ReportCard(
                title: 'Thuốc',
                value: report.medicineCount.toString(),
                subtitle: 'Bao gồm số lượng tồn',
                icon: Icons.medication_outlined,
                onTap: () => _openDetails(_ReportType.medicines),
              ),
              _ReportCard(
                title: 'Lô thuốc',
                value: report.batchCount.toString(),
                subtitle: 'Danh sách theo lô',
                icon: Icons.inventory_2_outlined,
                onTap: () => _openDetails(_ReportType.batches),
              ),
              _ReportCard(
                title: 'Sắp hết hạn',
                value: report.nearExpiryBatchCount.toString(),
                subtitle: 'Trong 90 ngày tới',
                icon: Icons.event,
                onTap: () => _openDetails(_ReportType.nearExpiry),
              ),
              _ReportCard(
                title: 'Đã hết hạn',
                value: report.expiredBatchCount.toString(),
                subtitle: 'Cần xử lý ngay',
                icon: Icons.event_busy,
                onTap: () => _openDetails(_ReportType.expired),
              ),
              _ReportCard(
                title: 'Quét hôm nay',
                value: report.todayScanCount.toString(),
                subtitle: 'Số lượt quét mã',
                icon: Icons.qr_code_scanner,
                onTap: () => _openDetails(_ReportType.todayScans),
              ),
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
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const Spacer(),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportDetailScreen extends StatelessWidget {
  const _ReportDetailScreen({
    required this.type,
    required this.reportService,
    required this.medicineService,
  });

  final _ReportType type;
  final ReportService reportService;
  final MedicineService medicineService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(type.title)),
      body: switch (type) {
        _ReportType.medicines => _MedicinesReportList(
            future: reportService.medicines(),
            medicineService: medicineService,
          ),
        _ReportType.batches => _BatchesReportList(future: reportService.batches()),
        _ReportType.nearExpiry => _BatchesReportList(future: reportService.nearExpiryBatches()),
        _ReportType.expired => _BatchesReportList(future: reportService.expiredBatches()),
        _ReportType.todayScans => _ScansReportList(future: reportService.todayScans()),
      },
    );
  }
}

class _MedicinesReportList extends StatelessWidget {
  const _MedicinesReportList({
    required this.future,
    required this.medicineService,
  });

  final Future<List<Medicine>> future;
  final MedicineService medicineService;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Medicine>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const AppError(message: 'Không tải được danh sách thuốc.');
        }
        final medicines = snapshot.data ?? [];
        if (medicines.isEmpty) {
          return const Center(child: Text('Chưa có thuốc.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: medicines.length,
          itemBuilder: (context, index) {
            final medicine = medicines[index];
            return Card(
              child: ListTile(
                title: Text(medicine.name),
                subtitle: Text('Tồn kho: ${medicine.totalQuantity} - Đơn giá: ${medicine.salePrice.toStringAsFixed(0)} VND'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MedicineDetailScreen(medicine: medicine, service: medicineService),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _BatchesReportList extends StatelessWidget {
  const _BatchesReportList({required this.future});

  final Future<List<Batch>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Batch>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const AppError(message: 'Không tải được danh sách lô thuốc.');
        }
        final batches = snapshot.data ?? [];
        if (batches.isEmpty) {
          return const Center(child: Text('Không có dữ liệu.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: batches.length,
          itemBuilder: (context, index) {
            final batch = batches[index];
            final lowStockText = batch.quantity <= batch.lowStockThreshold ? ' - tồn thấp' : '';
            return Card(
              child: ListTile(
                title: Text(batch.medicineName),
                subtitle: Text(
                  'Lô: ${batch.batchNumber}\nTồn: ${batch.quantity}$lowStockText - Hạn dùng: ${AppDateUtils.formatDate(batch.expiryDate)}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

class _ScansReportList extends StatelessWidget {
  const _ScansReportList({required this.future});

  final Future<List<ReportScan>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReportScan>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const AppError(message: 'Không tải được danh sách quét hôm nay.');
        }
        final scans = snapshot.data ?? [];
        if (scans.isEmpty) {
          return const Center(child: Text('Hôm nay chưa có lượt quét.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: scans.length,
          itemBuilder: (context, index) {
            final scan = scans[index];
            return Card(
              child: ListTile(
                leading: Icon(scan.found ? Icons.check_circle_outline : Icons.help_outline),
                title: Text(scan.medicineName ?? 'Không tìm thấy thuốc'),
                subtitle: Text('Barcode: ${scan.barcode}\nThời gian: ${scan.createdAt}'),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

enum _ReportType {
  medicines('Thuốc'),
  batches('Lô thuốc'),
  nearExpiry('Thuốc sắp hết hạn'),
  expired('Thuốc đã hết hạn'),
  todayScans('Số thuốc quét hôm nay');

  const _ReportType(this.title);

  final String title;
}
