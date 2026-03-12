// lib/data/models/task_model.dart

import 'package:uuid/uuid.dart';

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? projectId;
  final String priority; // 'high', 'medium', 'low', 'routine'
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<String> tags;

  TaskModel({
    String? id,
    required this.title,
    this.description,
    this.dueDate,
    this.projectId,
    this.priority = 'medium',
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
    this.tags = const [],
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? projectId,
    String? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    List<String>? tags,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      projectId: projectId ?? this.projectId,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'projectId': projectId,
      'priority': priority,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'tags': tags,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      projectId: json['projectId'],
      priority: json['priority'] ?? 'medium',
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}
