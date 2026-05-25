class UserProfile {
  const UserProfile({
    required this.id,
    this.name,
    this.email,
    this.createdAt,
  });

  final String id;
  final String? name;
  final String? email;
  final DateTime? createdAt;

  /// Nome de exibição — cai para a parte local do e-mail se não configurado.
  String displayName(String fallbackEmail) {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    return fallbackEmail.split('@').first;
  }

  UserProfile copyWith({String? name}) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        email: email,
        createdAt: createdAt,
      );

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        name: map['name'] as String?,
        email: map['email'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'] as String)
            : null,
      );
}
