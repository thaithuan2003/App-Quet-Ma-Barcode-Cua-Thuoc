import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../history/models/scan_result.dart';
import '../../history/services/scan_service.dart';
import '../../medicine/models/interaction_result.dart';
import '../../medicine/screens/medicine_detail_screen.dart';
import '../../medicine/services/medicine_service.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  late final ScanService _scanService = ScanService(widget.apiClient);
  late final MedicineService _medicineService = MedicineService(widget.apiClient);
  final List<ScanResult> _results = [];
  final Set<String> _barcodes = {};
  bool _busy = false;
  String? _message;
  InteractionResult? _interactionResult;

  Future<void> _handleBarcode(String? value) async {
    if (value == null || value.isEmpty || _busy || _barcodes.contains(value)) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _barcodes.add(value);
    });
    try {
      final result = await _scanService.scan(value);
      setState(() => _results.insert(0, result));
    } on ApiException catch (error) {
      setState(() => _message = error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _checkInteractions() async {
    if (_barcodes.length < 2) {
      setState(() => _message = 'Can it nhat 2 barcode de kiem tra tuong tac.');
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await _medicineService.checkInteractions(_barcodes.toList());
      setState(() => _interactionResult = result);
    } on ApiException catch (error) {
      setState(() => _message = error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _clear() {
    setState(() {
      _results.clear();
      _barcodes.clear();
      _interactionResult = null;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.7,
          child: MobileScanner(
            onDetect: (capture) {
              final barcode = capture.barcodes.isEmpty ? null : capture.barcodes.first;
              _handleBarcode(barcode?.rawValue);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: Text('Da quet: ${_barcodes.length}')),
              IconButton.filledTonal(
                tooltip: 'Kiem tra tuong tac',
                onPressed: _busy ? null : _checkInteractions,
                icon: const Icon(Icons.health_and_safety_outlined),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Xoa danh sach',
                onPressed: _clear,
                icon: const Icon(Icons.clear_all),
              ),
            ],
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (_interactionResult != null)
          Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.warning_amber),
              title: Text(_interactionResult!.message),
              subtitle: Text(_interactionResult!.details.isEmpty ? 'Khong co chi tiet.' : _interactionResult!.details.join('\n')),
            ),
          ),
        Expanded(
          child: _results.isEmpty
              ? const Center(child: Text('Dua ma vach vao khung camera de quet.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    final medicine = result.medicine;
                    return Card(
                      child: ListTile(
                        leading: Icon(result.found ? Icons.check_circle_outline : Icons.help_outline),
                        title: Text(medicine?.name ?? result.message),
                        subtitle: Text(medicine?.barcode ?? 'Barcode khong co trong CSDL'),
                        trailing: medicine == null ? null : const Icon(Icons.chevron_right),
                        onTap: medicine == null
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MedicineDetailScreen(
                                      medicine: medicine,
                                      service: _medicineService,
                                    ),
                                  ),
                                );
                              },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
