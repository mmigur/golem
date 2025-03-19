import 'package:flutter/material.dart';
import 'package:golem/auth/sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isEmailValid = false;
  bool _isNicknameValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _nicknameController.addListener(_validateNickname);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      _isEmailValid = regex.hasMatch(email);
    });
  }

  void _validateNickname() {
    final nickname = _nicknameController.text;
    setState(() {
      _isNicknameValid = nickname.length > 3;
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;
    final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    setState(() {
      _isPasswordValid = regex.hasMatch(password);
    });
  }

  void _validateConfirmPassword() {
    final confirmPassword = _confirmPasswordController.text;
    setState(() {
      _isConfirmPasswordValid = confirmPassword == _passwordController.text;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Авторизация',
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
              const SizedBox(height: 8.0),
              Container(
                height: 48.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    hintText: '@yournickname',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Color(0xFF80858F)),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              if (!_isNicknameValid && _nicknameController.text.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Никнейм должен быть более 3 символов',
                        style: TextStyle(color: Colors.red),
                      )
                    ],
                  ),
                ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Почта',
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
              const SizedBox(height: 24.0),
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
                        'Пароль не прошел проверку',
                        style: TextStyle(color: Colors.red),
                      )
                    ],
                  ),
                ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Подтверждение пароля',
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
                  controller: _confirmPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Подтвердите пароль',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Color(0xFF80858F)),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              if (!_isConfirmPasswordValid && _confirmPasswordController.text.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Пароли не совпадают',
                        style: TextStyle(color: Colors.red),
                      )
                    ],
                  ),
                ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                height: 48.0,
                child: ElevatedButton(
                  onPressed: _isEmailValid && _isNicknameValid && _isPasswordValid && _isConfirmPasswordValid
                      ? () {
                    // Действие при нажатии на кнопку подтверждения почты
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEmailValid && _isNicknameValid && _isPasswordValid && _isConfirmPasswordValid ? Colors.black : const Color(0xFFD9D9D9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Подтвердить почту',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Есть аккаунт ?',
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