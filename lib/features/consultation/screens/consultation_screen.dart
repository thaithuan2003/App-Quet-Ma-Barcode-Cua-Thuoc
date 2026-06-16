import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/medicine_consultation.dart';
import '../services/consultation_service.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  late final ConsultationService _service = ConsultationService(widget.apiClient);
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showError(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông báo lỗi'),
        content: Text(message),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }

  Future<void> _showResult(MedicineConsultation result) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tư vấn: ${result.medicineName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(result.summary),
              if (result.sourceUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Link thuốc', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                SelectableText(result.sourceUrl, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ],
            ],
          ),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }

  Future<void> _search() async {
    final medicineName = _controller.text.trim();
    if (medicineName.isEmpty) {
      await _showError('Vui lòng nhập tên thuốc cần tư vấn.');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await _service.searchMedicine(medicineName);
      await _showResult(result);
    } on ApiException catch (error) {
      await _showError(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tư vấn thông tin thuốc', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _controller,
                  enabled: !_loading,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _loading ? null : _search(),
                  labelText: 'Tên thuốc',
                  hintText: 'Ví dụ: Paracetamol 500mg',
                  prefixIcon: const Icon(Icons.medication_outlined),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loading ? null : _search,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.travel_explore_outlined),
                  label: Text(_loading ? 'Đang tìm kiếm...' : 'Tìm và tổng hợp'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Nội dung tư vấn chỉ dùng để tham khảo. Khi cấp phát thuốc vẫn cần kiểm tra theo quy trình dược.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
