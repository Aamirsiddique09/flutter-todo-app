// lib/data/repositories/task_repository.dart

import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../models/project_model.dart';
import '../../services/local_storage.dart';

/// Repository pattern for task-related operations
/// Handles data operations and business logic
class TaskRepository {
  final LocalStorageService _storage;

  TaskRepository({LocalStorageService? storage})
    : _storage = storage ?? localStorage;

  // ==================== Task Operations ====================

  /// Get all tasks from storage
  List<TaskModel> getAllTasks() {
    return _storage.getTasks();
  }

  /// Get task by ID
  TaskModel? getTaskById(String taskId) {
    final tasks = getAllTasks();
    try {
      return tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  /// Get tasks filtered by completion status
  List<TaskModel> getTasksByCompletion(bool isCompleted) {
    return getAllTasks()
        .where((task) => task.isCompleted == isCompleted)
        .toList();
  }

  /// Get pending (incomplete) tasks
  List<TaskModel> getPendingTasks() {
    return getTasksByCompletion(false);
  }

  /// Get completed tasks
  List<TaskModel> getCompletedTasks() {
    return getTasksByCompletion(true);
  }

  /// Get tasks for specific date
  List<TaskModel> getTasksForDate(DateTime date) {
    return _storage.getTasksByDate(date);
  }

  /// Get tasks for today
  List<TaskModel> getTodaysTasks() {
    return getTasksForDate(DateTime.now());
  }

  /// Get tasks by project ID
  List<TaskModel> getTasksByProject(String projectId) {
    return _storage.getTasksByProject(projectId);
  }

  /// Get tasks by priority
  List<TaskModel> getTasksByPriority(String priority) {
    return getAllTasks().where((task) => task.priority == priority).toList();
  }

  /// Get high priority tasks
  List<TaskModel> getHighPriorityTasks() {
    return getTasksByPriority('high');
  }

  /// Search tasks by title or description
  List<TaskModel> searchTasks(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllTasks().where((task) {
      final titleMatch = task.title.toLowerCase().contains(lowerQuery);
      final descMatch =
          task.description?.toLowerCase().contains(lowerQuery) ?? false;
      return titleMatch || descMatch;
    }).toList();
  }

  /// Add new task
  Future<void> addTask(TaskModel task) async {
    await _storage.addTask(task);
  }

  /// Create task with validation
  Future<TaskModel> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String? projectId,
    String priority = 'medium',
    List<String> tags = const [],
  }) async {
    if (title.trim().isEmpty) {
      throw TaskRepositoryException('Task title cannot be empty');
    }

    final task = TaskModel(
      title: title.trim(),
      description: description?.trim(),
      dueDate: dueDate,
      projectId: projectId,
      priority: priority,
      tags: tags,
    );

    await _storage.addTask(task);
    return task;
  }

  /// Update existing task
  Future<void> updateTask(TaskModel task) async {
    await _storage.updateTask(task);
  }

  /// Toggle task completion status
  Future<void> toggleTaskCompletion(String taskId) async {
    final task = getTaskById(taskId);
    if (task == null) {
      throw TaskRepositoryException('Task not found');
    }

    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );

    await _storage.updateTask(updatedTask);
  }

  /// Complete task
  Future<void> completeTask(String taskId) async {
    final task = getTaskById(taskId);
    if (task == null) {
      throw TaskRepositoryException('Task not found');
    }

    if (task.isCompleted) return;

    final updatedTask = task.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    await _storage.updateTask(updatedTask);
    await _storage.completeTask(taskId);
  }

  /// Uncomplete task
  Future<void> uncompleteTask(String taskId) async {
    final task = getTaskById(taskId);
    if (task == null) {
      throw TaskRepositoryException('Task not found');
    }

    final updatedTask = task.copyWith(isCompleted: false, completedAt: null);

    await _storage.updateTask(updatedTask);
  }

  /// Delete task by ID
  Future<void> deleteTask(String taskId) async {
    await _storage.deleteTask(taskId);
  }

  /// Delete multiple tasks
  Future<void> deleteMultipleTasks(List<String> taskIds) async {
    for (final id in taskIds) {
      await deleteTask(id);
    }
  }

  /// Delete all completed tasks
  Future<int> clearCompletedTasks() async {
    final completedTasks = getCompletedTasks();
    final count = completedTasks.length;

    for (final task in completedTasks) {
      await deleteTask(task.id);
    }

    return count;
  }

  /// Delete all tasks
  Future<void> clearAllTasks() async {
    await _storage.saveTasks([]);
  }

  // ==================== Statistics ====================

  /// Get task completion statistics
  TaskStatistics getStatistics() {
    final allTasks = getAllTasks();
    final completedTasks = allTasks.where((t) => t.isCompleted).toList();
    final pendingTasks = allTasks.where((t) => !t.isCompleted).toList();

    return TaskStatistics(
      totalTasks: allTasks.length,
      completedTasks: completedTasks.length,
      pendingTasks: pendingTasks.length,
      completionRate: allTasks.isEmpty
          ? 0.0
          : completedTasks.length / allTasks.length,
      highPriorityPending: pendingTasks
          .where((t) => t.priority == 'high')
          .length,
      tasksDueToday: getTodaysTasks().length,
      streak: _storage.getStreak(),
    );
  }

  /// Get weekly progress data for charts
  List<DailyProgress> getWeeklyProgress() {
    final now = DateTime.now();
    final List<DailyProgress> progress = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayTasks = getTasksForDate(date);
      final completed = dayTasks.where((t) => t.isCompleted).length;

      progress.add(
        DailyProgress(
          date: date,
          totalTasks: dayTasks.length,
          completedTasks: completed,
          completionRate: dayTasks.isEmpty ? 0.0 : completed / dayTasks.length,
        ),
      );
    }

    return progress;
  }

  /// Get productivity score (0-100)
  int getProductivityScore() {
    final stats = getStatistics();
    if (stats.totalTasks == 0) return 0;

    final completionScore = (stats.completionRate * 60).toInt(); // 60% weight
    final streakScore = (stats.streak.clamp(0, 30) / 30 * 20)
        .toInt(); // 20% weight
    final consistencyScore = stats.pendingTasks < 5 ? 20 : 10; // 20% weight

    return (completionScore + streakScore + consistencyScore).clamp(0, 100);
  }

  // ==================== Batch Operations ====================

  /// Reorder tasks (update order in storage)
  Future<void> reorderTasks(List<TaskModel> orderedTasks) async {
    await _storage.saveTasks(orderedTasks);
  }

  /// Move task to different project
  Future<void> moveTaskToProject(String taskId, String? newProjectId) async {
    final task = getTaskById(taskId);
    if (task == null) {
      throw TaskRepositoryException('Task not found');
    }

    final updatedTask = task.copyWith(projectId: newProjectId);
    await _storage.updateTask(updatedTask);
  }

  /// Change task priority
  Future<void> setTaskPriority(String taskId, String priority) async {
    final task = getTaskById(taskId);
    if (task == null) {
      throw TaskRepositoryException('Task not found');
    }

    final updatedTask = task.copyWith(priority: priority);
    await _storage.updateTask(updatedTask);
  }

  /// Postpone task to next day
  Future<void> postponeTask(String taskId) async {
    final task = getTaskById(taskId);
    if (task == null) {
      throw TaskRepositoryException('Task not found');
    }

    final newDueDate = (task.dueDate ?? DateTime.now()).add(
      const Duration(days: 1),
    );
    final updatedTask = task.copyWith(dueDate: newDueDate);
    await _storage.updateTask(updatedTask);
  }

  /// Duplicate task
  Future<TaskModel> duplicateTask(String taskId) async {
    final task = getTaskById(taskId);
    if (task == null) {
      throw TaskRepositoryException('Task not found');
    }

    final newTask = TaskModel(
      title: '${task.title} (Copy)',
      description: task.description,
      dueDate: task.dueDate,
      projectId: task.projectId,
      priority: task.priority,
      tags: List.from(task.tags),
    );

    await _storage.addTask(newTask);
    return newTask;
  }

  // ==================== Project Operations ====================

  /// Get all projects
  List<ProjectModel> getAllProjects() {
    return _storage.getProjects();
  }

  /// Get project by ID
  ProjectModel? getProjectById(String projectId) {
    final projects = getAllProjects();
    try {
      return projects.firstWhere((p) => p.id == projectId);
    } catch (e) {
      return null;
    }
  }

  /// Create new project
  Future<ProjectModel> createProject({
    required String name,
    String? description,
    String color = '#5247E6',
    IconData icon = Icons.folder,
  }) async {
    if (name.trim().isEmpty) {
      throw TaskRepositoryException('Project name cannot be empty');
    }

    final project = ProjectModel(
      name: name.trim(),
      description: description?.trim(),
      color: color,
      icon: icon,
    );

    await _storage.addProject(project);
    return project;
  }

  /// Update project
  Future<void> updateProject(ProjectModel project) async {
    await _storage.updateProject(project);
  }

  /// Delete project and optionally its tasks
  Future<void> deleteProject(
    String projectId, {
    bool deleteTasks = false,
  }) async {
    if (deleteTasks) {
      final projectTasks = getTasksByProject(projectId);
      for (final task in projectTasks) {
        await deleteTask(task.id);
      }
    } else {
      // Move tasks to no project
      final projectTasks = getTasksByProject(projectId);
      for (final task in projectTasks) {
        await moveTaskToProject(task.id, null);
      }
    }

    await _storage.deleteProject(projectId);
  }

  /// Update project task counts
  Future<void> recalculateProjectStats(String projectId) async {
    final project = getProjectById(projectId);
    if (project == null) return;

    final tasks = getTasksByProject(projectId);
    final total = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;

    final updatedProject = project.copyWith(
      totalTasks: total,
      completedTasks: completed,
    );

    await _storage.updateProject(updatedProject);
  }

  // ==================== Sync & Backup ====================

  /// Export all data
  Future<String> exportAllData() async {
    return await _storage.exportData();
  }

  /// Import data
  Future<void> importAllData(String jsonData) async {
    await _storage.importData(jsonData);
  }

  /// Clear all data
  Future<void> clearAllData() async {
    await _storage.clearAllData();
  }
}

/// Custom exception for repository errors
class TaskRepositoryException implements Exception {
  final String message;
  TaskRepositoryException(this.message);

  @override
  String toString() => 'TaskRepositoryException: $message';
}

/// Statistics model
class TaskStatistics {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final double completionRate;
  final int highPriorityPending;
  final int tasksDueToday;
  final int streak;

  TaskStatistics({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.completionRate,
    required this.highPriorityPending,
    required this.tasksDueToday,
    required this.streak,
  });

  @override
  String toString() {
    return 'TaskStatistics(total: $totalTasks, completed: $completedTasks, '
        'pending: $pendingTasks, rate: ${(completionRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Daily progress model for charts
class DailyProgress {
  final DateTime date;
  final int totalTasks;
  final int completedTasks;
  final double completionRate;

  DailyProgress({
    required this.date,
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
  });

  String get dayName {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  String get shortDate {
    return '${date.day}/${date.month}';
  }
}
