import 'package:flutter/material.dart';
import '../models/user.dart';

class UserService {
  static final ValueNotifier<User> user = ValueNotifier(
    User(
      id: 1, // Default for demo; set real user id after login
      fullName: 'Juan Dela Cruz',
      email: 'juandelacruz@example.com',
      dob: DateTime(1990, 1, 1),
      gender: 'Male',
      phone: '+639 1234 567',
      location: 'Cabuyao, Laguna Philippines 4025',
    ),
  );
  // Add a method to update user after login if needed
}
