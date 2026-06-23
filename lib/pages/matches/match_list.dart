import 'package:flutter/material.dart';
import 'package:obstawiator/main.dart' as main;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:obstawiator/pages/matches/match_bets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obstawiator/pages/start_page/login_page.dart';
import 'package:flutter/foundation.dart';

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
      isGroupStage: json['isGroupStage'] == 'true' || json['isGroupStage'] == 1 || json['isGroupStage'] == true,
      winner: json['winner'],
      hasBet: json['hasBet'] == 1 || json['hasBet'] == true,
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

  static String getFlag(String countryName) {
    switch (countryName.toLowerCase().trim()) {
      case 'polska': return '🇵🇱';
      case 'niemcy': return '🇩🇪';
      case 'usa':
      case 'stany zjednoczone': return '🇺🇸';
      case 'kanada': return '🇨🇦';
      case 'meksyk': return '🇲🇽';
      case 'argentyna': return '🇦🇷';
      case 'brazylia': return '🇧🇷';
      case 'francja': return '🇫🇷';
      case 'hiszpania': return '🇪🇸';
      case 'anglia': return '🏴󠁧󠁢󠁥󠁮󠁧󠁿';
      case 'portugalia': return '🇵🇹';
      case 'włochy': return '🇮🇹';
      case 'holandia': return '🇳🇱';
      case 'belgia': return '🇧🇪';
      case 'chorwacja': return '🇭🇷';
      case 'urugwaj': return '🇺🇾';
      case 'maroko': return '🇲🇦';
      case 'szwajcaria': return '🇨🇭';
      case 'dania': return '🇩🇰';
      case 'japonia': return '🇯🇵';
      case 'korea południowa': return '🇰🇷';
      case 'senegal': return '🇸🇳';
      case 'serbia': return '🇷🇸';
      case 'austria': return '🇦🇹';
      case 'szkocja': return '🏴󠁧󠁢󠁳󠁣󠁴󠁿';
      case 'turcja': return '🇹🇷';
      case 'rumunia': return '🇷🇴';
      case 'węgry': return '🇭🇺';
      case 'słowacja': return '🇸🇰';
      case 'słowenia': return '🇸🇮';
      case 'czechy': return '🇨🇿';
      case 'gruzja': return '🇬🇪';
      case 'albania': return '🇦🇱';
      case 'ukraina': return '🇺🇦';
      case 'szwecja': return '🇸🇪';
      case 'norwegia': return '🇳🇴';
      case 'finlandia': return '🇫🇮';
      case 'islandia': return '🇮🇸';
      case 'walia': return '🏴󠁧󠁢󠁷󠁬󠁳󠁿';
      case 'republika południowej afryki': return '🇿🇦';
      case 'bośnia i hercegowina': return '🇧🇦';
      case 'katar': return '🇶🇦';
      case 'haiti': return '🇭🇹';
      case 'paragwaj': return '🇵🇾';
      case 'australia': return '🇦🇺';
      case 'ekwador': return '🇪🇨';
      case 'wybrzeże kości słoniowej': return '🇨🇮';
      case 'curacao': return '🇨🇼';
      case 'tunezja': return '🇹🇳';
      case 'egipt': return '🇪🇬';
      case 'iran': return '🇮🇷';
      case 'nowa zelandia': return '🇳🇿';
      case 'republika zielonego przylądka': return '🇨🇻';
      case 'arabia saudyjska': return '🇸🇦';
      case 'algieria': return '🇩🇿';
      case 'jordania': return '🇯🇴';
      case 'kolumbia': return '🇨🇴';
      case 'demokratyczna republika konga':
      case 'demokratyczna republika kongu':
      case 'demokratyczna republika kongo': return '🇨🇩';
      case 'uzbekistan': return '🇺🇿';
      case 'ghana': return '🇬🇭';
      case 'panama': return '🇵🇦';
      case 'irak': return '🇮🇶';
      default: return '⚽';
    }
  }

  static String getShortName(String countryName) {
    switch (countryName.toLowerCase().trim()) {
      case 'stany zjednoczone': return 'USA';
      case 'republika południowej afryki': return 'RPA';
      case 'wybrzeże kości słoniowej': return 'WKS';
      case 'demokratyczna republika konga':
      case 'demokratyczna republika kongu':
      case 'demokratyczna republika kongo': return 'DR Kongo';
      case 'korea południowa': return 'Korea Płd.';
      case 'bośnia i hercegowina': return 'Bośnia';
      case 'republika zielonego przylądka': return 'Z. Przylądek';
      case 'arabia saudyjska': return 'Arabia Saud.';
      case 'nowa zelandia': return 'N. Zelandia';
      case 'północna macedonia': return 'Macedonia Płn.';
      default: return countryName;
    }
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
  List<Match> _upcomingMatches = [];
  List<Match> _finishedMatches = [];
  
  int _upcomingOffset = 0;
  int _finishedOffset = 0;
  
  bool _hasMoreUpcoming = true;
  bool _hasMoreFinished = true;
  
  bool _isLoadingUpcoming = false;
  bool _isLoadingFinished = false;

  @override
  void initState() {
    super.initState();
    _loadUpcomingMatches();
    _loadFinishedMatches();
  }

  Future<void> _loadUpcomingMatches() async {
    if (_isLoadingUpcoming || !_hasMoreUpcoming) return;
    setState(() => _isLoadingUpcoming = true);

    try {
      final response = await http.post(
        Uri.parse('https://obstawiator.pages.dev/API/GetMatches'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': main.sessionToken ?? '',
        },
        body: jsonEncode(<String, dynamic>{
          'ID': main.userID,
          'sessionToken': main.sessionToken,
          'finished': false,
          'limit': 10,
          'offset': _upcomingOffset,
        }),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final newMatches = data.map((item) => Match.fromJson(item)).toList();
        
        setState(() {
          _upcomingMatches.addAll(newMatches);
          _upcomingOffset += newMatches.length;
          if (newMatches.length < 10) {
            _hasMoreUpcoming = false;
          }
          _isLoadingUpcoming = false;
        });
      } else if (response.statusCode == 401) {
        _handleSessionExpired();
      } else {
        _showError('Nie udało się załadować nadchodzących meczów');
        setState(() => _isLoadingUpcoming = false);
      }
    } catch (e) {
      _showError('Błąd połączenia');
      setState(() => _isLoadingUpcoming = false);
    }
  }

  Future<void> _loadFinishedMatches() async {
    if (_isLoadingFinished || !_hasMoreFinished) return;
    setState(() => _isLoadingFinished = true);

    try {
      final response = await http.post(
        Uri.parse('https://obstawiator.pages.dev/API/GetMatches'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': main.sessionToken ?? '',
        },
        body: jsonEncode(<String, dynamic>{
          'ID': main.userID,
          'sessionToken': main.sessionToken,
          'finished': true,
          'limit': 5,
          'offset': _finishedOffset,
          'finishedMatchesOffset': _finishedOffset,
        }),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final newMatches = data.map((item) => Match.fromJson(item)).toList();
        
        setState(() {
          _finishedMatches.addAll(newMatches);
          _finishedOffset += newMatches.length;
          if (newMatches.length < 5) {
            _hasMoreFinished = false;
          }
          _isLoadingFinished = false;
        });
      } else if (response.statusCode == 401) {
        _handleSessionExpired();
      } else {
        _showError('Nie udało się załadować zakończonych meczów');
        setState(() => _isLoadingFinished = false);
      }
    } catch (e) {
      _showError('Błąd połączenia');
      setState(() => _isLoadingFinished = false);
    }
  }

  Future<void> _refreshMatches() async {
    if (!mounted) return;
    setState(() {
      _upcomingMatches.clear();
      _upcomingOffset = 0;
      _hasMoreUpcoming = true;
      _finishedMatches.clear();
      _finishedOffset = 0;
      _hasMoreFinished = true;
    });
    await _loadUpcomingMatches();
    await _loadFinishedMatches();
  }

  void _handleSessionExpired() async {
    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userID');
      await prefs.remove('sessionToken');
      main.userID = null;
      main.sessionToken = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesja wygasła. Zaloguj się ponownie.')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _buildMatchCard(Match match) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Płynne przejście szerokości: na telefonach 100%, na większych ekranach rośnie wolniej
    final containerWidth = screenWidth < 600 
        ? screenWidth 
        : (600 + (screenWidth - 600) * 0.3).clamp(0.0, 1000.0);

    final bool isNotPlaced = !match.hasBet && match.matchStart.isAfter(DateTime.now());
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        width: containerWidth,
        constraints: const BoxConstraints(minWidth: 300),
        child: Card(
          color: isNotPlaced 
            ? (isDarkMode ? Colors.orange.withOpacity(0.05) : Colors.orange.withOpacity(0.1)) 
            : null,
          shape: isNotPlaced
              ? RoundedRectangleBorder(
                  side: BorderSide(
                    color: isDarkMode ? Colors.orange.withOpacity(0.5) : Colors.orange, 
                    width: isDarkMode ? 1.0 : 1.5
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              await Navigator.push(
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
                ),
              );
              _refreshMatches();
            },
            child: ListTile(
              title: Row(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: [
                        Text(Match.getFlag(match.host), style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final fullName = match.host;
                              final shortName = Match.getShortName(fullName);
                              const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
                              
                              String displayName = fullName;
                              if (fullName != shortName) {
                                final textPainter = TextPainter(
                                  text: TextSpan(text: fullName, style: style),
                                  maxLines: 1,
                                  textDirection: Directionality.of(context),
                                )..layout(maxWidth: constraints.maxWidth);
                                
                                if (textPainter.didExceedMaxLines) {
                                  displayName = shortName;
                                }
                              }

                              return Text(
                                displayName,
                                textAlign: TextAlign.left,
                                style: style,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      '${match.homeScore ?? '-'} : ${match.awayScore ?? '-'}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final fullName = match.guest;
                              final shortName = Match.getShortName(fullName);
                              const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
                              
                              String displayName = fullName;
                              if (fullName != shortName) {
                                final textPainter = TextPainter(
                                  text: TextSpan(text: fullName, style: style),
                                  maxLines: 1,
                                  textDirection: Directionality.of(context),
                                )..layout(maxWidth: constraints.maxWidth);
                                
                                if (textPainter.didExceedMaxLines) {
                                  displayName = shortName;
                                }
                              }

                              return Text(
                                displayName,
                                textAlign: TextAlign.right,
                                style: style,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(Match.getFlag(match.guest), style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                DateFormat('EEEE, dd/MM HH:mm', 'pl_PL').format(match.matchStart),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const main.ObstawiatorAppBar(),
      body: Material(
        color: Theme.of(context).colorScheme.surface,
        child: RefreshIndicator(
          onRefresh: _refreshMatches,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Upcoming Matches Section
                if (_upcomingMatches.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Nadchodzące mecze', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  ..._upcomingMatches.map((m) => _buildMatchCard(m)),
                  if (_hasMoreUpcoming)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: _isLoadingUpcoming ? null : _loadUpcomingMatches,
                        label: _isLoadingUpcoming ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Załaduj więcej nadchodzących'),
                        icon: const Icon(Icons.add),
                      ),
                    ),
                ],

                const Divider(thickness: 2, height: 40),

                // Finished Matches Section
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Zakończone mecze', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                if (_finishedMatches.isEmpty && !_hasMoreFinished)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Brak zakończonych meczów'),
                  ),
                ..._finishedMatches.map((m) => _buildMatchCard(m)),
                
                if (_hasMoreFinished)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingFinished ? null : _loadFinishedMatches,
                      label: _isLoadingFinished ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Załaduj więcej zakończonych'),
                      icon: const Icon(Icons.history),
                    ),
                  ),
                const SizedBox(height: 80), // Space for FAB/BottomBar
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const main.ObstawiatorBottomNavigationBar(currentIndex: 1),
    );
  }
}
