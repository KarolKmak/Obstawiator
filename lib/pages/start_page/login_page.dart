import 'package:flutter/material.dart';
import 'package:obstawiator/pages/main table/main_table.dart' as main_table;
import 'package:obstawiator/pages/start_page/registration_page.dart' as registration;

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

  void login()
  {
    if (_formKey.currentState!.validate()) {
      // Process login
      // For now, just print to console
      print('Email: ${_emailController.text}');
      print('Password: ${_passwordController.text}');

      //ToDo create login function

      if(false)
      {
        final scaffold = ScaffoldMessenger.of(context);
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Wrong password or email')
          ));
      }
      else
      {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const main_table.MyHomePage(title: "Obstawiator")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      if (value == null || value.isEmpty) {
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
                        onPressed: () {
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}