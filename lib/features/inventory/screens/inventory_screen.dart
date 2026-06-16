import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../medicine/models/medicine.dart';
import '../../medicine/services/medicine_service.dart';
import '../../suppliers/models/supplier.dart';
import '../../suppliers/services/supplier_service.dart';
import '../models/batch.dart';
import '../models/inventory_transaction.dart';
import '../services/inventory_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late final InventoryService _service = InventoryService(widget.apiClient);
  late final MedicineService _medicineService = MedicineService(widget.apiClient);
  late final SupplierService _supplierService = SupplierService(widget.apiClient);
  late final TabController _tabController = TabController(length: 2, vsync: this);
  late Future<List<Batch>> _batchesFuture = _service.batches();
  late Future<List<InventoryTransaction>> _transactionsFuture = _loadImportHistory();

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<InventoryTransaction>> _loadImportHistory() async {
    final transactions = await _service.transactions();
    return transactions.where((item) => item.type.contains('Import')).toList();
  }

  void _reload() {
    setState(() {
      _batchesFuture = _service.batches();
      _transactionsFuture = _loadImportHistory();
    });
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

  Future<void> _showSuccess(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openBatchForm([Batch? batch]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BatchFormSheet(
        batch: batch,
        medicineService: _medicineService,
        supplierService: _supplierService,
        onSave: ({
          required medicineId,
          required supplierId,
          required batchNumber,
          required manufactureDate,
          required expiryDate,
          required quantity,
          required lowStockThreshold,
        }) async {
          if (batch == null) {
            await _service.createBatch(
              medicineId: medicineId,
              supplierId: supplierId,
              batchNumber: batchNumber,
              manufactureDate: manufactureDate,
              expiryDate: expiryDate,
              quantity: quantity,
              lowStockThreshold: lowStockThreshold,
            );
          } else {
            await _service.updateBatch(
              batchId: batch.id,
              medicineId: medicineId,
              supplierId: supplierId,
              batchNumber: batchNumber,
              manufactureDate: manufactureDate,
              expiryDate: expiryDate,
              quantity: quantity,
              lowStockThreshold: lowStockThreshold,
            );
          }
        },
      ),
    );
    if (saved == true) {
      _reload();
      await _showSuccess(batch == null ? 'Đã thêm lô thuốc thành công.' : 'Đã cập nhật lô thuốc thành công.');
    }
  }

  Future<void> _deleteBatch(Batch batch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lô thuốc'),
        content: Text('Bạn muốn xóa lô ${batch.batchNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteBatch(batch.id);
      _reload();
      await _showSuccess('Đã xóa lô thuốc thành công.');
    } on ApiException catch (error) {
      await _showError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _openBatchForm(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm lô thuốc'),
            ),
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Lô thuốc'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Lịch sử'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _BatchList(
                future: _batchesFuture,
                onRetry: _reload,
                onEdit: _openBatchForm,
                onDelete: _deleteBatch,
              ),
              _ImportHistoryList(future: _transactionsFuture, onRetry: _reload),
            ],
          ),
        ),
      ],
    );
  }
}

class _BatchList extends StatelessWidget {
  const _BatchList({
    required this.future,
    required this.onRetry,
    required this.onEdit,
    required this.onDelete,
  });

  final Future<List<Batch>> future;
  final VoidCallback onRetry;
  final ValueChanged<Batch> onEdit;
  final ValueChanged<Batch> onDelete;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Batch>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return AppError(message: error is ApiException ? error.message : 'Không tải được lô thuốc.', onRetry: onRetry);
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Chưa có lô thuốc.'));
        }
        return RefreshIndicator(
          onRefresh: () async => onRetry(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final batch = items[index];
              return Card(
                child: ListTile(
                  title: Text(batch.medicineName),
                  subtitle: Text(
                    'Lô: ${batch.batchNumber}\n'
                    'HSD: ${batch.expiryDate} - Tồn: ${batch.quantity}\n'
                    'Nhà cung ứng: ${batch.supplierName ?? 'Chưa chọn'}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<_BatchAction>(
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: _BatchAction.edit, child: Text('Sửa lô')),
                      PopupMenuItem(value: _BatchAction.delete, child: Text('Xóa lô')),
                    ],
                    onSelected: (action) {
                      if (action == _BatchAction.edit) {
                        onEdit(batch);
                      } else {
                        onDelete(batch);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ImportHistoryList extends StatelessWidget {
  const _ImportHistoryList({required this.future, required this.onRetry});

  final Future<List<InventoryTransaction>> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InventoryTransaction>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return AppError(message: error is ApiException ? error.message : 'Không tải được lịch sử nhập kho.', onRetry: onRetry);
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Chưa có lịch sử nhập kho.'));
        }
        return RefreshIndicator(
          onRefresh: () async => onRetry(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.add_box_outlined),
                  title: Text(item.medicineName),
                  subtitle: Text('Lô: ${item.batchNumber}\nSố lượng nhập: ${item.quantity}\nGhi chú: ${item.note}'),
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

class _BatchFormSheet extends StatefulWidget {
  const _BatchFormSheet({
    required this.batch,
    required this.medicineService,
    required this.supplierService,
    required this.onSave,
  });

  final Batch? batch;
  final MedicineService medicineService;
  final SupplierService supplierService;
  final Future<void> Function({
    required int medicineId,
    required int supplierId,
    required String batchNumber,
    required String manufactureDate,
    required String expiryDate,
    required int quantity,
    required int lowStockThreshold,
  }) onSave;

  @override
  State<_BatchFormSheet> createState() => _BatchFormSheetState();
}

class _BatchFormSheetState extends State<_BatchFormSheet> {
  late final TextEditingController _batchNumber;
  late final TextEditingController _manufactureDate;
  late final TextEditingController _expiryDate;
  late final TextEditingController _quantity;
  late final TextEditingController _threshold;
  late Future<void> _loadFuture;
  List<Medicine> _medicines = [];
  List<Supplier> _suppliers = [];
  int? _medicineId;
  int? _supplierId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final batch = widget.batch;
    _medicineId = batch?.medicineId;
    _supplierId = batch?.supplierId;
    _batchNumber = TextEditingController(text: batch?.batchNumber ?? '');
    _manufactureDate = TextEditingController(text: batch?.manufactureDate ?? '2026-01-01');
    _expiryDate = TextEditingController(text: batch?.expiryDate ?? '2027-01-01');
    _quantity = TextEditingController(text: batch?.quantity.toString() ?? '10');
    _threshold = TextEditingController(text: batch?.lowStockThreshold.toString() ?? '10');
    _loadFuture = _loadOptions();
  }

  @override
  void dispose() {
    _batchNumber.dispose();
    _manufactureDate.dispose();
    _expiryDate.dispose();
    _quantity.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    final medicines = await widget.medicineService.search('');
    final suppliers = await widget.supplierService.suppliers();
    if (!mounted) return;
    setState(() {
      _medicines = medicines;
      _suppliers = suppliers;
      if (_medicineId == null && medicines.isNotEmpty) {
        _medicineId = medicines.first.id;
      }
      if (_supplierId == null && suppliers.isNotEmpty) {
        _supplierId = suppliers.first.id;
      }
    });
  }

  Future<void> _showError(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông báo lỗi'),
        content: Text(message),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }

  bool _isValidDate(String value) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);

  Future<void> _save() async {
    final medicineId = _medicineId;
    final supplierId = _supplierId;
    final quantity = int.tryParse(_quantity.text.trim());
    final threshold = int.tryParse(_threshold.text.trim());

    if (medicineId == null) {
      await _showError('Vui lòng chọn thuốc cho lô.');
      return;
    }
    if (supplierId == null) {
      await _showError('Vui lòng thêm và chọn nhà cung ứng trước.');
      return;
    }
    if (_batchNumber.text.trim().isEmpty) {
      await _showError('Số lô không được để trống.');
      return;
    }
    if (!_isValidDate(_manufactureDate.text.trim()) || !_isValidDate(_expiryDate.text.trim())) {
      await _showError('Ngày sản xuất và hạn sử dụng phải có dạng yyyy-MM-dd.');
      return;
    }
    if (quantity == null || quantity < 0) {
      await _showError('Số lượng tồn không hợp lệ.');
      return;
    }
    if (threshold == null || threshold < 0) {
      await _showError('Ngưỡng tồn thấp không hợp lệ.');
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(
        medicineId: medicineId,
        supplierId: supplierId,
        batchNumber: _batchNumber.text.trim(),
        manufactureDate: _manufactureDate.text.trim(),
        expiryDate: _expiryDate.text.trim(),
        quantity: quantity,
        lowStockThreshold: threshold,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        await _showError(error.message);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không tải được dữ liệu thuốc hoặc nhà cung ứng.'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: () => Navigator.pop(context, false), child: const Text('Đóng')),
                ],
              );
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.batch == null ? 'Thêm lô thuốc' : 'Sửa lô thuốc', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _medicines.any((item) => item.id == _medicineId) ? _medicineId : null,
                    decoration: const InputDecoration(labelText: 'Thuốc'),
                    items: [
                      for (final medicine in _medicines)
                        DropdownMenuItem(value: medicine.id, child: Text('${medicine.name} - ${medicine.strength}')),
                    ],
                    onChanged: _saving ? null : (value) => setState(() => _medicineId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _suppliers.any((item) => item.id == _supplierId) ? _supplierId : null,
                    decoration: const InputDecoration(labelText: 'Nhà cung ứng'),
                    items: [
                      for (final supplier in _suppliers) DropdownMenuItem(value: supplier.id, child: Text(supplier.name)),
                    ],
                    onChanged: _saving ? null : (value) => setState(() => _supplierId = value),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(controller: _batchNumber, enabled: !_saving, labelText: 'Số lô'),
                  const SizedBox(height: 12),
                  AppTextField(controller: _manufactureDate, enabled: !_saving, labelText: 'Ngày sản xuất yyyy-MM-dd'),
                  const SizedBox(height: 12),
                  AppTextField(controller: _expiryDate, enabled: !_saving, labelText: 'Hạn sử dụng yyyy-MM-dd'),
                  const SizedBox(height: 12),
                  AppTextField(controller: _quantity, enabled: !_saving, keyboardType: TextInputType.number, labelText: 'Số lượng tồn'),
                  const SizedBox(height: 12),
                  AppTextField(controller: _threshold, enabled: !_saving, keyboardType: TextInputType.number, labelText: 'Ngưỡng tồn thấp'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Thoát'))),
                      const SizedBox(width: 12),
                      Expanded(child: FilledButton(onPressed: _saving ? null : _save, child: const Text('Lưu'))),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _BatchAction { edit, delete }
