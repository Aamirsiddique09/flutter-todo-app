// lib/services/local_storage.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/task_model.dart';
import '../data/models/project_model.dart';
import '../data/models/user_model.dart';

class LocalStorageKeys {
  LocalStorageKeys._();

  // User Data
  static const String user = 'user_data';
  static const String isLoggedIn = 'is_logged_in';
  static const String authToken = 'auth_token';
  static const String themeMode = 'theme_mode';

  // Tasks
  static const String tasks = 'tasks_list';
  static const String completedTasks = 'completed_tasks';

  // Projects
  static const String projects = 'projects_list';

  // Settings
  static const String notificationsEnabled = 'notifications_enabled';
  static const String reminderTime = 'reminder_time';
  static const String language = 'app_language';

  // Stats
  static const String dailyStreak = 'daily_streak';
  static const String lastActiveDate = 'last_active_date';
  static const String totalTasksCompleted = 'total_tasks_completed';
}

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Generic Methods
  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  // User Methods
  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await setString(LocalStorageKeys.user, userJson);
    await setBool(LocalStorageKeys.isLoggedIn, true);
  }

  UserModel? getUser() {
    final userJson = getString(LocalStorageKeys.user);
    if (userJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearUser() async {
    await remove(LocalStorageKeys.user);
    await remove(LocalStorageKeys.authToken);
    await setBool(LocalStorageKeys.isLoggedIn, false);
  }

  bool isLoggedIn() {
    return getBool(LocalStorageKeys.isLoggedIn) ?? false;
  }

  // Theme Methods
  Future<void> saveThemeMode(String mode) async {
    await setString(LocalStorageKeys.themeMode, mode);
  }

  String? getThemeMode() {
    return getString(LocalStorageKeys.themeMode);
  }

  // Task Methods
  Future<void> saveTasks(List<TaskModel> tasks) async {
    final tasksJson = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await setStringList(LocalStorageKeys.tasks, tasksJson);
  }

  List<TaskModel> getTasks() {
    final tasksJson = getStringList(LocalStorageKeys.tasks) ?? [];
    return tasksJson
        .map((json) => TaskModel.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addTask(TaskModel task) async {
    final tasks = getTasks();
    tasks.add(task);
    await saveTasks(tasks);
  }

  Future<void> updateTask(TaskModel updatedTask) async {
    final tasks = getTasks();
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await saveTasks(tasks);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = getTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await saveTasks(tasks);
  }

  Future<void> completeTask(String taskId) async {
    final tasks = getTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(isCompleted: true);
      await saveTasks(tasks);
      await _incrementCompletedTasks();
    }
  }

  List<TaskModel> getTasksByDate(DateTime date) {
    final tasks = getTasks();
    return tasks.where((t) {
      return t.dueDate?.year == date.year &&
          t.dueDate?.month == date.month &&
          t.dueDate?.day == date.day;
    }).toList();
  }

  List<TaskModel> getTasksByProject(String projectId) {
    final tasks = getTasks();
    return tasks.where((t) => t.projectId == projectId).toList();
  }

  // Project Methods
  Future<void> saveProjects(List<ProjectModel> projects) async {
    final projectsJson = projects.map((p) => jsonEncode(p.toJson())).toList();
    await setStringList(LocalStorageKeys.projects, projectsJson);
  }

  List<ProjectModel> getProjects() {
    final projectsJson = getStringList(LocalStorageKeys.projects) ?? [];
    return projectsJson
        .map((json) => ProjectModel.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addProject(ProjectModel project) async {
    final projects = getProjects();
    projects.add(project);
    await saveProjects(projects);
  }

  Future<void> updateProject(ProjectModel updatedProject) async {
    final projects = getProjects();
    final index = projects.indexWhere((p) => p.id == updatedProject.id);
    if (index != -1) {
      projects[index] = updatedProject;
      await saveProjects(projects);
    }
  }

  Future<void> deleteProject(String projectId) async {
    final projects = getProjects();
    projects.removeWhere((p) => p.id == projectId);
    await saveProjects(projects);
  }

  // Stats Methods
  Future<void> updateStreak() async {
    final lastActive = getString(LocalStorageKeys.lastActiveDate);
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastActive == today) return; // Already updated today

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')[0];

    int currentStreak = getInt(LocalStorageKeys.dailyStreak) ?? 0;

    if (lastActive == yesterday) {
      // Continued streak
      currentStreak++;
    } else {
      // Broken streak, start over
      currentStreak = 1;
    }

    await setInt(LocalStorageKeys.dailyStreak, currentStreak);
    await setString(LocalStorageKeys.lastActiveDate, today);
  }

  int getStreak() {
    return getInt(LocalStorageKeys.dailyStreak) ?? 0;
  }

  Future<void> _incrementCompletedTasks() async {
    final current = getInt(LocalStorageKeys.totalTasksCompleted) ?? 0;
    await setInt(LocalStorageKeys.totalTasksCompleted, current + 1);
  }

  int getTotalCompletedTasks() {
    return getInt(LocalStorageKeys.totalTasksCompleted) ?? 0;
  }

  // Settings Methods
  Future<void> setNotificationsEnabled(bool enabled) async {
    await setBool(LocalStorageKeys.notificationsEnabled, enabled);
  }

  bool getNotificationsEnabled() {
    return getBool(LocalStorageKeys.notificationsEnabled) ?? true;
  }

  Future<void> setReminderTime(String time) async {
    await setString(LocalStorageKeys.reminderTime, time);
  }

  String? getReminderTime() {
    return getString(LocalStorageKeys.reminderTime);
  }

  // Batch Operations
  Future<String> exportData() async {
    final data = {
      'user': getUser()?.toJson(),
      'tasks': getTasks().map((t) => t.toJson()).toList(),
      'projects': getProjects().map((p) => p.toJson()).toList(),
      'stats': {
        'streak': getStreak(),
        'totalCompleted': getTotalCompletedTasks(),
      },
      'settings': {
        'theme': getThemeMode(),
        'notifications': getNotificationsEnabled(),
        'reminderTime': getReminderTime(),
      },
    };
    return jsonEncode(data);
  }

  Future<void> importData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      if (data['user'] != null) {
        await saveUser(UserModel.fromJson(data['user']));
      }

      if (data['tasks'] != null) {
        final tasks = (data['tasks'] as List)
            .map((t) => TaskModel.fromJson(t))
            .toList();
        await saveTasks(tasks);
      }

      if (data['projects'] != null) {
        final projects = (data['projects'] as List)
            .map((p) => ProjectModel.fromJson(p))
            .toList();
        await saveProjects(projects);
      }

      if (data['stats'] != null) {
        final stats = data['stats'] as Map<String, dynamic>;
        if (stats['streak'] != null) {
          await setInt(LocalStorageKeys.dailyStreak, stats['streak']);
        }
        if (stats['totalCompleted'] != null) {
          await setInt(
            LocalStorageKeys.totalTasksCompleted,
            stats['totalCompleted'],
          );
        }
      }

      if (data['settings'] != null) {
        final settings = data['settings'] as Map<String, dynamic>;
        if (settings['theme'] != null) {
          await saveThemeMode(settings['theme']);
        }
        if (settings['notifications'] != null) {
          await setNotificationsEnabled(settings['notifications']);
        }
        if (settings['reminderTime'] != null) {
          await setReminderTime(settings['reminderTime']);
        }
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  // Clear All Data
  Future<void> clearAllData() async {
    await clear();
  }

  // Debug Methods
  Map<String, dynamic> getAllData() {
    return {
      'keys': _prefs?.getKeys().toList(),
      'user': getUser()?.toJson(),
      'tasks': getTasks().map((t) => t.toJson()).toList(),
      'projects': getProjects().map((p) => p.toJson()).toList(),
    };
  }
}

// Singleton instance
final localStorage = LocalStorageService();
