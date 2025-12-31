class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final String? dateOfBirth;
  final String? gender;
  final String? aboutMe;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    this.dateOfBirth,
    this.gender,
    this.aboutMe,
    this.profileImageUrl,
  });

  // Create User from Supabase profile JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      aboutMe: json['about_me'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  // Convert User to JSON for Supabase updates
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'about_me': aboutMe,
      'profile_image_url': profileImageUrl,
    };
  }

  // Format phone number display
  String get formattedPhone {
    if (phone.startsWith('+')) {
      return phone;
    }
    return '+$phone';
  }

  // Get fake user data for testing
  static User getFakeUser() {
    return User(
      id: '1',
      name: 'Nadia Solomon',
      email: 'nadiasolomon@gmail.com',
      phone: '251089645340',
      address: 'Bahir Dar, Ethiopia',
      dateOfBirth: '24/12/2018',
      gender: 'Male',
      aboutMe: '',
      profileImageUrl: null,
    );
  }
}

