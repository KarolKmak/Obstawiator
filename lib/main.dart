import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obstawiator/utils/notification_helper.dart';
import 'package:obstawiator/pages/main_table/main_table.dart';
import 'package:obstawiator/pages/matches/match_list.dart';
import 'package:obstawiator/pages/start_page/login_page.dart';

//***********************************************************************
// Buduj wersję WEB poleceniem flutter pub global run peanut -b deploy_ready
// Następnie ręcznie przenieś różnice do brancha "deploy"


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

int? userID;
String? sessionToken;

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
            } else if (value == 'powiadomienia') {
              if (kIsWeb) {
                requestWebNotificationPermission();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Powiadomienia konfiguruje się w ustawieniach systemu.')),
                );
              }
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'powiadomienia',
              child: ListTile(
                leading: Icon(Icons.notifications_active),
                title: Text('Powiadomienia iPhone'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'licencje',
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Licencje'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Wyloguj',
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('userID');
            await prefs.remove('sessionToken');
            userID = null;
            sessionToken = null;
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            }
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
