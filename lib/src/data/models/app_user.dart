/// The logged-in customer, as returned by the website auth API.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        phone: json['phone']?.toString(),
      );
}

/// Result of a successful login/register: the user plus their JWT.
class AuthResult {
  const AuthResult({required this.user, required this.token});

  final AppUser user;
  final String token;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        user: AppUser.fromJson(json),
        token: (json['token'] ?? '').toString(),
      );
}
