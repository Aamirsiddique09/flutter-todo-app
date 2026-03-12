// lib/data/models/project_model.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ProjectModel {
  final String id;
  final String name;
  final String? description;
  final String color; // Hex color
  final IconData icon;
  final DateTime createdAt;
  final int totalTasks;
  final int completedTasks;

  ProjectModel({
    String? id,
    required this.name,
    this.description,
    this.color = '#5247E6',
    this.icon = Icons.folder,
    DateTime? createdAt,
    this.totalTasks = 0,
    this.completedTasks = 0,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  double get progress => totalTasks > 0 ? completedTasks / totalTasks : 0;

  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    IconData? icon,
    DateTime? createdAt,
    int? totalTasks,
    int? completedTasks,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'createdAt': createdAt.toIso8601String(),
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
    };
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      color: json['color'],
      icon: IconData(
        json['icon'],
        fontFamily: json['iconFontFamily'] ?? 'MaterialIcons',
      ),
      createdAt: DateTime.parse(json['createdAt']),
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
    );
  }
}
