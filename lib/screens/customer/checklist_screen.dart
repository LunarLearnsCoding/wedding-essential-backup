import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/checklist_task_model.dart';
import '../../services/checklist_service.dart';

/// Displays the checklist page and coordinates the actions available on it.
class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});
  static final ChecklistService _service = ChecklistService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Wedding Checklist')),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddTask(context, user.uid),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Add task'),
            ),
      body: user == null
          ? const _ChecklistMessage('Please sign in again.')
          : StreamBuilder<List<ChecklistTaskModel>>(
              stream: _service.getTasksByCustomer(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const _ChecklistMessage(
                    'Could not load your checklist. Please try again.',
                  );
                }
                final tasks = [...?snapshot.data]
                  ..sort((a, b) {
                    if (a.isCompleted != b.isCompleted) {
                      return a.isCompleted ? 1 : -1;
                    }
                    return b.createdAt.compareTo(a.createdAt);
                  });
                if (tasks.isEmpty) {
                  return const _ChecklistEmpty();
                }
                final completed = tasks
                    .where((task) => task.isCompleted)
                    .length;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                  children: [
                    _ProgressCard(completed: completed, total: tasks.length),
                    const SizedBox(height: 16),
                    ...tasks.map((task) => _TaskCard(task: task)),
                  ],
                );
              },
            ),
    );
  }

  /// Opens the add task interface for the user.
  Future<void> _showAddTask(BuildContext context, String customerId) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add checklist task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Task',
            hintText: 'e.g. Confirm photographer',
          ),
          onSubmitted: (_) => _saveTask(dialogContext, customerId, controller),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _saveTask(dialogContext, customerId, controller),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  /// Validates and saves the current task values.
  Future<void> _saveTask(
    BuildContext dialogContext,
    String customerId,
    TextEditingController controller,
  ) async {
    final title = controller.text.trim();
    if (title.isEmpty) return;
    try {
      await _service.addTask(
        ChecklistTaskModel(
          id: '',
          customerId: customerId,
          title: title,
          description: '',
          isCompleted: false,
          createdAt: DateTime.now(),
        ),
      );
      if (dialogContext.mounted) Navigator.pop(dialogContext);
    } catch (_) {
      if (!dialogContext.mounted) return;
      ScaffoldMessenger.of(
        dialogContext,
      ).showSnackBar(const SnackBar(content: Text('Could not add this task.')));
    }
  }
}

/// Renders the reusable progress card UI component.
class _ProgressCard extends StatelessWidget {
  final int completed;
  final int total;
  const _ProgressCard({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.selectedSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$completed of $total tasks completed',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: AppColors.surface,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// Renders the reusable task card UI component.
class _TaskCard extends StatefulWidget {
  final ChecklistTaskModel task;
  const _TaskCard({required this.task});
  @override
  State<_TaskCard> createState() => _TaskCardState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _TaskCardState extends State<_TaskCard> {
  final ChecklistService _service = ChecklistService();
  bool _isUpdating = false;

  Future<void> _toggle(bool? value) async {
    if (_isUpdating || value == null) return;
    setState(() => _isUpdating = true);
    try {
      await _service.toggleTask(taskId: widget.task.id, isCompleted: value);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this task.')),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  /// Removes the selected item after the required checks or confirmation.
  Future<void> _delete() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await _service.deleteTask(widget.task.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this task.')),
      );
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Checkbox(value: task.isCompleted, onChanged: _toggle),
        title: Text(
          task.title,
          style: TextStyle(
            color: task.isCompleted
                ? AppColors.textSecondary
                : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          tooltip: 'Delete task',
          onPressed: _isUpdating ? null : _delete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ),
    );
  }
}

/// Renders the reusable checklist empty UI component.
class _ChecklistEmpty extends StatelessWidget {
  const _ChecklistEmpty();
  @override
  Widget build(BuildContext context) {
    return const _ChecklistMessage(
      'Your checklist is empty. Add your first wedding task.',
      icon: Icons.checklist_rounded,
    );
  }
}

/// Renders the reusable checklist message UI component.
class _ChecklistMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  const _ChecklistMessage(
    this.message, {
    this.icon = Icons.error_outline_rounded,
  });
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
