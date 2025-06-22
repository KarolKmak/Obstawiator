import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:obstawiator/pages/main table/main_table.dart' as main_table;
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
      request.body = json.encode({"email": _emailController.text, "password": _passwordController.text});
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
          MaterialPageRoute(builder: (context) => const main_table.MyHomePage(title: "Obstawiator")),
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

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.4, // 40% of screen width
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                      {
                        return 'Please enter your password';
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
                        child: const Text('Login'),
                      ),
                      TextButton(
                        onPressed: ()
                        {
                          print('Zmiana hasła');
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: register,
                    child: const Text('Create New Account'),
                  ),
                ],
              ),
            ),
          ),
        ),
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