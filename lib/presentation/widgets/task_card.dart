// lib/presentation/widgets/task_card.dart

import 'package:flutter/material.dart';
import 'package:todolist/core/utils/extensions.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/task_model.dart';
import 'glass_container.dart';

/// Task card display modes
enum TaskCardMode {
  compact, // Minimal info, single line
  standard, // Default with description
  detailed, // Full info with all metadata
  checklist, // Checkbox focus, no border
}

/// Task card size variants
enum TaskCardSize {
  small, // 64px height
  medium, // 80px height (default)
  large, // 100px height
}

/// Callback types for task interactions
typedef TaskToggleCallback = void Function(String taskId, bool isCompleted);
typedef TaskEditCallback = void Function(TaskModel task);
typedef TaskDeleteCallback = void Function(String taskId);
typedef TaskTapCallback = void Function(TaskModel task);

/// A highly customizable, animated task card widget with glassmorphism design
class TaskCard extends StatefulWidget {
  final TaskModel task;
  final TaskCardMode mode;
  final TaskCardSize size;
  final bool showCheckbox;
  final bool showPriority;
  final bool showTime;
  final bool showProject;
  final bool showTags;
  final bool enableDismiss;
  final bool enableAnimation;
  final EdgeInsets margin;
  final EdgeInsets padding;

  // Callbacks
  final TaskToggleCallback? onToggle;
  final TaskEditCallback? onEdit;
  final TaskDeleteCallback? onDelete;
  final TaskTapCallback? onTap;
  final VoidCallback? onLongPress;

  const TaskCard({
    super.key,
    required this.task,
    this.mode = TaskCardMode.standard,
    this.size = TaskCardSize.medium,
    this.showCheckbox = true,
    this.showPriority = true,
    this.showTime = true,
    this.showProject = false,
    this.showTags = false,
    this.enableDismiss = true,
    this.enableAnimation = true,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.all(16),
    this.onToggle,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const ElasticOutCurve(0.6)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Getters for styling
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

  double get _checkboxSize {
    switch (widget.size) {
      case TaskCardSize.small:
        return 20;
      case TaskCardSize.medium:
        return 24;
      case TaskCardSize.large:
        return 28;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    Widget card = _buildCardContent(isDark);

    // Add dismissible if enabled
    if (widget.enableDismiss) {
      card = Dismissible(
        key: Key('dismiss_${widget.task.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          return await _showDeleteConfirmation();
        },
        onDismissed: (_) => widget.onDelete?.call(widget.task.id),
        background: _buildDismissBackground(),
        child: card,
      );
    }

    // Add press animation
    if (widget.enableAnimation) {
      card = GestureDetector(
        onTapDown: (_) {
          _controller.forward();
        },
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call(widget.task);
        },
        onTapCancel: () {
          _controller.reverse();
        },
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnimation.value, child: child),
          child: card,
        ),
      );
    } else {
      card = GestureDetector(
        onTap: () => widget.onTap?.call(widget.task),
        onLongPress: widget.onLongPress,
        child: card,
      );
    }

    return Container(margin: widget.margin, child: card);
  }

  Widget _buildCardContent(bool isDark) {
    // Compact mode - minimal design
    if (widget.mode == TaskCardMode.compact) {
      return _buildCompactCard(isDark);
    }

    // Checklist mode - no border, checkbox focus
    if (widget.mode == TaskCardMode.checklist) {
      return _buildChecklistCard(isDark);
    }

    // Standard and detailed modes with glass container
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: widget.mode == TaskCardMode.detailed
            ? Border(
                left: BorderSide(color: _priorityColor, width: 4),
                top: BorderSide(color: context.glassBorderColor),
                right: BorderSide(color: context.glassBorderColor),
                bottom: BorderSide(color: context.glassBorderColor),
              )
            : Border(left: BorderSide(color: _priorityColor, width: 4)),
      ),
      child: GlassContainer(
        padding: widget.padding,
        borderRadius: BorderRadius.circular(16),
        child: _buildMainContent(isDark),
      ),
    );
  }

  Widget _buildCompactCard(bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          if (widget.showCheckbox) ...[
            _buildCheckbox(),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              widget.task.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: widget.task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: widget.task.isCompleted ? Colors.grey : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.showPriority) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _priorityColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistCard(bool isDark) {
    return Row(
      children: [
        _buildCheckbox(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.task.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: widget.task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: widget.task.isCompleted ? Colors.grey : null,
                ),
              ),
              if (widget.task.description != null &&
                  widget.task.description!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.task.description!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox
        if (widget.showCheckbox) ...[
          _buildCheckbox(),
          const SizedBox(width: 16),
        ],

        // Main content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                widget.task.title,
                style: TextStyle(
                  fontSize: widget.size == TaskCardSize.large ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  decoration: widget.task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: widget.task.isCompleted ? Colors.grey : null,
                ),
              ),

              // Description
              if (widget.task.description != null &&
                  widget.task.description!.isNotEmpty &&
                  widget.mode != TaskCardMode.compact) ...[
                const SizedBox(height: 4),
                Text(
                  widget.task.description!,
                  style: TextStyle(
                    fontSize: widget.size == TaskCardSize.large ? 14 : 13,
                    color: Colors.grey[500],
                  ),
                  maxLines: widget.mode == TaskCardMode.detailed ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Metadata row
              const SizedBox(height: 8),
              _buildMetadataRow(isDark),
            ],
          ),
        ),

        // Edit button for detailed mode
        if (widget.mode == TaskCardMode.detailed && widget.onEdit != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            color: Colors.grey,
            onPressed: () => _showOptionsMenu(),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckbox() {
    return GestureDetector(
      onTap: () {
        widget.onToggle?.call(widget.task.id, !widget.task.isCompleted);
        if (widget.task.isCompleted) {
          _controller.forward(from: 0);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _checkboxSize,
        height: _checkboxSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.task.isCompleted ? AppColors.primary : Colors.grey,
            width: 2,
          ),
          color: widget.task.isCompleted
              ? AppColors.primary
              : Colors.transparent,
        ),
        child: widget.task.isCompleted
            ? AnimatedBuilder(
                animation: _checkAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _checkAnimation.value,
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildMetadataRow(bool isDark) {
    final items = <Widget>[];

    // Time
    if (widget.showTime && widget.task.dueDate != null) {
      items.add(
        _buildMetadataItem(
          icon: Icons.schedule,
          text: _formatTime(widget.task.dueDate!),
          color: _isOverdue ? Colors.red : Colors.grey[400],
        ),
      );
    }

    // Priority badge
    if (widget.showPriority) {
      items.add(_buildPriorityBadge());
    }

    // Project
    if (widget.showProject && widget.task.projectId != null) {
      items.add(
        _buildMetadataItem(
          icon: Icons.folder,
          text: widget.task.projectId!,
          color: Colors.grey[400],
        ),
      );
    }

    // Tags
    if (widget.showTags && widget.task.tags.isNotEmpty) {
      for (final tag in widget.task.tags.take(2)) {
        items.add(_buildTag(tag));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items,
    );
  }

  Widget _buildMetadataItem({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[400]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: color ?? Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete, color: Colors.red),
          SizedBox(width: 8),
          Text(
            'Delete',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    // Return true to confirm dismiss, false to cancel
    return true;
  }

  void _showOptionsMenu() {
    // Show bottom sheet with edit/delete options
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool get _isOverdue {
    if (widget.task.dueDate == null || widget.task.isCompleted) return false;
    return widget.task.dueDate!.isBefore(DateTime.now());
  }
}

/// Shimmer loading placeholder for task cards
class TaskCardShimmer extends StatelessWidget {
  final TaskCardSize size;
  final EdgeInsets margin;

  const TaskCardShimmer({
    super.key,
    this.size = TaskCardSize.medium,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      margin: margin,
      height: size == TaskCardSize.small ? 64 : 80,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            colors: [baseColor, highlightColor, baseColor],
            stops: const [0.0, 0.5, 1.0],
            begin: const Alignment(-1.0, -0.3),
            end: const Alignment(1.0, 0.3),
            tileMode: TileMode.clamp,
          ).createShader(bounds);
        },
        blendMode: BlendMode.srcATop,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// Animated list of task cards with reorder support
class TaskCardList extends StatelessWidget {
  final List<TaskModel> tasks;
  final TaskCardMode mode;
  final bool enableReorder;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final TaskToggleCallback? onToggle;
  final TaskDeleteCallback? onDelete;
  final TaskTapCallback? onTap;

  const TaskCardList({
    super.key,
    required this.tasks,
    this.mode = TaskCardMode.standard,
    this.enableReorder = false,
    this.onReorder,
    this.onToggle,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (enableReorder && onReorder != null) {
      return ReorderableListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: tasks.length,
        onReorder: onReorder!,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(
            key: ValueKey(task.id),
            task: task,
            mode: mode,
            onToggle: onToggle,
            onDelete: onDelete,
            onTap: onTap,
          );
        },
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return AnimatedTaskCard(
          task: task,
          mode: mode,
          index: index,
          onToggle: onToggle,
          onDelete: onDelete,
          onTap: onTap,
        );
      },
    );
  }
}

/// Task card with enter/exit animations
class AnimatedTaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskCardMode mode;
  final int index;
  final TaskToggleCallback? onToggle;
  final TaskDeleteCallback? onDelete;
  final TaskTapCallback? onTap;

  const AnimatedTaskCard({
    super.key,
    required this.task,
    required this.mode,
    required this.index,
    this.onToggle,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: TaskCard(
        task: task,
        mode: mode,
        onToggle: onToggle,
        onDelete: onDelete,
        onTap: onTap,
      ),
    );
  }
}
