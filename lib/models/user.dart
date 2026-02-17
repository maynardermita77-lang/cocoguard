class User {
  int id;
  String fullName;
  String email;
  DateTime dob;
  String gender;
  String phone;
  String location;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.dob,
    required this.gender,
    required this.phone,
    required this.location,
  });

  User copyWith({
    int? id,
    String? fullName,
    String? email,
    DateTime? dob,
    String? gender,
    String? phone,
    String? location,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      location: location ?? this.location,
    );
  }
}
