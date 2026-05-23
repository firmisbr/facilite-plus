class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? createdAt;

  String get displayName =>
      name.trim().isNotEmpty ? name.trim() : email.split('@').first;
}
