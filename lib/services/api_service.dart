import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Service responsable des appels API vers le serveur backend PHP
class ApiService {
  // L'URL de base de votre API (À modifier lors du déploiement sur le VPS)
  static const String baseUrl = 'https://onedev.ovh/api'; 

  // Récupérer les en-têtes (Headers) avec le Token JWT s'il existe
  Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Fonction de connexion de l'utilisateur
  Future<String> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login.php'),
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      
      // Sauvegarder le Token, le Rôle, et le temps de connexion
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['role']);
      await prefs.setString('login_time', DateTime.now().toIso8601String()); // حفظ وقت الدخول
      
      return data['role'];
    }
    throw Exception('Échec de la connexion');
  }

  // Fonction de déconnexion
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Effacer toutes les données locales
  }

  // [ADMIN] Récupérer tous les projets
  Future<List<dynamic>> getAdminProjects() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/projects.php'), headers: await getHeaders());
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur lors du chargement des projets');
  }

  // [ADMIN] جلب قائمة الحرفاء
  Future<List<dynamic>> getClients() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/clients.php'), headers: await getHeaders());
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur lors du chargement des clients');
  }

  // [ADMIN] إنشاء حريف جديد مع بيانات الهوية والعنوان والشركة
  Future<void> createClient(
    String username, 
    String password, {
    String fullName = '',
    String country = '',
    String state = '',
    String city = '',
    String companyName = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/clients.php'),
      headers: await getHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'full_name': fullName,
        'country': country,
        'state': state,
        'city': city,
        'company_name': companyName,
      }),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body)['message'] ?? 'Error';
      throw Exception(err);
    }
  }

  // [ADMIN] تعديل بيانات حريف
  Future<void> editClient(
    int clientId, 
    String username, 
    String? password, {
    String fullName = '',
    String country = '',
    String state = '',
    String city = '',
    String companyName = '',
  }) async {
    final body = {
      'client_id': clientId,
      'username': username,
      'full_name': fullName,
      'country': country,
      'state': state,
      'city': city,
      'company_name': companyName,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    final res = await http.post(
      Uri.parse('$baseUrl/admin/edit_client.php'),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) throw Exception('Error editing client');
  }

  // [ADMIN] حذف حريف
  Future<void> deleteClient(int clientId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/delete_client.php'),
      headers: await getHeaders(),
      body: jsonEncode({'client_id': clientId}),
    );
    if (res.statusCode != 200) throw Exception('Error deleting client');
  }

  // تغيير كلمة المرور للمستخدم الحالي (أدمن أو حريف)
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/change_password.php'),
      headers: await getHeaders(),
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body)['message'] ?? 'Error';
      throw Exception(err);
    }
  }

  // [ADMIN] Créer un nouveau projet (et un client s'il n'existe pas)
  Future<void> createProject(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('$baseUrl/admin/projects.php'), headers: await getHeaders(), body: jsonEncode(data));
    if (res.statusCode != 200) throw Exception('Erreur lors de la création du projet');
  }

  // [ADMIN] حذف مشروع
  Future<void> deleteProject(int projectId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/delete_project.php'),
      headers: await getHeaders(),
      body: jsonEncode({'project_id': projectId}),
    );
    if (res.statusCode != 200) throw Exception('Error deleting project');
  }

  // [ADMIN] تعديل مشروع
  Future<void> editProject(int projectId, String title, String description, int durationDays, int clientId) async {
    final bodyData = {
      'project_id': projectId, 
      'title': title, 
      'description': description,
      'duration_days': durationDays,
      'client_id': clientId,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/admin/edit_project.php'),
      headers: await getHeaders(),
      body: jsonEncode(bodyData),
    );
    if (res.statusCode != 200) throw Exception('Error editing project');
  }

  // [CLIENT] تحديث حالة الموافقة (قبول أو رفض مع السبب)
  Future<void> updateApprovalStatus(int projectId, String status, {String? reason}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/client/update_approval.php'),
      headers: await getHeaders(),
      body: jsonEncode({
        'project_id': projectId,
        'status': status,
        'reason': reason ?? '',
      }),
    );
    if (res.statusCode != 200) throw Exception('Error updating approval status');
  }

  // [CLIENT] تحديث حالة المصادقة النهائية على استلام إنجاز المشروع (100% completed)
  Future<void> updateFinalApprovalStatus(int projectId, String status, {String? notes}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/client/update_final_approval.php'),
      headers: await getHeaders(),
      body: jsonEncode({
        'project_id': projectId,
        'status': status,
        'notes': notes ?? '',
      }),
    );
    if (res.statusCode != 200) throw Exception('Error updating final approval status');
  }

  // [ADMIN] إعادة تعيين/إلغاء المصادقة النهائية على استلام المشروع (في حال وجود خطأ)
  Future<void> resetFinalApprovalStatus(int projectId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/reset_final_approval.php'),
      headers: await getHeaders(),
      body: jsonEncode({'project_id': projectId}),
    );
    if (res.statusCode != 200) throw Exception('Error resetting final approval');
  }

  // [ADMIN] Récupérer les tâches d'un projet spécifique
  Future<List<dynamic>> getTasks(int projectId) async {
    final res = await http.get(Uri.parse('$baseUrl/admin/tasks.php?project_id=$projectId'), headers: await getHeaders());
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Erreur lors du chargement des tâches');
  }

  // [ADMIN] إضافة مهمة (رئيسية أو فرعية)
  Future<void> createTask(int projectId, String title, String desc, {int? parentId}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/tasks.php'),
      headers: await getHeaders(),
      body: jsonEncode({
        'project_id': projectId, 
        'parent_id': parentId, 
        'title': title, 
        'description': desc
      }),
    );
    if (res.statusCode != 200) throw Exception('Error creating task');
  }

  // [ADMIN] تعديل مهمة (العنوان، الوصف، والملاحظات/التقرير)
  Future<void> editTask(int taskId, String title, String desc, {String? notes}) async {
    final bodyData = <String, dynamic>{
      'task_id': taskId, 
      'title': title, 
      'description': desc,
    };
    if (notes != null) {
      bodyData['notes'] = notes;
    }
    final res = await http.post(
      Uri.parse('$baseUrl/admin/edit_task.php'),
      headers: await getHeaders(),
      body: jsonEncode(bodyData),
    );
    if (res.statusCode != 200) throw Exception('Error editing task');
  }

  // [ADMIN] حذف مهمة
  Future<void> deleteTask(int taskId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/delete_task.php'),
      headers: await getHeaders(),
      body: jsonEncode({'task_id': taskId}),
    );
    if (res.statusCode != 200) throw Exception('Error deleting task');
  }

  // [ADMIN] Valider une tâche (Marquer comme terminée avec un rapport)
  Future<void> validateTask(int taskId, String notes) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/validate_task.php'),
      headers: await getHeaders(),
      body: jsonEncode({'task_id': taskId, 'notes': notes}),
    );
    if (res.statusCode != 200) throw Exception('Erreur lors de la validation de la tâche');
  }

  // [CLIENT] Récupérer les données des projets spécifiques au client connecté
  Future<List<dynamic>> getClientProjects() async {
    final res = await http.get(Uri.parse('$baseUrl/client/project.php'), headers: await getHeaders());
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Aucun projet trouvé');
  }
}
