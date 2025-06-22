import 'package:flutter/material.dart';
import 'package:obstawiator/pages/start_page/login_page.dart';

//***********************************************************************
// Buduj wersję WEB poleceniem flutter pub global run peanut -b deploy_ready
// Następnie ręcznie przenieś różnice do brancha "deploy"

void main()
{
  runApp(const MyApp());
}

class MyApp extends StatelessWidget
{
  const MyApp({super.key});


  @override
  Widget build(BuildContext context)
  {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}