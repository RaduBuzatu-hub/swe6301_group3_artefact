import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/local_db.dart';

import 'admin_dashboard_page.dart';
import 'sign_in_page.dart';
import 'sign_up_page.dart';

/// Profile screen that reads auth state, shows user details, and edits local profile data.
/// - Mirrors Firebase user info into a local profile row for offline access.
/// - Streams admin status to reveal dashboard tools.
/// - Includes wallet balance and quick-add credits UI.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Cached future to avoid reloading profile data on every build.
  Future<LocalProfile?>? _profileFuture;
  // Track current Firebase user and controller sync state.
  User? _currentUser;
  String? _controllersUid;
  bool _controllersInitialized = false;

  // Editable fields for local profile updates.
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  // Load profile from local DB, seeding a fallback if missing.
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

  // Refresh future/cache when the authenticated user changes.
  void _refreshProfile(User user) {
    _currentUser = user;
    _profileFuture = _loadProfile(user);
  }

  // Keep controllers in sync with the loaded profile (once per UID).
  void _syncControllers(LocalProfile profile) {
    if (_controllersUid == profile.uid && _controllersInitialized) return;
    _controllersUid = profile.uid;
    _controllersInitialized = true;
    _nameController.text = profile.displayName ?? '';
    _bioController.text = profile.bio ?? '';
    _locationController.text = profile.location ?? '';
    _phoneController.text = profile.phone ?? '';
  }

  // Persist edits locally and refresh the UI snapshot.
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                    // Auth gate: show sign-in prompt or load profile details.
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

                        // Local profile load + admin role check.
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
                            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('admins')
                                  .doc(profile.uid)
                                  .snapshots(),
                              builder: (context, adminSnapshot) {
                                final isAdmin = adminSnapshot.data?.exists == true;
                                return _SignedInContent(
                                  profile: profile,
                                  nameController: _nameController,
                                  email: profile.email ?? 'No email',
                                  phoneController: _phoneController,
                                  locationController: _locationController,
                                  bioController: _bioController,
                                  isAdmin: isAdmin,
                                  onOpenAdmin: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const AdminDashboardPage(),
                                      ),
                                    );
                                  },
                                  onSave: () => _saveProfile(profile),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Card shown when the user is not authenticated.
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

/// Profile content shown when the user is signed in.
class _SignedInContent extends StatelessWidget {
  final LocalProfile profile;
  final TextEditingController nameController;
  final String email;
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final TextEditingController bioController;
  final bool isAdmin;
  final VoidCallback onOpenAdmin;
  final VoidCallback onSave;

  const _SignedInContent({
    required this.profile,
    required this.nameController,
    required this.email,
    required this.phoneController,
    required this.locationController,
    required this.bioController,
    required this.isAdmin,
    required this.onOpenAdmin,
    required this.onSave,
  });

  // Build initials for the avatar from the profile name.
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
        // Header block with avatar, name, and sign-out action.
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
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(0, 0),
                ),
                icon: const Icon(Icons.logout, size: 16),
                label: const Text(
                  'Sign out',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Wallet panel with live balance and credit add flow.
        _WalletCard(uid: profile.uid),
        if (isAdmin) ...[
          const SizedBox(height: 16),
          // Admin users get quick access to the dashboard.
          _AdminToolsCard(onOpenAdmin: onOpenAdmin),
        ],
        const SizedBox(height: 16),
        // Editable profile fields stored locally.
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
      ],
    );
  }
}

/// Wallet summary with a quick add-credits dialog.
class _WalletCard extends StatefulWidget {
  final String uid;
  const _WalletCard({required this.uid});

  @override
  State<_WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<_WalletCard> {
  bool _isUpdating = false;

  // Reference to the user's wallet document.
  DocumentReference<Map<String, dynamic>> get _walletRef {
    return FirebaseFirestore.instance.collection('wallets').doc(widget.uid);
  }

  // Increment balance by a fixed amount.
  Future<void> _addCredits(int amount) async {
    await _walletRef.set(
      {
        'balance': FieldValue.increment(amount),
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // Show a dialog to pick a credit amount and apply it.
  Future<void> _promptAddCredits() async {
    final theme = Theme.of(context).colorScheme;
    const quickAmounts = [10, 25, 50, 100, 250, 500, 1000, 1500, 2000, 5000];
    int selectedAmount = quickAmounts[2];
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: theme.primaryContainer,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('Add £'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in quickAmounts)
                        ChoiceChip(
                          label: Text('£$value'),
                          selected: selectedAmount == value,
                          onSelected: (_) {
                            setState(() {
                              selectedAmount = value;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: selectedAmount > 1
                            ? () {
                                setState(() {
                                  selectedAmount -= 1;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '£$selectedAmount',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedAmount += 1;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap chips for quick adds',
                    style: TextStyle(
                      color: theme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.onPrimaryContainer.withValues(alpha: 0.9),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.onPrimary,
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(selectedAmount);
                  },
                  child: Text('Add £$selectedAmount'),
                ),
              ],
            );
          },
        );
      },
    );
    if (amount == null) return;
    if (!mounted) return;
    setState(() {
      _isUpdating = true;
    });
    try {
      await _addCredits(amount).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Added £$amount')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Unable to add funds right now.')),
      );
    }
    if (!mounted) return;
    setState(() {
      _isUpdating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final walletRef = _walletRef;
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        // Listen to balance changes in real time.
        stream: walletRef.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final balance = (data?['balance'] as num?)?.toInt() ?? 0;
          return Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFFF7E7C5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wallet',
                      style: TextStyle(
                        color: Color(0xFFF7E7C5),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '£$balance',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isUpdating ? null : _promptAddCredits,
                icon: _isUpdating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.primary,
                        ),
                      )
                    : const Icon(Icons.add, size: 18),
                label: Text(
                  _isUpdating ? 'Adding...' : 'Add',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Admin-only quick access card.
class _AdminToolsCard extends StatelessWidget {
  final VoidCallback onOpenAdmin;
  const _AdminToolsCard({required this.onOpenAdmin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Icon(Icons.admin_panel_settings, color: Color(0xFFF7E7C5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Admin tools',
                  style: TextStyle(
                    color: Color(0xFFF7E7C5),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'View metrics and manage administrators.',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onOpenAdmin,
            icon: const Icon(Icons.analytics_outlined, size: 18),
            label: const Text(
              'Dashboard',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Consistent white input styling for editable profile fields.
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
