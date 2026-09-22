import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_models.dart';
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
  static String get currentLanguage => localeNotifier.currentLang;

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
      'decision_date': 'تاريخ وساعة القرار',
      'final_handover_title': 'المصادقة على استلام وإكتمال المشروع 🏆',
      'final_handover_approved_banner': 'تمت المصادقة النهائية على استلام وتسليم المشروع بنجاح! شكراً لتعاملكم معنا.',
      'final_handover_rejected_banner': 'تم تقديم ملاحظات عدم المصادقة على الاستلام وجاري مراجعتها من قبل الإدارة.',
      'final_handover_pending_banner': 'تهانينا! اكتملت جميع مهام المشروع بنسبة 100%. الرجاء المعاينة والمصادقة على الاستلام النهائي.',
      'confirm_final_approval': 'مصادقة واستلام النهائي',
      'reject_final_approval': 'عدم المصادقة / ملاحظات التسليم',
      'final_rejection_reason_label': 'اذكر ملاحظاتك وأسباب عدم المصادقة النهائية بدقة',
      'final_approval_status_label': 'حالة المصادقة النهائية',
      'reset_final_approval': 'إعادة تعيين الاستلام النهائي 🔄',
      'confirm_reset_final_approval': 'هل أنت متأكد من إلغاء وإعادة تعيين حالة الاستلام النهائي لهذا المشروع؟',
      'resolve_revision_button': 'تمت معالجة الملاحظات - إعادة الإرسال للحريف 🚀',
      'confirm_resolve_revision': 'هل قمت بإنهاء وتطبيق كافة الملاحظات وإعادة إرسال المشروع للحريف للمصادقة النهائية؟',
      'task_completed': 'مكتملة',
      'task_in_progress': 'قيد العمل',
      'completed_at_label': 'تاريخ ووقت الإنجاز',
      'no_active_projects': 'لم يتم العثور على مشاريع نشطة مخصصة لك حالياً.',

      // Admin Dashboard
      'total_projects': 'إجمالي المشاريع',
      'total_clients': 'إجمالي الحرفاء',
      'pending_approval': 'بانتظار الموافقة',
      'rejected_feedback': 'مرفوضة / تعديلات',
      'final_approved_kpi': 'مصادقة تسليم نهائي 🏆',
      'final_rejected_kpi': 'ملاحظات استلام نهائي ⚠️',
      'new_project': 'مشروع جديد',
      'manage_clients': 'إدارة الحرفاء',
      'system_settings_title': 'إعدادات النظام العامة ⚙️',
      'max_attachments_label': 'العدد الأقصى للمرفقات المسموحة',
      'max_file_size_label': 'الحد الأقصى لحجم الملف بالميجابايت (MB)',
      'auto_delete_days_label': 'مدة الاحتفاظ بالملفات (بالأيام)',
      'archived_file_label': 'ملف مؤرشف (تم حذفه من السيرفر آلياً بانتهاء المدة)',
      'security_password_section': 'أمان الحساب وتغيير كلمة المرور',
      'attachments_config_section': 'إعدادات تسليم المشاريع والمرفقات',
      'cron_job_section_title': 'ربط التنظيف الآلي للسيرفر عبر Cron Job ⏱️',
      'cron_job_description': 'يمكنك إضافة هذا الرابط المباشر في خدمة Cron خارجية (مثل cron-job.org) لتنفيذ مسح ملفات السيرفر المنتهية آلياً.',
      'cron_token_label': 'توكن أمان Cron Job',
      'generate_token_button': 'توليد توكن أمان جديد 🎲',
      'copy_cron_url': 'نسخ رابط Cron Job 📋',
      'test_cron_button': 'اختبار التنفيذ المباشر ⚡',
      'cron_url_copied': 'تم نسخ رابط Cron Job المباشر إلى المحفظة بنجاح!',
      'settings_saved_success': 'تم حفظ إعدادات النظام وتحديثها بنجاح!',
      'search_projects_clients': 'البحث باسم المشروع أو اسم العميل...',
      'all': 'الكل',
      'approved': 'مقبول',
      'rejected': 'مرفوض',
      'pending': 'بانتظار الموافقة',
      'client_owner': 'الحريف المالك',
      'edit_project': 'تعديل المشروع',
      'delete_project': 'حذف المشروع',
      'confirm_delete_project': 'هل أنت متأكد من حذف هذا المشروع نهائياً؟',
      'project_title': 'عنوان المشروع',
      'project_id_label': 'معرف المشروع المرجعي',
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
      'decision_date': 'Decision Date & Time',
      'final_handover_title': 'Final Project Handover Sign-off 🏆',
      'final_handover_approved_banner': 'Final project handover successfully approved! Thank you for your business.',
      'final_handover_rejected_banner': 'Final handover revision notes submitted and currently under review by management.',
      'final_handover_pending_banner': 'Congratulations! All project tasks are 100% completed. Please review and sign off on final handover.',
      'confirm_final_approval': 'Sign off & Final Accept',
      'reject_final_approval': 'Reject Handover / Notes',
      'final_rejection_reason_label': 'Please state your notes & reasons for final handover rejection',
      'final_approval_status_label': 'Final Handover Status',
      'reset_final_approval': 'Reset Final Handover 🔄',
      'confirm_reset_final_approval': 'Are you sure you want to cancel and reset the final handover status for this project?',
      'resolve_revision_button': 'Resolve Notes & Resubmit to Client 🚀',
      'confirm_resolve_revision': 'Have you resolved all notes and want to resubmit the project to the client for final sign-off?',
      'task_completed': 'Completed',
      'task_in_progress': 'In Progress',
      'no_active_projects': 'No active projects assigned to you currently.',

      // Admin Dashboard
      'total_projects': 'Total Projects',
      'total_clients': 'Total Clients',
      'pending_approval': 'Pending Approval',
      'rejected_feedback': 'Rejected / Revisions',
      'final_approved_kpi': 'Final Handover Approved 🏆',
      'final_rejected_kpi': 'Final Handover Notes ⚠️',
      'new_project': 'New Project',
      'manage_clients': 'Manage Clients',
      'system_settings_title': 'System Settings ⚙️',
      'max_attachments_label': 'Max Allowed Attachments Count',
      'max_file_size_label': 'Max File Size Limit (MB)',
      'auto_delete_days_label': 'Server File Retention (Days)',
      'archived_file_label': 'Archived File (Auto-deleted from server)',
      'security_password_section': 'Account Security & Password',
      'attachments_config_section': 'Project Handover & Attachment Configs',
      'cron_job_section_title': 'Automated Server Cleanup via Cron Job ⏱️',
      'cron_job_description': 'Add this trigger URL to an external Cron service (e.g. cron-job.org) to automatically cleanup old server files daily.',
      'cron_token_label': 'Cron Job Secret Token',
      'generate_token_button': 'Generate New Token 🎲',
      'copy_cron_url': 'Copy Cron Job URL 📋',
      'test_cron_button': 'Test Execution Now ⚡',
      'cron_url_copied': 'Cron Job Trigger URL copied to clipboard successfully!',
      'settings_saved_success': 'System settings saved and updated successfully!',
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
      'project_id_label': 'Project ID',
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
      'decision_date': 'Date et Heure de Décision',
      'final_handover_title': 'Validation Finale et Livraison du Projet 🏆',
      'final_handover_approved_banner': 'Livraison finale du projet approuvée avec succès ! Merci de votre confiance.',
      'final_handover_rejected_banner': 'Remarques de révision soumises et en cours d\'examen par la direction.',
      'final_handover_pending_banner': 'Félicitations ! Toutes les tâches sont complétées à 100%. Veuillez examiner et valider la livraison finale.',
      'confirm_final_approval': 'Valider la livraison finale',
      'reject_final_approval': 'Refuser la livraison / Remarques',
      'final_rejection_reason_label': 'Veuillez préciser vos remarques et motifs de refus final',
      'final_approval_status_label': 'Statut de Livraison Finale',
      'reset_final_approval': 'Réinitialiser Livraison Finale 🔄',
      'confirm_reset_final_approval': 'Êtes-vous sûr de vouloir annuler et réinitialiser le statut de livraison finale pour ce projet ?',
      'resolve_revision_button': 'Résoudre les remarques & Renvoyer au Client 🚀',
      'confirm_resolve_revision': 'Avez-vous résolu toutes les remarques et souhaitez-vous renvoyer le projet au client pour validation finale ?',
      'task_completed': 'Terminée',
      'task_in_progress': 'En Cours',
      'no_active_projects': 'Aucun projet actif ne vous est attribué actuellement.',

      // Admin Dashboard
      'total_projects': 'Total Projets',
      'total_clients': 'Total Clients',
      'pending_approval': 'En Attente de Validation',
      'rejected_feedback': 'Refusés / Révisions',
      'final_approved_kpi': 'Livraison Finale Validée 🏆',
      'final_rejected_kpi': 'Remarques Livraison Finale ⚠️',
      'new_project': 'Nouveau Projet',
      'manage_clients': 'Gérer les Clients',
      'system_settings_title': 'Paramètres du Système ⚙️',
      'max_attachments_label': 'Nombre Max de Pièces Jointes',
      'max_file_size_label': 'Taille Max du Fichier (Mo)',
      'auto_delete_days_label': 'Durée Conservation Fichiers (Jours)',
      'archived_file_label': 'Fichier Archivé (Supprimé automatiquement du serveur)',
      'security_password_section': 'Sécurité du Compte & Mot de Passe',
      'attachments_config_section': 'Configuration Livraisons & Pièces Jointes',
      'cron_job_section_title': 'Nettoyage Automatique via Cron Job ⏱️',
      'cron_job_description': 'Ajoutez cette URL déclencheuse à un service Cron externe (ex. cron-job.org) pour nettoyer automatiquement les fichiers.',
      'cron_token_label': 'Token de Sécurité Cron Job',
      'generate_token_button': 'Générer un Nouveau Token 🎲',
      'copy_cron_url': 'Copier L\'URL Cron Job 📋',
      'test_cron_button': 'Tester L\'Exécution ⚡',
      'cron_url_copied': 'URL Cron Job copiée dans le presse-papiers avec succès !',
      'settings_saved_success': 'Paramètres système enregistrés avec succès !',
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
      'project_id_label': 'ID du Projet',
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

  // طباعة شهادة ومحضر الاستلام النهائي للمشروع
  static void printHandoverCertificate(Project project) {
    if (kIsWeb) {
      final certHtml = _generateHandoverReportHtml(project);
      final blob = html.Blob([certHtml], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
    }
  }

  static String _generateHandoverReportHtml(Project project) {
    final String approvalDateStr = project.finalApprovalDate != null
        ? project.finalApprovalDate.toString().split('.')[0]
        : DateTime.now().toString().split('.')[0];

    final String initialApprovalDateStr = project.clientApprovalDate != null
        ? project.clientApprovalDate.toString().split('.')[0]
        : 'معتمد';

    final String refId = 'PRJ-${project.id}-${project.clientId}';

    // بناء صفوف محضر المهام والعمليات المكتملة 100% مع تقارير الإدارة
    String taskRows = '';
    for (var task in project.tasks) {
      String adminReportNote = task.notes.isNotEmpty ? '<br><span style="color:#2563eb; font-size:11px;">📌 تقرير الإنجاز: ${task.notes}</span>' : '';
      taskRows += '''
        <tr>
          <td><strong>${task.title}</strong><br><span style="color:#64748b; font-size:12px;">${task.description}</span>$adminReportNote</td>
          <td class="status">مكتملة 100% ✓</td>
        </tr>
      ''';
      for (var sub in task.subTasks) {
        String subAdminNote = sub.notes.isNotEmpty ? '<br><span style="color:#2563eb; font-size:11px;">📌 تقرير الإنجاز: ${sub.notes}</span>' : '';
        taskRows += '''
          <tr>
            <td style="padding-right: 30px;">↳ ${sub.title}<br><span style="color:#64748b; font-size:11px;">${sub.description}</span>$subAdminNote</td>
            <td class="status">مكتملة 100% ✓</td>
          </tr>
        ''';
      }
    }

    // بناء صفوف المرفقات والصور المعتمدة
    String attachmentSection = '';
    if (project.attachments.isNotEmpty) {
      String attRows = '';
      for (var att in project.attachments) {
        final double sizeMb = att.fileSize / (1024 * 1024);
        final String fullUrl = 'https://onedev.ovh/track/${att.filePath}';
        attRows += '''
          <tr>
            <td>📎 <strong>${att.fileName}</strong></td>
            <td>${att.fileType.toUpperCase()}</td>
            <td>${sizeMb.toStringAsFixed(2)} MB</td>
            <td><a href="$fullUrl" target="_blank" style="color:#2563eb; font-weight:bold; text-decoration:none;">معاينة المرفق 🔗</a></td>
          </tr>
        ''';
      }
      attachmentSection = '''
        <div class="section-title">المرفقات والدلائل المرفقة (${project.attachments.length} ملفات)</div>
        <table class="tasks-table">
          <thead>
            <tr>
              <th>اسم الملف المرفق</th>
              <th style="width: 80px;">النوع</th>
              <th style="width: 100px;">الحجم</th>
              <th style="width: 120px;">الرابط</th>
            </tr>
          </thead>
          <tbody>
            $attRows
          </tbody>
        </table>
      ''';
    }

    // بناء قسم سجل المراجعات والتعديلات المعالجة بأسلوب مشطب وأنيق
    String notesSection = '';
    if (project.revisions.isNotEmpty) {
      String revRows = '';
      for (var rev in project.revisions) {
        final bool isResolved = rev.status == 'resolved';
        final String revDate = rev.createdAt.toString().split('.')[0];
        final String resolvedDateStr = rev.resolvedAt != null ? ' (تمت المعالجة: ${rev.resolvedAt.toString().split('.')[0]})' : '';
        final String notesDecoration = isResolved ? 'text-decoration: line-through; color: #64748b;' : 'color: #991b1b;';
        final String statusBadge = isResolved 
            ? '<span style="color:#059669; font-weight:bold;">تمت المعالجة من الإدارة ✓</span>' 
            : '<span style="color:#dc2626; font-weight:bold;">بانتظار المعالجة ⚠️</span>';

        revRows += '''
          <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:10px; padding:12px 16px; margin-bottom:10px;">
            <div style="display:flex; justify-content:space-between; font-size:12px; margin-bottom:4px;">
              <strong>مراجعة #${rev.revisionNumber} — $statusBadge</strong>
              <span style="color:#94a3b8;">$revDate $resolvedDateStr</span>
            </div>
            <div style="font-size:13px; $notesDecoration">${rev.clientNotes}</div>
          </div>
        ''';
      }

      notesSection = '''
        <div class="section-title">سجل مراجعات وملاحظات الحريف المعالجة أثناء التسليم النهائي</div>
        <div style="margin-bottom:25px;">
          $revRows
        </div>
      ''';
    } else if (project.finalApprovalNotes != null && project.finalApprovalNotes!.isNotEmpty) {
      notesSection = '''
        <div class="section-title">ملاحظات وتعقيبات الحريف المعالجة أثناء التسليم النهائي</div>
        <div style="background:#fffbeb; border:1px solid #fde68a; padding:15px; border-radius:12px; margin-bottom:25px; font-size:13px; color:#92400e;">
          📝 <strong>الملاحظات المعتمدة:</strong> ${project.finalApprovalNotes}
        </div>
      ''';
    }

    return '''<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>شهادة ومحضر استلام مشروع - ${project.title}</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap');

    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Cairo', sans-serif;
      background: #f8fafc;
      color: #0f172a;
      padding: 40px 20px;
    }

    .cert-card {
      max-width: 880px;
      margin: 0 auto;
      background: #ffffff;
      border-radius: 20px;
      border: 2px solid #e2e8f0;
      box-shadow: 0 10px 30px rgba(0,0,0,0.05);
      padding: 40px;
      position: relative;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 2px solid #f1f5f9;
      padding-bottom: 20px;
      margin-bottom: 30px;
    }

    .logo-title {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .logo-icon {
      font-size: 36px;
    }

    .title-text {
      font-size: 24px;
      font-weight: 800;
      color: #0f172a;
    }

    .doc-badge {
      background: #ecfdf5;
      color: #047857;
      border: 1px solid #a7f3d0;
      padding: 6px 16px;
      border-radius: 20px;
      font-size: 13px;
      font-weight: 700;
    }

    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      background: #f8fafc;
      padding: 20px;
      border-radius: 14px;
      border: 1px solid #e2e8f0;
      margin-bottom: 30px;
    }

    .info-item {
      font-size: 14px;
    }

    .info-label {
      color: #64748b;
      font-weight: 600;
      font-size: 12px;
    }

    .info-val {
      color: #0f172a;
      font-weight: 700;
      font-size: 14px;
      margin-top: 2px;
    }

    .section-title {
      font-size: 16px;
      font-weight: 800;
      color: #0f172a;
      margin-bottom: 14px;
      margin-top: 20px;
      border-right: 4px solid #10b981;
      padding-right: 10px;
    }

    .tasks-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 25px;
    }

    .tasks-table th, .tasks-table td {
      padding: 10px 14px;
      border: 1px solid #e2e8f0;
      text-align: right;
      font-size: 13px;
    }

    .tasks-table th {
      background: #f1f5f9;
      font-weight: 700;
      color: #1e293b;
    }

    .tasks-table td.status {
      color: #10b981;
      font-weight: 700;
    }

    .stamp-section {
      margin-top: 40px;
      border-top: 2px dashed #cbd5e1;
      padding-top: 30px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 20px;
    }

    .stamp-box {
      display: flex;
      align-items: center;
      gap: 20px;
      background: #f0fdf4;
      border: 2px solid #86efac;
      padding: 16px 24px;
      border-radius: 16px;
    }

    .stamp-svg {
      width: 70px;
      height: 70px;
    }

    .stamp-text-title {
      font-size: 17px;
      font-weight: 800;
      color: #065f46;
    }

    .stamp-text-sub {
      font-size: 12px;
      color: #047857;
      margin-top: 2px;
    }

    .signatures {
      display: flex;
      gap: 40px;
      text-align: center;
      font-size: 13px;
      color: #475569;
    }

    .sig-line {
      margin-top: 30px;
      border-top: 1px dashed #94a3b8;
      width: 120px;
    }

    .no-print {
      margin-bottom: 20px;
      text-align: center;
    }

    .btn-print {
      background: #2563eb;
      color: white;
      border: none;
      padding: 12px 28px;
      border-radius: 10px;
      font-family: inherit;
      font-weight: 700;
      font-size: 15px;
      cursor: pointer;
      box-shadow: 0 4px 12px rgba(37,99,235,0.3);
    }

    @media print {
      body { padding: 0; background: white; }
      .cert-card { border: none; box-shadow: none; padding: 20px; }
      .no-print { display: none; }
    }
  </style>
</head>
<body>
  <div class="no-print">
    <button class="btn-print" onclick="window.print()">🖨️ طباعة الشهادة / تصدير PDF</button>
  </div>

  <div class="cert-card">
    <div class="header">
      <div class="logo-title">
        <span class="logo-icon">🚀</span>
        <div>
          <div class="title-text">OneDev Track</div>
          <div style="font-size:12px; color:#64748b;">محضر وشهادة استلام مشروع رسمي ومصادق • المرجع: $refId</div>
        </div>
      </div>
      <div class="doc-badge">مرخص ومعتمد ✓</div>
    </div>

    <div class="info-grid">
      <div class="info-item">
        <div class="info-label">اسم المشروع:</div>
        <div class="info-val">${project.title}</div>
      </div>
      <div class="info-item">
        <div class="info-label">الحريف المالك:</div>
        <div class="info-val">${project.clientName}</div>
      </div>
      <div class="info-item">
        <div class="info-label">تاريخ البدء والموعد النهائي:</div>
        <div class="info-val">${project.startDate.toString().split(' ')[0]} &rarr; ${project.deadline.toString().split(' ')[0]} (${project.durationDays} أيام عمل)</div>
      </div>
      <div class="info-item">
        <div class="info-label">تاريخ وتوقيت اعتماد الخطة المبدئي:</div>
        <div class="info-val">$initialApprovalDateStr</div>
      </div>
      <div class="info-item">
        <div class="info-label">تاريخ وتوقيت المصادقة والاستلام النهائي:</div>
        <div class="info-val" style="color:#10b981;">$approvalDateStr ✓</div>
      </div>
      <div class="info-item">
        <div class="info-label">إجمالي العمليات المنجزة:</div>
        <div class="info-val">${project.completedTasks} / ${project.totalTasks} مهام (إنجاز 100%)</div>
      </div>
    </div>

    $notesSection

    $attachmentSection

    <div class="section-title">محضر إنجاز وإكتمال كافة المهام وتقارير التنفيذ (100%)</div>
    <table class="tasks-table">
      <thead>
        <tr>
          <th>اسم المهمة / العملية وتفاصيل الإنجاز</th>
          <th style="width: 110px;">حالة الإنجاز</th>
        </tr>
      </thead>
      <tbody>
        $taskRows
      </tbody>
    </table>

    <div class="stamp-section">
      <div class="stamp-box">
        <svg class="stamp-svg" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect x="10" y="10" width="80" height="60" rx="10" stroke="#1E293B" stroke-width="6" fill="none"/>
          <rect x="35" y="22" width="30" height="8" rx="4" fill="#1E293B"/>
          <line x1="25" y1="40" x2="75" y2="40" stroke="#1E293B" stroke-width="5" stroke-linecap="round"/>
          <line x1="25" y1="52" x2="55" y2="52" stroke="#1E293B" stroke-width="5" stroke-linecap="round"/>
          <circle cx="65" cy="65" r="20" fill="#10B981" stroke="#FFFFFF" stroke-width="4"/>
          <path d="M65 53V77M53 65H77" stroke="#1E293B" stroke-width="6" stroke-linecap="round"/>
          <path d="M52 82L45 95L58 90L65 95L58 82" fill="#10B981"/>
          <path d="M78 82L85 95L72 90L65 95L72 82" fill="#10B981"/>
        </svg>
        <div>
          <div class="stamp-text-title">تمت المصادقة والاستلام النهائي بنجاح</div>
          <div class="stamp-text-sub">تم استلام جميع مخرجات المشروع بحالة تشغيلية ممتازة معتمدة</div>
        </div>
      </div>

      <div class="signatures">
        <div>
          <div>توقيع ومصادقة العميل</div>
          <div class="sig-line"></div>
          <div style="font-size:11px; margin-top:4px;">${project.clientName}</div>
        </div>
        <div>
          <div>إدارة التنفيذ والتعميد</div>
          <div class="sig-line"></div>
          <div style="font-size:11px; margin-top:4px;">OneDev IT Agency</div>
        </div>
      </div>
    </div>
  </div>

  <script>
    window.onload = function() {
      setTimeout(function() {
        window.print();
      }, 600);
    };
  </script>
</body>
</html>''';
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
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

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
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  labelText: AppLocalizations.tr('old_password'),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOld ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _newPasswordCtrl,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: AppLocalizations.tr('new_password'),
                  prefixIcon: const Icon(Icons.key_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: AppLocalizations.tr('confirm_new_password'),
                  prefixIcon: const Icon(Icons.key_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
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
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    final api = ApiService();
                    await api.changePassword(
                      _oldPasswordCtrl.text.trim(),
                      _newPasswordCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.tr('password_changed_success')),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isLoading = false);
                    messenger.showSnackBar(
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
                ApiService().changeLanguage(langCode);
              }
            },
          ),
        ),
      );
    },
  );
}
