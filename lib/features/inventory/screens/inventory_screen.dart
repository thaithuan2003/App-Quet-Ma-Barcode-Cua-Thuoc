import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_error.dart';
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
  late final TabController _tabController = TabController(length: 2, vsync: this);
  late Future<List<Batch>> _batchesFuture = _service.batches();
  late Future<List<InventoryTransaction>> _transactionsFuture = _service.transactions();

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _batchesFuture = _service.batches();
      _transactionsFuture = _service.transactions();
    });
  }

  Future<void> _openChangeSheet(Batch batch, _InventoryAction action) async {
    final quantityController = TextEditingController(text: action == _InventoryAction.adjust ? batch.quantity.toString() : '1');
    final noteController = TextEditingController(text: action.label);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${action.label}: ${batch.medicineName}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: action == _InventoryAction.adjust ? 'So luong moi' : 'So luong'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Ghi chu'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final quantity = int.tryParse(quantityController.text) ?? 0;
                  if (quantity < 0 || (quantity == 0 && action != _InventoryAction.adjust)) {
                    return;
                  }
                  try {
                    if (action == _InventoryAction.importStock) {
                      await _service.importStock(batch.id, quantity, noteController.text);
                    } else if (action == _InventoryAction.export) {
                      await _service.exportStock(batch.id, quantity, noteController.text);
                    } else {
                      await _service.adjustStock(batch.id, quantity, noteController.text);
                    }
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  } on ApiException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
                    }
                  }
                },
                icon: Icon(action.icon),
                label: const Text('Luu'),
              ),
            ],
          ),
        );
      },
    );
    quantityController.dispose();
    noteController.dispose();
    if (result == true) {
      _reload();
    }
  }

  Future<void> _openCreateBatchSheet() async {
    final medicineIdController = TextEditingController(text: '1');
    final batchController = TextEditingController();
    final manufactureController = TextEditingController(text: '2026-01-01');
    final expiryController = TextEditingController(text: '2027-01-01');
    final quantityController = TextEditingController(text: '10');
    final thresholdController = TextEditingController(text: '10');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Them lo thuoc', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(controller: medicineIdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Medicine ID')),
                const SizedBox(height: 12),
                TextField(controller: batchController, decoration: const InputDecoration(labelText: 'So lo')),
                const SizedBox(height: 12),
                TextField(controller: manufactureController, decoration: const InputDecoration(labelText: 'Ngay san xuat yyyy-MM-dd')),
                const SizedBox(height: 12),
                TextField(controller: expiryController, decoration: const InputDecoration(labelText: 'Han su dung yyyy-MM-dd')),
                const SizedBox(height: 12),
                TextField(controller: quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'So luong')),
                const SizedBox(height: 12),
                TextField(controller: thresholdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nguong ton thap')),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await _service.createBatch(
                        medicineId: int.tryParse(medicineIdController.text) ?? 0,
                        batchNumber: batchController.text.trim(),
                        manufactureDate: manufactureController.text.trim(),
                        expiryDate: expiryController.text.trim(),
                        quantity: int.tryParse(quantityController.text) ?? 0,
                        lowStockThreshold: int.tryParse(thresholdController.text) ?? 10,
                      );
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    } on ApiException catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
                      }
                    }
                  },
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Tao lo'),
                ),
              ],
            ),
          ),
        );
      },
    );

    medicineIdController.dispose();
    batchController.dispose();
    manufactureController.dispose();
    expiryController.dispose();
    quantityController.dispose();
    thresholdController.dispose();
    if (result == true) {
      _reload();
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
              onPressed: _openCreateBatchSheet,
              icon: const Icon(Icons.add),
              label: const Text('Them lo'),
            ),
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Ton kho'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Giao dich'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              FutureBuilder<List<Batch>>(
                future: _batchesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    return AppError(message: error is ApiException ? error.message : 'Khong tai duoc ton kho.', onRetry: _reload);
                  }
                  final items = snapshot.data ?? [];
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final batch = items[index];
                        return Card(
                          child: ListTile(
                            title: Text(batch.medicineName),
                            subtitle: Text('Lo ${batch.batchNumber} - HSD ${batch.expiryDate}\nTon: ${batch.quantity}'),
                            isThreeLine: true,
                            trailing: PopupMenuButton<_InventoryAction>(
                              onSelected: (action) => _openChangeSheet(batch, action),
                              itemBuilder: (context) => [
                                for (final action in _InventoryAction.values)
                                  PopupMenuItem(value: action, child: Text(action.label)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              FutureBuilder<List<InventoryTransaction>>(
                future: _transactionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    return AppError(message: error is ApiException ? error.message : 'Khong tai duoc giao dich.', onRetry: _reload);
                  }
                  final items = snapshot.data ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        child: ListTile(
                          title: Text('${item.type} - ${item.medicineName}'),
                          subtitle: Text('Lo ${item.batchNumber} - SL ${item.quantity}\n${item.note}'),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _InventoryAction {
  importStock('Nhap kho', Icons.add_box_outlined),
  export('Xuat/ban', Icons.outbox_outlined),
  adjust('Kiem ke', Icons.fact_check_outlined);

  const _InventoryAction(this.label, this.icon);

  final String label;
  final IconData icon;
}
