import 'package:flutter/material.dart';
import '../../../common/widgets/AppBar/appBar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';


class FarmerHomePage extends StatelessWidget {
  const FarmerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar(isDark: isDark),
      body: Container(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(USizes.defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your farm products',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight,
                  ),
                ),
                SizedBox(height: USizes.spaceBteSections),

                // Weather Card
                Container(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 12 ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.wb_sunny,
                                color: UColors.textWhite,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Today's Weather",
                                style: TextStyle(
                                  color: UColors.textWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text(
                                '72°F',
                                style: TextStyle(
                                  color: UColors.textWhite,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'California, USA',
                        style: TextStyle(
                          color: UColors.textWhite70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sunny',
                        style: TextStyle(
                          color: UColors.textWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildWeatherDetail(Icons.water_drop, 'Humidity', '45%'),
                          _buildWeatherDetail(Icons.air, 'Wind', '8 mph'),
                          _buildWeatherDetail(Icons.visibility, 'Visibility', '10 mi'),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: USizes.spaceBteSections),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.check_circle_outline,
                        iconColor: UColors.success,
                        iconBgColor: UColors.success.withOpacity(0.1),
                        label: 'Active',
                        value: '2',
                        subtitle: 'Products Listed',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.trending_up,
                        iconColor: UColors.info,
                        iconBgColor: UColors.info.withOpacity(0.1),
                        label: '+12%',
                        value: '\$4,580',
                        subtitle: 'Total Revenue',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats Grid (Bottom Row)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.trending_up,
                        iconColor: UColors.purple,
                        iconBgColor: UColors.purple.withOpacity(0.1),
                        label: '+8%',
                        value: '24',
                        subtitle: 'Orders This Week',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.shield_outlined,
                        iconColor: UColors.warning,
                        iconBgColor: UColors.warning.withOpacity(0.1),
                        label: 'Secure',
                        value: '2',
                        subtitle: 'Smart Contracts',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: UColors.textWhite70,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: UColors.textWhite70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: UColors.textWhite,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? UColors.cardDark : UColors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? UColors.textPrimaryDark : UColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required String image,
    required String title,
    required String category,
    required Color categoryColor,
    required String price,
    required String priceUnit,
    required String stock,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? UColors.cardDark : UColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: UColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: UColors.gray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Icon(
                Icons.image_outlined,
                size: 32,
                color: UColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: UColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: categoryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: UColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      priceUnit,
                      style: const TextStyle(
                        fontSize: 12,
                        color: UColors.textSecondaryLight,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      stock,
                      style: const TextStyle(
                        fontSize: 12,
                        color: UColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action Buttons
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: UColors.textSecondaryLight,
                onPressed: () {
                  // TODO: Edit product
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: UColors.textSecondaryLight,
                onPressed: () {
                  // TODO: Delete product
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


