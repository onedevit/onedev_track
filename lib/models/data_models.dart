// Modèle de données représentant un Projet
// نموذج بيانات كائن العميل (ClientUser)
class ClientUser {
  final int id;
  final String username;
  final String fullName;
  final String country;
  final String state;
  final String city;
  final String companyName;
  final int projectsCount;

  ClientUser({
    required this.id,
    required this.username,
    this.fullName = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.companyName = '',
    this.projectsCount = 0,
  });

  factory ClientUser.fromJson(Map<String, dynamic> json) {
    return ClientUser(
      id: int.parse(json['id'].toString()),
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      country: json['country'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      companyName: json['company_name'] ?? '',
      projectsCount: json['projects_count'] != null ? int.parse(json['projects_count'].toString()) : 0,
    );
  }
}

class Project {
  final int id;
  final int clientId; // معرف العميل
  final String title;
  final String description; // وصف المشروع
  final String clientName;
  final DateTime startDate;
  final int durationDays;
  final DateTime deadline;
  final int totalTasks;
  final int completedTasks;
  final String approvalStatus; // حالة الموافقة
  final String? rejectionReason; // سبب الرفض
  final List<Task> tasks; // هذه القائمة ستحتوي فقط على "المهام الرئيسية" وجذور الشجرة

  Project({
    required this.id,
    required this.clientId,
    required this.title,
    this.description = '',
    this.clientName = '',
    required this.startDate,
    required this.durationDays,
    required this.deadline,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.approvalStatus = 'pending',
    this.rejectionReason,
    this.tasks = const [],
  });

  // تحويل الـ JSON وبناء شجرة المهام
  factory Project.fromJson(Map<String, dynamic> json) {
    List<Task> allTasks = json['tasks'] != null 
        ? (json['tasks'] as List).map((i) => Task.fromJson(i)).toList() 
        : [];
        
    // خوارزمية بناء الشجرة (Tree Building)
    List<Task> rootTasks = [];
    Map<int, Task> taskMap = {for (var t in allTasks) t.id: t};

    for (var task in allTasks) {
      if (task.parentId == null) {
        // هذه مهمة رئيسية (Root)
        rootTasks.add(task);
      } else {
        // هذه مهمة فرعية، نضيفها لقائمة subTasks الخاصة بأبيها
        if (taskMap.containsKey(task.parentId)) {
          taskMap[task.parentId]!.subTasks.add(task);
        }
      }
    }

    return Project(
      id: int.parse(json['id'].toString()),
      clientId: json['client_id'] != null ? int.parse(json['client_id'].toString()) : 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      clientName: json['client_name'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      durationDays: int.parse(json['duration_days'].toString()),
      deadline: DateTime.parse(json['deadline']),
      totalTasks: json['total_tasks'] != null ? int.parse(json['total_tasks'].toString()) : 0,
      completedTasks: json['completed_tasks'] != null ? int.parse(json['completed_tasks'].toString()) : 0,
      approvalStatus: json['client_approval_status'] ?? 'pending',
      rejectionReason: json['client_rejection_reason'],
      tasks: rootTasks, // نمرر الجذور فقط للواجهة
    );
  }
  
  double get progress => totalTasks == 0 ? 0 : (completedTasks / totalTasks);
  int get daysLeft => deadline.difference(DateTime.now()).inDays;
}

class Task {
  final int id;
  final int? parentId; // معرف الأب (إن وُجد)
  final String title;
  final String description;
  final String status;
  final String notes;
  final DateTime? completedAt;
  final List<Task> subTasks; // المهام الفرعية التابعة لهذه المهمة

  Task({
    required this.id,
    this.parentId,
    required this.title,
    required this.description,
    required this.status,
    required this.notes,
    this.completedAt,
    List<Task>? subTasks,
  }) : subTasks = subTasks ?? [];

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: int.parse(json['id'].toString()),
      parentId: json['parent_id'] != null ? int.parse(json['parent_id'].toString()) : null,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      notes: json['notes'] ?? '',
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
    );
  }
}
