import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:obstawiator/pages/start_page/initial_bets.dart';
import 'package:obstawiator/pages/start_page/login_page.dart';
import 'package:obstawiator/main.dart' as main;

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
      var resultJSON = json.decode(result);
      main.userID = resultJSON['userID'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultJSON['message'])),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const InitialBets()),
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
      appBar: main.titleBar(),
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
                    'Stwórz konto',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nazwa użytkownika',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value)
                    {
                      if (value == null || value.isEmpty)
                      {
                        return 'Proszę podać nazwę użytkownika';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                      {
                        return 'Proszę podać adres e-mail';
                      }
                      if (!value.contains('@'))
                      {
                        return 'Proszę podać poprawny adres e-mail';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Hasło',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value)
                    {
                      if (value == null || value.isEmpty)
                      {
                        return 'Proszę podać hasło';
                      }
                      if (value.length < 6)
                      {
                        return 'Hasło musi mieć co najmniej 6 znaków';
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
                        return 'Proszę podać token';
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
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   const SnackBar(content: Text('Przetwarzanie danych')),
                          // );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), // Adjust padding as needed
                      ),child: const Text('Zarejestruj się'),
                    ),
                  ),
                  TextButton(
                    onPressed: ()
                    {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text('Masz już konto? Zaloguj się'),
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
