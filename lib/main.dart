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


import 'package:firebase_core/firebase_core.dart';
import 'package:obstawiator/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

int? userID;
String? sessionToken;
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class ObstawiatorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const ObstawiatorAppBar({
    super.key,
    this.title = '⚽ Obstawiator ⚽',
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF002868), // Deep Navy Blue (USA)
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
              requestWebNotificationPermission();
              if (!kIsWeb) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Powiadomienia konfiguruje się w ustawieniach systemu.')),
                );
              }
            } else if (value == 'regulamin') {
              _showRulesDialog(context);
            } else if (value == 'dark_mode') {
              _toggleDarkMode();
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'regulamin',
              child: ListTile(
                leading: Icon(Icons.description_outlined),
                title: Text('Regulamin'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem<String>(
              value: 'dark_mode',
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, mode, child) {
                  final isDark = mode == ThemeMode.dark;
                  return ListTile(
                    leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                    title: Text(isDark ? 'Tryb jasny' : 'Tryb ciemny'),
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ),
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

  void _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (themeNotifier.value == ThemeMode.light) {
      themeNotifier.value = ThemeMode.dark;
      await prefs.setBool('isDarkMode', true);
    } else {
      themeNotifier.value = ThemeMode.light;
      await prefs.setBool('isDarkMode', false);
    }
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regulamin i Punktacja'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Zasady Ogólne:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  '• Typujemy wyniki meczów w regulaminowym czasie gry.\n'
                  '• W fazie pucharowej dodatkowo wybieramy drużynę, która awansuje dalej.'),
              SizedBox(height: 12),
              Text(
                'Punktacja - Faza Grupowa:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  '• Dokładny wynik: 5 pkt\n'
                  '• Rozstrzygnięcie i różnica bramek: 2 pkt\n'
                  '• Tylko rozstrzygnięcie (zwycięzca/remis): 1 pkt'),
              SizedBox(height: 12),
              Text(
                'Punktacja - Faza Pucharowa:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  '• Wybór zwycięzcy (awans): 2 pkt\n'
                  '• Dokładny wynik (90 min): 4 pkt\n'
                  '• Możliwe zdobycie łącznie 6 pkt za mecz.'),
              SizedBox(height: 12),
              Text(
                'Dodatkowe:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Typy na Mistrza i Króla Strzelców należy oddać przed rozpoczęciem turnieju.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
        ],
      ),
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Obstawiator',
          themeMode: currentMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF002868),
              primary: const Color(0xFF002868),
              secondary: const Color(0xFFBF0A30), // Red (Canada/USA)
              tertiary: const Color(0xFF006847), // Green (Mexico)
              surface: Colors.white,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF002868),
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF002868),
              primary: const Color(0xFF002868),
              secondary: const Color(0xFFBF0A30),
              tertiary: const Color(0xFF006847),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF002868), // Keep consistent navy for dark mode too or slightly darker
              foregroundColor: Colors.white,
            ),
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}
