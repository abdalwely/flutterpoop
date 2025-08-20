import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationState {
  final int currentIndex;
  final PageController pageController;
  final List<Widget> pages;
  final bool canPop;

  const NavigationState({
    this.currentIndex = 0,
    required this.pageController,
    this.pages = const [],
    this.canPop = false,
  });

  NavigationState copyWith({
    int? currentIndex,
    PageController? pageController,
    List<Widget>? pages,
    bool? canPop,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      pageController: pageController ?? this.pageController,
      pages: pages ?? this.pages,
      canPop: canPop ?? this.canPop,
    );
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(NavigationState(pageController: PageController()));

  void changeTab(int index) {
    if (index != state.currentIndex) {
      state = state.copyWith(currentIndex: index);
      state.pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToHome() {
    changeTab(0);
  }

  void goToExplore() {
    changeTab(1);
  }

  void goToReels() {
    changeTab(2);
  }

  void goToNotifications() {
    changeTab(3);
  }

  void goToProfile() {
    changeTab(4);
  }

  @override
  void dispose() {
    state.pageController.dispose();
    super.dispose();
  }
}

// Provider definition
final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});

// Helper providers
final currentTabProvider = Provider<int>((ref) {
  return ref.watch(navigationProvider).currentIndex;
});

final pageControllerProvider = Provider<PageController>((ref) {
  return ref.watch(navigationProvider).pageController;
});
