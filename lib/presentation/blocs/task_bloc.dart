// lib/presentation/blocs/task_bloc.dart

import 'dart:async';
import 'dart:developer' as developer;
import '../../data/models/task_model.dart';
import '../../data/models/project_model.dart';
import '../../data/repositories/task_repository.dart';

/// Simple BLoC pattern for task state management
class TaskBloc {
  final TaskRepository _repository;
  bool _isInitialized = false;

  // Streams
  final _tasksController = StreamController<List<TaskModel>>.broadcast();
  final _projectsController = StreamController<List<ProjectModel>>.broadcast();
  final _statsController = StreamController<TaskStatistics>.broadcast();
  final _loadingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Public stream getters
  Stream<List<TaskModel>> get tasksStream => _tasksController.stream;
  Stream<List<ProjectModel>> get projectsStream => _projectsController.stream;
  Stream<TaskStatistics> get statsStream => _statsController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;
  Stream<String> get errorStream => _errorController.stream;

  TaskBloc({TaskRepository? repository})
    : _repository = repository ?? TaskRepository();

  // Current state
  List<TaskModel> _currentTasks = [];
  List<ProjectModel> _currentProjects = [];

  // Initialize
  Future<void> init() async {
    developer.log('🚀 TaskBloc initialized', name: 'TaskBloc');
    _isInitialized = true;
    await loadTasks();
    await loadProjects();
    updateStats();
  }

  // Load all tasks - FORCE RELOAD FROM STORAGE
  Future<void> loadTasks() async {
    if (!_isInitialized) {
      developer.log('⚠️ TaskBloc not initialized yet', name: 'TaskBloc');
      return;
    }

    developer.log('📥 Loading tasks...', name: 'TaskBloc');
    _loadingController.add(true);
    try {
      // Force fresh read from storage
      final tasks = _repository.getAllTasks();
      developer.log(
        '📋 Loaded ${tasks.length} tasks from repository',
        name: 'TaskBloc',
      );

      // ALWAYS create new list instance
      _currentTasks = List<TaskModel>.from(tasks);
      _tasksController.add(_currentTasks);
      developer.log(
        '✅ Tasks emitted to stream: ${_currentTasks.length}',
        name: 'TaskBloc',
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to load tasks',
        error: e,
        stackTrace: stackTrace,
        name: 'TaskBloc',
      );
      _errorController.add('Failed to load tasks: $e');
    } finally {
      _loadingController.add(false);
    }
  }

  // Create task - FIXED VERSION
  Future<void> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String? projectId,
    String priority = 'medium',
  }) async {
    developer.log('➕ Creating task: $title', name: 'TaskBloc');
    _loadingController.add(true);

    try {
      // Step 1: Create task in repository
      developer.log('📝 Calling repository.createTask...', name: 'TaskBloc');
      final newTask = await _repository.createTask(
        title: title,
        description: description,
        dueDate: dueDate,
        projectId: projectId,
        priority: priority,
      );
      developer.log(
        '✅ Task created in repository with ID: ${newTask.id}',
        name: 'TaskBloc',
      );

      // Step 2: FORCE RELOAD from storage to get fresh data
      developer.log(
        '🔄 Force reloading tasks from storage...',
        name: 'TaskBloc',
      );
      final freshTasks = _repository.getAllTasks();
      developer.log(
        '📊 Repository reports ${freshTasks.length} total tasks',
        name: 'TaskBloc',
      );

      // Step 3: Create COMPLETELY NEW list and emit
      _currentTasks = List<TaskModel>.from(freshTasks);
      developer.log(
        '📤 EMITTING ${_currentTasks.length} tasks to stream (hash: ${_currentTasks.hashCode})',
        name: 'TaskBloc',
      );
      _tasksController.add(_currentTasks);

      // Step 4: Update stats
      updateStats();

      // Step 5: Update project if needed
      if (projectId != null) {
        developer.log(
          '📁 Updating project stats for $projectId',
          name: 'TaskBloc',
        );
        await _repository.recalculateProjectStats(projectId);
        await loadProjects();
      }

      developer.log(
        '🎉 Task creation completed successfully',
        name: 'TaskBloc',
      );
    } on TaskRepositoryException catch (e) {
      developer.log(
        '❌ TaskRepositoryException: ${e.message}',
        name: 'TaskBloc',
      );
      _errorController.add(e.message);
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Unexpected error creating task',
        error: e,
        stackTrace: stackTrace,
        name: 'TaskBloc',
      );
      _errorController.add('Failed to create task: $e');
      rethrow;
    } finally {
      _loadingController.add(false);
    }
  }

  // Toggle task completion
  Future<void> toggleTask(String taskId) async {
    try {
      developer.log('🔄 Toggling task: $taskId', name: 'TaskBloc');
      await _repository.toggleTaskCompletion(taskId);

      // FORCE RELOAD
      final freshTasks = _repository.getAllTasks();
      _currentTasks = List<TaskModel>.from(freshTasks);
      _tasksController.add(_currentTasks);

      updateStats();

      final task = _repository.getTaskById(taskId);
      if (task?.projectId != null) {
        await _repository.recalculateProjectStats(task!.projectId!);
        await loadProjects();
      }
    } catch (e) {
      developer.log('❌ Failed to toggle task', error: e, name: 'TaskBloc');
      _errorController.add('Failed to update task: $e');
      rethrow;
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      developer.log('🗑️ Deleting task: $taskId', name: 'TaskBloc');
      final task = _repository.getTaskById(taskId);
      await _repository.deleteTask(taskId);

      // FORCE RELOAD
      final freshTasks = _repository.getAllTasks();
      _currentTasks = List<TaskModel>.from(freshTasks);
      _tasksController.add(_currentTasks);

      updateStats();

      if (task?.projectId != null) {
        await _repository.recalculateProjectStats(task!.projectId!);
        await loadProjects();
      }
    } catch (e) {
      developer.log('❌ Failed to delete task', error: e, name: 'TaskBloc');
      _errorController.add('Failed to delete task: $e');
      rethrow;
    }
  }

  // Load all projects
  Future<void> loadProjects() async {
    try {
      final projects = _repository.getAllProjects();
      _currentProjects = List<ProjectModel>.from(projects);
      _projectsController.add(_currentProjects);
    } catch (e) {
      developer.log('❌ Failed to load projects', error: e, name: 'TaskBloc');
      _errorController.add('Failed to load projects: $e');
    }
  }

  // Create project
  Future<void> createProject({
    required String name,
    String? description,
    String color = '#5247E6',
  }) async {
    _loadingController.add(true);
    try {
      await _repository.createProject(
        name: name,
        description: description,
        color: color,
      );
      await loadProjects();
    } on TaskRepositoryException catch (e) {
      _errorController.add(e.message);
      rethrow;
    } finally {
      _loadingController.add(false);
    }
  }

  // Update stats
  void updateStats() {
    final stats = _repository.getStatistics();
    _statsController.add(stats);
    developer.log(
      '📊 Stats updated: ${stats.completedTasks}/${stats.totalTasks}',
      name: 'TaskBloc',
    );
  }

  // Get filtered tasks
  List<TaskModel> getFilteredTasks({
    bool? completed,
    String? projectId,
    String? priority,
    DateTime? date,
  }) {
    var tasks = _currentTasks;

    if (completed != null) {
      tasks = tasks.where((t) => t.isCompleted == completed).toList();
    }

    if (projectId != null) {
      tasks = tasks.where((t) => t.projectId == projectId).toList();
    }

    if (priority != null) {
      tasks = tasks.where((t) => t.priority == priority).toList();
    }

    if (date != null) {
      tasks = tasks.where((t) {
        if (t.dueDate == null) return false;
        return t.dueDate!.year == date.year &&
            t.dueDate!.month == date.month &&
            t.dueDate!.day == date.day;
      }).toList();
    }

    return tasks;
  }

  // Search tasks
  List<TaskModel> searchTasks(String query) {
    return _repository.searchTasks(query);
  }

  // Dispose
  void dispose() {
    _tasksController.close();
    _projectsController.close();
    _statsController.close();
    _loadingController.close();
    _errorController.close();
  }
}

// Singleton instance
final taskBloc = TaskBloc();
