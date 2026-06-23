class User {
  final String? id;
  final String phone;
  final String? name;
  final DateTime? expirePro;
  final String? token;

  User({
    this.id,
    required this.phone,
    this.name,
    this.expirePro,
    this.token,
  });

  bool get isPro {
    if (expirePro == null) return false;
    return expirePro!.isAfter(DateTime.now());
  }

  User copyWith({
    String? id,
    String? phone,
    String? name,
    DateTime? expirePro,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      expirePro: expirePro ?? this.expirePro,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'expirePro': expirePro?.toIso8601String(),
      'token': token,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String?,
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String?,
      expirePro: json['expirePro'] != null
          ? DateTime.tryParse(json['expirePro'] as String)
          : (json['user'] != null && json['user']['expirePro'] != null
              ? DateTime.tryParse(json['user']['expirePro'].toString())
              : null),
      token: json['token'] as String?,
    );
  }
}
