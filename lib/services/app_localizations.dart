import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class LocaleNotifier extends ValueNotifier<Locale> {
  static const String _prefKey = 'user_locale';

  LocaleNotifier(super.value) {
    _loadSavedLocale();
  }

  void _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString(_prefKey);
    if (langCode != null && (langCode == 'ar' || langCode == 'en' || langCode == 'fr')) {
      value = Locale(langCode);
    }
  }

  void setLocale(String langCode) async {
    if (langCode == 'ar' || langCode == 'en' || langCode == 'fr') {
      value = Locale(langCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, langCode);
    }
  }

  bool get isRtl => value.languageCode == 'ar';
  String get currentLang => value.languageCode;
}

final localeNotifier = LocaleNotifier(const Locale('ar'));

class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      // General
      'app_title': 'Onedev Track - بوابة متابعة المشاريع',
      'admin_portal': 'لوحة تحكم الإدارة',
      'client_portal': 'بوابة متابعة المشاريع',
      'my_dashboard': 'لوحة التحكم الخاصة بي',
      'login': 'تسجيل الدخول',
      'logout': 'تسجيل الخروج',
      'change_password': 'تغيير كلمة المرور',
      'theme_toggle': 'تبديل المظهر',
      'select_language': 'تغيير اللغة',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'confirm': 'تأكيد',
      'delete': 'حذف',
      'edit': 'تعديل',
      'search': 'بحث...',
      'error': 'حدث خطأ غير متوقع',
      'success': 'تمت العملية بنجاح',

      // Change Password Dialog
      'old_password': 'كلمة المرور القديمة',
      'new_password': 'كلمة المرور الجديدة',
      'confirm_new_password': 'تأكيد كلمة المرور الجديدة',
      'passwords_dont_match': 'كلمتا المرور غير متطابقتين',
      'password_changed_success': 'تم تغيير كلمة المرور بنجاح!',
      'enter_all_fields': 'الرجاء تعبئة كافة الحقول',

      // Login Screen
      'welcome_back': 'مرحباً بك مجدداً 👋',
      'login_subtitle': 'قم بتسجيل الدخول للوصول لبوابة متابعة مشاريعك',
      'username': 'اسم المستخدم',
      'password': 'كلمة المرور',
      'signing_in': 'جاري تسجيل الدخول...',
      'invalid_login_error': 'بيانات الدخول غير صحيحة! يرجى المحاولة مرة أخرى.',

      // Client Dashboard
      'welcome_client': 'مرحباً بك،',
      'progress_rate': 'نسبة الإنجاز الإجمالية',
      'days_left': 'الأيام المتبقية',
      'deadline': 'الموعد النهائي',
      'work_days_pack': 'أيام عمل حزمة',
      'project_timeline': 'الجدول الزمني للمهام والعمليات',
      'project_details': 'تفاصيل ومعاينة المشروع',
      'approve_plan': 'أوافق على الخطة والمهام',
      'request_changes': 'طلب تعديلات (رفض)',
      'approval_approved': 'مشروع معتمد وقيد التنفيذ',
      'approval_rejected': 'تم الرفض - بانتظار التعديل',
      'approval_pending': 'بانتظار مراجعتك وموافقتك',
      'approval_approved_banner': 'لقد قمت بالموافقة على خطة هذا المشروع ومهامه بنجاح. العمل جاري طبقاً للخطة!',
      'approval_rejected_banner': 'تم إرسال ملاحظات الرفض للإدارة وجاري مراجعة خطة العمل.',
      'approval_pending_banner': 'الرجاء مراجعة خطة المشروع والمهام أدناه والتأكيد للبدء مباشرة.',
      'rejection_reason_label': 'اذكر سبب الرفض أو التعديلات المطلوبة بكل دقة',
      'confirm_rejection': 'تأكيد وإرسال للإدارة',
      'task_completed': 'مكتملة',
      'task_in_progress': 'قيد العمل',
      'no_active_projects': 'لم يتم العثور على مشاريع نشطة مخصصة لك حالياً.',

      // Admin Dashboard
      'total_projects': 'إجمالي المشاريع',
      'total_clients': 'إجمالي الحرفاء',
      'pending_approval': 'بانتظار الموافقة',
      'rejected_feedback': 'مرفوضة / تعديلات',
      'new_project': 'مشروع جديد',
      'manage_clients': 'إدارة الحرفاء',
      'search_projects_clients': 'البحث باسم المشروع أو اسم العميل...',
      'all': 'الكل',
      'approved': 'المقبولة',
      'rejected': 'المرفوضة',
      'pending': 'بانتظار الموافقة',
      'client_owner': 'الحريف المالك',
      'edit_project': 'تعديل المشروع',
      'delete_project': 'حذف المشروع',
      'confirm_delete_project': 'هل أنت متأكد من حذف هذا المشروع نهائياً؟',
      'project_title': 'عنوان المشروع',
      'project_duration': 'المدة التقديرية (بالأيام)',
      'project_start_date': 'تاريخ بدء المشروع',
      'project_description': 'مواصفات ومعاينة المشروع (HTML / CSS / JS)',
      'launch_project': 'إطلاق المشروع',
      'save_changes': 'حفظ التعديلات',
      'no_projects_found': 'لا توجد مشاريع تطابق البحث حالياً',
      'basic_project_info': 'البيانات الأساسية للمشروع',
      'estimated_timeline': 'الجدول الزمني التقديري',
      'project_specs': 'مواصفات ومعاينة المشروع (HTML / CSS / JS)',
      'project_form_subtitle_new': 'تعبئة الخطة والمواصفات وربطه بالحريف مباشرة',
      'project_form_subtitle_edit': 'تحديث المواصفات، المدة، أو الحريف المالك',
      'client_rejection_note': 'ملاحظة العميل للرفض',
      'select_client_required': 'الرجاء إضافة حريف واحد على الأقل أولاً من صفحة إدارة الحرفاء',

      // Client Management
      'client_management_title': 'إدارة الحرفاء (Clients)',
      'add_new_client': 'إضافة حريف جديد',
      'edit_client': 'تعديل بيانات الحريف',
      'full_name': 'الاسم واللقب',
      'company_name': 'اسم الشركة (اختياري)',
      'country': 'الدولة',
      'state': 'الولاية / المحافظة (اختياري)',
      'city': 'المدينة / البلدية (اختياري)',
      'unspecified_optional': '-- بدون تحديد (اختياري) --',
      'search_clients_placeholder': 'البحث باسم الحريف، الاسم الكامل، الدولة أو الشركة...',
      'no_clients_found': 'لا يوجد حرفاء مسجلين يطابقون البحث',
      'account_username': 'اسم الحساب',
      'projects_count_label': 'مشاريع',
      'confirm_delete_client': 'هل أنت متأكد من حذف هذا الحريف نهائياً؟',
      'account_identity_info': 'بيانات الحساب والهوية',
      'company_address_info': 'الشركة والعنوان (اختياري)',

      // Task Manager
      'task_manager_title': 'إدارة مهام المشروع',
      'add_main_phase': 'إضافة مرحلة رئيسية',
      'add_sub_task': 'إضافة مهمة فرعية',
      'validate_task': 'اعتماد وإكمال المهمة',
      'validate_task_dialog_title': 'اعتماد وتأكيد إنجاز المهمة',
      'task_notes_report': 'ملاحظات وتفاصيل تقرير إنجاز المهمة',
      'confirm_validation': 'تأكيد الاعتماد',
      'task_title': 'عنوان المهمة',
      'task_description': 'وصف المهمة (اختياري)',
    },
    'en': {
      // General
      'app_title': 'Onedev Track - Project Tracking Portal',
      'admin_portal': 'Admin Control Panel',
      'client_portal': 'Project Tracking Portal',
      'my_dashboard': 'My Dashboard',
      'login': 'Sign In',
      'logout': 'Sign Out',
      'change_password': 'Change Password',
      'theme_toggle': 'Toggle Theme',
      'select_language': 'Language',
      'cancel': 'Cancel',
      'save': 'Save',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search...',
      'error': 'An unexpected error occurred',
      'success': 'Operation completed successfully',

      // Change Password Dialog
      'old_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_new_password': 'Confirm New Password',
      'passwords_dont_match': 'Passwords do not match',
      'password_changed_success': 'Password changed successfully!',
      'enter_all_fields': 'Please fill in all fields',

      // Login Screen
      'welcome_back': 'Welcome Back 👋',
      'login_subtitle': 'Sign in to access your project tracking portal',
      'username': 'Username',
      'password': 'Password',
      'signing_in': 'Signing in...',
      'invalid_login_error': 'Invalid credentials! Please try again.',

      // Client Dashboard
      'welcome_client': 'Welcome,',
      'progress_rate': 'Overall Progress',
      'days_left': 'Days Remaining',
      'deadline': 'Deadline',
      'work_days_pack': 'Working Days',
      'project_timeline': 'Tasks & Operations Timeline',
      'project_details': 'Project Details & Preview',
      'approve_plan': 'Approve Plan & Tasks',
      'request_changes': 'Request Changes (Reject)',
      'approval_approved': 'Approved & In Progress',
      'approval_rejected': 'Rejected - Revisions Pending',
      'approval_pending': 'Awaiting Your Approval',
      'approval_approved_banner': 'You have successfully approved this project plan. Work is underway!',
      'approval_rejected_banner': 'Rejection feedback sent to management. Plan is under review.',
      'approval_pending_banner': 'Please review the project plan and tasks below to confirm and start.',
      'rejection_reason_label': 'Please specify the reason for rejection or required changes',
      'confirm_rejection': 'Confirm & Send to Admin',
      'task_completed': 'Completed',
      'task_in_progress': 'In Progress',
      'no_active_projects': 'No active projects assigned to you currently.',

      // Admin Dashboard
      'total_projects': 'Total Projects',
      'total_clients': 'Total Clients',
      'pending_approval': 'Pending Approval',
      'rejected_feedback': 'Rejected / Revisions',
      'new_project': 'New Project',
      'manage_clients': 'Manage Clients',
      'search_projects_clients': 'Search by project or client name...',
      'all': 'All',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'pending': 'Pending',
      'client_owner': 'Owner Client',
      'edit_project': 'Edit Project',
      'delete_project': 'Delete Project',
      'confirm_delete_project': 'Are you sure you want to permanently delete this project?',
      'project_title': 'Project Title',
      'project_duration': 'Estimated Duration (Days)',
      'project_start_date': 'Start Date',
      'project_description': 'Project Specs & Preview (HTML / CSS / JS)',
      'launch_project': 'Launch Project',
      'save_changes': 'Save Changes',
      'no_projects_found': 'No projects found matching search',
      'basic_project_info': 'Basic Project Details',
      'estimated_timeline': 'Estimated Timeline',
      'project_specs': 'Project Specs & Preview (HTML / CSS / JS)',
      'project_form_subtitle_new': 'Fill in plan & specs and link to client directly',
      'project_form_subtitle_edit': 'Update specs, duration, or owner client',
      'client_rejection_note': 'Client Rejection Note',
      'select_client_required': 'Please add at least one client first from Client Management page',

      // Client Management
      'client_management_title': 'Client Management',
      'add_new_client': 'Add New Client',
      'edit_client': 'Edit Client Data',
      'full_name': 'Full Name',
      'company_name': 'Company Name (Optional)',
      'country': 'Country',
      'state': 'State / Governorate (Optional)',
      'city': 'City / Municipality (Optional)',
      'unspecified_optional': '-- Unspecified (Optional) --',
      'search_clients_placeholder': 'Search by username, full name, country or company...',
      'no_clients_found': 'No clients found matching your search',
      'account_username': 'Account Username',
      'projects_count_label': 'Projects',
      'confirm_delete_client': 'Are you sure you want to permanently delete this client?',
      'account_identity_info': 'Account & Identity Details',
      'company_address_info': 'Company & Address (Optional)',

      // Task Manager
      'task_manager_title': 'Project Task Manager',
      'add_main_phase': 'Add Main Phase',
      'add_sub_task': 'Add Sub-task',
      'validate_task': 'Validate & Complete Task',
      'validate_task_dialog_title': 'Task Completion Validation',
      'task_notes_report': 'Completion Report Details / Notes',
      'confirm_validation': 'Confirm Validation',
      'task_title': 'Task Title',
      'task_description': 'Task Description (Optional)',
    },
    'fr': {
      // General
      'app_title': 'Onedev Track - Portail de Suivi de Projets',
      'admin_portal': 'Panneau d\'Administration',
      'client_portal': 'Portail de Suivi de Projets',
      'my_dashboard': 'Mon Tableau de Bord',
      'login': 'Se Connecter',
      'logout': 'Se Déconnecter',
      'change_password': 'Changer le mot de passe',
      'theme_toggle': 'Changer le thème',
      'select_language': 'Langue',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'confirm': 'Confirmer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'search': 'Rechercher...',
      'error': 'Une erreur inattendue est survenue',
      'success': 'Opération réussie',

      // Change Password Dialog
      'old_password': 'Ancien mot de passe',
      'new_password': 'Nouveau mot de passe',
      'confirm_new_password': 'Confirmer le nouveau mot de passe',
      'passwords_dont_match': 'Les mots de passe ne correspondent pas',
      'password_changed_success': 'Mot de passe modifié avec succès !',
      'enter_all_fields': 'Veuillez remplir tous les champs',

      // Login Screen
      'welcome_back': 'Bon retour 👋',
      'login_subtitle': 'Connectez-vous pour accéder à votre portail de suivi',
      'username': 'Nom d\'utilisateur',
      'password': 'Mot de passe',
      'signing_in': 'Connexion en cours...',
      'invalid_login_error': 'Identifiants invalides ! Veuillez réessayer.',

      // Client Dashboard
      'welcome_client': 'Bienvenue,',
      'progress_rate': 'Avancement Global',
      'days_left': 'Jours Restants',
      'deadline': 'Date Limite',
      'work_days_pack': 'Jours ouvrables',
      'project_timeline': 'Calendrier des Tâches et Opérations',
      'project_details': 'Détails et Aperçu du Projet',
      'approve_plan': 'Approuver le Plan & Tâches',
      'request_changes': 'Demander des Modifications (Refuser)',
      'approval_approved': 'Projet Approuvé & En Cours',
      'approval_rejected': 'Refusé - Révisions En Attente',
      'approval_pending': 'En Attente de Votre Validation',
      'approval_approved_banner': 'Vous avez approuvé ce plan de projet avec succès. Les travaux sont en cours !',
      'approval_rejected_banner': 'Commentaires de refus envoyés à la direction. Plan en cours de révision.',
      'approval_pending_banner': 'Veuillez examiner le plan et les tâches ci-dessous pour confirmer et démarrer.',
      'rejection_reason_label': 'Veuillez préciser la raison du refus ou les modifications requises',
      'confirm_rejection': 'Confirmer & Envoyer à l\'Admin',
      'task_completed': 'Terminée',
      'task_in_progress': 'En Cours',
      'no_active_projects': 'Aucun projet actif ne vous est attribué actuellement.',

      // Admin Dashboard
      'total_projects': 'Total Projets',
      'total_clients': 'Total Clients',
      'pending_approval': 'En Attente de Validation',
      'rejected_feedback': 'Refusés / Révisions',
      'new_project': 'Nouveau Projet',
      'manage_clients': 'Gérer les Clients',
      'search_projects_clients': 'Rechercher par nom de projet ou client...',
      'all': 'Tous',
      'approved': 'Approuvés',
      'rejected': 'Refusés',
      'pending': 'En Attente',
      'client_owner': 'Client Propriétaire',
      'edit_project': 'Modifier le Projet',
      'delete_project': 'Supprimer le Projet',
      'confirm_delete_project': 'Êtes-vous sûr de vouloir supprimer définitivement ce projet ?',
      'project_title': 'Titre du Projet',
      'project_duration': 'Durée Estimée (Jours)',
      'project_start_date': 'Date de Début',
      'project_description': 'Spécifications & Aperçu (HTML / CSS / JS)',
      'launch_project': 'Lancer le Projet',
      'save_changes': 'Enregistrer les Modifications',
      'no_projects_found': 'Aucun projet ne correspond à la recherche',
      'basic_project_info': 'Informations de base du projet',
      'estimated_timeline': 'Calendrier estimé',
      'project_specs': 'Spécifications & Aperçu du projet (HTML / CSS / JS)',
      'project_form_subtitle_new': 'Remplir le plan et spécifications et lier au client',
      'project_form_subtitle_edit': 'Mettre à jour spécifications, durée ou client',
      'client_rejection_note': 'Note de refus du client',
      'select_client_required': 'Veuillez d\'abord ajouter au moins un client depuis la page de gestion des clients',

      // Client Management
      'client_management_title': 'Gestion des Clients',
      'add_new_client': 'Ajouter un Client',
      'edit_client': 'Modifier le Client',
      'full_name': 'Nom et Prénom',
      'company_name': 'Nom de l\'Entreprise (Optionnel)',
      'country': 'Pays',
      'state': 'Gouvernorat / Région (Optionnel)',
      'city': 'Ville / Municipalité (Optionnel)',
      'unspecified_optional': '-- Non Spécifié (Optionnel) --',
      'search_clients_placeholder': 'Rechercher par nom d\'utilisateur, nom complet, pays ou entreprise...',
      'no_clients_found': 'Aucun client ne correspond à votre recherche',
      'account_username': 'Nom de compte',
      'projects_count_label': 'Projets',
      'confirm_delete_client': 'Êtes-vous sûr de vouloir supprimer définitivement ce client ?',
      'account_identity_info': 'Détails du compte et de l\'identité',
      'company_address_info': 'Entreprise et adresse (Optionnel)',

      // Task Manager
      'task_manager_title': 'Gestionnaire de Tâches du Projet',
      'add_main_phase': 'Ajouter une Phase Principale',
      'add_sub_task': 'Ajouter une Sous-Tâche',
      'validate_task': 'Valider & Terminer la Tâche',
      'validate_task_dialog_title': 'Validation de la Tâche',
      'task_notes_report': 'Détails du Rapport / Notes de Réalisation',
      'confirm_validation': 'Confirmer la Validation',
      'task_title': 'Titre de la Tâche',
      'task_description': 'Description de la Tâche (Optionnel)',
    }
  };

  static String tr(String key) {
    final lang = localeNotifier.currentLang;
    return _localizedValues[lang]?[key] ?? _localizedValues['ar']?[key] ?? key;
  }
}

// ودجت تغيير كلمة المرور المعاد استخدامها في الواجهتين
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock_reset_rounded, color: Colors.blue),
          const SizedBox(width: 10),
          Text(AppLocalizations.tr('change_password')),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.tr('old_password'),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _newPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.tr('new_password'),
                  prefixIcon: const Icon(Icons.key_rounded),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.tr('confirm_new_password'),
                  prefixIcon: const Icon(Icons.key_rounded),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.tr('cancel')),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
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

                  setState(() => _isLoading = true);
                  try {
                    final api = ApiService();
                    await api.changePassword(
                      _oldPasswordCtrl.text.trim(),
                      _newPasswordCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.tr('password_changed_success')),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    setState(() => _isLoading = false);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(AppLocalizations.tr('save')),
        ),
      ],
    );
  }
}

// قائمة اختيار اللغة المعادة الاستخدام في AppBar
Widget buildLanguageSelector(bool isDark) {
  return ValueListenableBuilder<Locale>(
    valueListenable: localeNotifier,
    builder: (context, locale, _) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: locale.languageCode,
            icon: const Icon(Icons.language_rounded, size: 18),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            items: const [
              DropdownMenuItem(
                value: 'ar',
                child: Row(
                  children: [
                    Text('🇸🇦 ', style: TextStyle(fontSize: 14)),
                    Text('العربية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    Text('🇬🇧 ', style: TextStyle(fontSize: 14)),
                    Text('English', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'fr',
                child: Row(
                  children: [
                    Text('🇫🇷 ', style: TextStyle(fontSize: 14)),
                    Text('Français', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
            onChanged: (langCode) {
              if (langCode != null) {
                localeNotifier.setLocale(langCode);
              }
            },
          ),
        ),
      );
    },
  );
}
