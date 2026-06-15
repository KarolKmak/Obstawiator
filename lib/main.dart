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

import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseSupported = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  if (isFirebaseSupported) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Inicjalizacja nasłuchiwania w tle (Android APK)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      if (kDebugMode) print("Firebase initialization failed: $e");
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

// Handler dla wiadomości w tle (wymagany statyczny/top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  bool isFirebaseSupported = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  if (isFirebaseSupported) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print("Handling a background message: ${message.messageId}");
  }
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
                'Typy Długoterminowe:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  '• Trafienie Mistrza: 15 pkt\n'
                  '• Trafienie Króla Strzelców: 10 pkt\n'
                  '• Król strzelców: brak możliwości zmiany po rozpoczęciu turnieju.\n'
                  '• Mistrz: zmiana możliwa do startu fazy pucharowej. Pierwsza zmiana kosztuje 5 pkt (odejmowane jednorazowo), kolejne zmiany są bezpłatne.'),
              SizedBox(height: 12),
              Text(
                'Zakłady Specjalne:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Zasady punktowania i rozliczania zakładów specjalnych będą opisane bezpośrednio w zakładce danego zakładu specjalnego.'),
              SizedBox(height: 12),
              Text(
                'Zasady Rozstrzygania Remisów (Ex Aequo):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  'W przypadku uzyskania przez kilku uczestników tej samej liczby punktów, nagrody przewidziane dla zajmowanych przez nich miejsc są sumowane i dzielone po równo pomiędzy tych uczestników.\n\n'
                  'Przykład: Jeśli 3 osoby zajmą ex aequo 1. miejsce:\n'
                  '• Łączy się nagrody za 1., 2. i 3. miejsce (np. 50% + 30% + 20% = 100% puli).\n'
                  '• Cała kwota jest dzielona po równo na te 3 osoby.\n'
                  '• W takim przypadku nie przyznaje się już oddzielnie 2. i 3. miejsca.'),
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    if (Firebase.apps.isNotEmpty) {
      _setupInteractedMessage();
      _listenToForegroundMessages();
    }
  }

  // Obsługa powiadomień, gdy aplikacja jest otwarta (Foreground)
  void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        // Pokaż powiadomienie wewnątrz aplikacji jako SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${message.notification!.title}: ${message.notification!.body}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF002868), // Deep Navy
          ),
        );
      }
    });
  }

  // Obsługa powiadomienia, które otwiera aplikację (np. kliknięcie w banner)
  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    if (kDebugMode) print('Message clicked!');
  }

  @override
  Widget build(BuildContext context) {
    // Automatycznie odświeżaj token przy każdym wejściu do aplikacji
    if (userID != null) {
      syncPushToken();
    }

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
              secondary: const Color(0xFFBF0A30),
              tertiary: const Color(0xFF006847),
              brightness: Brightness.dark,
            ).copyWith(
              primary: const Color(0xFF5C9DFF), // Bright blue
              onPrimary: Colors.black,
              secondary: const Color(0xFFEF5350), // Brighter red
              onSecondary: Colors.black,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF001A44), // Very dark navy
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C9DFF),
                foregroundColor: Colors.black,
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF5C9DFF),
              foregroundColor: Colors.black,
            ),
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}
