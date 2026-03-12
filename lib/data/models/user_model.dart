// lib/data/models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isPremium;
  final DateTime joinedAt;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isPremium = false,
    DateTime? joinedAt,
    this.preferences = const {},
  }) : joinedAt = joinedAt ?? DateTime.now();

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    bool? isPremium,
    DateTime? joinedAt,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPremium: isPremium ?? this.isPremium,
      joinedAt: joinedAt ?? this.joinedAt,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'isPremium': isPremium,
      'joinedAt': joinedAt.toIso8601String(),
      'preferences': preferences,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      isPremium: json['isPremium'] ?? false,
      joinedAt: DateTime.parse(json['joinedAt']),
      preferences: json['preferences'] ?? {},
    );
  }
}
