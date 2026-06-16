import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/info_tile.dart';
import '../models/medicine.dart';
import '../services/medicine_service.dart';

class MedicineDetailScreen extends StatefulWidget {
  const MedicineDetailScreen({
    super.key,
    required this.medicine,
    required this.service,
  });

  final Medicine medicine;
  final MedicineService service;

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  late Future<List<Medicine>> _similarFuture = widget.service.similar(widget.medicine.id);

  @override
  Widget build(BuildContext context) {
    final medicine = widget.medicine;
    return Scaffold(
      appBar: AppBar(title: Text(medicine.name)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Column(
              children: [
                InfoTile(label: 'Mã vạch', value: medicine.barcode, icon: Icons.qr_code),
                InfoTile(label: 'Hoạt chất', value: medicine.activeIngredient, icon: Icons.science_outlined),
                InfoTile(label: 'Hàm lượng', value: medicine.strength, icon: Icons.medication_outlined),
                InfoTile(label: 'Dạng bào chế', value: medicine.dosageForm, icon: Icons.category_outlined),
                InfoTile(label: 'Nhà sản xuất', value: medicine.manufacturer, icon: Icons.factory_outlined),
                InfoTile(label: 'Đơn giá bán', value: '${medicine.salePrice.toStringAsFixed(0)} VND', icon: Icons.sell_outlined),
                InfoTile(label: 'Số lượng tồn', value: '${medicine.totalQuantity}', icon: Icons.inventory_outlined),
                InfoTile(label: 'Hạn sử dụng gần nhất', value: AppDateUtils.formatDate(medicine.nearestExpiryDate), icon: Icons.event_outlined),
                InfoTile(label: 'Phân loại', value: medicine.requiresPrescription ? 'Thuốc kê đơn' : 'Thuốc không kê đơn', icon: Icons.assignment_outlined),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                InfoTile(label: 'Hướng dẫn sử dụng', value: medicine.usageInstruction, icon: Icons.info_outline),
                InfoTile(label: 'Cảnh báo', value: medicine.warningNote, icon: Icons.warning_amber),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Text('Thuốc thay thế', style: Theme.of(context).textTheme.titleMedium),
          ),
          FutureBuilder<List<Medicine>>(
            future: _similarFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const ListTile(title: Text('Chưa có thuốc thay thế phù hợp.'));
              }
              return Column(
                children: [
                  for (final item in items)
                    Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text('${item.activeIngredient} - ${item.strength}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MedicineDetailScreen(medicine: item, service: widget.service),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
