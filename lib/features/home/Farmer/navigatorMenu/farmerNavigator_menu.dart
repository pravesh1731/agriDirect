import 'package:flutter/material.dart';
import '../../../../utils/constants/colors.dart';
import '../farmerHomePage.dart';
import '../farmerProductPage.dart';
import '../farmerOrdersPage.dart';
import '../farmerChatPage.dart';
import '../farmerProfilePage.dart';

class NavigatorMenu extends StatefulWidget {
  const NavigatorMenu({super.key});

  @override
  State<NavigatorMenu> createState() => _NavigatorMenuState();
}

class _NavigatorMenuState extends State<NavigatorMenu> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const FarmerHomePage(),
    const FarmerProductPage(),
    const FarmerOrdersPage(),
    const FarmerChatPage(),
    const FarmerProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
    
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? UColors.cardDark : UColors.white,
          boxShadow: [
            BoxShadow(
              color: UColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? UColors.cardDark : UColors.white,
          selectedItemColor: UColors.primary,
          unselectedItemColor:
              isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
