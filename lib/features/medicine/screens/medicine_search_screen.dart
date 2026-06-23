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
  List<Medicine> _items = [];
  bool _loading = true;
  Object? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines([String query = '']) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _service.search(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _search() async {
    _query = _queryController.text.trim();
    await _loadMedicines(_query);
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
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Tìm',
                onPressed: _search,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        Expanded(child: _buildResult()),
      ],
    );
  }

  Widget _buildResult() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return AppError(
        message: error is ApiException
            ? error.message
            : 'Không tải được danh sách thuốc.',
        onRetry: () => _loadMedicines(_query),
      );
    }

    if (_items.isEmpty) {
      return const Center(child: Text('Không tìm thấy thuốc phù hợp.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          child: ListTile(
            title: Text(item.name),
            subtitle: Text('${item.barcode} - Tồn: ${item.totalQuantity}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MedicineDetailScreen(medicine: item, service: _service),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
