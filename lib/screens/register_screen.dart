// 사용자가 보는 회원가입 화면
// 사용자에게 가입 정보를 입력받고, VM에 전달하고, 결과를 화면에 보여주는 파일임
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/sign_up_view_model.dart';
import '../data/models/create_member_request.dart';
import '../widgets/movielog_button.dart';

import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.onRegistered});

  final ValueChanged<int>? onRegistered;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _nicknameFocusNode = FocusNode();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _agreedToTerms = false;

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return '이메일을 입력해 주세요.';
    if (!RegExp(r'^[^\s@]+@[^\s@.]+(?:\.[^\s@.]+)+$').hasMatch(email)) {
      return '올바른 이메일 형식을 입력해 주세요.';
    }
    return null;
  }

  String? _validateNickname(String? value) {
    final length = value?.trim().length ?? 0;
    if (length == 0) return '닉네임을 입력해 주세요.';
    if (length < 2) return '닉네임은 2자 이상이어야 합니다.';
    if (length > 12) return '닉네임은 12자 이하여야 합니다.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return '비밀번호를 입력해 주세요.';
    if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    if (!RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password) ||
        !RegExp(r'[!@#$%^&*]').hasMatch(password)) {
      return '대문자, 소문자, 숫자, 특수문자를 모두 포함해 주세요.';
    }
    return null;
  }

  // 1. 가입하기 버튼을 켜기 전에 두 종류의 조건을 확인함
  bool _canSubmit(SignUpViewModel? vm) =>
      vm?.canSubmit == true &&
      _validateNickname(_nicknameController.text) == null &&
      _validateEmail(_emailController.text) == null &&
      _validatePassword(_passwordController.text) == null &&
      _agreedToTerms;

  @override
  void dispose() {
    _nicknameController.dispose();
    _nicknameFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<SignUpViewModel?>();
    if (vm == null ||
        !_canSubmit(vm) ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();

    // 2. 가입하기 버튼을 누르면 입력값 세 개를 VM에 보냄
    // 이 화면이 넘기는 건 Dart 객체이고 toJson()을 호출하고 Dio로 서버에 보내는 건 SignUpService가 맡음
    final memberId = await vm.submit(
      CreateMemberRequest(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      ),
    );

    // 4. 받은 결과에 따라 오류를 보여주거나 회원 번호를 라우터에 넘김
    // mounted : 응답을 기다리는 동안 이 화면이 닫히지 않았는지 확인하는 코드
    if (!mounted) return;
    if (memberId != null) {
      widget.onRegistered?.call(memberId);
      return;
    }
    if (vm.snackbarMessage case final message?) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _input({
    required String label,
    required String hint,
    required String fieldKey,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String? Function(String?) validator,
    required VoidCallback onSubmitted,
    bool isPassword = false,
    bool isEmail = false,
    CheckStatus? checkStatus,
    VoidCallback? onCheck,
    ValueChanged<String>? onChanged,
    String? serverError,
    bool enabled = true,
  }) {
    final hasInput = controller.text.isNotEmpty;
    final error = validator(controller.text);
    final duplicate = checkStatus == CheckStatus.duplicated;
    final hasError =
        serverError != null || duplicate || (hasInput && error != null);
    final checkError = duplicate
        ? '이미 사용 중인 $label입니다.'
        : checkStatus == CheckStatus.error
        ? '확인하지 못했어요. 다시 시도해 주세요.'
        : null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.inputBorder),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: Key(fieldKey),
                enabled: enabled,
                controller: controller,
                focusNode: focusNode,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: hint,
                  errorText: serverError ?? checkError,
                  hintStyle: const TextStyle(color: AppColors.outline),
                  filled: true,
                  fillColor: hasError
                      ? AppColors.inputErrorBackground
                      : AppColors.inputBackground,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border.copyWith(
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  errorBorder: border.copyWith(
                    borderSide: const BorderSide(color: AppColors.inputError),
                  ),
                  focusedErrorBorder: border.copyWith(
                    borderSide: const BorderSide(color: AppColors.inputError),
                  ),
                  errorStyle: const TextStyle(
                    color: AppColors.inputError,
                    fontSize: 12,
                  ),
                  errorMaxLines: 2,
                  suffixIcon: hasInput
                      ? Icon(
                          hasError ? Icons.error_outline : Icons.check_circle,
                          color: hasError
                              ? AppColors.inputError
                              : AppColors.primary,
                          size: 20,
                        )
                      : null,
                ),
                obscureText: isPassword,
                keyboardType: isEmail
                    ? TextInputType.emailAddress
                    : TextInputType.text,
                autocorrect: !isEmail && !isPassword,
                enableSuggestions: !isPassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: isPassword
                    ? TextInputAction.done
                    : TextInputAction.next,
                validator: validator,
                onChanged: (value) {
                  onChanged?.call(value);
                  setState(() {});
                },
                onFieldSubmitted: (_) => onSubmitted(),
              ),
            ),
            if (checkStatus != null) ...[
              const SizedBox(width: 8),
              MovieLogButton(
                label: '중복 확인',
                isLoading: checkStatus == CheckStatus.checking,
                onPressed: enabled && error == null ? onCheck : null,
              ),
            ],
          ],
        ),
        if (checkStatus == CheckStatus.available) Text('사용할 수 있는 $label입니다.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    // 3. 요청하는 동안에는 화면이 ViewModel의 상태를 받아서 바꿈
    // VM이 가입 요청을 시작하고 notifyListeners()를 호출하면 화면이 다시 그려지면서 vm.isSubmitting을 읽음
    final vm = context.watch<SignUpViewModel?>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            '회원가입',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: AppColors.primary, fontSize: 20),
          ),
          automaticallyImplyLeading: false,
          scrolledUnderElevation: 0,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 48).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _RegisterHeader(),
                          const SizedBox(height: 48),
                          _input(
                            label: '닉네임',
                            hint: '닉네임을 입력해주세요',
                            fieldKey: 'nicknameField',
                            enabled: vm?.isSubmitting != true,
                            checkStatus: vm?.nicknameCheckStatus,
                            onChanged: vm?.onNicknameChanged,
                            onCheck: vm == null
                                ? null
                                : () => vm.checkNickname(
                                    _nicknameController.text,
                                  ),
                            controller: _nicknameController,
                            focusNode: _nicknameFocusNode,
                            validator: _validateNickname,
                            onSubmitted: () => _emailFocusNode.requestFocus(),
                          ),
                          const SizedBox(height: 16),
                          _input(
                            label: '이메일',
                            hint: '이메일 주소를 입력해주세요',
                            fieldKey: 'emailField',
                            enabled: vm?.isSubmitting != true,
                            checkStatus: vm?.emailStatus,
                            onChanged: vm?.onEmailChanged,
                            onCheck: vm == null
                                ? null
                                : () => vm.checkEmail(_emailController.text),
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            validator: _validateEmail,
                            isEmail: true,
                            onSubmitted: () =>
                                _passwordFocusNode.requestFocus(),
                          ),
                          const SizedBox(height: 16),
                          _input(
                            label: '비밀번호',
                            hint: '비밀번호를 입력해주세요',
                            fieldKey: 'passwordField',
                            enabled: vm?.isSubmitting != true,
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            isPassword: true,
                            validator: _validatePassword,
                            serverError: vm?.passwordErrorText,
                            onChanged: (_) => vm?.onPasswordChanged(),
                            onSubmitted: () {
                              if (_canSubmit(vm)) {
                                _submit();
                              } else {
                                _passwordFocusNode.unfocus();
                              }
                            },
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TermsAgreement(
                              value: _agreedToTerms,
                              onChanged: (value) =>
                                  setState(() => _agreedToTerms = value),
                            ),
                            const SizedBox(height: 16),
                            MovieLogButton(
                              key: const Key('registerButton'),
                              label: '가입하기',
                              width: double.infinity,
                              isLoading: vm?.isSubmitting ?? false,
                              onPressed: _canSubmit(vm) ? _submit : null,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('이미 계정이 있나요?'),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('로그인'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(height: 1.6, fontWeight: FontWeight.w600),
    );
  }
}

class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            key: const Key('termsCheckbox'),
            value: value,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(color: AppColors.inputBorder),
            onChanged: (value) => onChanged(value ?? false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '필수 약관에 동의합니다',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
