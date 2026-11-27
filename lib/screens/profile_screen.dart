import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/common_app_bar.dart';
import '../widgets/favorite_genres.dart';
import '../widgets/profile_edit_button.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel?>();
    return Scaffold(
      appBar: CommonAppBar(
        title: '내 프로필',
        actions: [
          if (auth != null)
            TextButton(
              onPressed: auth.storageCleanupInProgress ? null : auth.logout,
              child: const Text('로그아웃'),
            ),
        ],
      ),
      body: const ProfileBody(),
    );
  }
}

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel?>();
    final member = auth?.member;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeader(
              nickname: auth == null ? '무비러버' : member?.nickname ?? '내 프로필',
              email: auth == null ? null : member?.email ?? '',
            ),
            const SizedBox(height: 24),
            ProfileEditButton(
              onPressed: member == null
                  ? null
                  : () => context.push('/my/profile/edit'),
            ),
            const SizedBox(height: 40),
            const ProfileStats(),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('내가 등록한 평점'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/my/ratings'),
            ),
            const SizedBox(height: 24),
            const FavoriteGenres(),
          ],
        ),
      ),
    );
  }
}
