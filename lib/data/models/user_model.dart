class User {
  final int id;
  final String slug;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String country;
  final int status; // 1=inactive, 2=active
  final DateTime? emailVerifiedAt;
  final String? address;
  final String? photo; // Profile photo URL or path

  User({
    required this.id,
    required this.slug,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.country,
    required this.status,
    this.emailVerifiedAt,
    this.address,
    this.photo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      country: json['country'] ?? '',
      status: json['status'] ?? 1,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'])
          : null,
      address: json['address'] ?? '',
      photo: json['photo'],
      slug: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'country': country,
      'status': status,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'address': address,
      'photo': photo,
    };
  }

  // Helper methods
  String get fullName => '$firstName $lastName';

  bool get isActive => status == 2;

  bool get isInactive => status == 1;

  bool get isEmailVerified => emailVerifiedAt != null;

  // Copy with method for immutability
  User copyWith({
    int? id,
    String? slug,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? country,
    int? status,
    DateTime? emailVerifiedAt,
    String? address,
    String? photo,
  }) {
    return User(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      country: country ?? this.country,
      status: status ?? this.status,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      address: address ?? this.address,
      photo: photo ?? this.photo,
    );
  }
}
