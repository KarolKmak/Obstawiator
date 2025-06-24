import 'package:flutter/material.dart';
import 'package:obstawiator/main.dart' as main;
import 'package:http/http.dart' as http;
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
  /// Tworzy obiekt [Match].
  Match({
    required this.host,
    required this.guest,
    required this.homeScore,
    required this.awayScore,
    required this.matchStart,
    required this.ID,
  });

  /// Tworzy obiekt [Match] z mapy JSON.
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

/// Widżet wyświetlający listę meczów.
class MatchList extends StatefulWidget {
  const MatchList({super.key});

  /// Tworzy nowy widżet [MatchList].
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
      // Obsługa błędu, np. wyświetlenie snackbara lub komunikatu o błędzie
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
          child: ListView.builder(
            shrinkWrap: true, // ListView zajmuje tylko niezbędne miejsce
            itemCount: _matches.length,
            itemBuilder: (context, index) {
              final match = _matches[index];
              return Center( // Wyśrodkowanie każdej karty
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5, // 50% szerokości ekranu
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
                        subtitle: Text('Początek o: ${DateFormat('dd/MM HH:mm').format(match.matchStart)}', textAlign: TextAlign.center),
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