import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../features/admin/screens/admin_screen.dart';
import '../features/alerts/screens/alerts_screen.dart';
import '../features/barcode_scan/screens/barcode_scan_screen.dart';
import '../features/consultation/screens/consultation_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/inventory/screens/inventory_screen.dart';
import '../features/medicine/screens/medicine_search_screen.dart';
import '../features/medicine/screens/verification_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/suppliers/screens/suppliers_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({
    super.key,
    required this.apiClient,
    required this.roles,
    required this.onLogout,
  });

  final ApiClient apiClient;
  final List<String> roles;
  final VoidCallback onLogout;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;
  int _supplierRefreshVersion = 0;

  late List<_Page> _pages = _buildPages();

  List<_Page> _buildPages() {
    return [
      _Page(
        'Quét mã',
        Icons.qr_code_scanner,
        BarcodeScanScreen(apiClient: widget.apiClient),
      ),
      _Page(
        'Tư vấn',
        Icons.support_agent_outlined,
        ConsultationScreen(apiClient: widget.apiClient),
      ),
      _Page(
        'Tìm thuốc',
        Icons.search,
        MedicineSearchScreen(apiClient: widget.apiClient),
      ),
      _Page(
        'Kho và lô',
        Icons.inventory_2_outlined,
        InventoryScreen(apiClient: widget.apiClient),
      ),
      _Page(
        'Lịch sử quét',
        Icons.history,
        HistoryScreen(apiClient: widget.apiClient),
      ),
      _Page(
        'Xác thực',
        Icons.verified_user_outlined,
        VerificationScreen(apiClient: widget.apiClient),
      ),
      _Page(
        'Cảnh báo',
        Icons.warning_amber,
        AlertsScreen(apiClient: widget.apiClient),
      ),
      _Page(
        'Danh sách thuốc',
        Icons.medication_outlined,
        ReportsScreen(apiClient: widget.apiClient),
      ),
      if (widget.roles.contains('Admin'))
        _Page(
          'Nhà cung ứng',
          Icons.local_shipping_outlined,
          SuppliersScreen(
            apiClient: widget.apiClient,
            refreshVersion: _supplierRefreshVersion,
          ),
        ),
      if (widget.roles.contains('Admin'))
        _Page(
          'Quản trị',
          Icons.admin_panel_settings_outlined,
          AdminScreen(apiClient: widget.apiClient),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(page.title),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          Navigator.pop(context);
          setState(() {
            _index = index;
            if (_pages[index].title == 'Nhà cung ứng') {
              _supplierRefreshVersion++;
            }
            _pages = _buildPages();
          });
        },
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 24, 16, 12),
            child: Text('Chức năng'),
          ),
          for (final item in _pages)
            NavigationDrawerDestination(
              icon: Icon(item.icon),
              label: Text(item.title),
            ),
        ],
      ),
      body: page.child,
    );
  }
}

class _Page {
  const _Page(this.title, this.icon, this.child);

  final String title;
  final IconData icon;
  final Widget child;
}
