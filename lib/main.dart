import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:obstawiator/table_data.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Tabela Wyników'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<UserStandings> userStandingsTable = [
    //UserStandings(name: "User1", championbet: "Polska", topscorer: "Lewandowski", points: 15)
  ];

  fetchData() async{
    var url = Uri.parse("https://earlycub-eu.backendless.app/api/data/StandingsTable?sortBy=%60Points%60%20desc");
    var response = await http.get(url);

    if(response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;

      for (var i=0; i<jsonData.length; i++){
        setState((){userStandingsTable.add(UserStandings(name: jsonData[i]['name'], championbet: jsonData[i]['ChampionBet'], topscorer: jsonData[i]['TopScorerBet'], points: jsonData[i]['Points']));});
      }


    }
    else{
      print("Failed, status: ${response.statusCode}");
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
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
  }



  @override
  Widget build(BuildContext context) {
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

  List<DataColumn> _createColumns(){
    return [
      const DataColumn(label: Text("Gracz")),
      const DataColumn(label: Text("Mistrz")),
      const DataColumn(label: Text("Król strzelców")),
      const DataColumn(label: Text("Punkty")),
    ];
  }
  List<DataRow> _createRows(){
    return userStandingsTable.map((e) {
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
