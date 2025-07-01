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
    backgroundColor: Colors.blueAccent,
    foregroundColor: Colors.white,
    centerTitle: true,
    title: const Text('⚽ Obstawiator ⚽'),
    actions: <Widget>[
      Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ustawienia',
            onPressed: () {
              final RenderBox button = context.findRenderObject() as RenderBox;
              final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
              final RelativeRect position = RelativeRect.fromRect(
                Rect.fromPoints(
                  button.localToGlobal(Offset.zero, ancestor: overlay),
                  button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                ),
                Offset.zero & overlay.size,
              );
              showMenu(
                context: context,
                position: position.shift(const Offset(0, kToolbarHeight -5)), // Adjust Y offset if needed
                items: [
                  PopupMenuItem(
                    child: const Text('Licencje'),
                    onTap: () {
                      // Delay navigation to allow the menu to close
                      Future.delayed(Duration.zero, () {
                        showLicensePage(
                          context: context,
                          applicationName: 'Obstawiator',
                          applicationVersion: '1.0.0', // Możesz dostosować wersję
                        );
                      });
                    },
                  ),
                  // Add more PopupMenuItems for other settings options here
                ],
              );
            },
          );
        }
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
  );
}

int ?userID;
class MyApp extends StatelessWidget
{
  const MyApp({super.key});


  @override
  Widget build(BuildContext context)
  {
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