import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/local_db.dart';

import 'sign_in_page.dart';
import 'sign_up_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<LocalProfile?>? _profileFuture;
  User? _currentUser;
  String? _controllersUid;
  bool _controllersInitialized = false;

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<LocalProfile> _loadProfile(User user) async {
    final existing = await LocalDb.instance.getProfile(user.uid);
    if (existing != null) return existing;
    final fallback = LocalProfile(
      uid: user.uid,
      displayName: user.displayName ?? 'Traveler',
      email: user.email,
      bio: null,
      photoUrl: user.photoURL,
      location: null,
      phone: null,
      website: null,
      updatedAt: DateTime.now(),
    );
    await LocalDb.instance.upsertProfile(fallback);
    return fallback;
  }

  void _refreshProfile(User user) {
    _currentUser = user;
    _profileFuture = _loadProfile(user);
  }

  void _syncControllers(LocalProfile profile) {
    if (_controllersUid == profile.uid && _controllersInitialized) return;
    _controllersUid = profile.uid;
    _controllersInitialized = true;
    _nameController.text = profile.displayName ?? '';
    _bioController.text = profile.bio ?? '';
    _locationController.text = profile.location ?? '';
    _phoneController.text = profile.phone ?? '';
  }

  Future<void> _saveProfile(LocalProfile profile) async {
    final updated = profile.copyWith(
      displayName: _nameController.text.trim().isEmpty
          ? 'Traveler'
          : _nameController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      website: null,
      updatedAt: DateTime.now(),
    );
    await LocalDb.instance.upsertProfile(updated);
    if (mounted && _currentUser != null) {
      setState(() {
        _profileFuture = _loadProfile(_currentUser!);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved locally')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFB388FF),
            Color(0xFF7E57C2),
            Color(0xFF5E35B1),
            Color(0xFF311B92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  const Icon(Icons.lock_outline, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }
                  final user = snapshot.data;
                  if (user == null) {
                    return const _AuthCard();
                  }

                  if (_currentUser?.uid != user.uid || _profileFuture == null) {
                    _refreshProfile(user);
                  }

                  return FutureBuilder<LocalProfile?>(
                    future: _profileFuture,
                    builder: (context, profileSnapshot) {
                      if (profileSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        );
                      }
                      final profile = profileSnapshot.data;
                      if (profile == null) {
                        return const _AuthCard();
                      }
                      _syncControllers(profile);
                      return _SignedInContent(
                        profile: profile,
                        nameController: _nameController,
                        email: profile.email ?? 'No email',
                        phoneController: _phoneController,
                        locationController: _locationController,
                        bioController: _bioController,
                        onSave: () => _saveProfile(profile),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sign in to view your account',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Track trips, save activities, and earn eco badges.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A148C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignInPage()),
                    );
                  },
                  child: const Text(
                    'Sign in',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  child: const Text(
                    'Create account',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignedInContent extends StatelessWidget {
  final LocalProfile profile;
  final TextEditingController nameController;
  final String email;
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final TextEditingController bioController;
  final VoidCallback onSave;

  const _SignedInContent({
    required this.profile,
    required this.nameController,
    required this.email,
    required this.phoneController,
    required this.locationController,
    required this.bioController,
    required this.onSave,
  });

  String _initials() {
    final name = profile.displayName ?? '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return name.isNotEmpty ? name.characters.first.toUpperCase() : 'U';
    }
    return (parts.take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join())
        .padRight(2, ' ')
        .substring(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  _initials(),
                  style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName?.isNotEmpty == true ? profile.displayName! : 'Traveler',
                      style: const TextStyle(
                        color: Color(0xFFF7E7C5), // sand-gold tint
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (profile.location?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Color(0xFFF7E7C5), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              profile.location!,
                              style: const TextStyle(
                                color: Color(0xFFF7E7C5),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lock_outline, color: Color(0xFFF7E7C5), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Local only',
                      style: TextStyle(
                        color: Color(0xFFF7E7C5),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFB388FF),
                Color(0xFF7E57C2),
                Color(0xFF5E35B1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Profile',
                style: TextStyle(
                  color: const Color(0xFFF7E7C5),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              _WhiteField(
                label: 'Name',
                controller: nameController,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 10),
              _WhiteField(
                label: 'Email',
                controller: TextEditingController(text: email),
                icon: Icons.email_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 10),
              _WhiteField(
                label: 'Phone',
                controller: phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              _WhiteField(
                label: 'Address',
                controller: locationController,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 10),
              _WhiteField(
                label: 'Bio',
                controller: bioController,
                icon: Icons.info_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: Colors.white,
                        foregroundColor: theme.primary,
                      ),
                      onPressed: onSave,
                      child: const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w800)),
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick actions',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _ActionRow(icon: Icons.notifications_none, label: 'Notifications', trailing: 'Off'),
              const SizedBox(height: 8),
              _ActionRow(icon: Icons.bar_chart_outlined, label: 'Statistics', trailing: 'Soon'),
              const SizedBox(height: 8),
              _ActionRow(icon: Icons.settings_outlined, label: 'Settings'),
              const SizedBox(height: 8),
              _ActionRow(icon: Icons.help_outline, label: 'Help & support'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;

  const _ActionRow({required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.7)),
      ],
    );
  }
}

class _WhiteField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final bool readOnly;
  final TextInputType? keyboardType;

  const _WhiteField({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.readOnly = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white),
            ),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
          style: TextStyle(color: Colors.white.withValues(alpha: readOnly ? 0.8 : 0.95)),
          cursorColor: theme.onPrimary,
        ),
      ],
    );
  }
}
