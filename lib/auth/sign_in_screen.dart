import 'package:flutter/material.dart';
import 'package:golem/auth/sign_up_screen.dart';
import 'package:golem/models/user.dart' as golem_model_user;

import '../service/service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  void _validateEmail() {
    final email = _emailController.text;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      _isEmailValid = regex.hasMatch(email);
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;
    final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    setState(() {
      _isPasswordValid = regex.hasMatch(password);
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _register() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final nickname = _nicknameController.text;

    if (!_isEmailValid || !_isPasswordValid || nickname.isEmpty) {
      setState(() {
        _errorMessage = 'Пожалуйста, заполните все поля корректно';
      });
      return;
    }

    final user = golem_model_user.User(
      nickname: nickname,
      email: email,
      password: password,
    );

    final userId = await SupabaseService().registerUser(user);

    if (userId != null) {
      // Переходим на экран входа с сообщением о подтверждении почты
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SignUpScreen(),
        ),
      );

      // Показываем сообщение о необходимости подтвердить почту
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пожалуйста, подтвердите вашу почту.'),
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Проверьте данные и попробуйте снова.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Регистрация',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Никнейм',
                    style: TextStyle(color: Color(0xFF80858F)),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 48.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    hintText: 'Введите никнейм',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Color(0xFF80858F)),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Почта',
                    style: TextStyle(color: Color(0xFF80858F)),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 48.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'example@gmail.com',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Color(0xFF80858F)),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              if (!_isEmailValid && _emailController.text.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Введите корректный email',
                        style: TextStyle(color: Colors.red),
                      )
                    ],
                  ),
                ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Пароль',
                    style: TextStyle(color: Color(0xFF80858F)),
                  )
                ],
              ),
              const SizedBox(height: 8.0),
              Container(
                height: 48.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Введите пароль',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Color(0xFF80858F)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF80858F),
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              if (!_isPasswordValid && _passwordController.text.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Пароль должен содержать минимум 8 символов, включая буквы, цифры и спецсимволы',
                        style: TextStyle(color: Colors.red),
                      )
                    ],
                  ),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                height: 48.0,
                child: ElevatedButton(
                  onPressed: _isEmailValid && _isPasswordValid && _nicknameController.text.isNotEmpty
                      ? _register
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEmailValid && _isPasswordValid && _nicknameController.text.isNotEmpty
                        ? Colors.black
                        : const Color(0xFFD9D9D9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Зарегистрироваться',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Уже есть аккаунт?',
                    style: TextStyle(color: Color(0xFF80858F)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
                    child: const Text(
                      'Войти',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}