enum TaskKind { task, routine, capture }

enum TaskPriority { low, normal, high }

class TaskItem {
  final String id;
  final String title;
  final String? notes;
  final TaskKind kind;
  final TaskPriority priority;
  final DateTime? dueAt;
  final String? recurrence;
  final DateTime? reminderAt;
  final DateTime? snoozedUntil;
  final bool completed;
  final int? focusMinutes;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TaskItem({
    required this.id,
    required this.title,
    this.notes,
    this.kind = TaskKind.task,
    this.priority = TaskPriority.normal,
    this.dueAt,
    this.recurrence,
    this.reminderAt,
    this.snoozedUntil,
    this.completed = false,
    this.focusMinutes,
    required this.createdAt,
    this.completedAt,
  });

  TaskItem copyWith({
    String? title,
    String? notes,
    TaskKind? kind,
    TaskPriority? priority,
    DateTime? dueAt,
    String? recurrence,
    DateTime? reminderAt,
    DateTime? snoozedUntil,
    bool? completed,
    int? focusMinutes,
    DateTime? completedAt,
  }) =>
      TaskItem(
        id: id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        kind: kind ?? this.kind,
        priority: priority ?? this.priority,
        dueAt: dueAt ?? this.dueAt,
        recurrence: recurrence ?? this.recurrence,
        reminderAt: reminderAt ?? this.reminderAt,
        snoozedUntil: snoozedUntil ?? this.snoozedUntil,
        completed: completed ?? this.completed,
        focusMinutes: focusMinutes ?? this.focusMinutes,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
      );

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        notes: json['notes'] as String?,
        kind: TaskKind.values.firstWhere(
          (value) => value.name == json['kind'],
          orElse: () => TaskKind.task,
        ),
        priority: TaskPriority.values.firstWhere(
          (value) => value.name == json['priority'],
          orElse: () => TaskPriority.normal,
        ),
        dueAt: _date(json['dueAt']),
        recurrence: json['recurrence'] as String?,
        reminderAt: _date(json['reminderAt']),
        snoozedUntil: _date(json['snoozedUntil']),
        completed: json['completed'] as bool? ?? false,
        focusMinutes: json['focusMinutes'] as int?,
        createdAt: _date(json['createdAt']) ?? DateTime.now(),
        completedAt: _date(json['completedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'kind': kind.name,
        'priority': priority.name,
        'dueAt': dueAt?.toIso8601String(),
        'recurrence': recurrence,
        'reminderAt': reminderAt?.toIso8601String(),
        'snoozedUntil': snoozedUntil?.toIso8601String(),
        'completed': completed,
        'focusMinutes': focusMinutes,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  static DateTime? _date(Object? value) => value is String
      ? DateTime.tryParse(value)
      : value is DateTime
          ? value
          : null;
}
