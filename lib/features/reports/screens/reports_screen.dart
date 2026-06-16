import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../medicine/models/medicine.dart';
import '../../medicine/screens/medicine_detail_screen.dart';
import '../../medicine/services/medicine_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final MedicineService _service = MedicineService(widget.apiClient);
  late Future<List<Medicine>> _future = _service.search('');
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _future = _service.search(_query));
  }

  void _search() {
    _query = _searchController.text.trim();
    _reload();
  }

  Future<void> _showMessage(String title, String message) async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Future<void> _openForm([Medicine? medicine]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MedicineFormSheet(
        medicine: medicine,
        onSave: ({
          required name,
          required barcode,
          required activeIngredient,
          required manufacturer,
          required dosageForm,
          required strength,
          required usageInstruction,
          required warningNote,
          required salePrice,
          required requiresPrescription,
        }) async {
          if (medicine == null) {
            await _service.createMedicine(
              name: name,
              barcode: barcode,
              activeIngredient: activeIngredient,
              manufacturer: manufacturer,
              dosageForm: dosageForm,
              strength: strength,
              usageInstruction: usageInstruction,
              warningNote: warningNote,
              salePrice: salePrice,
              requiresPrescription: requiresPrescription,
            );
          } else {
            await _service.updateMedicine(
              id: medicine.id,
              name: name,
              barcode: barcode,
              activeIngredient: activeIngredient,
              manufacturer: manufacturer,
              dosageForm: dosageForm,
              strength: strength,
              usageInstruction: usageInstruction,
              warningNote: warningNote,
              salePrice: salePrice,
              requiresPrescription: requiresPrescription,
            );
          }
        },
      ),
    );
    if (saved == true) {
      _reload();
      await _showMessage('Thành công', medicine == null ? 'Đã thêm thuốc thành công.' : 'Đã cập nhật thuốc thành công.');
    }
  }

  Future<void> _delete(Medicine medicine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thuốc'),
        content: Text('Bạn muốn xóa thuốc ${medicine.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    try {
      await _service.deleteMedicine(medicine.id);
      _reload();
      await _showMessage('Thành công', 'Đã xóa thuốc thành công.');
    } on ApiException catch (error) {
      await _showMessage('Thông báo lỗi', error.message);
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
                  labelText: 'Tìm thuốc theo tên, hoạt chất hoặc mã vạch',
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
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
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
                return AppError(message: error is ApiException ? error.message : 'Không tải được danh sách thuốc.', onRetry: _reload);
              }
              final medicines = snapshot.data ?? [];
              if (medicines.isEmpty) {
                return const Center(child: Text('Không có thuốc phù hợp.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final medicine = medicines[index];
                  return Card(
                    child: ListTile(
                      title: Text(medicine.name),
                      subtitle: Text('Tồn: ${medicine.totalQuantity} - Giá: ${medicine.salePrice.toStringAsFixed(0)} VND\n${medicine.barcode}'),
                      isThreeLine: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MedicineDetailScreen(medicine: medicine, service: _service)),
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(tooltip: 'Sửa', onPressed: () => _openForm(medicine), icon: const Icon(Icons.edit_outlined)),
                          IconButton(tooltip: 'Xóa', onPressed: () => _delete(medicine), icon: const Icon(Icons.delete_outline)),
                        ],
                      ),
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

class _MedicineFormSheet extends StatefulWidget {
  const _MedicineFormSheet({required this.medicine, required this.onSave});

  final Medicine? medicine;
  final Future<void> Function({
    required String name,
    required String barcode,
    required String activeIngredient,
    required String manufacturer,
    required String dosageForm,
    required String strength,
    required String usageInstruction,
    required String warningNote,
    required num salePrice,
    required bool requiresPrescription,
  }) onSave;

  @override
  State<_MedicineFormSheet> createState() => _MedicineFormSheetState();
}

class _MedicineFormSheetState extends State<_MedicineFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _barcode;
  late final TextEditingController _activeIngredient;
  late final TextEditingController _manufacturer;
  late final TextEditingController _dosageForm;
  late final TextEditingController _strength;
  late final TextEditingController _usageInstruction;
  late final TextEditingController _warningNote;
  late final TextEditingController _salePrice;
  bool _requiresPrescription = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final medicine = widget.medicine;
    _name = TextEditingController(text: medicine?.name ?? '');
    _barcode = TextEditingController(text: medicine?.barcode ?? '');
    _activeIngredient = TextEditingController(text: medicine?.activeIngredient ?? '');
    _manufacturer = TextEditingController(text: medicine?.manufacturer ?? '');
    _dosageForm = TextEditingController(text: medicine?.dosageForm ?? '');
    _strength = TextEditingController(text: medicine?.strength ?? '');
    _usageInstruction = TextEditingController(text: medicine?.usageInstruction ?? '');
    _warningNote = TextEditingController(text: medicine?.warningNote ?? '');
    _salePrice = TextEditingController(text: medicine?.salePrice.toStringAsFixed(0) ?? '0');
    _requiresPrescription = medicine?.requiresPrescription ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _barcode.dispose();
    _activeIngredient.dispose();
    _manufacturer.dispose();
    _dosageForm.dispose();
    _strength.dispose();
    _usageInstruction.dispose();
    _warningNote.dispose();
    _salePrice.dispose();
    super.dispose();
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

  Future<void> _save() async {
    final price = num.tryParse(_salePrice.text.trim());
    if (_name.text.trim().isEmpty) {
      await _showError('Tên thuốc không được để trống.');
      return;
    }
    if (_barcode.text.trim().isEmpty) {
      await _showError('Mã vạch thuốc không được để trống.');
      return;
    }
    if (price == null || price < 0) {
      await _showError('Đơn giá bán không hợp lệ.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(
        name: _name.text.trim(),
        barcode: _barcode.text.trim(),
        activeIngredient: _activeIngredient.text.trim(),
        manufacturer: _manufacturer.text.trim(),
        dosageForm: _dosageForm.text.trim(),
        strength: _strength.text.trim(),
        usageInstruction: _usageInstruction.text.trim(),
        warningNote: _warningNote.text.trim(),
        salePrice: price,
        requiresPrescription: _requiresPrescription,
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(widget.medicine == null ? 'Thêm thuốc' : 'Sửa thuốc', style: Theme.of(context).textTheme.titleMedium)),
                  IconButton(onPressed: _saving ? null : () => Navigator.pop(context, false), icon: const Icon(Icons.close)),
                ],
              ),
              AppTextField(controller: _name, labelText: 'Tên thuốc'),
              AppTextField(controller: _barcode, labelText: 'Mã vạch'),
              AppTextField(controller: _salePrice, keyboardType: TextInputType.number, labelText: 'Đơn giá bán'),
              AppTextField(controller: _activeIngredient, labelText: 'Hoạt chất'),
              AppTextField(controller: _manufacturer, labelText: 'Nhà sản xuất'),
              AppTextField(controller: _dosageForm, labelText: 'Dạng bào chế'),
              AppTextField(controller: _strength, labelText: 'Hàm lượng'),
              AppTextField(controller: _usageInstruction, labelText: 'Hướng dẫn sử dụng'),
              AppTextField(controller: _warningNote, labelText: 'Cảnh báo'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _requiresPrescription,
                onChanged: (value) => setState(() => _requiresPrescription = value),
                title: const Text('Thuốc kê đơn'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Thoát'))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(onPressed: _saving ? null : _save, child: const Text('Lưu'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
