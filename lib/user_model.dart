class UserModel {
  final String name;
  final String bio;
  final String? avatarUrl;
  String? instagramHandle;
  String? facebookUrl;

  UserModel({
    required this.name,
    required this.bio,
    this.avatarUrl,
    this.instagramHandle,
    this.facebookUrl,
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
  instagramHandle: 'alex.rivera',
  facebookUrl: null,
);