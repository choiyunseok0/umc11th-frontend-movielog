import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../view_models/profile_edit_view_model.dart';
import '../widgets/movielog_button.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _nickname;

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController(
      text: context.read<AuthViewModel>().member?.nickname ?? '',
    );
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<ProfileEditViewModel>();
    final auth = context.read<AuthViewModel>();
    final version = auth.sessionVersion;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    FocusScope.of(context).unfocus();
    final success = await vm.save(_nickname.text);
    if (!mounted ||
        version != auth.sessionVersion ||
        auth.status != AuthStatus.signedIn) {
      return;
    }
    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/my');
      }
    } else if (vm.message case final message?) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthViewModel, String?>(
      (auth) => auth.member?.email,
    );
    final vm = context.watch<ProfileEditViewModel>();
    final saving = vm.status == ProfileEditStatus.saving;
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('프로필 수정'), centerTitle: true),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  initialValue: email,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: '이메일'),
                ),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('profileNickname'),
                  controller: _nickname,
                  enabled: !saving,
                  maxLength: 12,
                  decoration: InputDecoration(
                    labelText: '닉네임',
                    errorText: vm.nicknameError,
                  ),
                  onChanged: (_) => vm.onNicknameChanged(),
                  onSubmitted: saving ? null : (_) => _submit(),
                ),
                const SizedBox(height: 40),
                MovieLogButton(
                  label: '저장',
                  width: double.infinity,
                  isLoading: saving,
                  onPressed: saving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
