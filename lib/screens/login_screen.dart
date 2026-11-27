import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await context.read<AuthViewModel>().login(_email.text, _password.text);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final busy =
        auth.status == AuthStatus.authenticating ||
        auth.storageCleanupInProgress;
    return Scaffold(
      appBar: AppBar(title: const Text('로그인'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 36),
                Text(
                  'MovieLog',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  key: const Key('loginEmail'),
                  controller: _email,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: '이메일'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '이메일을 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('loginPassword'),
                  controller: _password,
                  enabled: !busy,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                  validator: (value) =>
                      value == null || value.isEmpty ? '비밀번호를 입력해 주세요.' : null,
                  onFieldSubmitted: busy ? null : (_) => _login(),
                ),
                if (auth.message case final message?) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                MovieLogButton(
                  label: '로그인',
                  width: double.infinity,
                  isLoading: auth.status == AuthStatus.authenticating,
                  onPressed: busy ? null : _login,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: busy ? null : () => context.go('/register'),
                  child: const Text('회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
