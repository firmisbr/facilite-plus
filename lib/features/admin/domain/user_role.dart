enum UserRole {
  guest,
  user,
  admin;

  static UserRole fromString(String? raw) {
    switch (raw) {
      case 'admin':
        return UserRole.admin;
      case 'user':
        return UserRole.user;
      default:
        return UserRole.user;
    }
  }

  bool get isAdmin => this == UserRole.admin;
}
