import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:obstawiator/pages/main_table/table_data.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obstawiator/main.dart' as main;
import 'package:obstawiator/pages/start_page/login_page.dart';

class MyHomePage extends StatefulWidget
{
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage>
{

  List<UserStandings> userStandingsTable = [];

  Future<void> fetchData() async
  {
    // Przywróć sesję, jeśli została utracona (np. po odświeżeniu strony)
    if (main.userID == null || main.sessionToken == null) {
      final prefs = await SharedPreferences.getInstance();
      main.userID = prefs.getInt('userID');
      main.sessionToken = prefs.getString('sessionToken');
    }

    if (main.userID == null || main.sessionToken == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
      return;
    }

    setState(() {
      userStandingsTable.clear();
    });

    final url = Uri.parse("https://obstawiator.pages.dev/API/GetMainTable");
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': main.sessionToken ?? '',
        },
        body: json.encode({"ID": main.userID}),
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body) as List;
        for (var i = 0; i < jsonData.length; i++) {
          int id = jsonData[i]['ID'] ?? 0;
          String name = jsonData[i]['name'] ?? 'N/A';
          String championBet = jsonData[i]['championBet'] ?? 'N/A';
          String topScorerBet = jsonData[i]['topScorerBet'] ?? 'N/A';
          int points = jsonData[i]['points'] ?? 0;
          setState(() {
            userStandingsTable.add(UserStandings(
                ID: id,
                name: name,
                championbet: championBet,
                topscorer: topScorerBet,
                points: points));
          });
        }
      } else if (response.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesja wygasła. Zaloguj się ponownie.')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        if (kDebugMode) {
          print("Failed, status: ${response.statusCode}, body: ${response.body}");
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Błąd pobierania danych')),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching table: $e");
    }
  }
  @override
  void initState()
  {
    // TODO: implement initState
    super.initState();
    fetchData();
  }



  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: const main.ObstawiatorAppBar(),
      body: Center(
        child: SizedBox.expand(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                      columnSpacing: constraints.maxWidth < 600 ? 10 : null, // Adjust column spacing for narrow screens
                      dividerThickness: 1, // Add a divider between columns
                      columns: _createColumns(),
                      showCheckboxColumn: false, // Add this line
                      rows: _createRows()),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const main.ObstawiatorBottomNavigationBar(currentIndex: 0),
    );
  }
  void _handleRowTap(int id) {
    if (kDebugMode) {
      print('Row with ID $id was tapped. UserID is ${main.userID}');
    }
    if (id == main.userID) {
      final championSuggestions = userStandingsTable
          .map((u) => u.championbet)
          .where((s) => s != 'N/A' && s.isNotEmpty && s != 'empty')
          .toSet()
          .toList();
      final topScorerSuggestions = userStandingsTable
          .map((u) => u.topscorer)
          .where((s) => s != 'N/A' && s.isNotEmpty && s != 'empty')
          .toSet()
          .toList();

      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          // Find the current user's data
          final currentUserData = userStandingsTable.firstWhere((user) => user.ID == main.userID);
          String currentChampion = currentUserData.championbet;
          String currentTopScorer = currentUserData.topscorer;

          return AlertDialog(
            title: const Text('Zmień typy'),
            content: StatefulBuilder(
              builder: (context, setStateDialog) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: currentChampion == 'empty' ? '' : currentChampion),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return championSuggestions;
                          }
                          return championSuggestions.where((String option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) {
                          currentChampion = selection;
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          // Use a more robust way to sync text
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(labelText: 'Mistrz'),
                            onChanged: (value) => currentChampion = value,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: currentTopScorer == 'empty' ? '' : currentTopScorer),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return topScorerSuggestions;
                          }
                          return topScorerSuggestions.where((String option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) {
                          currentTopScorer = selection;
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(labelText: 'Król strzelców'),
                            onChanged: (value) => currentTopScorer = value,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Anuluj'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Zapisz'),
                onPressed: () async {
                  if (currentChampion.isEmpty || currentTopScorer.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Oba pola muszą być wypełnione!')),
                    );
                    return;
                  }

                  var url = Uri.parse("https://obstawiator.pages.dev/API/InitialBets");
                  try {
                    final response = await http.post(
                      url,
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': main.sessionToken ?? '',
                      },
                      body: json.encode({
                        "ID": main.userID,
                        "championBet": currentChampion,
                        "topScorerBet": currentTopScorer
                      }),
                    );

                    if (response.statusCode == 201) {
                      final decodedBody = jsonDecode(response.body);
                      final message = decodedBody['message'] ?? 'Zapisano pomyślnie!';
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );

                      fetchData(); // Refresh the table data
                      Navigator.of(context).pop();
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Błąd zapisu: ${response.statusCode}')),
                      );
                    }
                  } catch (e) {
                    if (kDebugMode) print("Update bets error: $e");
                  }
                },
              ),
            ],
          );
        },
      );
    } else {
      if (kDebugMode) {
        print("Row ID: $id does not match UserID: ${main.userID}");
      }
    }
  }

  List<DataColumn> _createColumns()
  {
    return
      [
        const DataColumn(label: Text("Gracz")),
        const DataColumn(label: Text("Mistrz")),
        const DataColumn(label: Text("Król strzelców")),
        const DataColumn(label: Text("Punkty")),
      ];
  }
  List<DataRow> _createRows()
  {
    // Sort userStandingsTable by points in descending order before mapping to rows
    List<UserStandings> sortedStandings = List.from(userStandingsTable)..sort((a, b) => b.points.compareTo(a.points));

    return sortedStandings.asMap().entries.map((entry)
    {
      int index = entry.key;
      UserStandings e = entry.value;
      final bool isUserRow = e.ID == main.userID;
      final Color? rowColor = isUserRow
          ? Colors.blue.withValues(alpha: 0.1) // Light blue for user row
          : (index % 2 == 0 ? Colors.grey.withValues(alpha: 0.1) : null); // Light grey for even rows

      DataRow rowWidget = DataRow(
          color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) => rowColor),
          cells: [
            DataCell(Text(e.name)),
            DataCell(Text(e.championbet)),
            DataCell(Text(e.topscorer)),
            DataCell(Text(e.points.toString())),
          ],
          onSelectChanged: (isSelected) {
            if (isSelected != null) { // Removed isSelected check as it's not needed without checkboxes
              _handleRowTap(e.ID);
            }
          },
        );

      if (isUserRow) {
        return DataRow(
          cells: rowWidget.cells.map((cell) => DataCell(Tooltip(message: 'Kliknij, aby edytować swoje typy', child: cell.child))).toList(),
          onSelectChanged: rowWidget.onSelectChanged,
          color: rowWidget.color,
        );
          }
      return rowWidget;
    }).toList();
  }
}