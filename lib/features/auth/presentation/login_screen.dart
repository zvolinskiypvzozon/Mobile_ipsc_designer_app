import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool signUp}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final auth = Supabase.instance.client.auth;
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (signUp) {
        await auth.signUp(password: password, email: email);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Аккаунт создан. Если включено подтверждение '
                'email — подтвердите его и войдите.'),
          ),
        );
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
      if (auth.currentSession != null) {
        navigator.pushReplacementNamed(AppRoutes.stageLibrary);
      }
    } on AuthException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Неожиданная ошибка: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дизайнер стейджей IPSC')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _emailController,
                    decoration:
                        const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) {
                      if (value == null ||
                          !value.contains('@') ||
                          value.trim().length < 5) {
                        return 'Введите корректный email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration:
                        const InputDecoration(labelText: 'Пароль'),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Пароль должен быть не короче 6 символов';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed:
                        _busy ? null : () => _submit(signUp: false),
                    child: const Text('Войти'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed:
                        _busy ? null : () => _submit(signUp: true),
                    child: const Text('Регистрация'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
