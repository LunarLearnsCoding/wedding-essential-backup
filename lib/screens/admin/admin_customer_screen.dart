import 'package:flutter/material.dart';

import '../../core/constants/admin_app_colors.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_data_table.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_formatters.dart';
import 'widgets/admin_helpers.dart';
import 'widgets/admin_search_bar.dart';
import 'widgets/admin_status_chip.dart';

/// Displays the admin users page and coordinates the actions available on it.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSearchBar(
          hintText: 'Search customers by name, email, phone, or status',
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: widget.service.plainCollectionStream('users'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return AdminEmptyState(
                  title: 'Unable to load users',
                  message: snapshot.error.toString(),
                  icon: Icons.error_outline,
                );
              }

              final users =
                  (snapshot.data?.docs ?? [])
                      .map((doc) => AdminCollectionItem.fromDoc(doc))
                      .where((item) {
                        final role = item.stringValue(['role']).toLowerCase();
                        return role.isEmpty ||
                            role == 'customer' ||
                            role == 'user';
                      })
                      .where((item) {
                        return AdminHelpers.matchesValues(_search, [
                          item.stringValue([
                            'name',
                            'fullName',
                            'displayName',
                            'username',
                          ]),
                          item.stringValue(['email']),
                          item.stringValue(['phone', 'phoneNumber']),
                          item.stringValue(['status'], fallback: 'active'),
                        ]);
                      })
                      .toList()
                    ..sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
              if (users.isEmpty) {
                return const AdminEmptyState(
                  title: 'No users found',
                  message: 'Registered customer accounts will appear here.',
                  icon: Icons.people_alt_outlined,
                );
              }

              return AdminDataTable(
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('NAME')),
                  DataColumn(label: Text('EMAIL')),
                  DataColumn(label: Text('PHONE')),
                  DataColumn(label: Text('JOINED')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: users.asMap().entries.map((entry) {
                  final item = entry.value;
                  final name = item.stringValue([
                    'name',
                    'fullName',
                    'displayName',
                    'username',
                  ], fallback: 'Unnamed user');
                  final email = item.stringValue(['email'], fallback: '-');
                  final phone = item.stringValue([
                    'phone',
                    'phoneNumber',
                  ], fallback: '-');
                  final status = item.stringValue([
                    'status',
                  ], fallback: 'active');
                  final joined = item.dateValue(['createdAt', 'joinedAt']);
                  final inactive = {
                    'inactive',
                    'suspended',
                    'blocked',
                  }.contains(status.toLowerCase());

                  return DataRow(
                    cells: [
                      DataCell(Text('${entry.key + 1}')),
                      DataCell(Text(name)),
                      DataCell(Text(email)),
                      DataCell(Text(phone)),
                      DataCell(Text(AdminFormatters.date(joined))),
                      DataCell(AdminStatusChip(label: status)),
                      DataCell(
                        AdminTableActions(
                          children: [
                            AdminTableAction(
                              tooltip: inactive ? 'Activate' : 'Suspend',
                              icon: inactive
                                  ? Icons.check_circle_outline
                                  : Icons.block_outlined,
                              onPressed: () =>
                                  _toggleStatus(item.id, inactive: inactive),
                            ),
                            AdminTableAction(
                              tooltip: 'Delete',
                              icon: Icons.delete_outline,
                              color: AdminAppColors.danger,
                              onPressed: () => _deleteUser(item.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  DateTime _createdAt(AdminCollectionItem item) =>
      item.dateValue(['createdAt', 'joinedAt', 'registeredAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _toggleStatus(String id, {required bool inactive}) async {
    try {
      if (inactive) {
        await widget.service.activateUser(id);
      } else {
        await widget.service.suspendUser(id);
      }
      if (!mounted) return;
      AdminHelpers.showSnack(
        context,
        inactive ? 'User activated' : 'User suspended',
      );
    } catch (error) {
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }

  /// Removes the selected item after the required checks or confirmation.
  Future<void> _deleteUser(String id) async {
    final confirmed = await AdminHelpers.confirm(
      context,
      title: 'Delete user?',
      message:
          'This permanently deletes the Firebase Authentication account and '
          'its customer records.',
      confirmText: 'Delete',
    );
    if (!confirmed) return;
    try {
      await widget.service.deleteUserData(id);
      if (!mounted) return;
      AdminHelpers.showSnack(context, 'User deleted');
    } catch (error) {
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }
}
