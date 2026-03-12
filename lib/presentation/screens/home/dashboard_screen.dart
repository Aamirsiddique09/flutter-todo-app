// lib/presentation/screens/home/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../blocs/task_bloc.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/custom_nav_bar.dart';
import '../projects/projects_screen.dart';
import '../calendar/calendar_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TaskBloc _taskBloc = TaskBloc();
  bool _isLoading = true;
  String? _error;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    developer.log('🏠 DashboardScreen initState', name: 'Dashboard');
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize BLoC
      await _taskBloc.init();

      setState(() {
        _isLoading = false;
      });

      _screens.addAll([
        _HomeContent(bloc: _taskBloc),
        const CalendarScreen(),
        const ProjectsScreen(),
        const ProfileScreen(),
      ]);

      _animationController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
      _fadeAnimation = CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      );
      _animationController.forward();
    } catch (e) {
      developer.log('❌ Failed to initialize: $e', name: 'Dashboard');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _taskBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: FadeTransition(
          key: ValueKey<int>(_currentIndex),
          opacity: _fadeAnimation,
          child: _screens[_currentIndex],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                developer.log(
                  '➕ FAB pressed - showing add task modal',
                  name: 'Dashboard',
                );
                _showAddTaskModal(context);
              },
              backgroundColor: AppColors.primary,
              elevation: 8,
              highlightElevation: 12,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _animationController.reset();
          _animationController.forward();
        },
      ),
    );
  }

  void _showAddTaskModal(BuildContext context) {
    developer.log('📋 Showing add task modal', name: 'Dashboard');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: _AddTaskModal(
          bloc: _taskBloc,
          onTaskAdded: () {
            developer.log(
              '✅ onTaskAdded callback called - popping modal',
              name: 'Dashboard',
            );
            Navigator.pop(context);
          },
        ),
      ),
    ).then((_) {
      developer.log('👋 Modal closed', name: 'Dashboard');
    });
  }
}

class _HomeContent extends StatelessWidget {
  final TaskBloc bloc;

  const _HomeContent({required this.bloc});

  @override
  Widget build(BuildContext context) {
    developer.log('🏠 Building _HomeContent', name: 'Dashboard');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildProgressCard(context, isDark),
                ],
              ),
            ),
          ),

          // Tasks Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => _showAllTasks(context),
                    child: const Text('View all'),
                  ),
                ],
              ),
            ),
          ),

          // Tasks List with StreamBuilder - DEBUG VERSION WITH LISTENER
          StreamBuilder<List<TaskModel>>(
            stream: bloc.tasksStream,
            builder: (context, snapshot) {
              developer.log(
                '📊 StreamBuilder rebuild - '
                'Connection: ${snapshot.connectionState}, '
                'HasData: ${snapshot.hasData}, '
                'DataLength: ${snapshot.data?.length ?? 0}, '
                'DataHash: ${snapshot.data?.hashCode}',
                name: 'Dashboard',
              );

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final tasks = snapshot.data ?? [];
              developer.log(
                '📋 Processing ${tasks.length} tasks',
                name: 'Dashboard',
              );

              // Print all tasks for debugging
              for (var i = 0; i < tasks.length; i++) {
                developer.log(
                  '  Task $i: ${tasks[i].title} (ID: ${tasks[i].id}, Due: ${tasks[i].dueDate})',
                  name: 'Dashboard',
                );
              }

              final todaysTasks = tasks.where((task) {
                if (task.dueDate == null) {
                  developer.log(
                    '  Task ${task.title} has no due date - excluding',
                    name: 'Dashboard',
                  );
                  return false;
                }
                final now = DateTime.now();
                final isToday =
                    task.dueDate!.year == now.year &&
                    task.dueDate!.month == now.month &&
                    task.dueDate!.day == now.day;
                developer.log(
                  '  Task ${task.title}: Due ${task.dueDate}, IsToday: $isToday',
                  name: 'Dashboard',
                );
                return isToday;
              }).toList();

              developer.log(
                '📅 Today\'s tasks count: ${todaysTasks.length}',
                name: 'Dashboard',
              );

              if (todaysTasks.isEmpty) {
                return SliverToBoxAdapter(child: _buildEmptyState(context));
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final task = todaysTasks[index];
                  developer.log(
                    '🎨 Building task card $index: ${task.title}',
                    name: 'Dashboard',
                  );
                  return _TaskCard(
                    task: task,
                    onToggle: () => bloc.toggleTask(task.id),
                    onDelete: () => bloc.deleteTask(task.id),
                  );
                }, childCount: todaysTasks.length),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Hero(
              tag: 'avatar',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                  image: const DecorationImage(
                    image: NetworkImage('https://i.pravatar.cc/150?img=11 '),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<TaskStatistics>(
                  stream: bloc.statsStream,
                  builder: (context, snapshot) {
                    final hour = DateTime.now().hour;
                    String greeting = 'Good Morning';
                    if (hour >= 12 && hour < 17) greeting = 'Good Afternoon';
                    if (hour >= 17) greeting = 'Good Evening';

                    return Text(
                      '$greeting, Aamir',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                Text(
                  _formatDate(DateTime.now()),
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        GlassContainer(
          width: 44,
          height: 44,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.grey),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(BuildContext context, bool isDark) {
    return StreamBuilder<TaskStatistics>(
      stream: bloc.statsStream,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final totalTasks = stats?.totalTasks ?? 0;
        final completedTasks = stats?.completedTasks ?? 0;
        final completionRate = stats?.completionRate ?? 0.0;

        return GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY PROGRESS',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$completedTasks/$totalTasks ',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: 'tasks',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(completionRate * 100).toInt()}% Complete',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: completionRate),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 8,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _getMotivationalQuote(completionRate),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tasks for today!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add a new task',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getMotivationalQuote(double completionRate) {
    if (completionRate == 0) return '"Start your day with a small win!"';
    if (completionRate < 0.3) return '"Great start! Keep the momentum going."';
    if (completionRate < 0.6) return '"You\'re making good progress!"';
    if (completionRate < 1.0) return '"Almost there! Finish strong."';
    return '"Amazing! All tasks completed! 🎉"';
  }

  void _showAllTasks(BuildContext context) {
    // Navigate to full task list
  }
}

class _TaskCard extends StatefulWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  Color get _priorityColor {
    switch (widget.task.priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      case 'routine':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  String get _priorityLabel {
    switch (widget.task.priority) {
      case 'high':
        return 'High Priority';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      case 'routine':
        return 'Routine';
      default:
        return 'Normal';
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onToggle,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: _priorityColor, width: 4),
                ),
              ),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.task.isCompleted
                                ? AppColors.primary
                                : Colors.grey,
                            width: 2,
                          ),
                          color: widget.task.isCompleted
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                        child: widget.task.isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: widget.task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: widget.task.isCompleted
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                          if (widget.task.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.task.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (widget.task.dueDate != null) ...[
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(widget.task.dueDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _priorityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _priorityLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _priorityColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ==================== PROFESSIONAL ADD TASK MODAL ====================

class _AddTaskModal extends StatefulWidget {
  final TaskBloc bloc;
  final VoidCallback onTaskAdded;

  const _AddTaskModal({required this.bloc, required this.onTaskAdded});

  @override
  State<_AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<_AddTaskModal>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPriority = 'medium';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _priorities = [
    {
      'value': 'high',
      'label': 'High',
      'color': const Color(0xFFFF4757),
      'icon': Icons.priority_high_rounded,
      'gradient': [const Color(0xFFFF4757), const Color(0xFFFF6B81)],
    },
    {
      'value': 'medium',
      'label': 'Medium',
      'color': const Color(0xFFFFA502),
      'icon': Icons.flag_rounded,
      'gradient': [const Color(0xFFFFA502), const Color(0xFFFFC107)],
    },
    {
      'value': 'low',
      'label': 'Low',
      'color': const Color(0xFF2ED573),
      'icon': Icons.low_priority_rounded,
      'gradient': [const Color(0xFF2ED573), const Color(0xFF7BED9F)],
    },
    {
      'value': 'routine',
      'label': 'Routine',
      'color': const Color(0xFF1E90FF),
      'icon': Icons.repeat_rounded,
      'gradient': [const Color(0xFF1E90FF), const Color(0xFF70A1FF)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF2D3436).withOpacity(0.95),
                          const Color(0xFF000000).withOpacity(0.9),
                        ]
                      : [
                          Colors.white.withOpacity(0.95),
                          const Color(0xFFF8F9FA).withOpacity(0.9),
                        ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.8),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_task_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Task',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a new task to stay organized',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Title Input
                  _buildInputField(
                    controller: _titleController,
                    label: 'Task Title',
                    hint: 'What needs to be done?',
                    icon: Icons.title_rounded,
                    isDark: isDark,
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),

                  // Description Input
                  _buildInputField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Add details (optional)',
                    icon: Icons.description_outlined,
                    isDark: isDark,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 28),

                  // Priority Section
                  Text(
                    'Priority Level',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPrioritySelector(isDark),
                  const SizedBox(height: 28),

                  // Date & Time Section
                  Text(
                    'Schedule',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeCard(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: _selectedDate == null
                              ? 'Today'
                              : '${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)}',
                          isSelected: _selectedDate != null,
                          onTap: () => _selectDate(context),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTimeCard(
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: _selectedTime == null
                              ? 'Anytime'
                              : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                          isSelected: _selectedTime != null,
                          onTap: () => _selectTime(context),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  StreamBuilder<bool>(
                    stream: widget.bloc.loadingStream,
                    builder: (context, snapshot) {
                      final isLoading = snapshot.data ?? false;
                      return _buildSubmitButton(isLoading, isDark);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool autofocus = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
              ),
              prefixIcon: Icon(
                icon,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.4),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector(bool isDark) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _priorities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final priority = _priorities[index];
          final isSelected = _selectedPriority == priority['value'];

          return GestureDetector(
            onTap: () {
              setState(() => _selectedPriority = priority['value']);
              HapticFeedback.lightImpact();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 80,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: priority['gradient'],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? priority['color'].withOpacity(0.5)
                      : isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: priority['color'].withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    priority['icon'],
                    color: isSelected ? Colors.white : priority['color'],
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    priority['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isDark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateTimeCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.5)
                : isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primary
                    : isDark
                    ? Colors.white60
                    : Colors.black45,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isLoading, bool isDark) {
    return GestureDetector(
      onTap: isLoading ? null : _addTask,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Create Task',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: const Color(0xFF2D3436),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: const Color(0xFF2D3436),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _addTask() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a task title');
      return;
    }

    DateTime dueDate = _selectedDate ?? DateTime.now();
    if (_selectedTime != null) {
      dueDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    try {
      await widget.bloc.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dueDate: dueDate,
        priority: _selectedPriority,
      );

      if (mounted) {
        widget.onTaskAdded();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to add task: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
