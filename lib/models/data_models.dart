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
  final String preferredLanguage;
  final int projectsCount;

  ClientUser({
    required this.id,
    required this.username,
    this.fullName = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.companyName = '',
    this.preferredLanguage = 'ar',
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
      preferredLanguage: json['preferred_language'] ?? 'ar',
      projectsCount: json['projects_count'] != null ? int.parse(json['projects_count'].toString()) : 0,
    );
  }
}

class ProjectAttachment {
  final int id;
  final int projectId;
  final int? revisionId;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final bool fileDeleted;

  ProjectAttachment({
    required this.id,
    required this.projectId,
    this.revisionId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    this.fileDeleted = false,
  });

  factory ProjectAttachment.fromJson(Map<String, dynamic> json) {
    return ProjectAttachment(
      id: int.parse(json['id'].toString()),
      projectId: int.parse(json['project_id'].toString()),
      revisionId: json['revision_id'] != null ? int.parse(json['revision_id'].toString()) : null,
      fileName: json['file_name'] ?? '',
      filePath: json['file_path'] ?? '',
      fileType: json['file_type'] ?? '',
      fileSize: json['file_size'] != null ? int.parse(json['file_size'].toString()) : 0,
      fileDeleted: json['file_deleted'] == true || json['file_deleted'].toString() == '1',
    );
  }
}

class ProjectRevision {
  final int id;
  final int projectId;
  final int revisionNumber;
  final String clientNotes;
  final String status; // 'pending' or 'resolved'
  final DateTime createdAt;
  final DateTime? resolvedAt;

  ProjectRevision({
    required this.id,
    required this.projectId,
    required this.revisionNumber,
    required this.clientNotes,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory ProjectRevision.fromJson(Map<String, dynamic> json) {
    return ProjectRevision(
      id: int.parse(json['id'].toString()),
      projectId: int.parse(json['project_id'].toString()),
      revisionNumber: int.parse(json['revision_number'].toString()),
      clientNotes: json['client_notes'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
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
  final String approvalStatus; // حالة الموافقة المبدئية
  final String? rejectionReason; // سبب الرفض
  final DateTime? clientApprovalDate; // تاريخ ووقت رد الحريف (الموافقة أو الرفض المبدئي)
  final String finalApprovalStatus; // حالة المصادقة النهائية على التسليم الإنجاز 100%
  final String? finalApprovalNotes; // ملاحظات عدم المصادقة أو استلام الإنجاز
  final DateTime? finalApprovalDate; // تاريخ المصادقة النهائية
  final List<Task> tasks; // هذه القائمة ستحتوي فقط على "المهام الرئيسية" وجذور الشجرة
  final List<ProjectAttachment> attachments; // قائمة المرفقات الصورية ومستندات PDF
  final List<ProjectRevision> revisions; // سجل المراجعات التراكمية والتاريخية للحريف

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
    this.clientApprovalDate,
    this.finalApprovalStatus = 'pending',
    this.finalApprovalNotes,
    this.finalApprovalDate,
    this.tasks = const [],
    this.attachments = const [],
    this.revisions = const [],
  });

  // تحويل الـ JSON وبناء شجرة المهام والمرفقات والمراجعات
  factory Project.fromJson(Map<String, dynamic> json) {
    List<Task> allTasks = json['tasks'] != null 
        ? (json['tasks'] as List).map((i) => Task.fromJson(i)).toList() 
        : [];

    List<ProjectAttachment> allAttachments = json['attachments'] != null
        ? (json['attachments'] as List).map((i) => ProjectAttachment.fromJson(i)).toList()
        : [];

    List<ProjectRevision> allRevisions = json['revisions'] != null
        ? (json['revisions'] as List).map((i) => ProjectRevision.fromJson(i)).toList()
        : [];
        
    // خوارزمية بناء الشجرة (Tree Building)
    List<Task> rootTasks = [];
    Map<int, Task> taskMap = {for (var t in allTasks) t.id: t};

    for (var task in allTasks) {
      if (task.parentId == null) {
        rootTasks.add(task);
      } else {
        if (taskMap.containsKey(task.parentId)) {
          taskMap[task.parentId]!.subTasks.add(task);
        }
      }
    }

    int total = json['total_tasks'] != null ? int.parse(json['total_tasks'].toString()) : 0;
    int completed = json['completed_tasks'] != null ? int.parse(json['completed_tasks'].toString()) : 0;

    // حساب تلقائي ديناميكي واحتياطي لضمان تطابق النسبة المئوية 100% بين لوحتي الأدمن والحريف
    if (total == 0 && allTasks.isNotEmpty) {
      total = allTasks.length;
      completed = allTasks.where((t) => t.status == 'completed').length;
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
      totalTasks: total,
      completedTasks: completed,
      approvalStatus: json['client_approval_status'] ?? 'pending',
      rejectionReason: json['client_rejection_reason'],
      clientApprovalDate: json['client_approval_date'] != null ? DateTime.parse(json['client_approval_date']) : null,
      finalApprovalStatus: json['final_approval_status'] ?? 'pending',
      finalApprovalNotes: json['final_approval_notes'],
      finalApprovalDate: json['final_approval_date'] != null ? DateTime.parse(json['final_approval_date']) : null,
      tasks: rootTasks,
      attachments: allAttachments,
      revisions: allRevisions,
    );
  }
  
  double get progress => totalTasks == 0 ? 0 : (completedTasks / totalTasks);
  int get daysLeft {
    if (progress >= 0.99 || finalApprovalStatus == 'approved') {
      return 0;
    }
    final int diff = deadline.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }
}

class Task {
  final int id;
  final int? parentId;
  final String title;
  final String description;
  final String status;
  final String notes;
  final DateTime? completedAt;
  final List<Task> subTasks;

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
