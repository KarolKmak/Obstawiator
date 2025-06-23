import 'package:flutter/material.dart';
import 'package:obstawiator/pages/main_table/main_table.dart';
import 'package:obstawiator/pages/matches/match_list.dart';
import 'package:obstawiator/pages/start_page/login_page.dart';


//***********************************************************************
// Buduj wersję WEB poleceniem flutter pub global run peanut -b deploy_ready
// Następnie ręcznie przenieś różnice do brancha "deploy"

void main()
{
  runApp(const MyApp());
}

BottomNavigationBar navigationBar(BuildContext context)
{
  return BottomNavigationBar(
    items: const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.table_chart),
        label: 'Tabela Główna',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.list),
        label: 'Lista Meczów',
      ),
    ],
    currentIndex: 0, // Domyślnie zaznaczony pierwszy element
    selectedItemColor: Colors.blueAccent,
    onTap: (index) {
      // Handle navigation based on index
      if (index == 0) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const MyHomePage()));
      } else if (index == 1) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const MatchList()));
      }
    },
  );
}

AppBar titleBar(BuildContext context)
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
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: 'Wyloguj',
        onPressed: () {
          userID = null;
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const LoginPage()));
        },
      ),
    ],
    backgroundColor: Colors.blueAccent,
    foregroundColor: Colors.white,
    centerTitle: true,
  );
}

int ?userID = 0;
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
      home: const MyHomePage(),
    );
  }
}