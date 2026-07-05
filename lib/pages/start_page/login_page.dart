import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:obstawiator/pages/main_table/main_table.dart' as main_table;
import 'package:obstawiator/pages/start_page/registration_page.dart' as registration;
import 'package:obstawiator/main.dart' as main;

class LoginPage extends StatefulWidget
{
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
{
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getInt('userID');
    final savedToken = prefs.getString('sessionToken');

    if (savedUserId != null && savedToken != null) {
      main.userID = savedUserId;
      main.sessionToken = savedToken;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const main.MainNavigationContainer()),
        );
      }
    }
  }

  void register()
  {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const registration.RegistrationPage()),
    );
  }

  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      var url = Uri.parse("https://obstawiator.pages.dev/API/Login");
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            "email": _emailController.text.toLowerCase(),
            "password": _passwordController.text
          }),
        );

        var resultJSON = json.decode(response.body);
        if (response.statusCode == 200) {
          main.userID = resultJSON['userID'];
          main.sessionToken = resultJSON['sessionToken'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userID', main.userID!);
          await prefs.setString('sessionToken', main.sessionToken!);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resultJSON['message'])),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const main.MainNavigationContainer()),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resultJSON['message'])),
          );
        }
      } catch (e) {
        if (kDebugMode) print("Login error: $e");
      }
    }
  }

  void _handleChangePassword() {
    // Placeholder for password change functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funkcja zmiany hasła nie jest jeszcze zaimplementowana.')),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: const main.ObstawiatorAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
                      ? MediaQuery.of(context).size.width // Use full width if height > width
                      : MediaQuery.of(context).size.width * 0.4, // 40% of screen width
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: [AutofillHints.newUsername, AutofillHints.username],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Proszę podać adres e-mail';
                          }
                          if (!value.contains('@')) {
                            return 'Proszę podać poprawny adres e-mail';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(labelText: 'Hasło'),
                        obscureText: true,
                        autofillHints: [AutofillHints.newPassword, AutofillHints.password],
                        onEditingComplete: () => TextInput.finishAutofillContext(),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                          {
                            return 'Proszę podać hasło';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: login,
                            child: const Text('Zaloguj się'),
                          ),
                          TextButton(
                            onPressed: _handleChangePassword,
                            child: const Text('Zapomniałeś hasła?'),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: register,
                        child: const Text('Stwórz nowe konto'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        )
      ),
    );
  }

  @override
  void dispose()
  {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}