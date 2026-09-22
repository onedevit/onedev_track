import 'package:flutter/material.dart';
import '../data/arab_locations_data.dart';
import '../models/data_models.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import '../main.dart'; // للوصول لـ themeNotifier

class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  List<ClientUser> _clients = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // ربط القاموس الجغرافي الشامل لدول جامعة الدول العربية الـ 22 ودول العالم من الملف المخصص
  static Map<String, Map<String, List<String>>> get _locationData => ArabLocationsData.locationsMap;

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  void _fetchClients() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getClients();
      if (mounted) {
        setState(() {
          _clients = data.map((e) => ClientUser.fromJson(e)).toList();
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

  List<ClientUser> get _filteredClients {
    if (_searchQuery.trim().isEmpty) return _clients;
    final query = _searchQuery.toLowerCase();
    return _clients.where((c) {
      return c.username.toLowerCase().contains(query) ||
          c.fullName.toLowerCase().contains(query) ||
          c.companyName.toLowerCase().contains(query) ||
          c.country.toLowerCase().contains(query);
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
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people_alt_rounded, color: Colors.blue, size: 22),
                ),
                const SizedBox(width: 12),
                Text(AppLocalizations.tr('client_management_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            elevation: 0,
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
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final double screenWidth = constraints.maxWidth;
                    final bool isMobile = screenWidth < 650;
                    final bool isTablet = screenWidth >= 650 && screenWidth < 950;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : (isTablet ? 24 : 40),
                        vertical: isMobile ? 20 : 32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. بطاقات ملخص الإحصائيات المباشرة للحرفاء (KPI Cards)
                              _buildClientKpiOverview(isDark, isMobile, isTablet),
                              const SizedBox(height: 32),

                              // 2. شريط البحث والأمر الإنشائي
                              _buildSearchAndActionBar(isDark, isMobile),
                              const SizedBox(height: 24),

                              // 3. شبكة/قائمة الحرفاء المتجاوبة
                              _filteredClients.isEmpty
                                  ? _buildEmptyState(isDark)
                                  : _buildClientsGrid(_filteredClients, isDark, isMobile, isTablet),
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

  // 1. ملخص الإحصائيات المباشرة للحرفاء
  Widget _buildClientKpiOverview(bool isDark, bool isMobile, bool isTablet) {
    final int withCompanyCount = _clients.where((c) => c.companyName.trim().isNotEmpty).length;
    final int totalProjects = _clients.fold(0, (sum, c) => sum + c.projectsCount);
    final int countriesCount = _clients.map((c) => c.country).where((c) => c.trim().isNotEmpty).toSet().length;

    final cards = [
      _buildKpiCard(AppLocalizations.tr('total_clients'), '${_clients.length}', Icons.group_rounded, const Color(0xFF3B82F6), isDark),
      _buildKpiCard(AppLocalizations.tr('company_name'), '$withCompanyCount', Icons.business_rounded, const Color(0xFF8B5CF6), isDark),
      _buildKpiCard(AppLocalizations.tr('projects_count_label'), '$totalProjects', Icons.folder_copy_rounded, const Color(0xFF10B981), isDark),
      _buildKpiCard(AppLocalizations.tr('country'), '$countriesCount', Icons.public_rounded, const Color(0xFFF59E0B), isDark),
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

  // 2. شريط البحث والأمر الإنشائي
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showClientFormModal(),
                    icon: const Icon(Icons.person_add_rounded),
                    label: Text(AppLocalizations.tr('add_new_client')),
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
                ElevatedButton.icon(
                  onPressed: () => _showClientFormModal(),
                  icon: const Icon(Icons.person_add_rounded),
                  label: Text(AppLocalizations.tr('add_new_client')),
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
        hintText: AppLocalizations.tr('search_clients_placeholder'),
        hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      ),
    );
  }

  // 3. شبكة/قائمة الحرفاء الفخمة
  Widget _buildClientsGrid(List<ClientUser> clients, bool isDark, bool isMobile, bool isTablet) {
    if (isMobile) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: clients.length,
        itemBuilder: (ctx, i) => _buildClientCard(clients[i], isDark, isMobile),
      );
    } else {
      final int crossCount = isTablet ? 2 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 220,
        ),
        itemCount: clients.length,
        itemBuilder: (ctx, i) => _buildClientCard(clients[i], isDark, isMobile),
      );
    }
  }

  // بطاقة الحريف الفردية الأنيقة
  Widget _buildClientCard(ClientUser c, bool isDark, bool isMobile) {
    final String displayName = c.fullName.isNotEmpty ? c.fullName : c.username;
    final String locationStr = [c.country, c.state, c.city].where((s) => s.isNotEmpty).join(' • ');

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 14 : 0),
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
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // الهيدر: رمز الصورة + الاسم واللقب + وسم الحساب
          Row(
            children: [
              Container(
                width: 46,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 17, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${c.username}',
                      style: TextStyle(color: isDark ? Colors.blue.shade300 : Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                    ),
                    child: Text(
                      _getLangLabel(c.preferredLanguage),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: isDark ? Colors.white70 : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${c.projectsCount} ${AppLocalizations.tr('projects_count_label')}',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // تفاصيل الشركة والعنوان الجغرافي
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.companyName.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.business_rounded, size: 14, color: Colors.purple),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        c.companyName,
                        style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (locationStr.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        locationStr,
                        style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), height: 1),

          // أزرار التعديل والحذف
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showClientFormModal(client: c),
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: Text(AppLocalizations.tr('edit'), style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: BorderSide(color: Colors.blue.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _confirmDeleteClient(c),
                icon: const Icon(Icons.delete_outline_rounded, size: 15),
                label: Text(AppLocalizations.tr('delete'), style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLangLabel(String lang) {
    switch (lang.toLowerCase()) {
      case 'en':
        return '🇬🇧 English';
      case 'fr':
        return '🇫🇷 Français';
      case 'ar':
      default:
        return '🇸🇦 العربية';
    }
  }

  // حالة عدم وجود نتائج
  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(AppLocalizations.tr('no_clients_found'), style: TextStyle(fontSize: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showClientFormModal(), 
              icon: const Icon(Icons.person_add_rounded), 
              label: Text(AppLocalizations.tr('add_new_client')),
            )
          ],
        ),
      ),
    );
  }

  // نافذة إضافة / تعديل الحريف المتقدمة والمتجاوبة
  void _showClientFormModal({ClientUser? client}) {
    final bool isEditing = client != null;
    final usernameCtrl = TextEditingController(text: client?.username ?? '');
    final passwordCtrl = TextEditingController();
    final fullNameCtrl = TextEditingController(text: client?.fullName ?? '');
    final companyCtrl = TextEditingController(text: client?.companyName ?? '');

    String selectedLanguage = (client != null && client.preferredLanguage.isNotEmpty)
        ? client.preferredLanguage
        : 'ar';

    String selectedCountry = client != null && client.country.isNotEmpty && _locationData.containsKey(client.country)
        ? client.country
        : _locationData.keys.first;

    String? selectedState = (client != null && client.state.isNotEmpty) ? client.state : null;
    String? selectedCity = (client != null && client.city.isNotEmpty) ? client.city : null;

    bool isSaving = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final double screenWidth = MediaQuery.of(context).size.width;
            final bool isMobile = screenWidth < 650;

            Map<String, List<String>> statesMap = _locationData[selectedCountry] ?? {};
            List<String> statesList = statesMap.keys.toList();

            List<String> citiesList = (selectedState != null && statesMap.containsKey(selectedState))
                ? statesMap[selectedState]!
                : [];

            List<DropdownMenuItem<String?>> stateItems = [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(AppLocalizations.tr('unspecified_optional'), style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ),
              ...statesList.map((s) => DropdownMenuItem<String?>(
                value: s,
                child: Text(s, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A))),
              )),
            ];

            List<DropdownMenuItem<String?>> cityItems = [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(AppLocalizations.tr('unspecified_optional'), style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ),
              ...citiesList.map((ci) => DropdownMenuItem<String?>(
                value: ci,
                child: Text(ci, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A))),
              )),
            ];

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                              isEditing ? Icons.manage_accounts_rounded : Icons.person_add_alt_1_rounded,
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
                                  isEditing ? AppLocalizations.tr('edit_client') : AppLocalizations.tr('add_new_client'),
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

                      _buildSectionHeader(AppLocalizations.tr('account_identity_info'), Icons.person_outline_rounded, isDark),
                      const SizedBox(height: 14),

                      if (isMobile) ...[
                        _buildTextField(fullNameCtrl, AppLocalizations.tr('full_name'), 'ex: Walid Al-Hassani', Icons.badge_outlined, isDark),
                        const SizedBox(height: 14),
                        _buildTextField(usernameCtrl, AppLocalizations.tr('username'), 'ex: walid_h', Icons.account_circle_outlined, isDark),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: _buildTextField(fullNameCtrl, AppLocalizations.tr('full_name'), 'ex: Walid Al-Hassani', Icons.badge_outlined, isDark)),
                            const SizedBox(width: 14),
                            Expanded(child: _buildTextField(usernameCtrl, AppLocalizations.tr('username'), 'ex: walid_h', Icons.account_circle_outlined, isDark)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),

                      _buildTextField(
                        passwordCtrl, 
                        AppLocalizations.tr('password'), 
                        '********', 
                        Icons.lock_outline_rounded, 
                        isDark,
                        isObscure: obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildSectionHeader(AppLocalizations.tr('company_address_info'), Icons.business_outlined, isDark),
                      const SizedBox(height: 14),

                      _buildTextField(companyCtrl, AppLocalizations.tr('company_name'), 'ex: OneDev Agency', Icons.domain_outlined, isDark),
                      const SizedBox(height: 14),

                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedCountry,
                            decoration: _buildInputDecoration(AppLocalizations.tr('country'), Icons.public_rounded, isDark),
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            items: _locationData.keys.map((c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(c, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedCountry = val;
                                  selectedState = null;
                                  selectedCity = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          if (isMobile) ...[
                            DropdownButtonFormField<String?>(
                              initialValue: selectedState,
                              decoration: _buildInputDecoration(AppLocalizations.tr('state'), Icons.map_outlined, isDark),
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              items: stateItems,
                              onChanged: (val) {
                                setModalState(() {
                                  selectedState = val;
                                  selectedCity = null;
                                });
                              },
                            ),
                            const SizedBox(height: 14),

                            DropdownButtonFormField<String?>(
                              initialValue: selectedCity,
                              decoration: _buildInputDecoration(AppLocalizations.tr('city'), Icons.location_city_outlined, isDark),
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              items: cityItems,
                              onChanged: (val) {
                                setModalState(() => selectedCity = val);
                              },
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    initialValue: selectedState,
                                    decoration: _buildInputDecoration(AppLocalizations.tr('state'), Icons.map_outlined, isDark),
                                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    items: stateItems,
                                    onChanged: (val) {
                                      setModalState(() {
                                        selectedState = val;
                                        selectedCity = null;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    initialValue: selectedCity,
                                    decoration: _buildInputDecoration(AppLocalizations.tr('city'), Icons.location_city_outlined, isDark),
                                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    items: cityItems,
                                    onChanged: (val) {
                                      setModalState(() => selectedCity = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildSectionHeader('اللغة الافتراضية للواجهة 🌐', Icons.translate_rounded, isDark),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        initialValue: selectedLanguage,
                        decoration: _buildInputDecoration('اللغة الافتراضية للحريف', Icons.language_rounded, isDark),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'ar',
                            child: Row(
                              children: [
                                Text('🇸🇦 ', style: TextStyle(fontSize: 14)),
                                Text('العربية (Arabic)', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: 'en',
                            child: Row(
                              children: [
                                Text('🇬🇧 ', style: TextStyle(fontSize: 14)),
                                Text('English (الإنجليزية)', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: 'fr',
                            child: Row(
                              children: [
                                Text('🇫🇷 ', style: TextStyle(fontSize: 14)),
                                Text('Français (الفرنسية)', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedLanguage = val);
                          }
                        },
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
                                    if (usernameCtrl.text.trim().isEmpty) {
                                      return;
                                    }

                                    setModalState(() => isSaving = true);
                                    try {
                                      if (isEditing) {
                                        await ApiService().editClient(
                                          client.id,
                                          usernameCtrl.text.trim(),
                                          passwordCtrl.text.trim(),
                                          fullName: fullNameCtrl.text.trim(),
                                          country: selectedCountry,
                                          state: selectedState ?? '',
                                          city: selectedCity ?? '',
                                          companyName: companyCtrl.text.trim(),
                                          preferredLanguage: selectedLanguage,
                                        );
                                      } else {
                                        await ApiService().createClient(
                                          usernameCtrl.text.trim(),
                                          passwordCtrl.text.trim(),
                                          fullName: fullNameCtrl.text.trim(),
                                          country: selectedCountry,
                                          state: selectedState ?? '',
                                          city: selectedCity ?? '',
                                          companyName: companyCtrl.text.trim(),
                                          preferredLanguage: selectedLanguage,
                                        );
                                      }

                                      if (!dialogCtx.mounted || !mounted) return;
                                      Navigator.pop(dialogCtx);
                                      _fetchClients();
                                    } catch (e) {
                                      setModalState(() => isSaving = false);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.tr('error'))));
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Icon(isEditing ? Icons.save_rounded : Icons.person_add_rounded, size: 18),
                            label: Text(isEditing ? AppLocalizations.tr('save_changes') : AppLocalizations.tr('add_new_client')),
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

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, IconData icon, bool isDark, {bool isObscure = false, Widget? suffixIcon}) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure,
      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
      decoration: _buildInputDecoration(label, icon, isDark, hint: hint, suffixIcon: suffixIcon),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, bool isDark, {String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontSize: 12),
      prefixIcon: Icon(icon, size: 20, color: Colors.blue),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
    );
  }

  void _confirmDeleteClient(ClientUser client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.tr('delete')),
        content: Text(AppLocalizations.tr('confirm_delete_client')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await ApiService().deleteClient(client.id);
                if (!ctx.mounted || !mounted) return;
                Navigator.pop(ctx);
                _fetchClients();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.tr('error'))));
              }
            },
            child: Text(AppLocalizations.tr('delete')),
          )
        ],
      ),
    );
  }
}
