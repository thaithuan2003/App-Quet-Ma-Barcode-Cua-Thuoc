import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../services/verification_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _barcodeController = TextEditingController(text: '8938505974190');
  final _batchController = TextEditingController(text: 'PCM-2026-01');
  late final VerificationService _service = VerificationService(
    widget.apiClient,
  );
  VerificationResult? _result;
  bool _loading = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final result = await _service.verify(
        _barcodeController.text.trim(),
        _batchController.text.trim(),
      );
      setState(() => _result = result);
    } on ApiException catch (error) {
      setState(
        () => _result = VerificationResult(
          isVerified: false,
          severity: 'Warning',
          message: error.message,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _barcodeController,
          decoration: const InputDecoration(
            labelText: 'Mã vạch',
            prefixIcon: Icon(Icons.qr_code),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _batchController,
          decoration: const InputDecoration(
            labelText: 'Số lô',
            prefixIcon: Icon(Icons.numbers),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _loading ? null : _verify,
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('Kiểm tra xác thực'),
        ),
        if (result != null) ...[
          const SizedBox(height: 16),
          Card(
            color: result.isVerified
                ? Colors.green.shade50
                : Colors.orange.shade50,
            child: ListTile(
              leading: Icon(
                result.isVerified ? Icons.verified : Icons.warning_amber,
              ),
              title: Text(result.isVerified ? 'Hợp lệ' : 'Cần kiểm tra lại'),
              subtitle: Text(result.message),
            ),
          ),
        ],
      ],
    );
  }
}
