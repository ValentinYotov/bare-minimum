import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/app_drawer.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  bool _loading = true;
  bool _saving = false;

  // Profile fields
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _farmNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _farmNameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Load from Auth
      _nameCtrl.text = user.displayName ?? '';
      _emailCtrl.text = user.email ?? '';

      // Load extra fields from Realtime DB
      final snap = await _db.child('users/${user.uid}/profile').get();
      if (snap.exists && snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        _phoneCtrl.text = data['phone'] ?? '';
        _farmNameCtrl.text = data['farmName'] ?? '';
        _locationCtrl.text = data['location'] ?? '';
      }
    } catch (e) {
      _showSnack('Failed to load profile.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final farmName = _farmNameCtrl.text.trim();
    final location = _locationCtrl.text.trim();

    if (name.isEmpty) {
      _showSnack('Name cannot be empty.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      // Update Auth display name
      if (name != user.displayName) {
        await user.updateDisplayName(name);
      }

      // Update Realtime DB
      await _db.child('users/${user.uid}/profile').update({
        'name': name,
        'phone': phone,
        'farmName': farmName,
        'location': location,
        'updatedAt': ServerValue.timestamp,
      });

      _showSnack('Profile saved successfully.');
    } catch (e) {
      _showSnack('Failed to save profile.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
      }
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final initials = (_nameCtrl.text.isNotEmpty)
        ? _nameCtrl.text.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : '?');

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F5),
      drawer: const AppDrawer(selectedPage: 'settings'),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Settings',
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _saving ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + identity
                  _card(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF16A34A),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'No name set',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? '',
                                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _sectionLabel('Personal Information'),
                  const SizedBox(height: 10),

                  _card(
                    child: Column(
                      children: [
                        _ProfileField(
                          label: 'Full name',
                          controller: _nameCtrl,
                          icon: Icons.person_outline_rounded,
                          hint: 'Your full name',
                          onChanged: (_) => setState(() {}),
                        ),
                        _divider(),
                        _ProfileField(
                          label: 'Email address',
                          controller: _emailCtrl,
                          icon: Icons.mail_outline_rounded,
                          hint: 'your@email.com',
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true,
                          readOnlyNote: 'Change email via account settings',
                        ),
                        _divider(),
                        _ProfileField(
                          label: 'Phone number',
                          controller: _phoneCtrl,
                          icon: Icons.phone_outlined,
                          hint: '+1 234 567 890',
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _sectionLabel('Farm Information'),
                  const SizedBox(height: 10),

                  _card(
                    child: Column(
                      children: [
                        _ProfileField(
                          label: 'Farm name',
                          controller: _farmNameCtrl,
                          icon: Icons.agriculture_outlined,
                          hint: 'e.g. Green Valley Farm',
                        ),
                        _divider(),
                        _ProfileField(
                          label: 'Location',
                          controller: _locationCtrl,
                          icon: Icons.location_on_outlined,
                          hint: 'City, Country',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _sectionLabel('Account'),
                  const SizedBox(height: 10),

                  _card(
                    child: Column(
                      children: [
                        _ActionRow(
                          icon: Icons.lock_outline_rounded,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF3B82F6),
                          label: 'Change password',
                          subtitle: 'Update your account password',
                          onTap: () => _showChangePasswordSheet(),
                        ),
                        _divider(),
                        _ActionRow(
                          icon: Icons.notifications_outlined,
                          iconBg: const Color(0xFFFFF9E6),
                          iconColor: const Color(0xFFF59E0B),
                          label: 'Notifications',
                          subtitle: 'Manage alert preferences',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign out
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showChangePasswordSheet() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Change password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _SheetField(
                controller: currentCtrl,
                label: 'Current password',
                obscure: obscureCurrent,
                onToggle: () => setSheetState(() => obscureCurrent = !obscureCurrent),
              ),
              const SizedBox(height: 14),
              _SheetField(
                controller: newCtrl,
                label: 'New password',
                obscure: obscureNew,
                onToggle: () => setSheetState(() => obscureNew = !obscureNew),
              ),
              const SizedBox(height: 14),
              _SheetField(
                controller: confirmCtrl,
                label: 'Confirm new password',
                obscure: obscureNew,
                onToggle: () => setSheetState(() => obscureNew = !obscureNew),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (newCtrl.text != confirmCtrl.text) {
                      _showSnack('Passwords do not match.', error: true);
                      return;
                    }
                    if (newCtrl.text.length < 6) {
                      _showSnack('Password must be at least 6 characters.', error: true);
                      return;
                    }
                    try {
                      final user = _auth.currentUser!;
                      final cred = EmailAuthProvider.credential(
                        email: user.email!,
                        password: currentCtrl.text,
                      );
                      await user.reauthenticateWithCredential(cred);
                      await user.updatePassword(newCtrl.text);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _showSnack('Password updated successfully.');
                    } on FirebaseAuthException catch (e) {
                      _showSnack(
                        e.code == 'wrong-password' ? 'Current password is incorrect.' : 'Failed to update password.',
                        error: true,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Update password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4)),
          ],
        ),
        child: child,
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.3),
      );

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: Color(0xFFF3F4F6)),
      );
}

// ── Profile field ─────────────────────────────────────────────────────────────

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType keyboardType;
  final bool readOnly;
  final String? readOnlyNote;
  final void Function(String)? onChanged;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.readOnlyNote,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: readOnly ? Colors.grey[400] : const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[300], fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: readOnly ? Colors.grey[300] : Colors.grey[400]),
            filled: true,
            fillColor: readOnly ? const Color(0xFFFAFAFA) : const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
            ),
            suffixIcon: readOnly
                ? const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFFD1D5DB))
                : null,
          ),
        ),
        if (readOnlyNote != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Text(
              readOnlyNote!,
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ),
      ],
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 20),
        ],
      ),
    );
  }
}

// ── Bottom sheet password field ───────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: Colors.grey[400]),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5)),
      ),
    );
  }
}
