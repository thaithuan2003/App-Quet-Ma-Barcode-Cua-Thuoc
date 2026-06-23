import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../history/models/scan_result.dart';
import '../../history/services/scan_service.dart';
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
  late final MedicineService _medicineService = MedicineService(
    widget.apiClient,
  );
  final List<ScanResult> _results = [];
  final Set<String> _barcodes = {};
  final List<String> _interactionBarcodes = [];
  Timer? _scanTimeoutTimer;
  bool _busy = false;
  bool _waitingForConfirm = false;
  bool _interactionMode = false;
  String? _message;

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

  Future<void> _showInfoDialog({
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
  }) async {
    if (!mounted) {
      return;
    }
    _scanTimeoutTimer?.cancel();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  void _restartScanTimeout() {
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = Timer(const Duration(seconds: 10), () async {
      if (!mounted || _busy || _waitingForConfirm) {
        return;
      }
      setState(() => _waitingForConfirm = true);
      await _showInfoDialog(
        title: 'Chưa đọc được mã vạch',
        message: 'Vui lòng đưa mã vạch vào khung camera rõ hơn hoặc thử lại.',
        icon: Icons.qr_code_scanner,
      );
      if (mounted) {
        setState(() => _waitingForConfirm = false);
        _restartScanTimeout();
      }
    });
  }

  Future<void> _handleBarcode(String? value) async {
    if (_busy || _waitingForConfirm) {
      return;
    }

    if (value == null || value.isEmpty) {
      _waitingForConfirm = true;
      await _showInfoDialog(
        title: 'Không đọc được mã vạch',
        message: 'Vui lòng đưa mã vạch vào khung camera và thử lại.',
        icon: Icons.qr_code_scanner,
      );
      if (mounted) {
        setState(() => _waitingForConfirm = false);
      }
      _restartScanTimeout();
      return;
    }

    setState(() {
      _busy = true;
      _waitingForConfirm = true;
      _message = null;
      _barcodes.add(value);
    });

    ScanResult? result;
    String dialogTitle = 'Kết quả quét mã';
    String dialogMessage = 'Đã quét mã vạch: $value';
    IconData dialogIcon = Icons.qr_code_2;

    try {
      result = await _scanService.scan(value);
      if (!mounted) {
        return;
      }
      setState(() => _results.insert(0, result!));

      final medicine = result.medicine;
      if (medicine == null) {
        dialogTitle = 'Không tìm thấy thuốc';
        dialogMessage = '${result.message}\nMã vạch: $value';
        dialogIcon = Icons.help_outline;
      } else {
        dialogTitle = 'Đã tìm thấy thuốc';
        dialogMessage =
            '${medicine.name}\nMã vạch: $value\nTồn kho: ${medicine.totalQuantity}';
        dialogIcon = Icons.check_circle_outline;
      }

      if (_interactionMode &&
          medicine != null &&
          !_interactionBarcodes.contains(value)) {
        _interactionBarcodes.add(value);
      }
    } on ApiException catch (error) {
      setState(() => _message = error.message);
      dialogTitle = 'Thông báo lỗi';
      dialogMessage = error.message;
      dialogIcon = Icons.error_outline;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }

    await _showInfoDialog(
      title: dialogTitle,
      message: dialogMessage,
      icon: dialogIcon,
    );
    if (!mounted) {
      return;
    }

    if (_interactionMode && result?.medicine != null) {
      if (_interactionBarcodes.length == 1) {
        await _showInfoDialog(
          title: 'Kiểm tra tương tác thuốc',
          message: 'Đã quét thuốc thứ 1. Vui lòng quét thuốc thứ 2.',
          icon: Icons.health_and_safety_outlined,
        );
      } else if (_interactionBarcodes.length >= 2) {
        await _checkInteractions();
      }
    }

    if (mounted) {
      setState(() => _waitingForConfirm = false);
      _restartScanTimeout();
    }
  }

  Future<void> _checkInteractions() async {
    if (_interactionBarcodes.length < 2) {
      await _showInfoDialog(
        title: 'Kiểm tra tương tác thuốc',
        message: _interactionBarcodes.isEmpty
            ? 'Vui lòng quét thuốc thứ 1.'
            : 'Đã quét thuốc thứ 1. Vui lòng quét thuốc thứ 2.',
        icon: Icons.health_and_safety_outlined,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await _medicineService.checkInteractions(
        _interactionBarcodes.take(2).toList(),
      );
      if (!mounted) {
        return;
      }
      await _showInfoDialog(
        title: 'Kết quả tương tác thuốc',
        message: result.details.isEmpty
            ? result.message
            : '${result.message}\n\n${result.details.join('\n')}',
        icon: Icons.warning_amber_outlined,
      );
      setState(() {
        _interactionMode = false;
        _interactionBarcodes.clear();
      });
    } on ApiException catch (error) {
      setState(() => _message = error.message);
      await _showInfoDialog(
        title: 'Thông báo lỗi',
        message: error.message,
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _startInteractionCheck() async {
    setState(() {
      _interactionMode = true;
      _interactionBarcodes.clear();
      _message = null;
    });
    await _showInfoDialog(
      title: 'Kiểm tra tương tác thuốc',
      message: 'Vui lòng quét thuốc thứ 1.',
      icon: Icons.health_and_safety_outlined,
    );
  }

  void _clear() {
    setState(() {
      _results.clear();
      _barcodes.clear();
      _interactionBarcodes.clear();
      _interactionMode = false;
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
              final barcode = capture.barcodes.isEmpty
                  ? null
                  : capture.barcodes.first;
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
                onPressed: _busy || _waitingForConfirm
                    ? null
                    : _startInteractionCheck,
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
            child: Text(
              _message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_interactionMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _interactionBarcodes.isEmpty
                        ? 'Đang kiểm tra tương tác: quét thuốc thứ 1.'
                        : 'Đang kiểm tra tương tác: quét thuốc thứ 2.',
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _results.isEmpty
              ? const Center(
                  child: Text('Đưa mã vạch vào khung camera để quét.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    final medicine = result.medicine;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          result.found
                              ? Icons.check_circle_outline
                              : Icons.help_outline,
                        ),
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
                        trailing: medicine == null
                            ? null
                            : const Icon(Icons.chevron_right),
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
