import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../models/data_models.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import 'login_screen.dart';
import '../main.dart'; // للوصول لمدير الثيم

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});
  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  List<Project> _projects = [];
  int _selectedProjectIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final data = await ApiService().getClientProjects();
      if (mounted) {
        setState(() {
          _projects = data.map((e) => Project.fromJson(e)).toList();
          if (_selectedProjectIndex >= _projects.length) {
            _selectedProjectIndex = 0;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Project? get _currentProject => _projects.isNotEmpty ? _projects[_selectedProjectIndex] : null;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(isDark),
          body: _loading 
              ? const Center(child: CircularProgressIndicator()) 
              : _currentProject == null 
                  ? _buildEmptyState(isDark)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        final bool isMobile = width < 650;
                        final bool isTablet = width >= 650 && width < 950;
                        return _buildDashboardContent(_currentProject!, isDark, isMobile, isTablet);
                      },
                    ),
        );
      },
    );
  }

  // شريط التطبيق العلوي (AppBar)
  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: Colors.blue, size: 22),
          ),
          const SizedBox(width: 12),
          Text(AppLocalizations.tr('client_portal'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      elevation: 0,
      actions: [
        if (_projects.length > 1) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedProjectIndex,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                items: List.generate(_projects.length, (index) {
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(_projects[index].title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  );
                }),
                onChanged: (newIndex) {
                  if (newIndex != null) {
                    setState(() => _selectedProjectIndex = newIndex);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        buildLanguageSelector(isDark),
        const SizedBox(width: 8),

        IconButton(
          icon: const Icon(Icons.lock_reset_rounded, color: Colors.blue),
          tooltip: AppLocalizations.tr('change_password'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const ChangePasswordDialog(),
            );
          },
        ),
        const SizedBox(width: 4),

        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, mode, __) {
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
        const SizedBox(width: 4),

        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), 
          tooltip: AppLocalizations.tr('logout'),
          onPressed: () async {
            await ApiService().logout();
            if(!context.mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // الواجهة الرئيسية للوحة التحكم
  Widget _buildDashboardContent(Project project, bool isDark, bool isMobile, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : (isTablet ? 24 : 40), 
        vertical: isMobile ? 20 : 32
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. هيدر احترافي (Hero Banner)
              _buildHeroHeader(project, isDark, isMobile),
              const SizedBox(height: 24),
              
              // 2. قسم طلب الموافقة / الرفض
              _buildApprovalBanner(project, isDark, isMobile),
              const SizedBox(height: 24),
              
              // 3. بطاقات الإحصائيات الذكية
              _buildStatsSection(project, isDark, isMobile, isTablet),
              const SizedBox(height: 40),
              
              // 4. الجدول الزمني وشجرة المهام التفاعلية
              _buildTaskTimelineSection(project, isDark, isMobile),
              const SizedBox(height: 40),
              
              // 5. تفاصيل ومعاينة المشروع الناتيف (Native Flutter Rendering)
              _buildProjectPreviewSection(project, isDark, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  // 1. هيدر احترافي (Hero Banner)
  Widget _buildHeroHeader(Project project, bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E293B), const Color(0xFF334155)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBadge(project),
                const SizedBox(height: 16),
                Text('${AppLocalizations.tr('welcome_client')} ${project.clientName} 👋', style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                const SizedBox(height: 6),
                Text(project.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3)),
                const SizedBox(height: 24),
                Center(child: _buildCircularGauge(project)),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusBadge(project),
                      const SizedBox(height: 16),
                      Text('${AppLocalizations.tr('welcome_client')} ${project.clientName} 👋', style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 6),
                      Text(project.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                _buildCircularGauge(project),
              ],
            ),
    );
  }

  // شارة حالة المشروع
  Widget _buildStatusBadge(Project project) {
    Color color;
    String textKey;
    IconData icon;

    if (project.approvalStatus == 'approved') {
      color = const Color(0xFF10B981);
      textKey = 'approval_approved';
      icon = Icons.verified_rounded;
    } else if (project.approvalStatus == 'rejected') {
      color = const Color(0xFFEF4444);
      textKey = 'approval_rejected';
      icon = Icons.warning_amber_rounded;
    } else {
      color = const Color(0xFFF59E0B);
      textKey = 'approval_pending';
      icon = Icons.hourglass_top_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(AppLocalizations.tr(textKey), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  // مؤشر النسبة المئوية الدائري
  Widget _buildCircularGauge(Project project) {
    final int percent = (project.progress * 100).toInt();
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: project.progress,
              strokeWidth: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$percent%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(AppLocalizations.tr('task_completed'), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          )
        ],
      ),
    );
  }

  // 2. قسم طلب الموافقة / الرفض
  Widget _buildApprovalBanner(Project project, bool isDark, bool isMobile) {
    final String? formattedApprovalDate = project.clientApprovalDate != null 
        ? DateFormat('yyyy-MM-dd HH:mm').format(project.clientApprovalDate!) 
        : null;

    if (project.approvalStatus == 'approved') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFECFDF5), 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFA7F3D0))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.tr('approval_approved_banner'), 
                    style: TextStyle(color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 14)
                  ),
                ),
              ],
            ),
            if (formattedApprovalDate != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    '${AppLocalizations.tr('decision_date')}: $formattedApprovalDate',
                    style: TextStyle(color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ]
          ],
        ),
      );
    } else if (project.approvalStatus == 'rejected') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.1) : const Color(0xFFFEF2F2), 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.3) : const Color(0xFFFECACA))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(AppLocalizations.tr('approval_rejected_banner'), 
                    style: TextStyle(color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 14)
                  ),
                ),
              ],
            ),
            if (formattedApprovalDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  Text(
                    '${AppLocalizations.tr('decision_date')}: $formattedApprovalDate',
                    style: TextStyle(color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            if (project.rejectionReason != null && project.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Text('${project.rejectionReason}', style: TextStyle(color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B), fontSize: 13)),
              )
            ]
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 18 : 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.1) : const Color(0xFFFFFBEE), 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.3) : const Color(0xFFFDE68A))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_rounded, color: Color(0xFFF59E0B), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(AppLocalizations.tr('approval_pending_banner'), 
                    style: TextStyle(color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            isMobile
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _submitApproval(project, 'approved'),
                          icon: const Icon(Icons.check_rounded),
                          label: Text(AppLocalizations.tr('approve_plan')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981), 
                            foregroundColor: Colors.white, 
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(project),
                          icon: const Icon(Icons.close_rounded),
                          label: Text(AppLocalizations.tr('request_changes')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444), 
                            side: const BorderSide(color: Color(0xFFEF4444)), 
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _submitApproval(project, 'approved'),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(AppLocalizations.tr('approve_plan')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), 
                          foregroundColor: Colors.white, 
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(project),
                        icon: const Icon(Icons.close_rounded),
                        label: Text(AppLocalizations.tr('request_changes')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444), 
                          side: const BorderSide(color: Color(0xFFEF4444)), 
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  )
          ],
        ),
      );
    }
  }

  // 3. بطاقات الإحصائيات الذكية
  Widget _buildStatsSection(Project project, bool isDark, bool isMobile, bool isTablet) {
    final cards = [
      _buildStatCard(
        title: AppLocalizations.tr('progress_rate'), 
        value: '${(project.progress * 100).toInt()}%', 
        icon: Icons.analytics_rounded, 
        color: const Color(0xFF3B82F6), 
        isDark: isDark
      ),
      _buildStatCard(
        title: AppLocalizations.tr('days_left'), 
        value: '${project.daysLeft}', 
        icon: Icons.timer_rounded, 
        color: const Color(0xFFF59E0B), 
        isDark: isDark,
        subtitle: AppLocalizations.tr('work_days_pack')
      ),
      _buildStatCard(
        title: AppLocalizations.tr('deadline'), 
        value: DateFormat('MMM dd, yyyy').format(project.deadline), 
        icon: Icons.calendar_month_rounded, 
        color: const Color(0xFFEF4444), 
        isDark: isDark
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 12), child: card)).toList(),
      );
    } else if (isTablet) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: cards.map((card) => SizedBox(width: (MediaQuery.of(context).size.width - 64) / 2, child: card)).toList(),
      );
    } else {
      return Row(
        children: cards.map((card) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: card))).toList(),
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. الجدول الزمني وشجرة المهام التفاعلية
  Widget _buildTaskTimelineSection(Project project, bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_tree_rounded, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            Text(AppLocalizations.tr('project_timeline'), 
              style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: project.tasks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('---', style: TextStyle(color: Colors.grey))),
                )
              : _buildClientTaskTree(project.tasks, isDark),
        ),
      ],
    );
  }

  Widget _buildClientTaskTree(List<Task> tasks, bool isDark, {int level = 0}) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tasks.map((task) {
        bool isDone = task.status == 'completed';
        
        if (level == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDone 
                            ? const Color(0xFF10B981).withValues(alpha: 0.15) 
                            : (isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDone ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded, 
                        color: isDone ? const Color(0xFF10B981) : Colors.blue, 
                        size: 24
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDone ? Colors.grey : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    _buildTaskStatusChip(isDone, isDark),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 44.0),
                    child: Text(task.description, style: TextStyle(fontSize: 15, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.5)),
                  ),
                ],
                _buildTaskNotes(task, isDone, isDark, 44.0),
                if (task.subTasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 24.0, top: 16.0),
                    child: _buildClientTaskTree(task.subTasks, isDark, level: level + 1),
                  ),
                const SizedBox(height: 16),
                Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), height: 1),
              ],
            ),
          );
        } else if (level == 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Icon(Icons.circle_rounded, size: 10, color: isDone ? Colors.green : (isDark ? Colors.blue.shade400 : Colors.blue.shade600)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDone ? Colors.grey : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(right: 22.0),
                    child: Text(task.description, style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.4)),
                  ),
                ],
                _buildTaskNotes(task, isDone, isDark, 22.0),
                if (task.subTasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 22.0, top: 12.0),
                    child: _buildClientTaskTree(task.subTasks, isDark, level: level + 1),
                  ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Icon(Icons.circle_outlined, size: 10, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDone ? Colors.grey : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 22.0),
                    child: Text(task.description, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600)),
                  ),
                ],
                _buildTaskNotes(task, isDone, isDark, 22.0),
                if (task.subTasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 22.0, top: 8.0),
                    child: _buildClientTaskTree(task.subTasks, isDark, level: level + 1),
                  ),
              ],
            ),
          );
        }
      }).toList(),
    );
  }

  Widget _buildTaskStatusChip(bool isDone, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDone 
            ? const Color(0xFF10B981).withValues(alpha: 0.1) 
            : const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isDone ? AppLocalizations.tr('task_completed') : AppLocalizations.tr('task_in_progress'),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDone ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        ),
      ),
    );
  }

  Widget _buildTaskNotes(Task task, bool isDone, bool isDark, double rightPadding) {
    if (!isDone || task.notes.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.only(right: rightPadding, top: 10.0, bottom: 6.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50, 
          borderRadius: BorderRadius.circular(10), 
          border: Border.all(color: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, size: 18, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(task.notes, style: TextStyle(color: isDark ? Colors.blue.shade200 : Colors.blue.shade900, fontSize: 13, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }

  // 5. عرض ناتيف وفخم لمواصفات وتفاصيل المشروع بدون أي IFrames إطلاقاً
  Widget _buildProjectPreviewSection(Project project, bool isDark, bool isMobile) {
    if (project.description.trim().isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.purple.withValues(alpha: 0.2) : Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.preview_rounded, color: Colors.purple, size: 20),
            ),
            const SizedBox(width: 12),
            Text(AppLocalizations.tr('project_details'), 
              style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))
            ),
          ],
        ),
        const SizedBox(height: 20),

        // بطاقة ملخص الموافقة والمواصفات مع خيار الفتح بملء الشاشة
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: isDark ? 0.15 : 0.05),
                blurRadius: 25,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, color: Colors.purple, size: 16),
                        SizedBox(width: 8),
                        Text('وثيقة التقرير والمواصفات الفنية المعتمدة', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 12, color: Colors.green),
                        SizedBox(width: 6),
                        Text('secure-preview.local', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                project.title,
                style: TextStyle(fontSize: isMobile ? 20 : 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                'يمكنك استعراض تفاصيل العرض والتقرير التفاعلي والمواصفات المعتمدة كاملة بملء الشاشة أو قراءتها مباشرة.',
                style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 24),

              // عرض ناتيف نظيف لأجسام النص البرمجي
              _buildNativeHtmlViewer(project.description, isDark, isMobile),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openFullscreenPreview(project),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('فتح التقرير والتفاصيل الكاملة في نافذة جديدة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // بناء عرض ناتيف فخم وأنيق للنصوص والفقرات والبطاقات المضمنة بدون أي IFrames إطلاقاً
  Widget _buildNativeHtmlViewer(String rawHtml, bool isDark, bool isMobile) {
    if (rawHtml.trim().isEmpty) return const SizedBox.shrink();

    // تنظيف وجمع الفقرات والعناوين بنمط ناتيف فخم
    String cleanText = rawHtml
        .replaceAll(RegExp(r'<script[\s\S]*?<\/script>'), '')
        .replaceAll(RegExp(r'<style[\s\S]*?<\/style>'), '');

    List<Widget> parsedWidgets = [];
    final blockRegex = RegExp(r'<(h[1-6]|p|li|td)[^>]*>([\s\S]*?)<\/\1>', caseSensitive: false);
    final matches = blockRegex.allMatches(cleanText);

    if (matches.isNotEmpty) {
      for (final match in matches) {
        final tag = match.group(1)?.toLowerCase() ?? '';
        final content = match.group(2) ?? '';
        final fullTag = match.group(0) ?? '';

        final textContent = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (textContent.isEmpty || textContent.length < 3) continue;

        if (tag.startsWith('h')) {
          parsedWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 4, 
                    height: 18, 
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(2)
                    ),
                    margin: const EdgeInsets.only(left: 8, right: 8)
                  ),
                  Expanded(
                    child: Text(
                      textContent,
                      style: TextStyle(
                        fontSize: tag == 'h1' ? 20 : (tag == 'h2' ? 17 : 15),
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (fullTag.contains('critical') || fullTag.contains('danger') || fullTag.contains('red') || textContent.contains('حرج') || textContent.contains('عاجل')) {
          parsedWidgets.add(
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.red.withValues(alpha: 0.1) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border(right: BorderSide(color: Colors.red.shade400, width: 4)),
              ),
              child: Text(textContent, style: TextStyle(color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B), fontSize: 13, height: 1.5, fontWeight: FontWeight.w600)),
            ),
          );
        } else if (fullTag.contains('warn') || fullTag.contains('orange') || textContent.contains('تنبيه') || textContent.contains('تحذير')) {
          parsedWidgets.add(
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.amber.withValues(alpha: 0.1) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border(right: BorderSide(color: Colors.amber.shade700, width: 4)),
              ),
              child: Text(textContent, style: TextStyle(color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E), fontSize: 13, height: 1.5, fontWeight: FontWeight.w600)),
            ),
          );
        } else {
          parsedWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                textContent,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
            ),
          );
        }
      }
    }

    if (parsedWidgets.isEmpty) {
      final plainText = cleanText.replaceAll(RegExp(r'<[^>]*>'), '\n').trim();
      final lines = plainText.split('\n').where((l) => l.trim().length > 3).toList();

      for (var line in lines) {
        parsedWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line.trim(),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 350),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: parsedWidgets,
        ),
      ),
    );
  }

  // فتح العرض التفاعلي بملء الشاشة بتبويب جديد
  void _openFullscreenPreview(Project project) {
    if (kIsWeb) {
      final blob = html.Blob([project.description], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(AppLocalizations.tr('no_active_projects'), 
            style: TextStyle(fontSize: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)
          ),
        ],
      ),
    );
  }

  void _submitApproval(Project project, String status, {String? reason}) async {
    setState(() => _loading = true);
    try {
      await ApiService().updateApprovalStatus(project.id, status, reason: reason);
      if(!mounted) return;
      _loadData();
    } catch (e) {
      setState(() => _loading = false);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.tr('error'))));
    }
  }

  void _showRejectDialog(Project project) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.tr('request_changes')),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(
            labelText: AppLocalizations.tr('rejection_reason_label'),
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              if(reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              _submitApproval(project, 'rejected', reason: reasonCtrl.text);
            },
            child: Text(AppLocalizations.tr('confirm_rejection')),
          )
        ],
      )
    );
  }
}
