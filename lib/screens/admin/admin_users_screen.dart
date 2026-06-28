import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_formatters.dart';
import 'widgets/admin_helpers.dart';
import 'widgets/admin_record_card.dart';
import 'widgets/admin_search_bar.dart';
import 'widgets/admin_status_chip.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({
    super.key,
    required this.service,
  });

  final AdminService service;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSearchBar(
          hintText: 'Search users by name, email, role, or status',
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: widget.service.collectionStream('users'),
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

              final docs = snapshot.data?.docs ?? [];
              final users = docs
                  .map((doc) => AdminCollectionItem.fromDoc(doc))
                  .where((item) => AdminHelpers.matchesSearch(item.data, _search))
                  .toList();

              if (users.isEmpty) {
                return const AdminEmptyState(
                  title: 'No users found',
                  message: 'Users will appear here after customers or admins sign up.',
                  icon: Icons.people_alt_outlined,
                );
              }

              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = users[index];
                  final name = item.stringValue([
                    'name',
                    'fullName',
                    'displayName',
                    'username',
                  ], fallback: 'Unnamed user');
                  final email = item.stringValue(['email']);
                  final role = item.stringValue(['role'], fallback: 'customer');
                  final status = item.stringValue(['status'], fallback: 'active');
                  final createdAt = item.dateValue(['createdAt', 'joinedAt']);
                  final isSuspended = status.toLowerCase() == 'suspended';

                  return AdminRecordCard(
                    leadingIcon: Icons.person_outline,
                    title: name,
                    subtitle: email,
                    trailing: AdminStatusChip(label: status),
                    meta: [
                      AdminMetaPill(icon: Icons.badge_outlined, label: role),
                      AdminMetaPill(
                        icon: Icons.calendar_today_outlined,
                        label: AdminFormatters.date(createdAt),
                      ),
                    ],
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            if (isSuspended) {
                              await widget.service.activateUser(item.id);
                              if (!mounted) return;
                              AdminHelpers.showSnack(context, 'User activated');
                            } else {
                              await widget.service.suspendUser(item.id);
                              if (!mounted) return;
                              AdminHelpers.showSnack(context, 'User suspended');
                            }
                          } catch (error) {
                            if (!mounted) return;
                            AdminHelpers.showSnack(
                              context,
                              error.toString(),
                              isError: true,
                            );
                          }
                        },
                        icon: Icon(
                          isSuspended
                              ? Icons.check_circle_outline
                              : Icons.block_outlined,
                        ),
                        label: Text(isSuspended ? 'Activate' : 'Suspend'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await AdminHelpers.confirm(
                            context,
                            title: 'Delete user?',
                            message: 'This will permanently delete this user document.',
                            confirmText: 'Delete',
                          );
                          if (!confirmed) return;
                          try {
                            await widget.service.deleteDocument('users', item.id);
                            if (!mounted) return;
                            AdminHelpers.showSnack(context, 'User deleted');
                          } catch (error) {
                            if (!mounted) return;
                            AdminHelpers.showSnack(
                              context,
                              error.toString(),
                              isError: true,
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ],
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
