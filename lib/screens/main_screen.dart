import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthViewModel?>()?.loadMember();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          destinations: [
            _destination(
              context,
              selected: widget.navigationShell.currentIndex == 0,
              assetPath: 'assets/icons/home.svg',
              label: '홈',
            ),
            _destination(
              context,
              selected: widget.navigationShell.currentIndex == 1,
              assetPath: 'assets/icons/movie.svg',
              label: '영화',
            ),
            _destination(
              context,
              selected: widget.navigationShell.currentIndex == 2,
              assetPath: 'assets/icons/person.svg',
              label: '마이',
            ),
          ],
        ),
      ),
    );
  }

  NavigationDestination _destination(
    BuildContext context, {
    required bool selected,
    required String assetPath,
    required String label,
  }) {
    final colors = Theme.of(context).colorScheme;

    return NavigationDestination(
      icon: AnimatedContainer(
        key: ValueKey('navigation-$label'),
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              assetPath,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                selected ? colors.primary : colors.onSurfaceVariant,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? colors.primary : colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      label: label,
    );
  }
}
