import 'package:flutter/material.dart';
import 'package:obstawiator/main.dart' as main;

/// Represents a match between two teams.
class Match {
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
  });
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

  void _loadMatches() {
    // Placeholder: Replace with actual data fetching logic
    setState(() {
      _matches = [
        Match(team1: 'Team Alpha', team2: 'Team Bravo', score1: null, score2: null, startTime: DateTime.now().add(const Duration(hours: 2))), // Match ID: 0
        Match(team1: 'FC Winners', team2: 'Losers United', score1: 1, score2: 1, startTime: DateTime.now().add(const Duration(days: 1))), // Match ID: 1
        Match(team1: 'Dragons', team2: 'Knights', score1: null, score2: null, startTime: DateTime.now().add(const Duration(minutes: 30))), // Match ID: 2
        Match(team1: 'Team X', team2: 'Team Y', score1: 5, score2: 2, startTime: DateTime.now().add(const Duration(hours: 4))), // Match ID: 3
        Match(team1: 'Giants', team2: 'Titans', score1: 2, score2: 2, startTime: DateTime.now().add(const Duration(days: 2, hours: 1))), // Match ID: 4
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Wrap with Scaffold widget
      appBar: main.titleBar(context),
      body: Material( // Wrap with Material widget
        color: Theme.of(context).colorScheme.background, // Set background color
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
                      // Inform the user that this functionality is under development
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This feature is currently under development.'),
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