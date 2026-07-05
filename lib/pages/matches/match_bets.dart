import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:obstawiator/main.dart' as main;

class MatchBets extends StatefulWidget {
  final int matchID;
  final String host;
  final String guest;
  final DateTime matchStart;
  final int? homeScore;
  final int? awayScore;
  final int betVisible;
  final bool isGroupStage;
  final int? winner;
  MatchBets({
    super.key,
    required this.matchID,
    required this.host,
    required this.guest,
    required this.matchStart,
    this.homeScore,
    this.awayScore,
    required this.betVisible,
    required this.isGroupStage,
    required this.winner,
  }) {
    // Print all passed values
    print('MatchBets constructor called with:');
    print('  matchID: $matchID');
    print('  host: $host');
    print('  guest: $guest');
    print('  matchStart: $matchStart');
    print('  homeScore: $homeScore');
    print('  awayScore: $awayScore');
    print('  betVisible: $betVisible');
    print('  isGroupStage: $isGroupStage');
    print('  winner: $winner');
  }


  @override
  _MatchBetsState createState() => _MatchBetsState();
}

class _MatchBetsState extends State<MatchBets> {
  Map<String, dynamic>? userBetData;
  List<Map<String, dynamic>> otherUsersBetsData = [];

  @override
  void initState() {
    super.initState();
    fetchMatchBets();
  }

  Future<void> fetchMatchBets() async {
    final url = Uri.parse('https://obstawiator.pages.dev/API/GetMatchBets');
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": main.sessionToken ?? "",
        },
        body: json.encode({
          'matchID': widget.matchID,
          'ID': main.userID,
          'sessionToken': main.sessionToken
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['userBet'] != null) {
          userBetData = Map<String, dynamic>.from(data['userBet']);
        } else {
          userBetData = null; // Ensure userBetData is reset if not present
        }
        if (data['matchBets'] != null) {
          otherUsersBetsData = List<Map<String, dynamic>>.from(data['matchBets']);
          if (widget.homeScore != null && widget.awayScore != null) {
            otherUsersBetsData.sort((a, b) {
              int pointsA = 0;
              if (a['homeScore'] != null && a['awayScore'] != null) {
                pointsA = calculatePoints(
                  a['homeScore'],
                  a['awayScore'],
                  widget.homeScore!,
                  widget.awayScore!,
                  betWinner: a['winner'],
                  actualWinner: widget.winner,
                );
              }
              int pointsB = 0;
              if (b['homeScore'] != null && b['awayScore'] != null) {
                pointsB = calculatePoints(
                  b['homeScore'],
                  b['awayScore'],
                  widget.homeScore!,
                  widget.awayScore!,
                  betWinner: b['winner'],
                  actualWinner: widget.winner,
                );
              }

              if (pointsB != pointsA) {
                return pointsB.compareTo(pointsA);
              }
              return (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
            });
          }
        } else {
          otherUsersBetsData = []; // Ensure otherUsersBetsData is reset if not present
        }
        setState(() {}); // Update the UI with the fetched data
      } else {
        print('Failed to load match bets. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching match bets: $e');
    }
  }
  int calculatePoints(int betHomeScore, int betAwayScore, int actualHomeScore, int actualAwayScore, {int? betWinner, int? actualWinner}) {
    int points = 0;

    if (widget.isGroupStage) {
      // Original logic for group stage
      // Check for correct winner or draw
      if ((betHomeScore > betAwayScore && actualHomeScore > actualAwayScore) ||
          (betHomeScore < betAwayScore && actualHomeScore < actualAwayScore) ||
          (betHomeScore == betAwayScore && actualHomeScore == actualAwayScore)) {
        points += 1;
      }

      // Check for correct goal difference
      if ((betHomeScore - betAwayScore) == (actualHomeScore - actualAwayScore)) {
        points += 1; // This makes it 2 if winner was also correct
      } else if (points == 1 && (betHomeScore - betAwayScore) != (actualHomeScore - actualAwayScore)) {
        // If only winner was correct, but not goal difference, points remain 1.
      }

      // Check for exact score
      if (betHomeScore == actualHomeScore && betAwayScore == actualAwayScore) {
        points = 5; // Overrides previous points to be exactly 5
      }
    } else {
      // New logic for non-group stage
      // Check for correct winner
      if (betWinner != null && actualWinner != null && betWinner == actualWinner) { // betWinner is int (0 or 1), actualWinner is int (0 or 1)
        points += 2;
      }

      // Check for exact score
      if (betHomeScore == actualHomeScore && betAwayScore == actualAwayScore) {
        // If winner was also correct, total is 2 + 4 = 6.
        // If winner was not correct, but score is, this adds 4.
        points += 4;
      }
    }
    return points;
  }

  Future<void> submitBet(String homeScore, String awayScore, int? winner) async {
    final url = Uri.parse('https://obstawiator.pages.dev/API/BetMatch');
    try {
      final body = json.encode({
        'matchID': widget.matchID,
        'ID': main.userID,
        'sessionToken': main.sessionToken,
        'homeScore': int.tryParse(homeScore),
        'awayScore': int.tryParse(awayScore),
        'winner': winner
      });
      print('Submitting bet with body: $body'); // Print the body here
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": main.sessionToken ?? "",
        },
        body: body,
      );
      if (response.statusCode == 201) {
        print('Bet placed successfully');
        if (mounted) {
          _showSuccessConfirmation();
        }
        fetchMatchBets(); // Refresh bets after successful submission
      } else {
        final responseBody = json.decode(response.body);
        final errorMessage = responseBody['message'] ?? 'Failed to place bet. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error placing bet: $e');
    }
  }

  void _showSuccessConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 1), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        return Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Zakład przyjęty!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none, color: Colors.black),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // State variable to hold the selected winner
  int? _selectedWinner; // null: no winner, 0: host, 1: guest



  void placeBet(BuildContext context) {
    print("Placing bet for match ID: ${widget.matchID}");

    // Use current bet values if they exist, otherwise start at 0
    int dialogHomeScore = userBetData?['homeScore'] ?? 0;
    int dialogAwayScore = userBetData?['awayScore'] ?? 0;
    int? dialogSelectedWinner = userBetData?['winner'] ?? _selectedWinner;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.only(top: 16),
          title: Center(
            child: Text(
              'Obstaw wynik',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              void updateWinnerBasedOnScore() {
                if (dialogHomeScore > dialogAwayScore) {
                  setState(() => dialogSelectedWinner = 0);
                } else if (dialogAwayScore > dialogHomeScore) {
                  setState(() => dialogSelectedWinner = 1);
                }
              }

              Widget buildScoreStepper(String label, String flag, int score, Function(int) onUpdate) {
                final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
                final Color minusColor = isDarkMode ? Colors.red[300]! : Colors.redAccent;
                final Color plusColor = isDarkMode ? Colors.green[300]! : Colors.green;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(flag, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.remove_circle, size: 32, color: minusColor),
                            onPressed: score > 0 ? () {
                              setState(() {
                                onUpdate(score - 1);
                                if (!widget.isGroupStage) updateWinnerBasedOnScore();
                              });
                            } : null,
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              score.toString(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.add_circle, size: 32, color: plusColor),
                            onPressed: () {
                              setState(() {
                                onUpdate(score + 1);
                                if (!widget.isGroupStage) updateWinnerBasedOnScore();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              Widget buildWinnerButton(String label, String flag, int index) {
                final bool isSelected = dialogSelectedWinner == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => dialogSelectedWinner = index),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSelected ? 1.0 : 0.4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(flag, style: const TextStyle(fontSize: 16)),
                                if (isSelected) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.trending_up, size: 16, color: Colors.green),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (!widget.isGroupStage) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Wybierz wynik (90 min) oraz drużynę, która awansuje.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                    buildScoreStepper(widget.host, getFlag(widget.host), dialogHomeScore, (val) => dialogHomeScore = val),
                    const SizedBox(height: 8),
                    buildScoreStepper(widget.guest, getFlag(widget.guest), dialogAwayScore, (val) => dialogAwayScore = val),
                    if (!widget.isGroupStage) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Kto awansuje dalej?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          buildWinnerButton(widget.host, getFlag(widget.host), 0),
                          const SizedBox(width: 8),
                          buildWinnerButton(widget.guest, getFlag(widget.guest), 1),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: <Widget>[
            TextButton(
              child: Text('Anuluj', style: TextStyle(color: Colors.grey[600])),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text('Zatwierdź'),
              onPressed: () {
                if (!widget.isGroupStage && dialogSelectedWinner == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Musisz wybrać zwycięzcę meczu (awans).'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                submitBet(dialogHomeScore.toString(), dialogAwayScore.toString(), dialogSelectedWinner);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String getFlag(String countryName) {
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

  @override
  Widget build(BuildContext context) {
    final String? userBet = userBetData != null
        ? '${userBetData?['homeScore'] ?? '-'} : ${userBetData?['awayScore'] ?? '-'}'
            '${!widget.isGroupStage && userBetData?['winner'] != null ? ' (Zwycięzca: ${userBetData!['winner'] == 0 ? widget.host : widget.guest})' : ''}'
        : null; // Null if no bet, otherwise the bet string.

    String? userWinnerDisplay;
    if (!widget.isGroupStage && userBetData != null && userBetData!['winner'] != null) {
      userWinnerDisplay = userBetData!['winner'] == 0 ? widget.host : widget.guest;
    }

    final timeToMatch = widget.matchStart.difference(DateTime.now());
    // Show warning if no bet is placed and the match is less than 2 hours away, but not if it's less than 0 minutes away
    final bool showWarning = userBet == null && timeToMatch.inHours < 2 && timeToMatch.inMinutes > 0;
    final bool isExpired = widget.homeScore != null;

    return Scaffold(
      appBar: const main.ObstawiatorAppBar(),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 16.0), // Keep bottom padding, remove others for Container
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0, bottom: 24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DefaultTextStyle(
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(getFlag(widget.host), style: const TextStyle(fontSize: 40)),
                                const SizedBox(height: 8),
                                Text(
                                  widget.host,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.homeScore ?? '-'} : ${widget.awayScore ?? '-'}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFD700), // Gold score
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(getFlag(widget.guest), style: const TextStyle(fontSize: 40)),
                                const SizedBox(height: 8),
                                Text(
                                  widget.guest,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          DateFormat('EEEE, dd MMMM HH:mm', 'pl_PL').format(widget.matchStart),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center( // Center the Tile horizontally
              child: Tooltip(
                message: isExpired ? 'Obstawianie zakończone' : 'Kliknij, aby dodać/zmienić swój zakład',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card( // Use Card for tile appearance
                      elevation: 4.0, // Add some shadow for depth
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Added rounded corners
                      child: InkWell( // Make the Card tappable
                        onTap: isExpired ? null : () => placeBet(context),
                        borderRadius: BorderRadius.circular(8.0), // Ensure hover effect respects rounded corners
                        child: Opacity(
                          opacity: isExpired ? 0.7 : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0), // Padding inside the tile
                            child: Row(
                              mainAxisSize: MainAxisSize.min, // Row takes minimum space needed
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'Mój zakład: ${userBetData != null ? (userBetData!['homeScore']?.toString() ?? '-') + ' : ' + (userBetData!['awayScore']?.toString() ?? '-') : "Nie obstawiono"}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    if (userWinnerDisplay != null) Text('Zwycięzca: $userWinnerDisplay', style: Theme.of(context).textTheme.titleSmall),
                                  ],
                                ),
                                if (showWarning)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.warning, color: Colors.red, size: 24.0),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.homeScore != null && widget.awayScore != null && userBetData != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Card(
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Zdobyte punkty: ${calculatePoints(userBetData!['homeScore'], userBetData!['awayScore'], widget.homeScore!, widget.awayScore!, betWinner: userBetData!['winner'], actualWinner: widget.winner)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            Text('Zakłady innych użytkowników:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (widget.betVisible == 1 ||
                (widget.betVisible == 0 &&
                    widget.matchStart.isBefore(DateTime.now())))
              Expanded(
                child: SingleChildScrollView( // Added SingleChildScrollView for vertical scrolling if needed
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding
                    child: Table(
                      columnWidths: {
                        0: FlexColumnWidth(),
                        1: FixedColumnWidth(100.0), // Width for bet
                        if (!widget.isGroupStage) 2: FlexColumnWidth(), // Width for winner, adjusted to FlexColumnWidth
                        if (widget.homeScore != null && widget.isGroupStage) 2: FixedColumnWidth(90.0) // Width for points, if shown and group stage
                      },
                      border: TableBorder.all(color: Colors.grey.shade300, width: 1), // Add border to table
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer), // Adaptive header background
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Użytkownik', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondaryContainer)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Zakład', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondaryContainer), textAlign: TextAlign.center),
                            ),
                            if (!widget.isGroupStage)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Zwycięzca', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondaryContainer), textAlign: TextAlign.center),
                              ),
                            if (widget.homeScore != null) // Conditionally add Points cell
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Punkty', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondaryContainer), textAlign: TextAlign.center),
                              ),
                          ],
                        ),
                        ...otherUsersBetsData.map((betData) {
                          final name = betData['name'] as String;
                          final homeScore = betData['homeScore'] as int?;
                          final awayScore = betData['awayScore'] as int?;
                          final winner = betData['winner'] as int?;
                          int? calculatedPoints;
                          if (widget.homeScore != null && widget.awayScore != null && homeScore != null && awayScore != null) {
                            calculatedPoints = calculatePoints(
                              homeScore,
                              awayScore,
                              widget.homeScore!,
                              widget.awayScore!,
                              betWinner: winner, // Pass the integer winner directly
                              actualWinner: widget.winner,
                            );
                          }

                          final betDisplay = '${homeScore ?? '-'} : ${awayScore ?? '-'}';
                          String? winnerDisplay;
                          if (!widget.isGroupStage && winner != null) {
                            winnerDisplay = winner == 0 ? widget.host : widget.guest;
                          }

                          return TableRow(
                            // decoration: name == globals.userName ? BoxDecoration(color: Colors.lightBlue[50]) : null, // Highlight current user's row
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(name),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(betDisplay, textAlign: TextAlign.center),
                              ),
                              if (!widget.isGroupStage)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(winnerDisplay ?? '-', textAlign: TextAlign.center),
                                ),
                              if (widget.homeScore != null) // Conditionally add Points cell
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(calculatedPoints?.toString() ?? '-', textAlign: TextAlign.center),
                                ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Zakłady innych użytkowników będą widoczne po rozpoczęciu meczu.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
                        ),
      ),
    );
  }
}
