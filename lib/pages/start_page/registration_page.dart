import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:obstawiator/pages/start_page/login_page.dart';
import 'package:obstawiator/main.dart' as main;
import 'package:obstawiator/pages/main table/main_table.dart' as main_table;

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  Future<void> register() async {
    var headers =
    {
      'Content-Type': 'application/json'
    };
    var url = Uri.parse("https://obstawiator.pages.dev/API/Register");
    var request = http.Request('POST', url);
    request.body = json.encode({"email": _emailController.text, "password": _passwordController.text, "token": _tokenController.text, "name": _usernameController.text});
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 201)
    {
      var result = await response.stream.bytesToString();
      //transorm result to JSON and print "messege"
      var resultJSON = json.decode(result);
      main.userID = resultJSON['userID'];
      //add message to snackbar with resultJSON['messege']
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultJSON['messege'])),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const main_table.MyHomePage(title: "Obstawiator")),
      );
    }
    else
    {
      print(response);
    }

    print('Username: ${_usernameController.text}');
    print('Email: ${_emailController.text}');
    print('Password: ${_passwordController.text}');
    print('Token: ${_tokenController.text}');
  }
  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value)
                    {
                      if (value == null || value.isEmpty)
                      {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                      {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@'))
                      {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value)
                    {
                      if (value == null || value.isEmpty)
                      {
                        return 'Please enter your password';
                      }
                      if (value.length < 6)
                      {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Token',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    validator: (value)
                    {
                      if (value == null || value.isEmpty)
                      {
                        return 'Please enter your token';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, // Ensure the SizedBox takes full width for centering
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate())
                        {
                          // If the form is valid, display a snackbar. In a real app,
                          // you'd often call a server or save the information locally.
                          register();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Processing Data')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), // Adjust padding as needed
                      ),
                      child: const Text('Register'),
                    ),
                  ),
                  TextButton(
                    onPressed: ()
                    {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text('Already have an account? Login'),
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
