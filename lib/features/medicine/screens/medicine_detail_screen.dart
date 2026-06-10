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
                InfoTile(label: 'Barcode', value: medicine.barcode, icon: Icons.qr_code),
                InfoTile(label: 'Hoat chat', value: medicine.activeIngredient, icon: Icons.science_outlined),
                InfoTile(label: 'Ham luong', value: medicine.strength, icon: Icons.medication_outlined),
                InfoTile(label: 'Dang bao che', value: medicine.dosageForm, icon: Icons.category_outlined),
                InfoTile(label: 'Nha san xuat', value: medicine.manufacturer, icon: Icons.factory_outlined),
                InfoTile(label: 'Ton kho', value: '${medicine.totalQuantity}', icon: Icons.inventory_outlined),
                InfoTile(label: 'Han gan nhat', value: AppDateUtils.formatDate(medicine.nearestExpiryDate), icon: Icons.event_outlined),
                InfoTile(label: 'Can don', value: medicine.requiresPrescription ? 'Co' : 'Khong', icon: Icons.assignment_outlined),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                InfoTile(label: 'Huong dan', value: medicine.usageInstruction, icon: Icons.info_outline),
                InfoTile(label: 'Canh bao', value: medicine.warningNote, icon: Icons.warning_amber),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Text('Thuoc tuong tu rule-based', style: Theme.of(context).textTheme.titleMedium),
          ),
          FutureBuilder<List<Medicine>>(
            future: _similarFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const ListTile(title: Text('Chua co goi y phu hop.'));
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
