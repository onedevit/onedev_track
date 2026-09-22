import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/app_localizations.dart';
import '../main.dart'; // للوصول لـ themeNotifier

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // إعدادات المرفقات والنظام
  final _maxAttachmentsCtrl = TextEditingController(text: '5');
  final _maxFileSizeCtrl = TextEditingController(text: '30');
  final _autoDeleteDaysCtrl = TextEditingController(text: '30');
  final _cronSecretTokenCtrl = TextEditingController(text: 'ONEDEV_CLEANUP_CRON_2026_SECURE');
  bool _isLoadingSettings = true;
  bool _isSavingSettings = false;

  // إعدادات تغيير كلمة المرور
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isSavingPassword = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadSystemSettings();
  }

  void _loadSystemSettings() async {
    try {
      final settings = await ApiService().getSettings();
      if (mounted) {
        setState(() {
          _maxAttachmentsCtrl.text = settings['max_attachments_count'] ?? '5';
          _maxFileSizeCtrl.text = settings['max_file_size_mb'] ?? '30';
          _autoDeleteDaysCtrl.text = settings['auto_delete_attachments_days'] ?? '30';
          _cronSecretTokenCtrl.text = settings['cron_secret_token'] ?? 'ONEDEV_CLEANUP_CRON_2026_SECURE';
          _isLoadingSettings = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSettings = false);
      }
    }
  }

  void _generateRandomCronToken() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    final newToken = 'cron_${values.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
    setState(() {
      _cronSecretTokenCtrl.text = newToken;
    });
  }

  void _saveSettings() async {
    setState(() => _isSavingSettings = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService().updateSettings({
        "max_attachments_count": _maxAttachmentsCtrl.text.trim(),
        "max_file_size_mb": _maxFileSizeCtrl.text.trim(),
        "auto_delete_attachments_days": _autoDeleteDaysCtrl.text.trim(),
        "cron_secret_token": _cronSecretTokenCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() => _isSavingSettings = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.tr('settings_saved_success')),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingSettings = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.tr('error')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _changePassword() async {
    if (_oldPasswordCtrl.text.isEmpty ||
        _newPasswordCtrl.text.isEmpty ||
        _confirmPasswordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.tr('enter_all_fields'))),
      );
      return;
    }

    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.tr('passwords_dont_match'))),
      );
      return;
    }

    setState(() => _isSavingPassword = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService().changePassword(
        _oldPasswordCtrl.text.trim(),
        _newPasswordCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isSavingPassword = false;
        _oldPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.tr('password_changed_success')),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingPassword = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
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
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_rounded, color: Colors.blue, size: 22),
                ),
                const SizedBox(width: 12),
                Text(AppLocalizations.tr('system_settings_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
          body: _isLoadingSettings
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final double screenWidth = constraints.maxWidth;
                    final bool isMobile = screenWidth < 650;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 40,
                        vertical: isMobile ? 20 : 32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. بطاقة إعدادات التسليم والمرفقات
                              _buildAttachmentsConfigCard(isDark, isMobile),
                              const SizedBox(height: 32),

                              // 2. بطاقة ربط التنظيف الآلي عبر Cron Job
                              _buildCronJobCard(isDark, isMobile),
                              const SizedBox(height: 32),

                              // 3. بطاقة أمان الحساب وتغيير كلمة المرور
                              _buildSecurityPasswordCard(isDark, isMobile),
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

  // 1. بطاقة إعدادات تسليم المشاريع والمرفقات
  Widget _buildAttachmentsConfigCard(bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: isDark ? 0.15 : 0.05),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.attach_file_rounded, color: Colors.blue, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.tr('attachments_config_section'),
                      style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'التحكم في الحدود القصوى لمرفقات وحجم صور/PDF الرفض',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 20),

          if (isMobile) ...[
            _buildNumberField(_maxAttachmentsCtrl, AppLocalizations.tr('max_attachments_label'), 'ex: 5', Icons.collections_outlined, isDark),
            const SizedBox(height: 16),
            _buildNumberField(_maxFileSizeCtrl, AppLocalizations.tr('max_file_size_label'), 'ex: 30', Icons.sd_storage_outlined, isDark),
            const SizedBox(height: 16),
            _buildNumberField(_autoDeleteDaysCtrl, AppLocalizations.tr('auto_delete_days_label'), 'ex: 30', Icons.timer_outlined, isDark),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildNumberField(_maxAttachmentsCtrl, AppLocalizations.tr('max_attachments_label'), 'ex: 5', Icons.collections_outlined, isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(_maxFileSizeCtrl, AppLocalizations.tr('max_file_size_label'), 'ex: 30', Icons.sd_storage_outlined, isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(_autoDeleteDaysCtrl, AppLocalizations.tr('auto_delete_days_label'), 'ex: 30', Icons.timer_outlined, isDark)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 2. بطاقة أمان الحساب وتغيير كلمة المرور
  Widget _buildSecurityPasswordCard(bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.05),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.lock_reset_rounded, color: Colors.amber.shade700, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.tr('security_password_section'),
                      style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'تحديث كلمة مرور حساب الإدارة الرئيسي بكلمة جديدة معتمدة',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 20),

          _buildPasswordField(_oldPasswordCtrl, AppLocalizations.tr('old_password'), Icons.lock_outline_rounded, isDark, _obscureOld, () {
            setState(() => _obscureOld = !_obscureOld);
          }),
          const SizedBox(height: 16),

          if (isMobile) ...[
            _buildPasswordField(_newPasswordCtrl, AppLocalizations.tr('new_password'), Icons.key_rounded, isDark, _obscureNew, () {
              setState(() => _obscureNew = !_obscureNew);
            }),
            const SizedBox(height: 16),
            _buildPasswordField(_confirmPasswordCtrl, AppLocalizations.tr('confirm_new_password'), Icons.key_rounded, isDark, _obscureConfirm, () {
              setState(() => _obscureConfirm = !_obscureConfirm);
            }),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildPasswordField(_newPasswordCtrl, AppLocalizations.tr('new_password'), Icons.key_rounded, isDark, _obscureNew, () {
                  setState(() => _obscureNew = !_obscureNew);
                })),
                const SizedBox(width: 20),
                Expanded(child: _buildPasswordField(_confirmPasswordCtrl, AppLocalizations.tr('confirm_new_password'), Icons.key_rounded, isDark, _obscureConfirm, () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                })),
              ],
            ),
          ],

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSavingPassword ? null : _changePassword,
              icon: _isSavingPassword
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.shield_rounded, size: 20),
              label: Text(AppLocalizations.tr('change_password')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(TextEditingController ctrl, String label, String hint, IconData icon, bool isDark) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
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

  Widget _buildPasswordField(TextEditingController ctrl, String label, IconData icon, bool isDark, bool isObscure, VoidCallback onToggle) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure,
      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.amber.shade700),
        suffixIcon: IconButton(
          icon: Icon(isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.amber.shade700, width: 2)),
      ),
    );
  }

  // بطاقة ربط التنظيف الآلي للسيرفر عبر Cron Job
  Widget _buildCronJobCard(bool isDark, bool isMobile) {
    final String currentToken = _cronSecretTokenCtrl.text.trim();
    final String cronUrl = "${ApiService.baseUrl}/admin/auto_cleanup_attachments.php?cron_key=$currentToken";

    return Container(
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.timer_outlined, color: Colors.purple, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.tr('cron_job_section_title'),
                      style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.tr('cron_job_description'),
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 20),

          // حقل مفتاح التوكن الزمني المخصص + زر التوليد العشوائي
          if (isMobile) ...[
            TextField(
              controller: _cronSecretTokenCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13, fontFamily: 'monospace'),
              decoration: InputDecoration(
                labelText: AppLocalizations.tr('cron_token_label'),
                prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20, color: Colors.purple),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purple, width: 2)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _generateRandomCronToken,
                icon: const Icon(Icons.casino_rounded, size: 18),
                label: Text(AppLocalizations.tr('generate_token_button')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  side: const BorderSide(color: Colors.purple),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cronSecretTokenCtrl,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.tr('cron_token_label'),
                      prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20, color: Colors.purple),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purple, width: 2)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  onPressed: _generateRandomCronToken,
                  icon: const Icon(Icons.casino_rounded, size: 18),
                  label: Text(AppLocalizations.tr('generate_token_button')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade50,
                    foregroundColor: Colors.purple.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // صندوق كود الرابط الديناميكي
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: SelectableText(
              cronUrl,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (isMobile) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: cronUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.tr('cron_url_copied')),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(AppLocalizations.tr('copy_cron_url')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _testCronExecution(currentToken),
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(AppLocalizations.tr('test_cron_button')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  side: const BorderSide(color: Colors.purple),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: cronUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.tr('cron_url_copied')),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(AppLocalizations.tr('copy_cron_url')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _testCronExecution(currentToken),
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: Text(AppLocalizations.tr('test_cron_button')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      side: const BorderSide(color: Colors.purple),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 28),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSavingSettings ? null : _saveSettings,
              icon: _isSavingSettings
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, size: 22),
              label: Text(
                AppLocalizations.tr('save_changes'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.blue.shade600 : const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _testCronExecution(String token) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await ApiService().testCronCleanup(token);
      if (!mounted) return;
      Navigator.pop(context); // إغلاق مؤشر التحميل

      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 10),
              Text('استجابة Cron Job بنجاح ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الحالة: ${res['status'] ?? 'unknown'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              const SizedBox(height: 6),
              Text('توقيت التنفيذ: ${res['timestamp'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              Text('الرسالة: ${res['message'] ?? '-'}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black38 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '• عدد الملفات الممسوحة: ${res['deleted_files_count'] ?? 0}\n• عدد المجلدات الفارغة المحذوفة: ${res['deleted_dirs_count'] ?? 0}\n• مدة الحفظ الحالية: ${res['retention_days'] ?? 30} يوماً',
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الاتصال: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }
}
