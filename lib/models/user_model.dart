class User {
  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? profilePicture;
  final bool isVerified;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.createdAt,
    this.updatedAt,
    this.profilePicture,
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Combine first_name and last_name to create full name
    final firstName = json['first_name'] as String? ?? '';
    final lastName = json['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();

    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      name: fullName.isEmpty ? (json['name'] as String? ?? '') : fullName,
      phoneNumber:
          json['mobile'] as String? ?? (json['phone_number'] as String? ?? ''),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      profilePicture: json['profile_picture'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone_number': phoneNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'profile_picture': profilePicture,
      'is_verified': isVerified,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePicture,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePicture: profilePicture ?? this.profilePicture,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, phoneNumber: $phoneNumber, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
