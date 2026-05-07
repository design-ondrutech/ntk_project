import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'Sub Admin';
  final List<String> roles = ['Super Admin', 'Admin', 'Sub Admin'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header
              const Text(
                'Admin Login',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Access your community management portal',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Name Field (Common)
              _buildFieldLabel('Name'),
              _buildTextField(
                hintText: 'Enter your full name',
                prefixIcon: CupertinoIcons.person,
              ),
              const SizedBox(height: 24),

              // Role Selection (Common)
              _buildFieldLabel('Role Selection'),
              _buildRoleSelector(),
              const SizedBox(height: 24),

              // Conditional Fields
              if (selectedRole == 'Super Admin') ...[
                // State Field
                _buildFieldLabel('State'),
                _buildTextField(
                  hintText: 'Tamilnadu',
                  prefixIcon: CupertinoIcons.map,
                  enabled: false, // Assuming it's fixed for now as per "State: Tamilnadu"
                ),
                const SizedBox(height: 24),
              ],

              if (selectedRole == 'Admin' || selectedRole == 'Sub Admin') ...[
                // District Name
                _buildFieldLabel('District Name'),
                _buildTextField(
                  hintText: 'Search district',
                  prefixIcon: CupertinoIcons.location,
                ),
                const SizedBox(height: 24),

                // Constituency Name
                _buildFieldLabel('Constituency Name (Thoguthi)'),
                _buildTextField(
                  hintText: 'Enter constituency',
                  prefixIcon: CupertinoIcons.book,
                ),
                const SizedBox(height: 24),
              ],

              if (selectedRole == 'Sub Admin') ...[
                // Town Name
                _buildFieldLabel('Town (Ooru)'),
                _buildTextField(
                  hintText: 'Enter town',
                  prefixIcon: CupertinoIcons.house,
                ),
                const SizedBox(height: 24),
              ],

              // Password Field (Dynamic Label)
              _buildFieldLabel(
                selectedRole == 'Super Admin'
                    ? 'State Password'
                    : selectedRole == 'Admin'
                        ? 'Thoguthi Password'
                        : 'Town Password',
              ),
              _buildTextField(
                hintText: '••••••••',
                prefixIcon: CupertinoIcons.lock,
                isPassword: true,
                suffixIcon: CupertinoIcons.eye,
              ),
              const SizedBox(height: 40),

              // Login Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007B3E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Login',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.login_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    IconData? suffixIcon,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        enabled: enabled,
        obscureText: isPassword,
        style: TextStyle(
          color: enabled ? const Color(0xFF0F172A) : const Color(0xFF64748B),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 20),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: const Color(0xFF64748B), size: 20) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: roles.map((role) {
          final isSelected = selectedRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedRole = role),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF007B3E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  role,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
