import 'package:flutter/material.dart';
import 'package:obstawiator/main.dart' as main;
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:obstawiator/pages/matches/match_bets.dart';

/// Reprezentuje mecz pomiędzy dwiema drużynami.
class Match {
  final int ID;
  final String host;
  final String guest;
  final int? homeScore;
  final int? awayScore;
  final DateTime matchStart;
  final int betVisible;
  bool hasBet;
  final bool isGroupStage;
  final int? winner;
  /// Tworzy obiekt [Match].
  Match({
    required this.host,
    required this.guest,
    required this.homeScore,
    required this.awayScore,
    required this.matchStart,
    required this.ID,
    required this.betVisible,
    required this.isGroupStage,
    this.winner,
    this.hasBet = false, // Default to false
  });

  /// Tworzy obiekt [Match] z mapy JSON.
  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      ID: json['ID'] ?? 0, // Provide a default value if ID is null
      host: json['host'],
      guest: json['guest'],
      homeScore: json['homeScore'],
      awayScore: json['awayScore'], // Ensure this matches the JSON key
      matchStart: DateTime.fromMillisecondsSinceEpoch(json['matchStart'], isUtc: true).toLocal(),
      betVisible: json['betVisible'],
      isGroupStage: json['isGroupStage'] == 'true',
      winner: json['winner'],
      // hasBet will be updated later,
    );
  }

  /// Returns the color for the exclamation mark based on the match start time.
  Color? getExclamationMarkColor() {
    final now = DateTime.now();
    final difference = matchStart.difference(now);

    if (matchStart.isAfter(now) && matchStart.day == now.day && matchStart.month == now.month && matchStart.year == now.year) {
      if (difference.inHours < 2) {
        return Colors.red;
      } else if (difference.inHours < 8) {
        return Colors.yellow;
      }
      return Colors.grey;
    }
    return null; // No mark if not today
  }
}

/// Widżet wyświetlający listę meczów.
class MatchList extends StatefulWidget {
  const MatchList({super.key});

  /// Tworzy nowy widżet [MatchList].
  @override
  State<MatchList> createState() => _MatchListState();
}

class _MatchListState extends State<MatchList> {
  List<Match> _matches = [];
  List<Match> _finishedMatches = [];
  int _finishedMatchesOffset = 0;
  bool _showLoadMoreButton = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pl_PL', null).then((_) => _loadMatches());
    _loadMatches();
  }

  Future<void> _checkBetsForMatches(List<Match> matches) async {
    for (var match in matches) {
      // Only check if the bet was placed if the match start time is the same as the current date.
      final now = DateTime.now();
      // And if match has not already started
      if (match.matchStart.isAfter(now) && match.matchStart.year == now.year && match.matchStart.month == now.month && match.matchStart.day == now.day ) {
        final response = await http.post(
          Uri.parse('https://obstawiator.pages.dev/API/IsMyBetPlaced'), // Corrected API endpoint
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, int?>{
            'matchID': match.ID,
            'ID': main.userID,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          // Check if data is a list and not empty
          if (data is List && data.isNotEmpty) {
            // Assuming the relevant bet information is in the first element of the list
            // and the key for the bet is 'userBet' or if a winner is already declared.
            match.hasBet = (data[0]['userBetHome'] != null && data[0]['userBetAway'] != null);
          } else if (data is Map<String, dynamic>) {
            // Check if data is a map
            match.hasBet = data['userBet'] != null;
          }
        } else {
          final responseData = jsonDecode(response.body);
          final message = responseData['message'] ?? 'Nie udało się sprawdzić zakładu dla meczu ${match.ID}';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          }
        }
      }
    }
    setState(() {}); // Update the UI after checking bets
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
        final loadedMatches = data.map((item) => Match.fromJson(item)).toList();
        _matches = loadedMatches;
        _checkBetsForMatches(_matches); // Check bets after loading matches
      });
    } else {
      // Obsługa błędu, np. wyświetlenie snackbara lub komunikatu o błędzie
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się załadować meczów')),
        );
      }
      // For now, using placeholder data if API fails
    }
  }

  Future<void> _loadFinishedMatches() async {
    // ignore: avoid_print
    print('Loading finished matches with offset: $_finishedMatchesOffset');
    final response = await http.post(
      Uri.parse('https://obstawiator.pages.dev/API/GetMatches'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, int?>{
        // ignore: unnecessary_string_interpolations
        // ignore: avoid_print
        'ID': main.userID,
        'finishedMatchesOffset': _finishedMatchesOffset,
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      // ignore: avoid_print
      print('Received data for finished matches: $data');
      setState(() {
        if (data.isEmpty) {
          _showLoadMoreButton = false;
        } // No new matches to add
        final newMatches = data.map((item) => Match.fromJson(item)).toList();
        _finishedMatches.addAll(newMatches);
        _finishedMatchesOffset += newMatches.length;
        // ignore: avoid_print
        print('Current finished matches count after adding: ${_finishedMatches.length}');
        if (_finishedMatches.length < 10) {
          _showLoadMoreButton = false;
        }
        // ignore: avoid_print
        print('New finished matches offset: $_finishedMatchesOffset');
        _checkBetsForMatches(_finishedMatches); // Check bets after loading finished matches
      });
    } else {
      // ignore: avoid_print
      print('Failed to load finished matches: ${response.statusCode}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się załadować meczów')),
        );
      }
      // For now, using placeholder data if API fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Opakowanie widżetem Scaffold
      appBar: main.titleBar(context),
      body: Material( // Opakowanie widżetem Material
        color: Theme.of(context).colorScheme.surface, // Ustawienie koloru tła
        child: Center( // Wyśrodkowanie ListView
          child: _matches.isEmpty && _finishedMatches.isEmpty && !_showLoadMoreButton ? const Center(child: Text('Nie ma więcej zakończonych meczów do załadowania')) : ListView.builder(
            // shrinkWrap: true, // Usunięcie shrinkWrap, aby umożliwić przewijanie w przypadku dużej liczby elementów
            itemCount: _matches.length + _finishedMatches.length,
            itemBuilder: (context, index) {
              final match = index < _matches.length ? _matches[index] : _finishedMatches[index - _matches.length];
              // Sprawdzenie orientacji ekranu
              final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
              // Szerokość kontenera dostosowana do orientacji
              final containerWidth = isPortrait ? MediaQuery.of(context).size.width * 1 : MediaQuery.of(context).size.width * 0.5; // Zmienione z 0.5 na 0.9 dla portretu

              final exclamationColor = match.getExclamationMarkColor();
              return Center( // Wyśrodkowanie każdej karty
                child: Container(
                  width: containerWidth, // Użycie zdefiniowanej szerokości
                  constraints: const BoxConstraints(minWidth: 300), // Minimalna szerokość zawartości
                  child: Card( // Użycie Card dla lepszej wizualnej reprezentacji kafelka
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    clipBehavior: Clip.antiAlias, // Ta linia zapewnia, że zawartość respektuje zaokrąglone rogi Card
                    child: InkWell( // Opakowanie ListTile widżetem InkWell, aby uczynić go klikalnym
                    highlightColor: Theme.of(context).colorScheme.secondaryContainer, // Zmiana koloru tła po kliknięciu
                    splashColor: Colors.transparent, // Usunięcie efektu plusku
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
                            betVisible: match.betVisible,
                            isGroupStage: match.isGroupStage,
                            winner: match.winner,
                          ),
                        ));
                    },
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            if (exclamationColor != null && !match.hasBet && match.matchStart.isAfter(DateTime.now())) // Invisible placeholder to balance layout if no icon on left)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Icon(Icons.warning_amber_rounded, color: exclamationColor, size: 24),
                              )
                            else if (exclamationColor != null && match.hasBet) // Keep spacing consistent
                              const SizedBox(width: 32), // Icon width + padding

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
                            if (exclamationColor != null && !match.hasBet) // Invisible placeholder to balance layout if no icon on left
                              const SizedBox(width: 32)
                            else if (exclamationColor == null) // If no icon at all, add some padding
                              const SizedBox(width: 16),


                          ],
                        ),
                        subtitle: Text('${DateFormat('EEEE, dd/MM HH:mm', 'pl_PL').format(match.matchStart)}', textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _showLoadMoreButton
          ? FloatingActionButton.extended(
              onPressed: _loadFinishedMatches,
              label: const Text('Załaduj zakończone mecze'),
              icon: const Icon(Icons.download),
            )
          : const SizedBox.shrink(), // Use SizedBox.shrink() to make the button completely invisible
      bottomNavigationBar: main.navigationBar(context),
    );
  }
}