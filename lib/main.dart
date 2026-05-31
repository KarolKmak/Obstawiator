import 'package:flutter/material.dart';
import 'package:obstawiator/pages/main_table/main_table.dart';
import 'package:obstawiator/pages/matches/match_list.dart';
import 'package:obstawiator/pages/start_page/login_page.dart';


//***********************************************************************
// Buduj wersję WEB poleceniem flutter pub global run peanut -b deploy_ready
// Następnie ręcznie przenieś różnice do brancha "deploy"


void main() {
  runApp(const MyApp());
}

int? userID;

class ObstawiatorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const ObstawiatorAppBar({
    super.key,
    this.title = '⚽ Obstawiator ⚽',
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      centerTitle: true,
      title: Text(title),
      actions: <Widget>[
        PopupMenuButton<String>(
          icon: const Icon(Icons.settings),
          tooltip: 'Ustawienia',
          onSelected: (value) {
            if (value == 'licencje') {
              showLicensePage(
                context: context,
                applicationName: 'Obstawiator',
                applicationVersion: '1.0.0',
              );
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'licencje',
              child: Text('Licencje'),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Wyloguj',
          onPressed: () {
            userID = null;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ObstawiatorBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const ObstawiatorBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
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
      currentIndex: currentIndex,
      selectedItemColor: Colors.blueAccent,
      onTap: (index) {
        if (index == currentIndex) return;
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyHomePage()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MatchList()),
          );
        }
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Obstawiator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
