import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/token_storage.dart';
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

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TokenStorage _tokenStorage = TokenStorage();
  late final InventoryService _service = InventoryService(widget.apiClient);
  late final MedicineService _medicineService = MedicineService(
    widget.apiClient,
  );
  late final SupplierService _supplierService = SupplierService(
    widget.apiClient,
  );
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );
  late Future<List<Batch>> _batchesFuture = _service.batches();
  late Future<List<InventoryTransaction>> _transactionsFuture =
      _loadImportHistory();
  String _query = '';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final roles = await _tokenStorage.readRoles();
    if (!mounted) {
      return;
    }
    setState(() => _isAdmin = roles.contains('Admin'));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<List<InventoryTransaction>> _loadImportHistory() async {
    final transactions = await _service.transactions();
    return transactions.where((item) => item.type == 'Import').toList();
  }

  void _reload() {
    setState(() {
      _batchesFuture = _service.batches(query: _query);
      _transactionsFuture = _loadImportHistory();
    });
  }

  void _search() {
    _query = _searchController.text.trim();
    _reload();
  }

  Future<void> _showSuccess(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openBatchForm([Batch? batch]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BatchFormSheet(
        batch: batch,
        medicineService: _medicineService,
        supplierService: _supplierService,
        onSave:
            ({
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
      await _showSuccess(
        batch == null
            ? 'Đã thêm lô thuốc thành công.'
            : 'Đã cập nhật lô thuốc thành công.',
      );
    }
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
                  controller: _searchController,
                  labelText: 'Tìm theo số lô hoặc tên thuốc',
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
              if (_isAdmin) ...[
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _openBatchForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm lô thuốc'),
                ),
              ],
            ],
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
                isAdmin: _isAdmin,
                onRetry: _reload,
                onOpenDetails: _openBatchDetails,
                onEdit: _openBatchForm,
              ),
              _ImportHistoryList(future: _transactionsFuture, onRetry: _reload),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openBatchDetails(Batch batch) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BatchDetailsSheet(batch: batch),
    );
  }
}

class _BatchList extends StatelessWidget {
  const _BatchList({
    required this.future,
    required this.isAdmin,
    required this.onRetry,
    required this.onOpenDetails,
    required this.onEdit,
  });

  final Future<List<Batch>> future;
  final bool isAdmin;
  final VoidCallback onRetry;
  final ValueChanged<Batch> onOpenDetails;
  final ValueChanged<Batch> onEdit;

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
          return AppError(
            message: error is ApiException
                ? error.message
                : 'Không tải được lô thuốc.',
            onRetry: onRetry,
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Không có lô thuốc phù hợp.'));
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
                  onTap: () => onOpenDetails(batch),
                  trailing: isAdmin
                      ? IconButton(
                          tooltip: 'Sửa lô',
                          onPressed: () => onEdit(batch),
                          icon: const Icon(Icons.edit_outlined),
                        )
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _BatchDetailsSheet extends StatelessWidget {
  const _BatchDetailsSheet({required this.batch});

  final Batch batch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chi tiết lô thuốc',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _BatchDetailRow(label: 'Tên thuốc', value: batch.medicineName),
              _BatchDetailRow(label: 'Số lô', value: batch.batchNumber),
              _BatchDetailRow(
                label: 'Ngày sản xuất',
                value: batch.manufactureDate,
              ),
              _BatchDetailRow(label: 'Hạn sử dụng', value: batch.expiryDate),
              _BatchDetailRow(
                label: 'Số lượng tồn',
                value: batch.quantity.toString(),
              ),
              _BatchDetailRow(
                label: 'Ngưỡng tồn thấp',
                value: batch.lowStockThreshold.toString(),
              ),
              _BatchDetailRow(
                label: 'Nhà cung ứng',
                value: batch.supplierName ?? 'Chưa chọn',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchDetailRow extends StatelessWidget {
  const _BatchDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
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
          return AppError(
            message: error is ApiException
                ? error.message
                : 'Không tải được lịch sử nhập kho.',
            onRetry: onRetry,
          );
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
                  subtitle: Text(
                    'Lô: ${item.batchNumber}\nSố lượng nhập: ${item.quantity}\nGhi chú: ${item.note}',
                  ),
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
  })
  onSave;

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
    _manufactureDate = TextEditingController(
      text: batch?.manufactureDate ?? '2026-01-01',
    );
    _expiryDate = TextEditingController(
      text: batch?.expiryDate ?? '2027-01-01',
    );
    _quantity = TextEditingController(text: batch?.quantity.toString() ?? '10');
    _threshold = TextEditingController(
      text: batch?.lowStockThreshold.toString() ?? '10',
    );
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
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  bool _isValidDate(String value) =>
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);

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
    if (!_isValidDate(_manufactureDate.text.trim()) ||
        !_isValidDate(_expiryDate.text.trim())) {
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
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không tải được dữ liệu thuốc hoặc nhà cung ứng.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Đóng'),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.batch == null ? 'Thêm lô thuốc' : 'Sửa lô thuốc',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _medicines.any((item) => item.id == _medicineId)
                        ? _medicineId
                        : null,
                    decoration: const InputDecoration(labelText: 'Thuốc'),
                    items: [
                      for (final medicine in _medicines)
                        DropdownMenuItem(
                          value: medicine.id,
                          child: Text(
                            '${medicine.name} - ${medicine.strength}',
                          ),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _medicineId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _suppliers.any((item) => item.id == _supplierId)
                        ? _supplierId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Nhà cung ứng',
                    ),
                    items: [
                      for (final supplier in _suppliers)
                        DropdownMenuItem(
                          value: supplier.id,
                          child: Text(supplier.name),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _supplierId = value),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _batchNumber,
                    enabled: !_saving,
                    labelText: 'Số lô',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _manufactureDate,
                    enabled: !_saving,
                    labelText: 'Ngày sản xuất yyyy-MM-dd',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _expiryDate,
                    enabled: !_saving,
                    labelText: 'Hạn sử dụng yyyy-MM-dd',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _quantity,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    labelText: 'Số lượng tồn',
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _threshold,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    labelText: 'Ngưỡng tồn thấp',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.pop(context, false),
                          child: const Text('Thoát'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: const Text('Lưu'),
                        ),
                      ),
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

