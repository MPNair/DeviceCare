import 'package:flutter/material.dart';
import '../themes/glass_theme.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  bool _obscurePassword = true;

  void _handleAuth() async {
    setState(() => _isLoading = true);
    final api = ApiService();
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    try {
      if (_isLogin) {
        final data = await api.login(
          _emailController.text,
          _passwordController.text,
        );
        settings.login(
          data['user']['name'] ?? 'User',
          data['user']['email'],
          data['token'],
        );
      } else {
        final data = await api.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
        settings.login(
          data['user']['name'],
          data['user']['email'],
          data['token'],
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [scheme.surface, scheme.primaryContainer.withOpacity(0.32)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: GlassTheme.glassCard(
              context: context,
              height: _isLogin ? 480 : 550,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DeviceCare',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _isLogin ? 'Welcome Back' : 'Create Account',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      SizedBox(height: 30),
                      if (!_isLogin) ...[
                        _buildTextField(
                          _nameController,
                          'Full Name',
                          Icons.person,
                        ),
                        SizedBox(height: 20),
                      ],
                      _buildTextField(_emailController, 'Email', Icons.email),
                      SizedBox(height: 20),
                      _buildTextField(
                        _passwordController,
                        'Password',
                        Icons.lock,
                        isPassword: true,
                      ),
                      SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlassTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  color: scheme.onPrimary,
                                )
                              : Text(
                                  _isLogin ? 'Sign In' : 'Sign Up',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin
                              ? 'Create an account'
                              : 'Already have an account? Sign In',
                          style: TextStyle(color: scheme.onSurfaceVariant),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: TextStyle(color: scheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: scheme.primary),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: scheme.primary),
        ),
      ),
    );
  }
}
