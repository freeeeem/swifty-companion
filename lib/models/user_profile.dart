class ProjectItem {
  final String name;
  final String status;
  final int? finalMark;
  final bool? validated;
  final DateTime updatedAt;
  final DateTime? createdAt;

  ProjectItem({
    required this.name,
    required this.status,
    this.finalMark,
    this.validated,
    required this.updatedAt,
    this.createdAt,
  });

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    final project = json['project'] ?? {};
    final String name = project['name'] ?? 'N/A';
    final String status = json['status'] ?? 'N/A';
    final int? finalMark = json['final_mark'] as int?;
    final bool? validated = json['validated?'] as bool?;
    final DateTime updatedAt = DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now();
    final DateTime? createdAt = DateTime.tryParse(json['created_at'] ?? '');

    return ProjectItem(
      name: name,
      status: status,
      finalMark: finalMark,
      validated: validated,
      updatedAt: updatedAt,
      createdAt: createdAt,
    );
  }
}

class UserProfile {
  final String displayName;
  final String login;
  final String email;
  final String? avatarUrl;
  final String campus;
  final double level;
  final int levelInt;
  final int levelPercent;
  final int wallet;
  final int correctionPoints;
  final List<dynamic> skills;
  final List<ProjectItem> projects;
  final List<ProjectItem> lastThreeProjects;

  UserProfile({
    required this.displayName,
    required this.login,
    required this.email,
    this.avatarUrl,
    required this.campus,
    required this.level,
    required this.levelInt,
    required this.levelPercent,
    required this.wallet,
    required this.correctionPoints,
    required this.skills,
    required this.projects,
    required this.lastThreeProjects,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final String displayName = json['displayname'] ?? 'Inconnu';
    final String login = json['login'] ?? 'N/A';
    final String email = json['email'] ?? 'N/A';
    final String? avatarUrl = json['image']?['versions']?['medium'];

    // Campus
    final List<dynamic> campusList = json['campus'] ?? [];
    final String campusName = campusList.isNotEmpty ? campusList[0]['name'] ?? 'N/A' : 'N/A';
    final String campusCountry = campusList.isNotEmpty ? campusList[0]['country'] ?? '' : '';
    final String campus = campusCountry.isNotEmpty ? '$campusName, $campusCountry' : campusName;

    // Cursus & Level
    final List<dynamic> cursusList = json['cursus_users'] ?? [];
    final dynamic mainCursus = cursusList.firstWhere(
      (c) => c?['cursus']?['slug'] == '42cursus',
      orElse: () => cursusList.isNotEmpty ? cursusList.first : null,
    );
    final double level = (mainCursus?['level'] as num?)?.toDouble() ?? 0.0;
    final int levelInt = level.floor();
    final int levelPercent = ((level - levelInt) * 100).round();

    // Stats & Skills
    final int wallet = json['wallet'] ?? 0;
    final int correctionPoints = json['correction_point'] ?? 0;
    final List<dynamic> skills = mainCursus?['skills'] ?? [];

    // Projects (Filtrés pour le cursus actif et hors sous-projets)
    final int? currentCursusId = mainCursus?['cursus_id'];
    final List<dynamic> rawProjects = json['projects_users'] ?? [];
    
    final List<ProjectItem> projects = rawProjects.where((p) {
      final List<dynamic> cursusIds = p['cursus_ids'] ?? [];
      final projectData = p['project'];
      return cursusIds.contains(currentCursusId) && (projectData?['parent_id'] == null);
    }).map((p) => ProjectItem.fromJson(p)).toList();

    // Trier du plus récent au plus ancien
    final List<ProjectItem> sortedProjects = List.from(projects)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Filtrer pour ne garder que les projets notés/terminés, puis prendre les 3 derniers
    final List<ProjectItem> lastThreeProjects = sortedProjects
        .where((p) => p.finalMark != null)
        .take(3)
        .toList();

    return UserProfile(
      displayName: displayName,
      login: login,
      email: email,
      avatarUrl: avatarUrl,
      campus: campus,
      level: level,
      levelInt: levelInt,
      levelPercent: levelPercent,
      wallet: wallet,
      correctionPoints: correctionPoints,
      skills: skills,
      projects: projects,
      lastThreeProjects: lastThreeProjects,
    );
  }
}
