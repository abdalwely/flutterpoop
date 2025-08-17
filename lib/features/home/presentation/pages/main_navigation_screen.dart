import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/navigation_provider.dart';
import 'home_screen.dart';
import '../../../explore/presentation/pages/explore_screen.dart';
import '../../../reels/presentation/pages/reels_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../../../post/presentation/pages/add_post_screen.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationProvider);

    final List<Widget> pages = [
      const HomeScreen(),
      const ExploreScreen(),
      const AddPostScreen(),
      const ReelsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: _CustomBottomNavigationBar(
        selectedIndex: selectedIndex,
        onTap: (index) {
          ref.read(navigationProvider.notifier).setIndex(index);
        },
      ),
    );
  }
}

class _CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _CustomBottomNavigationBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.home,
                isSelected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavBarItem(
                icon: Icons.search,
                isSelected: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavBarItem(
                icon: Icons.add_box_outlined,
                isSelected: selectedIndex == 2,
                onTap: () => onTap(2),
                isSpecial: true,
              ),
              _NavBarItem(
                icon: Icons.video_library_outlined,
                isSelected: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavBarItem(
                icon: Icons.person_outline,
                isSelected: selectedIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isSpecial;

  const _NavBarItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(isSelected ? 6.w : 0),
          decoration: isSelected
              ? BoxDecoration(
                  color: isSpecial 
                      ? AppColors.primary 
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                )
              : null,
          child: Icon(
            icon,
            size: 24.sp,
            color: isSelected
                ? isSpecial 
                    ? AppColors.white 
                    : AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
