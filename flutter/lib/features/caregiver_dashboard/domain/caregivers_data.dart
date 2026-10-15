typedef CaregiversScope = (String, String);

class LinkedCaregiver {
  const LinkedCaregiver({
    required this.id,
    required this.userId,
    required this.name,
    required this.relationship,
    required this.permission,
    required this.primary,
    this.email,
  });
  final String id, userId, name, relationship, permission;
  final String? email;
  final bool primary;
}

class CaregiversData {
  const CaregiversData({this.links = const [], this.refreshedAt});
  final List<LinkedCaregiver> links;
  final DateTime? refreshedAt;
}

class CaregiverLinkDraft {
  const CaregiverLinkDraft({
    required this.email,
    required this.relationship,
    this.permission = 'viewer',
  });
  final String email, relationship, permission;
  bool get isValid =>
      email.trim().length <= 254 &&
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim()) &&
      relationship.trim().isNotEmpty &&
      relationship.trim().length <= 60 &&
      {'viewer', 'manager'}.contains(permission);
}
