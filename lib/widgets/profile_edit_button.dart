import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileEditButton extends StatelessWidget {
  const ProfileEditButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SizedBox(
        width: 168,
        height: 52,
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: textTheme.titleMedium,
          ),
          icon: SvgPicture.asset(
            'assets/icons/person.svg',
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
            semanticsLabel: '프로필 수정',
          ),
          label: const Text('프로필 수정'),
        ),
      ),
    );
  }
}
