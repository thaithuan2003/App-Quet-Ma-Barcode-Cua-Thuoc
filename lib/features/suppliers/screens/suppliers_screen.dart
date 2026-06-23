import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/supplier.dart';
import '../services/supplier_service.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({
    super.key,
    required this.apiClient,
    required this.refreshVersion,
  });

  final ApiClient apiClient;
  final int refreshVersion;

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  late final SupplierService _service = SupplierService(widget.apiClient);
  late Future<List<Supplier>> _future = _service.suppliers();

  @override
  void didUpdateWidget(covariant SuppliersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshVersion != oldWidget.refreshVersion) {
      setState(() => _future = _service.suppliers());
    }
  }

  Future<void> _reload() async {
    final future = _service.suppliers();
    setState(() => _future = future);
    await future;
  }

  Future<void> _showMessage(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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

  Future<void> _openForm([Supplier? supplier]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SupplierFormSheet(
        supplier: supplier,
        onSave: ({required name, required phone, required address}) async {
          if (supplier == null) {
            await _service.createSupplier(
              name: name,
              phone: phone,
              address: address,
            );
          } else {
            await _service.updateSupplier(
              id: supplier.id,
              name: name,
              phone: phone,
              address: address,
            );
          }
          await _reload();
        },
      ),
    );
    if (saved == true) {
      await _showMessage(
        'Thành công',
        supplier == null
            ? 'Đã thêm nhà cung ứng.'
            : 'Đã cập nhật nhà cung ứng.',
      );
    }
  }

  Future<void> _delete(Supplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhà cung ứng'),
        content: Text('Bạn muốn xóa ${supplier.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteSupplier(supplier.id);
      await _reload();
      await _showMessage('Thành công', 'Đã xóa nhà cung ứng.');
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
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm nhà cung ứng'),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Supplier>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final error = snapshot.error;
                return AppError(
                  message: error is ApiException
                      ? error.message
                      : 'Không tải được nhà cung ứng.',
                  onRetry: _reload,
                );
              }
              final suppliers = snapshot.data ?? [];
              if (suppliers.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 160),
                      Center(child: Text('Chưa có nhà cung ứng.')),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    return Card(
                      child: ListTile(
                        title: Text(supplier.name),
                        subtitle: Text(
                          '${supplier.phone}\n${supplier.address}',
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              onPressed: () => _openForm(supplier),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () => _delete(supplier),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
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

class _SupplierFormSheet extends StatefulWidget {
  const _SupplierFormSheet({required this.supplier, required this.onSave});

  final Supplier? supplier;
  final Future<void> Function({
    required String name,
    required String phone,
    required String address,
  })
  onSave;

  @override
  State<_SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<_SupplierFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.supplier?.name ?? '');
    _phone = TextEditingController(text: widget.supplier?.phone ?? '');
    _address = TextEditingController(text: widget.supplier?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
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

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      await _showError('Tên nhà cung ứng không được để trống.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.supplier == null
                  ? 'Thêm nhà cung ứng'
                  : 'Sửa nhà cung ứng',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            AppTextField(controller: _name, labelText: 'Tên nhà cung ứng'),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              labelText: 'Số điện thoại',
            ),
            const SizedBox(height: 12),
            AppTextField(controller: _address, labelText: 'Địa chỉ'),
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
      ),
    );
  }
}
