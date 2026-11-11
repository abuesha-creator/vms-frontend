/// Represents an active user session in the VMS frontend.
class UserSession {
  final String username;
  final String email;
  final String? token;
  final String role;
  final DateTime loginTime;

  const UserSession({
    required this.username,
    required this.email,
    this.token,
    this.role = 'ADMIN',
    required this.loginTime,
  });

  bool get isAuthenticated => username.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'token': token,
        'role': role,
        'loginTime': loginTime.toIso8601String(),
      };

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        token: json['token'] as String?,
        role: json['role'] as String? ?? 'ADMIN',
        loginTime: json['loginTime'] != null
            ? DateTime.tryParse(json['loginTime'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

