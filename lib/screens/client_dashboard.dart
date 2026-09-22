import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

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
    _injectWebRtlFix();
    _loadData();
  }

  // حقن كود CSS يمنع انحراف إحداثيات الـ Iframe عند اختيار العربية (RTL)
  void _injectWebRtlFix() {
    if (!kIsWeb) return;
    const String styleId = 'flt-platform-view-rtl-fix';
    if (html.document.getElementById(styleId) == null) {
      final style = html.StyleElement()
        ..id = styleId
        ..innerHtml = '''
          flt-glass-pane,
          flt-scene-host,
          flt-platform-views-host,
          flt-platform-view,
          flt-platform-view-slot {
            direction: ltr !important;
            left: 0 !important;
            right: auto !important;
            text-align: left !important;
          }
        ''';
      html.document.head?.append(style);
    }
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
        const SizedBox(width: 4),

        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), 
          tooltip: AppLocalizations.tr('logout'),
          onPressed: () async {
            await ApiService().logout();
            if (!mounted) return;
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
              
              // 2. قسم طلب الموافقة / الرفض المبدئي الخطة
              _buildApprovalBanner(project, isDark, isMobile),
              const SizedBox(height: 24),

              // 2.5 قسم المصادقة النهائية على استلام وتسليم المشروع عند اكتمال الإنجاز 100%
              _buildFinalHandoverBanner(project, isDark, isMobile),
              
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

  // 2.5 قسم المصادقة النهائية على استلام وتسليم المشروع عند اكتمال الإنجاز 100%
  Widget _buildFinalHandoverBanner(Project project, bool isDark, bool isMobile) {
    if (project.progress < 0.99) return const SizedBox.shrink();

    final String? formattedFinalDate = project.finalApprovalDate != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(project.finalApprovalDate!)
        : null;

    if (project.finalApprovalStatus == 'approved') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981), width: 1.5),
          boxShadow: [
            BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Color(0xFF10B981), size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    AppLocalizations.tr('final_handover_approved_banner'),
                    style: TextStyle(color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            if (formattedFinalDate != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    '${AppLocalizations.tr('decision_date')}: $formattedFinalDate',
                    style: TextStyle(color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            // عرض سجل المراجعات التراكمي في حالة الموافقة النهائية لمتابعة الأرشيف والمشطبات
            _buildRevisionsHistoryWidget(project, isDark),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => AppLocalizations.printHandoverCertificate(project),
              icon: const Icon(Icons.print_rounded),
              label: const Text('🖨️ طباعة وثيقة الاستلام النهائي والشهادة الرسمية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    } else if (project.finalApprovalStatus == 'rejected') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.15) : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_return_rounded, color: Color(0xFFEF4444), size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    AppLocalizations.tr('final_handover_rejected_banner'),
                    style: TextStyle(color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            if (formattedFinalDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  Text(
                    '${AppLocalizations.tr('decision_date')}: $formattedFinalDate',
                    style: TextStyle(color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            // عرض سجل المراجعات التراكمي والمرفقات في حالة الرفض
            _buildRevisionsHistoryWidget(project, isDark),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 24),
        padding: EdgeInsets.all(isMobile ? 18 : 24),
        decoration: BoxDecoration(
          color: isDark ? Colors.amber.withValues(alpha: 0.15) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.amber.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    AppLocalizations.tr('final_handover_pending_banner'),
                    style: TextStyle(color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16),
                  ),
                ),
              ],
            ),
            // عرض سجل المراجعات السابقة التي تم حلها وتطويرها من الإدارة
            _buildRevisionsHistoryWidget(project, isDark),
            isMobile
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _submitFinalApproval(project, 'approved'),
                          icon: const Icon(Icons.verified_rounded),
                          label: Text(AppLocalizations.tr('confirm_final_approval')),
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
                          onPressed: () => _showFinalRejectDialog(project),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: Text(AppLocalizations.tr('reject_final_approval')),
                          style: ElevatedButton.styleFrom(
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
                        onPressed: () => _submitFinalApproval(project, 'approved'),
                        icon: const Icon(Icons.verified_rounded),
                        label: Text(AppLocalizations.tr('confirm_final_approval')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () => _showFinalRejectDialog(project),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: Text(AppLocalizations.tr('reject_final_approval')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      );
    }
  }

  void _submitFinalApproval(Project project, String status, {String? notes}) async {
    setState(() => _loading = true);
    try {
      await ApiService().updateFinalApprovalStatus(project.id, status, notes: notes);
      if (!mounted) return;
      _loadData();
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.tr('error'))));
    }
  }

  // عرض سجل المراجعات التراكمية التاريخية للعميل
  Widget _buildRevisionsHistoryWidget(Project project, bool isDark) {
    if (project.revisions.isEmpty && project.attachments.isEmpty && (project.finalApprovalNotes == null || project.finalApprovalNotes!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (project.revisions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: project.revisions.map((rev) {
              final bool isResolved = rev.status == 'resolved';
              final String revDate = DateFormat('yyyy-MM-dd HH:mm').format(rev.createdAt);

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isResolved 
                      ? (isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green.shade50)
                      : (isDark ? Colors.red.withValues(alpha: 0.1) : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isResolved 
                        ? (isDark ? Colors.green.shade800 : Colors.green.shade200)
                        : (isDark ? Colors.red.shade800 : Colors.red.shade200),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isResolved ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                          size: 14,
                          color: isResolved ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ملاحظات مراجعة #${rev.revisionNumber} - ${isResolved ? "تمت معالجتها وتطويرها من الإدارة ✓" : "بانتظار معالجة الإدارة ⚠️"}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isResolved ? Colors.green : Colors.red,
                          ),
                        ),
                        const Spacer(),
                        Text(revDate, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rev.clientNotes,
                      style: TextStyle(
                        fontSize: 12,
                        color: isResolved 
                            ? Colors.grey 
                            : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
                        decoration: isResolved ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ] else if (project.finalApprovalNotes != null && project.finalApprovalNotes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Text('${project.finalApprovalNotes}', style: TextStyle(color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B), fontSize: 13)),
          ),
        ],

        if (project.attachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('المرفقات والصور المرفقة مع الطلب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFEF4444))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var att in project.attachments) ...[
                Builder(
                  builder: (context) {
                    final bool isPdf = att.fileType.toLowerCase() == 'pdf';
                    final String fullUrl = 'https://onedev.ovh/track/${att.filePath}';

                    return InkWell(
                      onTap: () {
                        if (kIsWeb) html.window.open(fullUrl, '_blank');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black38 : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded, size: 16, color: isPdf ? Colors.red : Colors.blue),
                            const SizedBox(width: 6),
                            Text(att.fileName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  void _showFinalRejectDialog(Project project) {
    final notesCtrl = TextEditingController();
    List<ProjectAttachment> localAttachments = List.from(project.attachments);
    bool isUploading = false;
    double uploadProgress = 0.0; // النسبة المئوية من 0.0 لـ 1.0

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final double dialogWidth = MediaQuery.of(context).size.width < 650 
              ? MediaQuery.of(context).size.width 
              : 560;

          void pickAndUploadFile() async {
            if (localAttachments.length >= 5) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('الحد الأقصى للمرفقات هو 5 ملفات فقط')),
              );
              return;
            }

            if (kIsWeb) {
              final uploadInput = html.FileUploadInputElement();
              uploadInput.accept = 'image/*,application/pdf';
              uploadInput.click();

              uploadInput.onChange.listen((e) async {
                final files = uploadInput.files;
                if (files != null && files.isNotEmpty) {
                  final file = files[0];
                  final int fileSize = file.size;
                  final String fileName = file.name;

                  // التحقق من الحد الأقصى للحجم (30 ميجابايت)
                  if (fileSize > 30 * 1024 * 1024) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('حجم الملف يتجاوز الحد الأقصى 30 ميجابايت')),
                    );
                    return;
                  }

                  setDialogState(() {
                    isUploading = true;
                    uploadProgress = 0.02;
                  });

                  try {
                    final formData = html.FormData();
                    formData.append('project_id', project.id.toString());
                    formData.appendBlob('file', file, fileName);

                    final request = html.HttpRequest();
                    request.open('POST', '${ApiService.baseUrl}/client/upload_attachment.php');

                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('token');
                    if (token != null) {
                      request.setRequestHeader('Authorization', 'Bearer $token');
                    }

                    // تتبع نسبة الرفع المباشرة واللحظية %0 -> %100 من المتصفح
                    request.upload.onProgress.listen((html.ProgressEvent pe) {
                      if (pe.lengthComputable && pe.total != null && pe.total! > 0) {
                        final double progress = pe.loaded! / pe.total!;
                        setDialogState(() {
                          uploadProgress = progress;
                        });
                      }
                    });

                    request.onLoadEnd.listen((pe) {
                      if (request.status == 200) {
                        try {
                          final res = jsonDecode(request.responseText ?? '{}');
                          if (res['attachment'] != null) {
                            final newAtt = ProjectAttachment.fromJson(res['attachment']);
                            setDialogState(() {
                              localAttachments.add(newAtt);
                              isUploading = false;
                              uploadProgress = 0.0;
                            });
                          } else {
                            setDialogState(() {
                              isUploading = false;
                              uploadProgress = 0.0;
                            });
                          }
                        } catch (_) {
                          setDialogState(() {
                            isUploading = false;
                            uploadProgress = 0.0;
                          });
                        }
                      } else {
                        setDialogState(() {
                          isUploading = false;
                          uploadProgress = 0.0;
                        });
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('تعذر رفع الملف، يرجى التأكد من الاتصال')),
                        );
                      }
                    });

                    request.send(formData);
                  } catch (err) {
                    setDialogState(() {
                      isUploading = false;
                      uploadProgress = 0.0;
                    });
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('حدث خطأ أثناء رفع المرفق: $err')),
                    );
                  }
                }
              });
            }
          }

          void deleteFile(ProjectAttachment att) async {
            try {
              await ApiService().deleteAttachment(att.id);
              setDialogState(() {
                localAttachments.removeWhere((a) => a.id == att.id);
              });
            } catch (err) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('تعذر حذف المرفق')),
              );
            }
          }

          return Dialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 20,
            child: Container(
              width: dialogWidth,
              padding: const EdgeInsets.all(28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الهيدر الفخم مع زر الإغلاق
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.assignment_return_rounded, color: Color(0xFFEF4444), size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.tr('reject_final_approval'),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'يرجى كتابة الملاحظات وإرفاق الدلائل المطلوبة',
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // حقل إدخال الملاحظات التفصيلية
                    TextField(
                      controller: notesCtrl,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.tr('final_rejection_reason_label'),
                        hintText: 'اكتب ملاحظاتك وأسباب عدم المصادقة النهائية بدقة...',
                        hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontSize: 12),
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2)),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),

                    // قسم المرفقات والحجم
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.attach_file_rounded, size: 18, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text(
                              'المرفقات والصور / PDF:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${localAttachments.length} / 5 ملفات',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // قائمة الملفات المرفوعة المكتملة
                    if (localAttachments.isNotEmpty) ...[
                      Column(
                        children: localAttachments.map((att) {
                          final bool isPdf = att.fileType.toLowerCase() == 'pdf';
                          final double sizeMb = att.fileSize / (1024 * 1024);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isPdf ? Colors.red : Colors.blue).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded, size: 18, color: isPdf ? Colors.red : Colors.blue),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        att.fileName,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${sizeMb.toStringAsFixed(2)} MB • ${att.fileType.toUpperCase()}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                  tooltip: 'حذف المرفق',
                                  onPressed: () => deleteFile(att),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // شريط الرفع المباشر الذكي الموضح للنسبة المئوية %0 -> %100
                    if (isUploading) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                    SizedBox(width: 10),
                                    Text('جاري رفع وتأمين المرفق على السيرفر...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                                  ],
                                ),
                                Text(
                                  '${(uploadProgress * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: uploadProgress > 0 ? uploadProgress : null,
                                backgroundColor: Colors.blue.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // زر رفع ملف جديد
                    if (localAttachments.length < 5 && !isUploading)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: pickAndUploadFile,
                          icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                          label: const Text('+ إرفاق صورة أو مستند PDF (أقل من 30MB)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // أزرار التحكم والإرسال
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(AppLocalizations.tr('cancel')),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (notesCtrl.text.trim().isEmpty && localAttachments.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('الرجاء كتابة الملاحظات أو إرفاق ملف')),
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            _submitFinalApproval(project, 'rejected', notes: notesCtrl.text.trim());
                          },
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text(AppLocalizations.tr('confirm_rejection')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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

// 5. معاينة تفاصيل المشروع الناتيف (Native Flutter Rendering)
  Widget _buildProjectPreviewSection(Project project, bool isDark, bool isMobile) {
    if (project.description.trim().isEmpty) return const SizedBox.shrink();

    // ربط معرف العرض باللغة لضمان إعادة الرسم النظيف عند التبديل
    final String currentLang = AppLocalizations.currentLanguage;
    final String viewId = 'iframe-${project.id}-$currentLang';

    // تنظيف القيود الثابتة
    String fullHtmlContent = project.description;
    fullHtmlContent = fullHtmlContent.replaceAll(RegExp(r'max-width:\s*\d+px\s*;?'), '');
    fullHtmlContent = fullHtmlContent.replaceAll(RegExp(r'border-radius:\s*\d+px\s*;?'), '');

    // CSS محكم بدون 100vw وبدون تكرار وسوم غير صالحة
    const String cleanCssRules = '''
      html, body {
        width: 100% !important;
        max-width: 100% !important;
        margin: 0 !important;
        padding: 0 !important;
        box-sizing: border-box !important;
        overflow-x: hidden !important;
        background-color: transparent !important;
      }
      .wrapper, .container, main, body > div {
        width: 100% !important;
        max-width: 100% !important;
        min-width: 100% !important;
        margin: 0 !important;
        padding: 0 !important;
        border-radius: 0 !important;
        border: none !important;
        box-shadow: none !important;
      }
    ''';

    if (fullHtmlContent.contains('</head>')) {
      fullHtmlContent = fullHtmlContent.replaceFirst('</head>', '<style>$cleanCssRules</style></head>');
    } else if (fullHtmlContent.contains('<body>')) {
      fullHtmlContent = fullHtmlContent.replaceFirst('<body>', '<style>$cleanCssRules</style><body>');
    } else {
      fullHtmlContent = '<style>$cleanCssRules</style>$fullHtmlContent';
    }

    if (kIsWeb) {
      try {
        ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
          final html.IFrameElement iframe = html.IFrameElement()
            ..style.border = 'none'
            ..style.margin = '0'
            ..style.padding = '0'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.display = 'block'
          // تدوير الحواف السفلية من داخل الـ iframe مباشرة لتفادي مشاكل ClipRRect
            ..style.borderRadius = '0 0 22px 22px'
            ..srcdoc = fullHtmlContent;

          return iframe;
        });
      } catch (_) {
        // تجاهل الخطأ في حال كان المعرف مسجلاً مسبقاً
      }
    }

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
            Text(
              AppLocalizations.tr('project_details'),
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // تغليف كامل نافذة العرض بنظام LTR لعزل محرك الويب عن انقلاب الاتجاه
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Container(
            height: isMobile ? 450 : 650,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                )
              ],
            ),
            child: Column(
              children: [
                // شريط عنوان المتصفح (Mac OS Bar)
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 6, backgroundColor: Colors.red.shade400),
                          const SizedBox(width: 8),
                          CircleAvatar(radius: 6, backgroundColor: Colors.amber.shade400),
                          const SizedBox(width: 8),
                          CircleAvatar(radius: 6, backgroundColor: Colors.green.shade400),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 12,
                              color: isDark ? Colors.green.shade400 : Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'secure-preview.local',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 52),
                    ],
                  ),
                ),

                // إزالة ClipRRect نهائياً واستبداله بحاوية مباشرة تأخذ مفتاحاً مرتبطاً باللغة
                Expanded(
                  child: HtmlElementView(
                    key: ValueKey(viewId),
                    viewType: viewId,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
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
