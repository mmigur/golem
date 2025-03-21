class User {
  final String? id;
  final String nickname;
  final String email;
  final String password;

  User({
    this.id,
    required this.nickname,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'email': email,
      'password': password,
    };
  }
}