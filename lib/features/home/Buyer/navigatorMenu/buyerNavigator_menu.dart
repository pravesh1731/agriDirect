import 'package:flutter/material.dart';

import 'package:agri_direct/utils/constants/colors.dart';
import 'package:agri_direct/features/home/Buyer/buyerHomePage.dart';
import 'package:agri_direct/features/home/Buyer/buyerOrdersPage.dart';
import 'package:agri_direct/features/home/Buyer/buyerChatPage.dart';
import 'package:agri_direct/features/home/Buyer/buyerProfilePage.dart';

class BuyerNavigatorMenu extends StatefulWidget {
	const BuyerNavigatorMenu({super.key});

	@override
	State<BuyerNavigatorMenu> createState() => _BuyerNavigatorMenuState();
}

class _BuyerNavigatorMenuState extends State<BuyerNavigatorMenu> {
	int _selectedIndex = 0;

	final List<Widget> _pages = const [
		BuyerHomePage(),
		BuyerOrdersPage(),
		BuyerChatPage(),
		BuyerProfilePage(),
	];

	void _onItemTapped(int index) {
		setState(() => _selectedIndex = index);
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
					unselectedItemColor: isDark ? UColors.textSecondaryDark : UColors.textSecondaryLight,
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
