import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'control_room_screen.dart';
import 'member_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String _selectedRole = 'member';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(value: 'member', child: Text('Member')),
                  DropdownMenuItem(value: 'control_room', child: Text('Control Room')),
                ],
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
            ],
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleAuthAction,
                    child: Text(_isLogin ? 'Login' : 'Sign Up'),
                  ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? 'Create Account' : 'Already have an account?'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAuthAction() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (_isLogin) {
        await auth.signIn(_emailController.text, _passwordController.text);
      } else {
        await auth.signUp(_emailController.text, _passwordController.text, _selectedRole);
      }
      
      if (!mounted) return;
      
      // Get the user role after authentication
      final userRole = auth.userRole;
      
      if (userRole == 'control_room') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ControlRoomScreen()),
        );
      } else if (userRole == 'member') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MemberScreen()),
        );
      } else {
        throw Exception('Invalid user role: $userRole');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}