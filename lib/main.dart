import 'package:flutter/material.dart';
import 'package:obstawiator/pages/start_page/initial_bets.dart';


//***********************************************************************
// Buduj wersję WEB poleceniem flutter pub global run peanut -b deploy_ready
// Następnie ręcznie przenieś różnice do brancha "deploy"

void main()
{
  runApp(const MyApp());
}

AppBar titleBar()
{
  return AppBar(
    title: const Text('⚽ Obstawiator ⚽'),
    actions: <Widget>[
      IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Ustawienia',
        onPressed: () {
          // handle the press
        },
      ),
    ],
    backgroundColor: Colors.blueAccent,
    foregroundColor: Colors.white,
    centerTitle: true,
  );
}

int ?userID = 2;
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
      home: InitialBets(),
    );
  }
}