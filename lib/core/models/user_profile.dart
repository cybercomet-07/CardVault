class UserProfile {
  const UserProfile({
    required this.uid,
    this.fullName,
    this.email,
    this.phone,
    this.company,
    this.photoUrl,
    this.themeMode,
  });

  final String uid;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? company;
  final String? photoUrl;
  final String? themeMode;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName ?? '',
      'email': email ?? '',
      'phone': phone ?? '',
      'company': company ?? '',
      'photoUrl': photoUrl ?? '',
      'themeMode': themeMode ?? 'dark',
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String? ?? '',
      fullName: map['fullName'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      company: map['company'] as String?,
      photoUrl: map['photoUrl'] as String?,
      themeMode: map['themeMode'] as String?,
    );
  }

  UserProfile copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    String? company,
    String? photoUrl,
    String? themeMode,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      photoUrl: photoUrl ?? this.photoUrl,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
