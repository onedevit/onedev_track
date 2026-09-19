import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import '../main.dart'; // للوصول لـ themeNotifier

class AdminTaskManagerScreen extends StatefulWidget {
  final Project project;

  const AdminTaskManagerScreen({super.key, required this.project});

  @override
  State<AdminTaskManagerScreen> createState() => _AdminTaskManagerScreenState();
}

class _AdminTaskManagerScreenState extends State<AdminTaskManagerScreen> {
  bool _isLoading = true;
  List<Task> _rootTasks = [];
  int _totalTasksCount = 0;
  int _completedTasksCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasksData = await ApiService().getTasks(widget.project.id);
      
      List<Task> allTasks = tasksData.map((e) => Task.fromJson(e)).toList();
      List<Task> roots = [];
      Map<int, Task> taskMap = {for (var t in allTasks) t.id: t};

      int doneCount = 0;
      for (var task in allTasks) {
        if (task.status == 'completed') doneCount++;
        if (task.parentId == null) {
          roots.add(task);
        } else {
          if (taskMap.containsKey(task.parentId)) {
            taskMap[task.parentId]!.subTasks.add(task);
          }
        }
      }

      if (mounted) {
        setState(() {
          _rootTasks = roots;
          _totalTasksCount = allTasks.length;
          _completedTasksCount = doneCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.tr('error'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(isDark),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddTaskDialog(),
            label: Text(AppLocalizations.tr('add_main_phase')),
            icon: const Icon(Icons.add_rounded),
            backgroundColor: isDark ? Colors.blue.shade600 : const Color(0xFF1E293B),
            foregroundColor: Colors.white,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final double screenWidth = constraints.maxWidth;
                    final bool isMobile = screenWidth < 650;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 24, 
                        vertical: isMobile ? 16 : 24
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. بطاقة ملخص إحصائيات المهام
                              _buildTaskSummaryHeader(isDark, isMobile),
                              const SizedBox(height: 24),

                              // 2. شجرة المهام
                              _rootTasks.isEmpty
                                  ? _buildEmptyState(isDark)
                                  : _buildTaskTree(_rootTasks, isDark, isMobile),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  // شريط التطبيق العلوي
  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.tr('task_manager_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          Text(widget.project.title, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        ],
      ),
      elevation: 1,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context, true),
      ),
      actions: [
        buildLanguageSelector(isDark),
        const SizedBox(width: 8),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, mode, _) {
            return IconButton(
              icon: Icon(mode == ThemeMode.light ? Icons.dark_mode_outlined : Icons.light_mode_outlined, 
                  color: isDark ? Colors.amber : const Color(0xFF1E293B)),
              tooltip: AppLocalizations.tr('theme_toggle'),
              onPressed: () {
                themeNotifier.value = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
              },
            );
          }
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // بطاقة ملخص إحصائيات المهام
  Widget _buildTaskSummaryHeader(bool isDark, bool isMobile) {
    final double progress = _totalTasksCount > 0 ? (_completedTasksCount / _totalTasksCount) : 0.0;
    final int percent = (progress * 100).toInt();

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.account_tree_rounded, color: Colors.blue, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.title,
                      style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppLocalizations.tr('client_owner')}: ${widget.project.clientName}',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_completedTasksCount / $_totalTasksCount ($percent%)',
                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // شجرة المهام المتجاوبة
  Widget _buildTaskTree(List<Task> tasks, bool isDark, bool isMobile, {int level = 0}) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    // إزاحة متناسبة حسب حجم الشاشة
    final double levelIndent = isMobile ? (level * 12.0) : (level * 24.0);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (ctx, i) {
        final t = tasks[i];
        bool hasChildren = t.subTasks.isNotEmpty;
        bool isDone = t.status == 'completed';

        return Padding(
          padding: EdgeInsets.only(
            right: localeNotifier.isRtl ? levelIndent : 0.0,
            left: !localeNotifier.isRtl ? levelIndent : 0.0,
            bottom: 8.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDone
                  ? (isDark ? const Color(0xFF10B981).withValues(alpha: 0.08) : const Color(0xFFECFDF5))
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDone
                    ? (isDark ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFA7F3D0))
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: ExpansionTile(
              initiallyExpanded: true,
              shape: const Border(),
              tilePadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: 4),
              childrenPadding: EdgeInsets.only(bottom: 12, left: isMobile ? 8 : 16, right: isMobile ? 8 : 16),
              iconColor: isDark ? Colors.white : Colors.black87,
              collapsedIconColor: isDark ? Colors.grey : Colors.grey.shade600,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : (isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  level == 0 ? Icons.folder_rounded : (level == 1 ? Icons.subdirectory_arrow_left_rounded : Icons.label_important_rounded),
                  color: isDone ? const Color(0xFF10B981) : Colors.blue,
                  size: isMobile ? 18 : 22,
                ),
              ),
              title: Text(
                t.title,
                style: TextStyle(
                  fontSize: level == 0 ? (isMobile ? 15 : 17) : (isMobile ? 14 : 15),
                  fontWeight: level == 0 ? FontWeight.bold : FontWeight.w600,
                  color: isDone ? Colors.grey : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: t.description.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        t.description,
                        style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    )
                  : null,

              // أزرار التحكم المتجاوبة (على الجوال تظهر كقائمة منسدلة لتفادي Overflow)
              trailing: isMobile
                  ? _buildMobileTaskMenu(t, isDone, hasChildren, level, isDark)
                  : _buildDesktopTaskActions(t, isDone, hasChildren, level, isDark),

              children: [
                if (t.notes.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(t.notes, style: TextStyle(fontSize: 12, color: isDark ? Colors.blue.shade200 : Colors.blue.shade900)),
                        ),
                      ],
                    ),
                  ),
                if (hasChildren) _buildTaskTree(t.subTasks, isDark, isMobile, level: level + 1),
              ],
            ),
          ),
        );
      },
    );
  }

  // أزرار التحكم للشاشات الكبيرة
  Widget _buildDesktopTaskActions(Task t, bool isDone, bool hasChildren, int level, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!hasChildren) ...[
          if (!isDone)
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
              tooltip: AppLocalizations.tr('validate_task'),
              onPressed: () => _showValidateTaskDialog(t),
            )
          else
            const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
        ] else ...[
          isDone
              ? const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20)
              : const Icon(Icons.hourglass_bottom_rounded, color: Color(0xFFF59E0B), size: 18),
        ],

        if (level < 2)
          IconButton(
            icon: const Icon(Icons.add_task_rounded, color: Colors.blue),
            tooltip: AppLocalizations.tr('add_sub_task'),
            onPressed: () => _showAddTaskDialog(parentId: t.id),
          ),

        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.amber),
          tooltip: AppLocalizations.tr('edit'),
          onPressed: () => _showEditTaskDialog(t),
        ),

        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          tooltip: AppLocalizations.tr('delete'),
          onPressed: () => _confirmDeleteTask(t),
        ),
      ],
    );
  }

  // قائمة خيارات منسدلة للشاشات الصغيرة لتفادي الـ Overflow
  Widget _buildMobileTaskMenu(Task t, bool isDone, bool hasChildren, int level, bool isDark) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      onSelected: (action) {
        if (action == 'validate') {
          _showValidateTaskDialog(t);
        } else if (action == 'add_sub') {
          _showAddTaskDialog(parentId: t.id);
        } else if (action == 'edit') {
          _showEditTaskDialog(t);
        } else if (action == 'delete') {
          _confirmDeleteTask(t);
        }
      },
      itemBuilder: (ctx) => [
        if (!hasChildren && !isDone)
          PopupMenuItem(
            value: 'validate',
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Text(AppLocalizations.tr('validate_task'), style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        if (level < 2)
          PopupMenuItem(
            value: 'add_sub',
            child: Row(
              children: [
                const Icon(Icons.add_task_rounded, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Text(AppLocalizations.tr('add_sub_task'), style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.tr('edit'), style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.tr('delete'), style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  // نافذة اعتماد المهمة وإرفاق التقرير
  void _showValidateTaskDialog(Task task) {
    final notesCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(AppLocalizations.tr('validate_task_dialog_title')),
            content: TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.tr('task_notes_report'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(onPressed: isSaving ? null : () => Navigator.pop(ctx), child: Text(AppLocalizations.tr('cancel'))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                onPressed: isSaving
                    ? null
                    : () async {
                        setStateDialog(() => isSaving = true);
                        try {
                          await ApiService().validateTask(task.id, notesCtrl.text.trim());
                          if (!ctx.mounted || !mounted) return;
                          Navigator.pop(ctx);
                          _loadTasks();
                        } catch (e) {
                          setStateDialog(() => isSaving = false);
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(AppLocalizations.tr('confirm_validation')),
              )
            ],
          );
        },
      ),
    );
  }

  // نافذة إضافة مهمة
  void _showAddTaskDialog({int? parentId}) {
    final tTitle = TextEditingController();
    final tDesc = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(parentId == null ? AppLocalizations.tr('add_main_phase') : AppLocalizations.tr('add_sub_task')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: tTitle, decoration: InputDecoration(labelText: AppLocalizations.tr('task_title'), border: const OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: tDesc, decoration: InputDecoration(labelText: AppLocalizations.tr('task_description'), border: const OutlineInputBorder()), maxLines: 3),
              ],
            ),
            actions: [
              TextButton(onPressed: isSaving ? null : () => Navigator.pop(ctx), child: Text(AppLocalizations.tr('cancel'))),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (tTitle.text.trim().isEmpty) return;
                        setStateDialog(() => isSaving = true);
                        try {
                          await ApiService().createTask(widget.project.id, tTitle.text.trim(), tDesc.text.trim(), parentId: parentId);
                          if (!ctx.mounted || !mounted) return;
                          Navigator.pop(ctx);
                          _loadTasks();
                        } catch (e) {
                          setStateDialog(() => isSaving = false);
                        }
                      },
                child: isSaving ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : Text(AppLocalizations.tr('save')),
              )
            ],
          );
        },
      ),
    );
  }

  // نافذة تعديل المهمة
  void _showEditTaskDialog(Task task) {
    final tTitle = TextEditingController(text: task.title);
    final tDesc = TextEditingController(text: task.description);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(AppLocalizations.tr('edit')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: tTitle, decoration: InputDecoration(labelText: AppLocalizations.tr('task_title'), border: const OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: tDesc, decoration: InputDecoration(labelText: AppLocalizations.tr('task_description'), border: const OutlineInputBorder()), maxLines: 3),
              ],
            ),
            actions: [
              TextButton(onPressed: isSaving ? null : () => Navigator.pop(ctx), child: Text(AppLocalizations.tr('cancel'))),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (tTitle.text.trim().isEmpty) return;
                        setStateDialog(() => isSaving = true);
                        try {
                          await ApiService().editTask(task.id, tTitle.text.trim(), tDesc.text.trim());
                          if (!ctx.mounted || !mounted) return;
                          Navigator.pop(ctx);
                          _loadTasks();
                        } catch (e) {
                          setStateDialog(() => isSaving = false);
                        }
                      },
                child: isSaving ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : Text(AppLocalizations.tr('save_changes')),
              )
            ],
          );
        },
      ),
    );
  }

  // نافذة تأكيد حذف المهمة
  void _confirmDeleteTask(Task task) {
    showDialog(
      context: context,
      builder: (deleteCtx) => AlertDialog(
        title: Text(AppLocalizations.tr('delete')),
        content: Text('${AppLocalizations.tr('delete')} "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(deleteCtx), child: Text(AppLocalizations.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await ApiService().deleteTask(task.id);
                if (!deleteCtx.mounted || !mounted) return;
                Navigator.pop(deleteCtx);
                _loadTasks();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.tr('error'))));
              }
            },
            child: Text(AppLocalizations.tr('delete')),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('---', style: TextStyle(fontSize: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddTaskDialog(),
              icon: const Icon(Icons.add_rounded),
              label: Text(AppLocalizations.tr('add_main_phase')),
            )
          ],
        ),
      ),
    );
  }
}
