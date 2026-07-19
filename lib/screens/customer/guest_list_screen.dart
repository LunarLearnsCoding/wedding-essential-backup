import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../models/guest_model.dart';
import '../../services/guest_service.dart';

class GuestListScreen extends StatelessWidget {
  const GuestListScreen({super.key});
  static final GuestService _service = GuestService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Guest List')),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddGroup(context, user.uid),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('New group'),
            ),
      body: user == null
          ? const _GuestMessage('Please sign in again.')
          : StreamBuilder<List<String>>(
              stream: _service.getGroupsByCustomer(user.uid),
              builder: (context, groupSnapshot) {
                if (groupSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (groupSnapshot.hasError) {
                  return const _GuestMessage(
                    'Could not load guest groups. Please try again.',
                  );
                }
                return StreamBuilder<List<GuestModel>>(
                  stream: _service.getGuestsByCustomer(user.uid),
                  builder: (context, guestSnapshot) {
                    if (guestSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (guestSnapshot.hasError) {
                      return const _GuestMessage(
                        'Could not load guests. Please try again.',
                      );
                    }
                    final guests = guestSnapshot.data ?? const <GuestModel>[];
                    final groups = <String>{...?groupSnapshot.data};
                    groups.addAll(
                      guests
                          .map((guest) => guest.relation.trim())
                          .where((group) => group.isNotEmpty),
                    );
                    final sortedGroups = groups.toList()
                      ..sort(
                        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
                      );
                    if (sortedGroups.isEmpty) return const _GuestEmpty();
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                      children: [
                        _GuestSummary(
                          groups: sortedGroups.length,
                          guests: guests.fold<int>(
                            0,
                            (total, guest) => total + guest.numberOfGuests,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...sortedGroups.map(
                          (group) => _GuestGroupCard(
                            customerId: user.uid,
                            groupName: group,
                            guests: guests
                                .where(
                                  (guest) => guest.relation.trim() == group,
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _showAddGroup(BuildContext context, String customerId) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create guest group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Group name',
            hintText: 'e.g. Bride’s Family',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              try {
                await _service.addGroup(
                  customerId: customerId,
                  groupName: name,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (_) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Could not create this group.')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

class _GuestSummary extends StatelessWidget {
  final int groups;
  final int guests;
  const _GuestSummary({required this.groups, required this.guests});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.selectedSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, color: AppColors.primary, size: 30),
          const SizedBox(width: 12),
          Text(
            '$guests ${guests == 1 ? 'guest' : 'guests'} in $groups ${groups == 1 ? 'group' : 'groups'}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _GuestGroupCard extends StatelessWidget {
  final String customerId;
  final String groupName;
  final List<GuestModel> guests;
  const _GuestGroupCard({
    required this.customerId,
    required this.groupName,
    required this.guests,
  });

  @override
  Widget build(BuildContext context) {
    final guestCount = guests.fold<int>(
      0,
      (total, guest) => total + guest.numberOfGuests,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _GuestGroupDetailsScreen(
              customerId: customerId,
              groupName: groupName,
            ),
          ),
        ),
        leading: const CircleAvatar(
          backgroundColor: AppColors.selectedSurface,
          child: Icon(Icons.group_outlined, color: AppColors.primary),
        ),
        title: Text(
          groupName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('$guestCount ${guestCount == 1 ? 'guest' : 'guests'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') _confirmDeleteGroup(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('Delete group')),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteGroup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete group?'),
        content: Text(
          guests.isEmpty
              ? 'Remove “$groupName” from your guest list?'
              : 'This will also remove all guests in “$groupName”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await GuestListScreen._service.deleteGroup(
        customerId: customerId,
        groupName: groupName,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this group.')),
      );
    }
  }
}

class _GuestGroupDetailsScreen extends StatelessWidget {
  final String customerId;
  final String groupName;

  const _GuestGroupDetailsScreen({
    required this.customerId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(groupName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGuest(context),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add guest'),
      ),
      body: StreamBuilder<List<GuestModel>>(
        stream: GuestListScreen._service.getGuestsByCustomer(customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _GuestMessage(
              'Could not load guests. Please try again.',
            );
          }
          final guests =
              (snapshot.data ?? const <GuestModel>[])
                  .where((guest) => guest.relation.trim() == groupName)
                  .toList()
                ..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );
          if (guests.isEmpty) {
            return const _GuestMessage(
              'No guests in this group yet. Tap Add guest to begin.',
              icon: Icons.person_add_alt_1_outlined,
            );
          }
          final partyTotal = guests.fold<int>(
            0,
            (total, guest) => total + guest.numberOfGuests,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.selectedSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${guests.length} ${guests.length == 1 ? 'guest' : 'guests'} • Party total: $partyTotal',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 14),
              ...guests.map(
                (guest) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: _GuestTile(guest: guest),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddGuest(BuildContext context) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final countController = TextEditingController(text: '1');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add guest to $groupName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Guest name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Party size'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final count = int.tryParse(countController.text.trim()) ?? 1;
              try {
                await GuestListScreen._service.addGuest(
                  GuestModel(
                    id: '',
                    customerId: customerId,
                    name: name,
                    phone: phoneController.text.trim(),
                    relation: groupName,
                    numberOfGuests: count < 1 ? 1 : count,
                    isInvited: false,
                    isAttending: false,
                    createdAt: DateTime.now(),
                  ),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (_) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Could not add this guest.')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    nameController.dispose();
    phoneController.dispose();
    countController.dispose();
  }
}

class _GuestTile extends StatefulWidget {
  final GuestModel guest;
  const _GuestTile({required this.guest});
  @override
  State<_GuestTile> createState() => _GuestTileState();
}

class _GuestTileState extends State<_GuestTile> {
  bool _isDeleting = false;
  @override
  Widget build(BuildContext context) {
    final guest = widget.guest;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.background,
        child: Text(
          guest.name.isEmpty ? '?' : guest.name[0].toUpperCase(),
          style: const TextStyle(color: AppColors.primaryDark),
        ),
      ),
      title: Text(
        guest.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          if (guest.phone.isNotEmpty) guest.phone,
          'Party of ${guest.numberOfGuests}',
        ].join(' • '),
      ),
      trailing: IconButton(
        tooltip: 'Remove guest',
        onPressed: _isDeleting
            ? null
            : () async {
                setState(() => _isDeleting = true);
                try {
                  await GuestListScreen._service.deleteGuest(guest.id);
                } catch (_) {
                  if (!mounted) return;
                  setState(() => _isDeleting = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not remove this guest.'),
                    ),
                  );
                }
              },
        icon: const Icon(Icons.person_remove_outlined),
      ),
    );
  }
}

class _GuestEmpty extends StatelessWidget {
  const _GuestEmpty();
  @override
  Widget build(BuildContext context) {
    return const _GuestMessage(
      'Create a group to start organizing your guests.',
      icon: Icons.groups_outlined,
    );
  }
}

class _GuestMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  const _GuestMessage(this.message, {this.icon = Icons.error_outline_rounded});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
