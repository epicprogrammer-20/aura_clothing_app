class UserModel {
  String name;
  final String bio;
  final String? avatarUrl;
  String? facebookUrl;

  // For SMS-based password reset once a backend/SMS provider is wired up.
  // Optional — the email-based reset flow (see forgot_password_screen.dart)
  // works whether or not this is set.
  String? phoneNumber;

  UserModel({
    required this.name,
    required this.bio,
    this.avatarUrl,
    this.facebookUrl,
    this.phoneNumber,
  });

  // Used for the initials avatar — first letter of the first name.
  // Once auth is wired up, `name` should be populated from whichever
  // provider the user logged in with (email display name, Google name,
  // or Apple name), and this will automatically reflect that.
  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

// ─────────────────────────────────────────────────────────
// MOCK DATA — replace with the logged-in user's real profile
// (name pulled from their auth provider) once auth is wired up.
// ─────────────────────────────────────────────────────────
final UserModel mockCurrentUser = UserModel(
  name: 'Alex Rivera',
  bio: 'Streetwear enthusiast. Always hunting for the next fit.',
  avatarUrl: null,
  facebookUrl: null,
  phoneNumber: null,
);