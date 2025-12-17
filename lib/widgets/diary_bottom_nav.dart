import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiaryBottomNavigation extends StatelessWidget {
  const DiaryBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            selectedItemColor: const Color(0xFFFF69B4),
            unselectedItemColor: Colors.black,
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/');
                  break;
                case 1:
                  context.go('/statistics');
                  break;
                case 2:
                  context.go('/settings');
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.today),
                label: '今天',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.check_circle_outline),
                label: '打卡',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: '我的',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
