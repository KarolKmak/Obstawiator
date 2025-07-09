import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void register()
  {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const registration.RegistrationPage()),
    );
  }

  Future<void> login()
  async {
    if (_formKey.currentState!.validate())
    {
      var headers =
      {
        'Content-Type': 'application/json'
      };
      var url = Uri.parse("https://obstawiator.pages.dev/API/Login");
      var request = http.Request('POST', url);
      request.body = json.encode({"email": _emailController.text.toLowerCase(), "password": _passwordController.text});
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();
      var result = await response.stream.bytesToString();
      var resultJSON = json.decode(result);
      if(response.statusCode == 200)
      {
        main.userID = resultJSON['userID'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultJSON['message'])),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const main_table.MyHomePage()),
        );
      }
      else
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultJSON['message'])),
        );
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
      appBar: main.titleBar(context),
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
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
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
                        decoration: const InputDecoration(labelText: 'Hasło'),
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
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