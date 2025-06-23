import 'package:flutter/material.dart';
import 'package:obstawiator/main.dart' as main;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:obstawiator/pages/matches/match_bets.dart';

/// Represents a match between two teams.
class Match {
  final int ID;
  final String host;
  final String guest;
  final int? homeScore;
  final int? awayScore;
  final DateTime matchStart;
  /// Creates a [Match] object.
  Match({
    required this.host,
    required this.guest,
    required this.homeScore,
    required this.awayScore,
    required this.matchStart,
    required this.ID,
  });

  /// Creates a [Match] object from a JSON map.
  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      ID: json['ID'],
      host: json['host'],
      guest: json['guest'],
      homeScore: json['homeScore'],
      awayScore: json['awayScore'],
      matchStart: DateTime.fromMillisecondsSinceEpoch(json['matchStart'], isUtc: true).toLocal(),
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
    final response = await http.post(
      Uri.parse('https://obstawiator.pages.dev/API/GetMatches'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int?>{
        'ID': main.userID,
      }),
    );

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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchBets(
                            host: match.host,
                            guest: match.guest,
                            matchStart: match.matchStart,
                            homeScore: match.homeScore,
                            awayScore: match.awayScore,
                            matchID: match.ID,
                          ),
                        ));
                    },
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Text(match.host, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                '${match.homeScore ?? '-'} : ${match.awayScore ?? '-'}',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                            Expanded(
                              child: Text(match.guest, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                            ),
                          ],
                        ),
                        subtitle: Text('Starts at: ${DateFormat('dd/MM HH:mm').format(match.matchStart)}', textAlign: TextAlign.center),
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