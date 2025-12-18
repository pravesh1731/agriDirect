import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/widgets/AppBar/appBar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../common/widgets/location_field.dart';
import 'package:agri_direct/features/authentication/screens/login/signIn.dart';

class FarmerProfilePage extends StatefulWidget {
  const FarmerProfilePage({super.key});

  @override
  State<FarmerProfilePage> createState() => _FarmerProfilePageState();
}

class _FarmerProfilePageState extends State<FarmerProfilePage> {
  bool emailNotifications = true;
  bool autoAcceptOrders = false;
  bool priceAlerts = true;
  bool isSigningOut = false;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _aboutController;
  late final TextEditingController _walletController;

  final _auth = FirebaseAuth.instance;
  final _fire = FirebaseFirestore.instance;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _aboutController = TextEditingController();
    _walletController = TextEditingController();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadUser() async {
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
          _nameController.text = (data['name'] ?? data['fullName'] ?? '') as String;
          _emailController.text = (data['email'] ?? user.email ?? '') as String;
          _phoneController.text = (data['phone'] ?? '') as String;
          _locationController.text = (data['location'] ?? data['farmLocation'] ?? '') as String;
          _aboutController.text = (data['about'] ?? data['bio'] ?? '') as String;
          _walletController.text = (data['wallet'] ?? '') as String;
          emailNotifications = (data['emailNotifications'] ?? emailNotifications) as bool;
          autoAcceptOrders = (data['autoAcceptOrders'] ?? autoAcceptOrders) as bool;
          priceAlerts = (data['priceAlerts'] ?? priceAlerts) as bool;
        });
      } else {
        setState(() {
          _emailController.text = user.email ?? '';
          _nameController.text = user.displayName ?? '';
        });
      }
    } catch (e) {
      _showSnack('Failed to load profile: $e');
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnack('Please sign in again');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showSnack('Name cannot be empty');
      return;
    }

    setState(() => isLoading = true);
    try {
      await _fire.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'about': _aboutController.text.trim(),
        'wallet': _walletController.text.trim(),
        'emailNotifications': emailNotifications,
        'autoAcceptOrders': autoAcceptOrders,
        'priceAlerts': priceAlerts,
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
        child: Column(
          children: [
            // Profile Header Card (matches design: avatar left, info right)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(USizes.defaultSpace),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: UColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: UColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: UColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name, location, badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.isNotEmpty ? _nameController.text : 'John Farmer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: UColors.textWhite,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _locationController.text.isNotEmpty ? _locationController.text : 'California, USA',
                          style: const TextStyle(
                            fontSize: 12,
                            color: UColors.textWhite70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(

                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: const [
                                _ProfileBadge(
                                  icon: Icons.verified,
                                  label: 'Verified',
                                ),
                                _ProfileBadge(
                                  icon: Icons.shield,
                                  label: 'Blockchain',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Farmer Information Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: USizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farmer Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Wrapped content in container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: UColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: UColors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoField(context, 'Full Name', _nameController),
                        const SizedBox(height: 16),
                        _buildInfoField(context, 'Email', _emailController),
                        const SizedBox(height: 16),
                        _buildInfoField(context, 'Phone Number', _phoneController),
                        const SizedBox(height: 16),
                        // Replace farm location with LocationField (Places autocomplete + current location)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Farm Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).brightness == Brightness.dark ? UColors.textSecondaryDark : UColors.textSecondaryLight)),
                              const SizedBox(height: 6),
                              LocationField(controller: _locationController, onSelected: (addr, lat, lng) {
                                // optional: store lat/lng
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoField(context, 'About Your Farm', _aboutController, maxLines: 3),
                        const SizedBox(height: 20),
                        // Save Changes Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => _saveProfile(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: UColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isLoading ? 'Saving...' : 'Save Changes',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: UColors.textWhite,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: USizes.spaceBteSections),

            // Blockchain Wallet Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: USizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Blockchain Wallet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: UColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: UColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: UColors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wallet Address',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: UColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: UColors.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextFormField(
                            controller: _walletController,
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: UColors.textSecondaryLight),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Wallet Status
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: UColors.success.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: UColors.success,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: UColors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Wallet Connected',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: UColors.textPrimaryLight,
                                      ),
                                    ),
                                    Text(
                                      'Blockchain secured',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: UColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: UColors.success,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: UColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Transaction Stats
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Transactions',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: UColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '47',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: UColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Contract Revenue',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: UColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '\$4,580',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: UColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: USizes.spaceBteSections),

            // Preferences Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: USizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: UColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: UColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: UColors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildPreferenceItem(
                          'Email Notifications',
                          'Receive order updates via email',
                          emailNotifications,
                          (value) => setState(() => emailNotifications = value),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        _buildPreferenceItem(
                          'Auto-Accept Orders',
                          'Automatically accept verified orders',
                          autoAcceptOrders,
                          (value) => setState(() => autoAcceptOrders = value),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        _buildPreferenceItem(
                          'Price Alerts',
                          'Get notified of market price changes',
                          priceAlerts,
                          (value) => setState(() => priceAlerts = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: USizes.spaceBteSections),

            // Logout button at bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: USizes.defaultSpace),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isSigningOut ? null : () async {
                    // confirmation dialog
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
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                        (route) => false,
                      );
                    } catch (e) {
                      _showSnack('Sign out failed: $e');
                    } finally {
                      if (mounted) setState(() { isSigningOut = false; });
                    }
                  },
                  icon: isSigningOut ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.logout_rounded),
                  label: Text(isSigningOut ? 'Signing out...' : 'Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: UColors.textPrimaryLight,
                    side: const BorderSide(color: UColors.borderPrimaryLight),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(BuildContext context, String label, TextEditingController controller, {int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: 1,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark ? UColors.cardDark : UColors.backgroundLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? UColors.borderPrimaryDark : UColors.borderPrimaryLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? UColors.borderPrimaryDark : UColors.borderPrimaryLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: UColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: UColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: UColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: UColors.primary,
        ),
      ],
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: UColors.textWhite.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: UColors.textWhite, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: UColors.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
