class User {
  final String userName;
  final String? avatar; // nullable
  final String? token;  // nullable

  User({
    required this.userName,
    this.avatar,
    this.token,
  });

  User copyWith({
    String? userName,
    String? avatar,
    String? token,
  }) {
    return User(
      userName: userName ?? this.userName,
      avatar: avatar ?? this.avatar,
      token: token ?? this.token,
    );
  }
}