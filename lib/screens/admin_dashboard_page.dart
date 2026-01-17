import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_styles.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _uidController = TextEditingController();
  final _emailController = TextEditingController();
  Future<_AdminMetrics>? _metricsFuture;
  bool _isAdding = false;
  final Set<String> _cancellingBookings = {};

  @override
  void dispose() {
    _uidController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<_AdminMetrics> _fetchMetrics() async {
    final walletsSnapshot = await FirebaseFirestore.instance.collection('wallets').get();
    final adminsSnapshot = await FirebaseFirestore.instance.collection('admins').get();
    final bookingsSnapshot = await FirebaseFirestore.instance.collection('bookings').get();
    final savedSnapshot =
        await FirebaseFirestore.instance.collection('saved_activities').get();
    var totalBalance = 0;
    for (final doc in walletsSnapshot.docs) {
      totalBalance += (doc.data()['balance'] as num?)?.toInt() ?? 0;
    }
    var bookingTotalPaid = 0;
    final bookings = <_AdminBooking>[];
    for (final doc in bookingsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'paid';
      if (status != 'paid') {
        continue;
      }
      final amountPaid = (data['amount_paid'] as num?)?.toInt() ?? 0;
      bookingTotalPaid += amountPaid;
      bookings.add(
        _AdminBooking(
          docId: doc.id,
          title: data['title'] as String? ?? '',
          location: data['location'] as String? ?? '',
          uid: data['uid'] as String? ?? '',
          amountPaid: amountPaid,
          nights: (data['nights'] as num?)?.toInt(),
          createdAt: (data['created_at'] as Timestamp?)?.toDate(),
          status: status,
        ),
      );
    }
    bookings.sort(
      (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );
    return _AdminMetrics(
      adminCount: adminsSnapshot.size,
      walletCount: walletsSnapshot.size,
      walletBalanceTotal: totalBalance,
      bookingCount: bookings.length,
      bookingTotalPaid: bookingTotalPaid,
      savedCount: savedSnapshot.size,
      bookings: bookings,
      refreshedAt: DateTime.now(),
    );
  }

  Future<void> _refreshMetrics() async {
    setState(() {
      _metricsFuture = _fetchMetrics();
    });
    await _metricsFuture;
  }

  Future<void> _addAdmin() async {
    final uid = _uidController.text.trim();
    final email = _emailController.text.trim();
    if (uid.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Enter a user UID.')),
      );
      return;
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Sign in required.')),
      );
      return;
    }
    setState(() {
      _isAdding = true;
    });
    try {
      await FirebaseFirestore.instance.collection('admins').doc(uid).set(
        {
          'uid': uid,
          if (email.isNotEmpty) 'email': email,
          'added_by': currentUser.uid,
          'added_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      if (!mounted) return;
      _uidController.clear();
      _emailController.clear();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Admin added.')),
      );
      await _refreshMetrics();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Unable to add admin right now.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isAdding = false;
      });
    }
  }

  Future<void> _cancelBooking(_AdminBooking booking) async {
    if (booking.status != 'paid') return;
    final docId = booking.docId;
    if (docId == null || docId.isEmpty) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Cancel booking'),
          content: const Text(
            'This will mark the booking as cancelled. Refunds are not processed automatically.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cancel booking'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    setState(() {
      _cancellingBookings.add(docId);
    });
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(docId).update(
        {
          'status': 'cancelled',
          'cancelled_at': FieldValue.serverTimestamp(),
          'cancelled_by': currentUser.uid,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Booking cancelled.')),
      );
      await _refreshMetrics();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Unable to cancel booking right now.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _cancellingBookings.remove(docId);
      });
    }
  }

  Widget _buildShell({required Widget child, bool refreshable = false}) {
    final scrollView = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.page,
      child: child,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: refreshable
              ? RefreshIndicator(
                  onRefresh: _refreshMetrics,
                  child: scrollView,
                )
              : scrollView,
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String message,
    IconData icon = Icons.lock_outline,
  }) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFF7E7C5)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
    _metricsFuture ??= _fetchMetrics();
    return _SectionCard(
      title: 'Metrics',
      child: FutureBuilder<_AdminMetrics>(
        future: _metricsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }
          if (snapshot.hasError) {
            return Text(
              'Unable to load metrics right now.',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            );
          }
          final metrics = snapshot.data ??
              const _AdminMetrics(
                adminCount: 0,
                walletCount: 0,
                walletBalanceTotal: 0,
                bookingCount: 0,
                bookingTotalPaid: 0,
                savedCount: 0,
                bookings: [],
                refreshedAt: null,
              );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricRow(label: 'Admins', value: metrics.adminCount.toString()),
              const SizedBox(height: 8),
              _MetricRow(label: 'Wallets', value: metrics.walletCount.toString()),
              const SizedBox(height: 8),
              _MetricRow(
                label: 'Total wallet balance',
                value: metrics.walletBalanceTotal.toString(),
              ),
              const SizedBox(height: 8),
              _MetricRow(
                label: 'Paid bookings',
                value: metrics.bookingCount.toString(),
              ),
              const SizedBox(height: 8),
              _MetricRow(
                label: 'Total paid',
                value: metrics.bookingTotalPaid.toString(),
              ),
              const SizedBox(height: 8),
              _MetricRow(
                label: 'Saved for later',
                value: metrics.savedCount.toString(),
              ),
              const SizedBox(height: 12),
              const Text(
                'Paid bookings',
                style: TextStyle(
                  color: Color(0xFFF7E7C5),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (metrics.bookings.isEmpty)
                const Text(
                  'No paid bookings yet.',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                )
              else
                Column(
                  children: [
                    for (final booking in metrics.bookings)
                      _BookingRow(
                        booking: booking,
                        isCancelling: booking.docId != null &&
                            _cancellingBookings.contains(booking.docId!),
                        onCancel: () => _cancelBooking(booking),
                      ),
                  ],
                ),
              if (metrics.refreshedAt != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Updated ${_formatTimestamp(metrics.refreshedAt!)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hours:$minutes';
  }

  Widget _buildAddAdminCard(User user) {
    return _SectionCard(
      title: 'Add administrator',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User UID',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _uidController,
            decoration: _inputDecoration(
              hintText: 'Paste the user UID',
              icon: Icons.person_add_alt_1_outlined,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Email (optional)',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration(
              hintText: 'admin@example.com',
              icon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your UID: ${user.uid}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isAdding ? null : _addAdmin,
            icon: _isAdding
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.admin_panel_settings_outlined, size: 18),
            label: Text(
              _isAdding ? 'Adding...' : 'Add admin',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
      ),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
    );
  }

  Widget _buildAdminList() {
    return _SectionCard(
      title: 'Administrators',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('admins')
            .orderBy('added_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Text(
              'No administrators found yet.',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            );
          }
          return Column(
            children: [
              for (final doc in docs) _AdminRow(data: doc.data()),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildShell(
        child: _buildStatusCard(
          title: 'Sign in required',
          message: 'Sign in with an admin account to access this dashboard.',
        ),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('admins').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data?.exists == true;
        if (!isAdmin) {
          return _buildShell(
            child: _buildStatusCard(
              title: 'No access',
              message: 'Your account does not have admin access.',
            ),
          );
        }
        return _buildShell(
          refreshable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Monitor key metrics and manage administrators.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildMetricsCard(),
              const SizedBox(height: 16),
              _buildAddAdminCard(user),
              const SizedBox(height: 16),
              _buildAdminList(),
            ],
          ),
        );
      },
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _BookingRow extends StatelessWidget {
  final _AdminBooking booking;
  final bool isCancelling;
  final VoidCallback onCancel;
  const _BookingRow({
    required this.booking,
    required this.isCancelling,
    required this.onCancel,
  });

  String? _formatTimestamp(DateTime? value) {
    if (value == null) return null;
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (booking.location.isNotEmpty) subtitleParts.add(booking.location);
    subtitleParts.add('Paid ${booking.amountPaid}');
    if (booking.nights != null) subtitleParts.add('${booking.nights} nights');
    if (booking.uid.isNotEmpty) subtitleParts.add('UID ${booking.uid}');
    final dateLabel = _formatTimestamp(booking.createdAt);
    if (dateLabel != null) subtitleParts.add('On $dateLabel');
    final canCancel =
        booking.status == 'paid' && (booking.docId != null && booking.docId!.isNotEmpty);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.receipt_long, color: Color(0xFFF7E7C5)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.title.isNotEmpty ? booking.title : 'Unknown booking',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitleParts.join(' | '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: !canCancel || isCancelling ? null : onCancel,
            child: isCancelling
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  )
                : const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AdminRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AdminRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final uid = data['uid'] as String? ?? '';
    final email = data['email'] as String? ?? '';
    final addedBy = data['added_by'] as String? ?? '';
    final addedAt = data['added_at'];
    final subtitleParts = <String>[];
    if (email.isNotEmpty) subtitleParts.add(email);
    if (addedBy.isNotEmpty) subtitleParts.add('Added by $addedBy');
    if (addedAt is Timestamp) {
      final date = addedAt.toDate();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final hours = date.hour.toString().padLeft(2, '0');
      final minutes = date.minute.toString().padLeft(2, '0');
      subtitleParts.add('On $day/$month/${date.year} $hours:$minutes');
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.admin_panel_settings, color: Color(0xFFF7E7C5)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uid.isNotEmpty ? uid : 'Unknown UID',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitleParts.join(' | '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF7E7C5),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AdminMetrics {
  final int adminCount;
  final int walletCount;
  final int walletBalanceTotal;
  final int bookingCount;
  final int bookingTotalPaid;
  final int savedCount;
  final List<_AdminBooking> bookings;
  final DateTime? refreshedAt;

  const _AdminMetrics({
    required this.adminCount,
    required this.walletCount,
    required this.walletBalanceTotal,
    required this.bookingCount,
    required this.bookingTotalPaid,
    required this.savedCount,
    required this.bookings,
    required this.refreshedAt,
  });
}

class _AdminBooking {
  final String? docId;
  final String title;
  final String location;
  final String uid;
  final int amountPaid;
  final int? nights;
  final DateTime? createdAt;
  final String status;

  const _AdminBooking({
    required this.docId,
    required this.title,
    required this.location,
    required this.uid,
    required this.amountPaid,
    required this.nights,
    required this.createdAt,
    required this.status,
  });
}
