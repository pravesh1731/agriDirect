import 'package:flutter/material.dart';
import 'package:agri_direct/common/widgets/AppBar/appBar.dart';
import 'package:agri_direct/utils/constants/colors.dart';
import 'package:agri_direct/utils/constants/sizes.dart';
import 'package:agri_direct/features/authentication/screens/login/signIn.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/widgets/location_field.dart';

class BuyerProfilePage extends StatefulWidget {
  const BuyerProfilePage({super.key});

  @override
  State<BuyerProfilePage> createState() => _BuyerProfilePageState();
}

class _BuyerProfilePageState extends State<BuyerProfilePage> {
  // controllers
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _wallet;

  bool isLoading = false;
  bool isSigningOut = false;

  // toggles
  bool _notifyOrders = true;
  bool _notifyNewProducts = true;
  bool _notifyPriceDrops = false;

  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _email = TextEditingController();
    _phone = TextEditingController();
    _address = TextEditingController();
    _wallet = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _wallet.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignInScreen()));
      return;
    }

    try {
      final doc = await _fire.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _name.text = (data['name'] ?? data['fullName'] ?? '') as String;
          _email.text = (data['email'] ?? user.email ?? '') as String;
          _phone.text = (data['phone'] ?? '') as String;
          _address.text = (data['address'] ?? '') as String;
          _wallet.text = (data['wallet'] ?? '') as String;
          _notifyOrders = (data['notifyOrders'] ?? _notifyOrders) as bool;
          _notifyNewProducts = (data['notifyNewProducts'] ?? _notifyNewProducts) as bool;
          _notifyPriceDrops = (data['notifyPriceDrops'] ?? _notifyPriceDrops) as bool;
        });
      } else {
        setState(() {
          _email.text = user.email ?? '';
          _name.text = user.displayName ?? '';
        });
      }
    } catch (e) {
      _showSnack('Failed to load profile: $e');
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnack('No authenticated user. Please sign in again.');
      return;
    }

    if (_name.text.trim().isEmpty) {
      _showSnack('Name cannot be empty');
      return;
    }

    setState(() => isLoading = true);
    try {
      await _fire.collection('users').doc(user.uid).set({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'wallet': _wallet.text.trim(),
        'notifyOrders': _notifyOrders,
        'notifyNewProducts': _notifyNewProducts,
        'notifyPriceDrops': _notifyPriceDrops,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _showSnack('Profile saved successfully');
    } catch (e) {
      _showSnack('Failed to save profile: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar(isDark: isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(USizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top profile card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: UColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Avatar(size: 56),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name.text.isNotEmpty ? _name.text : 'Buyer',
                              style: const TextStyle(color: UColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _address.text.split('\n').firstWhere((_) => true, orElse: () => ''),
                              style: const TextStyle(color: UColors.textWhite70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      _BadgeChip(label: 'Verified Buyer'),
                      SizedBox(width: 8),
                      _BadgeChip(label: 'Blockchain'),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: USizes.spaceBteSections),

            // Stats
            Row(
              children: const [
                Expanded(child: _StatCard(value: '15', label: 'Orders')),
                SizedBox(width: 12),
                Expanded(child: _StatCard(value: '8', label: 'Farmers')),
                SizedBox(width: 12),
                Expanded(child: _StatCard(value: '\uFFFD420', label: 'Spent', valueColor: UColors.success)),
              ],
            ),

            SizedBox(height: USizes.spaceBteSections),

            // Account Information
            _SectionCard(
              title: 'Account Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Full Name'),
                  TextField(controller: _name, decoration: InputDecoration(filled: true, fillColor: isDark ? UColors.cardDark : UColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),),
                  const SizedBox(height: 12),
                  _label('Email'),
                  _readonlyField(context, _email, isDark),
                  const SizedBox(height: 12),
                  _label('Phone Number'),
                  TextField(controller: _phone, decoration: InputDecoration(filled: true, fillColor: isDark ? UColors.cardDark : UColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),),
                  const SizedBox(height: 12),
                  _label('Delivery Address'),
                  LocationField(controller: _address, onSelected: (addr, lat, lng) {
                    // optionally store lat/lng in Firestore when saving profile
                  }),

                  SizedBox(height: USizes.spaceBtwItems),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _saveProfile(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(isLoading ? 'Saving...' : 'Save Changes', style: const TextStyle(color: UColors.textWhite, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: USizes.spaceBteSections),

            // Blockchain Wallet
            _SectionCard(
              title: 'Blockchain Wallet',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Wallet Address'),
                  TextField(controller: _wallet, decoration: InputDecoration(filled: true, fillColor: isDark ? UColors.cardDark : UColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDark ? UColors.cardDark : UColors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? UColors.borderPrimaryDark : UColors.borderPrimaryLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: UColors.success.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, color: UColors.success, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Wallet Connected', style: TextStyle(fontWeight: FontWeight.w700)),
                              SizedBox(height: 2),
                              Text('Blockchain secured', style: TextStyle(fontSize: 12, color: UColors.textSecondaryLight)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: UColors.success, borderRadius: BorderRadius.circular(999)),
                          child: const Text('Active', style: TextStyle(color: UColors.textWhite, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: UColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (isDark ? UColors.borderPrimaryDark : UColors.borderPrimaryLight).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Transactions', style: TextStyle(fontSize: 12, color: UColors.textSecondaryLight)),
                              SizedBox(height: 6),
                              Text('Total Spent', style: TextStyle(fontSize: 12, color: UColors.textSecondaryLight)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('15', style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(height: 6),
                            Text('\uFFFD420', style: TextStyle(fontWeight: FontWeight.w700, color: UColors.success)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: USizes.spaceBteSections),

            // Preferences
            _SectionCard(
              title: 'Preferences',
              child: Column(
                children: [
                  _prefRow(
                    title: 'Order Notifications',
                    subtitle: 'Get updates on your orders',
                    value: _notifyOrders,
                    onChanged: (v) => setState(() => _notifyOrders = v),
                  ),
                  const Divider(height: 1),
                  _prefRow(
                    title: 'New Products Alert',
                    subtitle: 'Notify when farmers add new products',
                    value: _notifyNewProducts,
                    onChanged: (v) => setState(() => _notifyNewProducts = v),
                  ),
                  const Divider(height: 1),
                  _prefRow(
                    title: 'Price Drops',
                    subtitle: 'Get alerts for price reductions',
                    value: _notifyPriceDrops,
                    onChanged: (v) => setState(() => _notifyPriceDrops = v),
                  ),
                ],
              ),
            ),

            SizedBox(height: USizes.spaceBteSections),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isSigningOut ? null : () async {
                  // Ask for confirmation first
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Logout')),
                      ],
                    ),
                  );
                  if (confirmed != true) return;

                  setState(() { isSigningOut = true; });
                  try {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignInScreen()), (route) => false);
                  } catch (e) {
                    _showSnack('Sign out failed: $e');
                  } finally {
                    if (mounted) setState(() { isSigningOut = false; });
                  }
                },
                icon: isSigningOut ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.logout_rounded),
                label: Text(isSigningOut ? 'Signing out...' : 'Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
                  side: BorderSide(color: isDark ? UColors.borderPrimaryDark : UColors.borderPrimaryLight),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // helpers
  Widget _readonlyField(BuildContext context, TextEditingController c, bool isDark, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      readOnly: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? UColors.cardDark : UColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? UColors.borderPrimaryDark : UColors.borderPrimaryLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? UColors.borderPrimaryDark : UColors.borderPrimaryLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
  );

  Widget _prefRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: UColors.textSecondaryLight)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? UColors.cardDark : UColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: UColors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, this.valueColor});
  final String value;
  final String label;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? UColors.cardDark : UColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: UColors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor ?? (isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight))),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: UColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: UColors.textWhite.withOpacity(0.18), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(color: UColors.textWhite, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: UColors.gray,
        border: Border.all(color: Colors.white, width: 2),
        image: const DecorationImage(
          image: AssetImage('assets/logo/logo_lightMode.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
