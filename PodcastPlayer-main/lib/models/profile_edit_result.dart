class ProfileEditResult {
  const ProfileEditResult({
    required this.name,
    required this.email,
    required this.birthDate,
    this.profileImagePath,
    this.passwordUpdated = false,
  });

  final String name;
  final String email;
  final DateTime birthDate;
  final String? profileImagePath;
  final bool passwordUpdated;

  ProfileEditResult copyWith({
    String? name,
    String? email,
    DateTime? birthDate,
    String? profileImagePath,
    bool? passwordUpdated,
  }) {
    return ProfileEditResult(
      name: name ?? this.name,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      passwordUpdated: passwordUpdated ?? this.passwordUpdated,
    );
  }
}
