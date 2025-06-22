import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:obstawiator/pages/main table/table_data.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:obstawiator/main.dart' as main;

class MyHomePage extends StatefulWidget
{
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage>
{

  List<UserStandings> userStandingsTable = [];

  Future<void> fetchData() async
  {
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
        setState((){userStandingsTable.add(UserStandings(name: jsonData[i]['name'], championbet: jsonData[i]['championBet'], topscorer: jsonData[i]['topScorerBet'], points: jsonData[i]['points']));});
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(

        child: SizedBox.expand(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
                columns: _createColumns(),
                rows: _createRows()
            ),
          ),
        ),

      ),
    );
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
    return userStandingsTable.map((e)
    {
      return DataRow(cells: [
        DataCell(Text(e.name)),
        DataCell(Text(e.championbet)),
        DataCell(Text(e.topscorer)),
        DataCell(Text(e.points.toString()))
      ]
      );

    }).toList();
  }
}