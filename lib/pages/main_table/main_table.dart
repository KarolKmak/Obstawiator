import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:obstawiator/pages/main_table/table_data.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:obstawiator/main.dart' as main;

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
    // Clear existing data before fetching new data
    setState(() {
      userStandingsTable.clear();
    });
    var headers =
    {
      'Content-Type': 'application/json'
    };
    var url = Uri.parse("https://obstawiator.pages.dev/API/GetMainTable");
    var request = http.Request('POST', url);
    request.body = json.encode({"ID": main.userID});
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();

    if(response.statusCode == 200)
    {
      var jsonData = jsonDecode(await response.stream.bytesToString()) as List;
      for (var i=0; i<jsonData.length; i++)
      {
        int id = jsonData[i]['ID'] ?? 'N/A';
        // Ensure that values are not null before adding to the table
        String name = jsonData[i]['name'] ?? 'N/A';
        String championBet = jsonData[i]['championBet'] ?? 'N/A';
        String topScorerBet = jsonData[i]['topScorerBet'] ?? 'N/A';
        int points = jsonData[i]['points'] ?? 0;
        setState((){userStandingsTable.add(UserStandings(ID: id, name: name, championbet: championBet, topscorer: topScorerBet, points: points));});
      }
    }
    else
    {
      if (kDebugMode) {
        print("Failed, status: ${response.statusCode}");
      }
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.showSnackBar(
        SnackBar(
          content: const Text('No nie działa... co ci poradzę?'),
          action: SnackBarAction(label: 'No ok...', onPressed: scaffold.hideCurrentSnackBar),
        ),
      );
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
      appBar: main.titleBar(context),
      body: Center(

        child: SizedBox.expand(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
                columns: _createColumns(),
                showCheckboxColumn: false, // Add this line
                rows: _createRows()
            ),
          ),
        ),

      ),
      bottomNavigationBar: main.navigationBar(context),
    );
  }

  void _handleRowTap(int id) {
    if (kDebugMode) {
      print('Row with ID $id was tapped. UserID is ${main.userID}');
    }
    if (id == main.userID) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          // Find the current user's data
          final currentUserData = userStandingsTable.firstWhere((user) => user.ID == main.userID);
          final TextEditingController championController = TextEditingController(text: currentUserData.championbet);
          final TextEditingController topScorerController = TextEditingController(text: currentUserData.topscorer);

          return AlertDialog(
            title: const Text('Zmień typy'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: championController,
                  decoration: const InputDecoration(labelText: 'Mistrz'),
                ),
                TextField(
                  controller: topScorerController,
                  decoration: const InputDecoration(labelText: 'Król strzelców'),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Anuluj'),
                onPressed: () {
                  // Dispose controllers when dialog is dismissed
                  championController.dispose();
                  topScorerController.dispose();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Zapisz'),
                onPressed: () async {
                  final String championBet = championController.text;
                  final String topScorerBet = topScorerController.text;

                  if (championBet.isEmpty || topScorerBet.isEmpty) {
                    // Show an error or prevent closing if fields are empty
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Oba pola muszą być wypełnione!')),
                    );
                    return;
                  }

                  var headers = {
                    'Content-Type': 'application/json'
                  };
                  var url = Uri.parse("https://obstawiator.pages.dev/API/InitialBets");
                  var request = http.Request('POST', url);
                  request.body = json.encode({
                    "ID": main.userID,
                    "championBet": championBet,
                    "topScorerBet": topScorerBet
                  });
                  request.headers.addAll(headers);

                  http.StreamedResponse response = await request.send();

                  if (response.statusCode == 201) {
                    final responseBody = await response.stream.bytesToString();
                    final decodedBody = jsonDecode(responseBody);
                    final message = decodedBody['message'] ?? 'Zapisano pomyślnie!'; // Default message if not provided
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );

                    // Optionally, refresh data or show success message
                    fetchData(); // Refresh the table data
                    championController.dispose();
                    topScorerController.dispose();
                    Navigator.of(context).pop();
                  } else {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Błąd zapisu: ${response.reasonPhrase}')),
                    );
                    // Optionally, keep the dialog open or handle the error in another way
                    // For now, we'll still dispose controllers and pop the dialog
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
          ? Colors.blue.withOpacity(0.1) // Light blue for user row
          : (index % 2 == 0 ? Colors.grey.withOpacity(0.1) : null); // Light grey for even rows

      DataRow rowWidget = DataRow(
          color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) => rowColor),
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