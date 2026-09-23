import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _captureController = TextEditingController();
  Timer? _timer;
  int _seconds = 0;
  bool _focusing = false;

  @override
  void dispose() {
    _timer?.cancel();
    _captureController.dispose();
    super.dispose();
  }

  void _toggleFocus() {
    if (_focusing) {
      _timer?.cancel();
      setState(() => _focusing = false);
      return;
    }
    setState(() {
      _focusing = true;
      _seconds = 25 * 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds <= 1) {
        _timer?.cancel();
        if (mounted) setState(() => _focusing = false);
      } else if (mounted) {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _capture(AppProvider app) async {
    final text = _captureController.text.trim();
    if (text.isEmpty) return;
    await app.addTask(title: text, kind: TaskKind.capture);
    _captureController.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final tasks = app.tasks;
    final openTasks = tasks.where((task) => !task.completed).toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.mint,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => app.navigate(AppScreen.home),
        ),
        title: const Text('Today'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${openTasks.length} ${openTasks.length == 1 ? 'thing' : 'things'} to hold today',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Start a focus session',
                onPressed: _toggleFocus,
                icon: Icon(_focusing
                    ? Icons.stop_circle_outlined
                    : Icons.timer_outlined),
              ),
            ],
          ),
          if (_focusing) ...[
            Text(
              '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
            const Text('One gentle focus session. Pausing is allowed.',
                textAlign: TextAlign.center),
            TextButton.icon(
              onPressed: () => app.openNotificationPrompt(
                'Stay with me as a body double while I work on my next task. Keep me company, ask for a tiny update, and help me restart gently if I get distracted.',
              ),
              icon: const Icon(Icons.people_outline),
              label: const Text('Invite AI body double'),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _captureController,
                  onSubmitted: (_) => _capture(app),
                  decoration: const InputDecoration(
                    hintText: 'Capture a thought or task',
                    prefixIcon: Icon(Icons.bolt_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Save capture',
                onPressed: () => _capture(app),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (tasks.isEmpty)
            const _EmptyToday()
          else
            ...tasks.map((task) => _TaskTile(task: task)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showAddTaskDialog(context, app),
            icon: const Icon(Icons.add_task),
            label: const Text('Add a task'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTaskDialog(BuildContext context, AppProvider app) async {
    final controller = TextEditingController();
    DateTime? dueAt;
    String recurrence = 'none';
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add one thing'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                    hintText: 'What would help to remember?'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_none_outlined),
                title: Text(
                    dueAt == null ? 'Add reminder' : _formatDateTime(dueAt!)),
                subtitle: const Text('Optional notification date and time'),
                trailing: dueAt == null
                    ? const Icon(Icons.chevron_right)
                    : IconButton(
                        tooltip: 'Remove reminder',
                        onPressed: () => setDialogState(() => dueAt = null),
                        icon: const Icon(Icons.close),
                      ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate: dueAt ?? DateTime.now(),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: dueAt == null
                        ? TimeOfDay.now()
                        : TimeOfDay.fromDateTime(dueAt!),
                  );
                  if (!context.mounted) return;
                  if (time != null) {
                    final selected = DateTime(date.year, date.month, date.day,
                        time.hour, time.minute);
                    if (!selected.isAfter(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Choose a future reminder time.')),
                      );
                      return;
                    }
                    setDialogState(() => dueAt = selected);
                  }
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: recurrence,
                decoration: const InputDecoration(
                    labelText: 'Repeat', prefixIcon: Icon(Icons.repeat)),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('Once')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekdays', child: Text('Weekdays')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (value) =>
                    setDialogState(() => recurrence = value ?? 'none'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Add')),
        ],
      ),
    );
    controller.dispose();
    if (title != null && title.trim().isNotEmpty) {
      await app.addTask(
        title: title,
        dueAt: dueAt,
        reminderAt: dueAt,
        recurrence: recurrence == 'none' ? null : recurrence,
      );
    }
  }
}

String _formatDateTime(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
          ? value.hour - 12
          : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.month}/${value.day}/${value.year} at $hour:$minute $period';
}

class _TaskTile extends StatelessWidget {
  final TaskItem task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final task = this.task;
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => app.deleteTask(task),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade100,
        child: const Icon(Icons.delete_outline),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Checkbox(
                value: task.completed, onChanged: (_) => app.toggleTask(task)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      style: TextStyle(
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          fontWeight: FontWeight.w600)),
                  if (task.kind == TaskKind.capture)
                    const Text('Quick capture',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textMid)),
                  if (task.dueAt != null)
                    Text('Reminder ${_formatDateTime(task.dueAt!)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMid)),
                ],
              ),
            ),
            if (!task.completed && task.priority == TaskPriority.high)
              const Icon(Icons.priority_high, color: Colors.deepOrange),
            IconButton(
              tooltip: 'Remove task',
              onPressed: () => app.deleteTask(task),
              icon: const Icon(Icons.delete_outline),
            ),
            if (!task.completed)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'hour') {
                    app.snoozeTask(task, const Duration(hours: 1));
                  }
                  if (value == 'tomorrow') {
                    app.snoozeTask(task, const Duration(days: 1));
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'hour', child: Text('Snooze 1 hour')),
                  PopupMenuItem(
                      value: 'tomorrow', child: Text('Snooze until tomorrow')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: AppColors.mint, borderRadius: BorderRadius.circular(14)),
        child: const Column(
          children: [
            Icon(Icons.self_improvement_outlined,
                size: 36, color: AppColors.primary),
            SizedBox(height: 8),
            Text('Nothing is demanding your attention yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Capture one small thing, or let the day stay spacious.',
                textAlign: TextAlign.center),
          ],
        ),
      );
}
