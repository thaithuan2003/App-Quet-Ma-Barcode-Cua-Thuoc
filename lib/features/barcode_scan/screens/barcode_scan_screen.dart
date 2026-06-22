import 'dart:async';

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
  Timer? _scanTimeoutTimer;
  bool _busy = false;
  String? _message;
  InteractionResult? _interactionResult;

  @override
  void initState() {
    super.initState();
    _restartScanTimeout();
  }

  @override
  void dispose() {
    _scanTimeoutTimer?.cancel();
    super.dispose();
  }

  void _showScanMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _restartScanTimeout() {
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted || _busy) {
        return;
      }
      _showScanMessage('Chưa đọc được mã vạch. Vui lòng đưa mã vào khung camera hoặc thử lại.');
      _restartScanTimeout();
    });
  }

  Future<void> _handleBarcode(String? value) async {
    if (value == null || value.isEmpty) {
      _showScanMessage('Không đọc được mã vạch. Vui lòng thử lại.');
      _restartScanTimeout();
      return;
    }
    if (_busy) {
      _showScanMessage('Hệ thống đang xử lý mã trước đó. Vui lòng chờ.');
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
        _restartScanTimeout();
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
              Expanded(child: Text('Đã quét: ${_barcodes.length}')),
              IconButton.filledTonal(
                tooltip: 'Kiểm tra tương tác',
                onPressed: _busy ? null : _checkInteractions,
                icon: const Icon(Icons.health_and_safety_outlined),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Xóa danh sách',
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
              subtitle: Text(_interactionResult!.details.isEmpty ? 'Không có chi tiết.' : _interactionResult!.details.join('\n')),
            ),
          ),
        Expanded(
          child: _results.isEmpty
              ? const Center(child: Text('Đưa mã vạch vào khung camera để quét.'))
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
                        subtitle: Text(
                          medicine == null
                              ? 'Barcode không có trong CSDL'
                              : 'Giá: ${medicine.salePrice.toStringAsFixed(0)} VND\n'
                                  'Tồn kho: ${medicine.totalQuantity} - HSD gần nhất: ${medicine.nearestExpiryDate ?? 'Không có'}\n'
                                  'Nhà sản xuất: ${medicine.manufacturer}\n'
                                  '${medicine.requiresPrescription ? 'Thuốc kê đơn' : 'Thuốc không kê đơn'}\n'
                                  'Hướng dẫn: ${medicine.usageInstruction.isEmpty ? 'Không có' : medicine.usageInstruction}\n'
                                  'Cảnh báo: ${medicine.warningNote.isEmpty ? 'Không có' : medicine.warningNote}\n'
                                  'Bấm để xem chi tiết và thuốc thay thế',
                        ),
                        isThreeLine: true,
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
