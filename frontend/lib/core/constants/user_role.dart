/// Strictly two supported user roles in AgroChat (no Admin role).
enum UserRole {
  farmer('farmer', 'Farmer'),
  agriculturalOfficer('agricultural_officer', 'Agricultural Officer');

  const UserRole(this.apiValue, this.displayName);

  final String apiValue;
  final String displayName;

  static UserRole fromApiValue(String value) {
    for (final role in UserRole.values) {
      if (role.apiValue == value) {
        return role;
      }
    }
    throw ArgumentError('Unsupported AgroChat user role: $value');
  }
}
