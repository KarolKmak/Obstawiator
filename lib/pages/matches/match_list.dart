import 'package:flutter/material.dart';
import 'package:obstawiator/main.dart' as main;
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Represents a match between two teams.
class Match {
  final String matchID;
  final String team1;
  final String team2;
  final int? score1;
  final int? score2;
  final DateTime startTime;
  /// Creates a [Match] object.
  Match({
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
    required this.startTime,
    required this.matchID,
  });

  /// Creates a [Match] object from a JSON map.
  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      matchID: json['matchID'],
      team1: json['team1'],
      team2: json['team2'],
      score1: json['score1'],
      score2: json['score2'],
      startTime: DateTime.parse(json['startTime']),
    );
  }
}

/// A widget that displays a list of matches.
class MatchList extends StatefulWidget {
  const MatchList({super.key});

  /// Creates a new [MatchList] widget.
  @override
  State<MatchList> createState() => _MatchListState();
}

class _MatchListState extends State<MatchList> {
  List<Match> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final response = await http.get(Uri.parse('https://obstawiator.pages.dev/API/GetMatches'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _matches = data.map((item) => Match.fromJson(item)).toList();
      });
    } else {
      // Handle error, e.g., show a snackbar or an error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load matches')),
        );
      }
      // For now, using placeholder data if API fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Wrap with Scaffold widget
      appBar: main.titleBar(context),
      body: Material( // Wrap with Material widget
        color: Theme.of(context).colorScheme.surface, // Set background color
        child: Center( // Center the ListView
          child: ListView.builder(
            shrinkWrap: true, // Make ListView take only necessary space
            itemCount: _matches.length,
            itemBuilder: (context, index) {
              final match = _matches[index];
              return Center( // Center each Card
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5, // 50% of screen width
                  constraints: const BoxConstraints(minWidth: 300), // Minimum width for content
                  child: Card( // Use Card for a better visual representation of a tile
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    clipBehavior: Clip.antiAlias, // Add this line to ensure content respects Card's rounded corners
                    child: InkWell( // Wrap ListTile with InkWell to make it clickable
                    highlightColor: Theme.of(context).colorScheme.secondaryContainer, // Change background color on tap
                    splashColor: Colors.transparent, // Remove splash effect
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Clicked on match with ID: ${match.matchID}'),
                        ),
                      );
                    },
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Text(match.team1, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                '${match.score1 ?? '-'} - ${match.score2 ?? '-'}',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                            Expanded(
                              child: Text(match.team2, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                            ),
                          ],
                        ),
                        subtitle: Text('Starts at: ${match.startTime.hour}:${match.startTime.minute.toString().padLeft(2, '0')}', textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
              );
            },

          ),
        ),
      ),
      bottomNavigationBar: main.navigationBar(context),
    );
  }
}