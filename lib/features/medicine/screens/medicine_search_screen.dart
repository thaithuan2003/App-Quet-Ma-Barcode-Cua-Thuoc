import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/medicine.dart';
import '../services/medicine_service.dart';
import 'medicine_detail_screen.dart';

class MedicineSearchScreen extends StatefulWidget {
  const MedicineSearchScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<MedicineSearchScreen> createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends State<MedicineSearchScreen> {
  final _queryController = TextEditingController();
  late final MedicineService _service = MedicineService(widget.apiClient);
  Future<List<Medicine>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _service.search('');
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _search() {
    setState(() => _future = _service.search(_queryController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _queryController,
                  labelText: 'Tên thuốc, hoạt chất hoặc mã vạch',
                  prefixIcon: const Icon(Icons.search),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Tim',
                onPressed: _search,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Medicine>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final error = snapshot.error;
                return AppError(
                  message: error is ApiException ? error.message : 'Không tải được danh sách thuốc.',
                  onRetry: _search,
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(child: Text('Không tìm thấy thuốc phù hợp.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text('${item.barcode} - Ton: ${item.totalQuantity}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicineDetailScreen(medicine: item, service: _service),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
