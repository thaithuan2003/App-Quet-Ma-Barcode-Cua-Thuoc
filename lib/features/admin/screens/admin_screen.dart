import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/admin_user.dart';
import '../services/admin_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final AdminService _service = AdminService(widget.apiClient);
  late Future<List<AdminUser>> _usersFuture = _service.users();

  void _reload() {
    setState(() {
      _usersFuture = _service.users();
    });
  }

  void _showSuccess(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thông báo lỗi'),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createOrEditStaff([AdminUser? user]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        return _StaffFormSheet(
          user: user,
          onSave:
              ({
                required fullName,
                required username,
                required password,
              }) async {
                if (user == null) {
                  await _service.createStaff(
                    fullName: fullName,
                    username: username,
                    password: password ?? '',
                  );
                } else {
                  await _service.updateStaff(
                    userId: user.id,
                    fullName: fullName,
                    username: username,
                    password: password,
                  );
                }
              },
        );
      },
    );
    if (saved == true) {
      _reload();
      _showSuccess(
        user == null
            ? 'Đã thêm nhân viên thành công.'
            : 'Đã cập nhật nhân viên thành công.',
      );
    }
  }

  Future<void> _deleteStaff(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa nhân viên'),
          content: Text('Bạn muốn xóa hoặc khóa tài khoản ${user.fullName}?'),
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
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _service.deleteStaff(user.id);
      _reload();
      _showSuccess('Đã xóa nhân viên thành công.');
    } on ApiException catch (error) {
      await _showErrorDialog(error.message);
    }
  }

  Future<void> _toggleUser(AdminUser user) async {
    try {
      await _service.updateUserStatus(user.id, !user.isActive);
      _reload();
    } on ApiException catch (error) {
      await _showErrorDialog(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _UsersTab(
      future: _usersFuture,
      onRetry: _reload,
      onCreate: () => _createOrEditStaff(),
      onEdit: _createOrEditStaff,
      onDelete: _deleteStaff,
      onToggle: _toggleUser,
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab({
    required this.future,
    required this.onRetry,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final Future<List<AdminUser>> future;
  final VoidCallback onRetry;
  final VoidCallback onCreate;
  final ValueChanged<AdminUser> onEdit;
  final ValueChanged<AdminUser> onDelete;
  final ValueChanged<AdminUser> onToggle;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    setState(() => _query = _searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminUser>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return AppError(
            message: error is ApiException
                ? error.message
                : 'Chỉ admin mới được truy cập quản trị.',
            onRetry: widget.onRetry,
          );
        }
        final users = snapshot.data ?? [];
        final staffUsers = users.where((user) {
          if (!user.roles.contains('Staff')) {
            return false;
          }
          final normalizedQuery = _query.trim().toLowerCase();
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return user.fullName.toLowerCase().contains(normalizedQuery) ||
              user.username.toLowerCase().contains(normalizedQuery);
        }).toList();
        final totalStaffCount = users
            .where((user) => user.roles.contains('Staff'))
            .length;
        final allStaffUsers = users
            .where((user) => user.roles.contains('Staff'))
            .toList();
        final activeStaffCount = allStaffUsers
            .where((user) => user.isActive)
            .length;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.groups_outlined),
                            title: Text('$totalStaffCount'),
                            subtitle: Text(
                              'Nhân viên ($activeStaffCount đang hoạt động)',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: widget.onCreate,
                        icon: const Icon(Icons.person_add_alt),
                        label: const Text('Tạo nhân viên'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _searchController,
                    labelText: 'Tìm theo họ tên hoặc tên đăng nhập',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? IconButton(
                            tooltip: 'Tìm',
                            onPressed: _search,
                            icon: const Icon(Icons.search),
                          )
                        : IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: staffUsers.isEmpty
                  ? const Center(
                      child: Text('Không tìm thấy nhân viên phù hợp.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: staffUsers.length,
                      itemBuilder: (context, index) {
                        final user = staffUsers[index];
                        return Card(
                          child: ListTile(
                            leading: Switch(
                              value: user.isActive,
                              onChanged: (_) => widget.onToggle(user),
                            ),
                            title: Text(user.fullName),
                            subtitle: Text(
                              '${user.username} - ${user.isActive ? 'Đang hoạt động' : 'Đã khóa'}',
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Sửa',
                                  onPressed: () => widget.onEdit(user),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Xóa',
                                  onPressed: () => widget.onDelete(user),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _StaffFormSheet extends StatefulWidget {
  const _StaffFormSheet({required this.user, required this.onSave});

  final AdminUser? user;
  final Future<void> Function({
    required String fullName,
    required String username,
    required String? password,
  })
  onSave;

  @override
  State<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends State<_StaffFormSheet> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.user?.fullName ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.user?.username ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.user == null ? 'staff123' : '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final password = _passwordController.text.trim();
      await widget.onSave(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: password.isEmpty ? null : password,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
      return;
    } on ApiException catch (error) {
      if (mounted) {
        await _showFormErrorDialog(error.message);
        setState(() => _saving = false);
      }
    } catch (_) {
      if (mounted) {
        await _showFormErrorDialog('Không lưu được dữ liệu.');
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showFormErrorDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thông báo lỗi'),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheetFrame(
      title: widget.user == null
          ? 'Tạo tài khoản nhân viên'
          : 'Sửa thông tin nhân viên',
      saving: _saving,
      onSave: _save,
      children: [
        AppTextField(controller: _fullNameController, labelText: 'Họ tên'),
        AppTextField(
          controller: _usernameController,
          labelText: 'Tên đăng nhập',
        ),
        AppTextField(
          controller: _passwordController,
          obscureText: true,
          labelText: widget.user == null
              ? 'Mật khẩu'
              : 'Mật khẩu mới (bỏ trống nếu không đổi)',
        ),
      ],
    );
  }
}

class _FormSheetFrame extends StatelessWidget {
  const _FormSheetFrame({
    required this.title,
    required this.children,
    required this.saving,
    required this.onSave,
  });

  final String title;
  final List<Widget> children;
  final bool saving;
  final Future<void> Function() onSave;

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
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Thoát',
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final field in children) ...[
                field,
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: saving
                          ? null
                          : () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                      label: const Text('Thoát'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: saving ? null : () => onSave(),
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
