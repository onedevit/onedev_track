import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/data_models.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import 'admin_task_manager.dart';
import 'admin_clients_screen.dart';
import 'login_screen.dart';
import '../main.dart'; // للوصول لـ themeNotifier

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Project> _projects = [];
  List<ClientUser> _clients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final pData = await ApiService().getAdminProjects();
      final cData = await ApiService().getClients();
      if (mounted) {
        setState(() {
          _projects = pData.map((e) => Project.fromJson(e)).toList();
          _clients = cData.map((e) => ClientUser.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Error fetching data: $e");
      }
    }
  }

  List<Project> get _filteredProjects {
    return _projects.where((p) {
      final matchesSearch = p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.clientName.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFilter = true;
      if (_selectedFilter == 'pending') {
        matchesFilter = p.approvalStatus == 'pending';
      } else if (_selectedFilter == 'approved') {
        matchesFilter = p.approvalStatus == 'approved';
      } else if (_selectedFilter == 'rejected') {
        matchesFilter = p.approvalStatus == 'rejected';
      }

      return matchesSearch && matchesFilter;
    }).toList();
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
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = constraints.maxWidth;
                    final bool isMobile = width < 650;
                    final bool isTablet = width >= 650 && width < 950;
                    return _buildDashboardContent(isDark, isMobile, isTablet);
                  },
                ),
        );
      },
    );
  }

  // شريط التطبيق الرئيسي
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
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.blue, size: 22),
          ),
          const SizedBox(width: 12),
          Text(AppLocalizations.tr('admin_portal'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      elevation: 0,
      actions: [
        // زر إدارة الحرفاء
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminClientsScreen()),
            );
            _fetchData();
          },
          icon: const Icon(Icons.people_alt_rounded, size: 18),
          label: Text(AppLocalizations.tr('manage_clients'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.blue.shade600 : const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 8),

        // محول اللغة
        buildLanguageSelector(isDark),
        const SizedBox(width: 8),

        // زر تغيير كلمة المرور
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

        // زر تبديل الثيم
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

        // زر تسجيل الخروج
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

  // محتوى اللوحة الرئيسي
  Widget _buildDashboardContent(bool isDark, bool isMobile, bool isTablet) {
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
              // 1. بطاقات الإحصائيات السريعة (KPI Overview)
              _buildKpiOverview(isDark, isMobile, isTablet),
              const SizedBox(height: 32),

              // 2. شريط البحث والأوامر والفلترة
              _buildSearchAndActionBar(isDark, isMobile),
              const SizedBox(height: 24),

              // 3. قائمة المشاريع
              _filteredProjects.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredProjects.length,
                      itemBuilder: (ctx, i) {
                        return _buildProjectCard(_filteredProjects[i], isDark, isMobile);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. بطاقات الإحصائيات السريعة
  Widget _buildKpiOverview(bool isDark, bool isMobile, bool isTablet) {
    final int pendingCount = _projects.where((p) => p.approvalStatus == 'pending').length;
    final int rejectedCount = _projects.where((p) => p.approvalStatus == 'rejected').length;

    final cards = [
      _buildKpiCard(AppLocalizations.tr('total_projects'), '${_projects.length}', Icons.folder_copy_rounded, const Color(0xFF3B82F6), isDark),
      _buildKpiCard(AppLocalizations.tr('total_clients'), '${_clients.length}', Icons.group_rounded, const Color(0xFF8B5CF6), isDark),
      _buildKpiCard(AppLocalizations.tr('pending_approval'), '$pendingCount', Icons.hourglass_top_rounded, const Color(0xFFF59E0B), isDark),
      _buildKpiCard(AppLocalizations.tr('rejected_feedback'), '$rejectedCount', Icons.warning_amber_rounded, const Color(0xFFEF4444), isDark),
    ];

    if (isMobile) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: cards,
      );
    } else if (isTablet) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
        children: cards,
      );
    } else {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
      );
    }
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, bool isDark) {
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 2. شريط البحث والفلترة والأوامر السريعة
  Widget _buildSearchAndActionBar(bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: isMobile
          ? Column(
              children: [
                _buildSearchInput(isDark),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _buildFilterChips(isDark)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showProjectFormModal(),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(AppLocalizations.tr('new_project')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.blue.shade600 : const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildSearchInput(isDark)),
                const SizedBox(width: 16),
                Row(children: _buildFilterChips(isDark)),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showProjectFormModal(),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(AppLocalizations.tr('new_project')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.blue.shade600 : const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchInput(bool isDark) {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: AppLocalizations.tr('search_projects_clients'),
        hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      ),
    );
  }

  List<Widget> _buildFilterChips(bool isDark) {
    final filters = [
      {'id': 'all', 'label': AppLocalizations.tr('all')},
      {'id': 'pending', 'label': AppLocalizations.tr('pending')},
      {'id': 'approved', 'label': AppLocalizations.tr('approved')},
      {'id': 'rejected', 'label': AppLocalizations.tr('rejected')},
    ];

    return filters.map((f) {
      final bool isSelected = _selectedFilter == f['id'];
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: ChoiceChip(
          label: Text(f['label']!),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedFilter = f['id']!),
          selectedColor: Colors.blue,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12
          ),
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
        ),
      );
    }).toList();
  }

  // 3. بطاقة المشروع الاحترافية
  Widget _buildProjectCard(Project p, bool isDark, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openTaskManager(p),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(p.title, 
                                style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))
                              ),
                            ),
                            _buildApprovalStatusBadge(p),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text('${AppLocalizations.tr('client_owner')}: ${p.clientName}', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 16),
                            Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text('${AppLocalizations.tr('deadline')}: ${DateFormat('MMM dd, yyyy').format(p.deadline)}', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
                            if (p.clientApprovalDate != null) ...[
                              const SizedBox(width: 16),
                              Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                              const SizedBox(width: 6),
                              Text('${AppLocalizations.tr('decision_date')}: ${DateFormat('yyyy-MM-dd HH:mm').format(p.clientApprovalDate!)}', 
                                style: TextStyle(color: isDark ? Colors.blue.shade300 : Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (p.approvalStatus == 'rejected' && p.rejectionReason != null && p.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.red.withValues(alpha: 0.1) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? Colors.red.withValues(alpha: 0.3) : const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${p.rejectionReason}', 
                          style: TextStyle(color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.w500)
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(AppLocalizations.tr('progress_rate'), style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                            Text('${(p.progress * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: p.progress,
                          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          color: const Color(0xFF10B981),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                    tooltip: AppLocalizations.tr('edit_project'),
                    onPressed: () => _showProjectFormModal(project: p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    tooltip: AppLocalizations.tr('delete_project'),
                    onPressed: () => _confirmDeleteProject(p),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalStatusBadge(Project p) {
    Color color;
    String textKey;

    if (p.approvalStatus == 'approved') {
      color = const Color(0xFF10B981);
      textKey = 'approved';
    } else if (p.approvalStatus == 'rejected') {
      color = const Color(0xFFEF4444);
      textKey = 'rejected';
    } else {
      color = const Color(0xFFF59E0B);
      textKey = 'pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(AppLocalizations.tr(textKey), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('---', style: TextStyle(fontSize: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showProjectFormModal(), 
              icon: const Icon(Icons.add_rounded), 
              label: Text(AppLocalizations.tr('new_project'))
            )
          ],
        ),
      ),
    );
  }

  // MODAL FOR CREATING / EDITING PROJECT
  void _showProjectFormModal({Project? project}) {
    if (_clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.tr('error')))
      );
      return;
    }

    final titleCtrl = TextEditingController(text: project?.title ?? '');
    final descCtrl = TextEditingController(text: project?.description ?? '');
    final durCtrl = TextEditingController(text: project != null ? project.durationDays.toString() : '7');
    DateTime startDate = project?.startDate ?? DateTime.now();
    int? selectedClientId = project != null && _clients.any((c) => c.id == project.clientId)
        ? project.clientId
        : _clients.first.id;

    bool isSaving = false;
    final bool isEditing = project != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final double screenWidth = MediaQuery.of(context).size.width;
            final bool isMobile = screenWidth < 650;

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 24,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                width: isMobile ? screenWidth : 680,
                padding: EdgeInsets.all(isMobile ? 18 : 28),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isEditing
                                  ? Colors.amber.withValues(alpha: 0.15)
                                  : Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isEditing ? Icons.edit_note_rounded : Icons.create_new_folder_rounded,
                              color: isEditing ? Colors.amber.shade700 : Colors.blue,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? AppLocalizations.tr('edit_project') : AppLocalizations.tr('new_project'),
                                  style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),

                      _buildStyledTextField(
                        controller: titleCtrl,
                        label: AppLocalizations.tr('project_title'),
                        hint: 'Project Title...',
                        icon: Icons.folder_outlined,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),

                      if (isMobile) ...[
                        _buildClientDropdown(selectedClientId, (val) => setModalState(() => selectedClientId = val), isDark),
                        const SizedBox(height: 14),
                        _buildStyledTextField(
                          controller: durCtrl,
                          label: AppLocalizations.tr('project_duration'),
                          hint: '7',
                          icon: Icons.timer_outlined,
                          isDark: isDark,
                          keyboardType: TextInputType.number,
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildClientDropdown(selectedClientId, (val) => setModalState(() => selectedClientId = val), isDark),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildStyledTextField(
                                controller: durCtrl,
                                label: AppLocalizations.tr('project_duration'),
                                hint: '7',
                                icon: Icons.timer_outlined,
                                isDark: isDark,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() => startDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range_rounded, color: Colors.blue, size: 20),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.tr('project_start_date'), style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                  const SizedBox(height: 2),
                                  Text(DateFormat('yyyy-MM-dd').format(startDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.edit_calendar_rounded, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildStyledTextField(
                        controller: descCtrl,
                        label: AppLocalizations.tr('project_description'),
                        hint: '<h2 style="color:blue">Preview...</h2>',
                        icon: Icons.integration_instructions_outlined,
                        isDark: isDark,
                        maxLines: 5,
                      ),

                      const SizedBox(height: 24),
                      Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                            child: Text(AppLocalizations.tr('cancel')),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (titleCtrl.text.trim().isEmpty || durCtrl.text.trim().isEmpty || selectedClientId == null) {
                                      return;
                                    }

                                    setModalState(() => isSaving = true);
                                    try {
                                      final int duration = int.parse(durCtrl.text.trim());
                                      final String deadlineStr = startDate.add(Duration(days: duration)).toIso8601String().split('T')[0];
                                      final String startDateStr = startDate.toIso8601String().split('T')[0];

                                      if (isEditing) {
                                        await ApiService().editProject(
                                          project.id,
                                          titleCtrl.text.trim(),
                                          descCtrl.text.trim(),
                                          duration,
                                          selectedClientId!,
                                        );
                                      } else {
                                        await ApiService().createProject({
                                          'title': titleCtrl.text.trim(),
                                          'description': descCtrl.text.trim(),
                                          'client_id': selectedClientId,
                                          'start_date': startDateStr,
                                          'duration_days': duration,
                                          'deadline': deadlineStr,
                                        });
                                      }

                                      if (!dialogCtx.mounted || !mounted) return;
                                      Navigator.pop(dialogCtx);
                                      _fetchData();
                                    } catch (e) {
                                      setModalState(() => isSaving = false);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(AppLocalizations.tr('error'))),
                                      );
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Icon(isEditing ? Icons.save_rounded : Icons.rocket_launch_rounded, size: 18),
                            label: Text(isEditing ? AppLocalizations.tr('save_changes') : AppLocalizations.tr('launch_project')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.blue.shade600 : const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontSize: 12),
        prefixIcon: Icon(icon, size: 20, color: Colors.blue),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
      ),
    );
  }

  Widget _buildClientDropdown(int? selectedId, Function(int?) onChanged, bool isDark) {
    return DropdownButtonFormField<int>(
      initialValue: selectedId,
      decoration: InputDecoration(
        labelText: AppLocalizations.tr('client_owner'),
        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: Colors.blue),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      ),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      items: _clients.map((c) => DropdownMenuItem<int>(
        value: c.id,
        child: Text(c.username, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      )).toList(),
      onChanged: onChanged,
    );
  }

  void _confirmDeleteProject(Project project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.tr('delete_project')),
        content: Text(AppLocalizations.tr('confirm_delete_project')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await ApiService().deleteProject(project.id);
                if(!ctx.mounted || !mounted) return;
                Navigator.pop(ctx);
                _fetchData();
              } catch (e) {
                if(!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(AppLocalizations.tr('error'))));
              }
            },
            child: Text(AppLocalizations.tr('delete')),
          )
        ],
      ),
    );
  }

  void _openTaskManager(Project project) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminTaskManagerScreen(project: project)),
    );
    if (result == true && mounted) {
      _fetchData();
    }
  }
}
