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
  MatchBets({
    super.key,
    required this.matchID,
    required this.host,
    required this.guest,
    required this.matchStart,
    this.homeScore,
    this.awayScore,
    required this.betVisible,
  })  : otherUsersBetsData = [],
        userBetData = null;

  Map<String, dynamic>? userBetData;
  List<Map<String, dynamic>> otherUsersBetsData = [];

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
        headers: {"Content-Type": "application/json"},
        body: json.encode({'matchID': widget.matchID, 'ID': main.userID}),
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
  int calculatePoints(int betHomeScore, int betAwayScore, int actualHomeScore, int actualAwayScore) {
    int points = 0;

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
      // This else if is to clarify, but not strictly needed if points are just additive.
    }

    // Check for exact score
    if (betHomeScore == actualHomeScore && betAwayScore == actualAwayScore) {
      points = 5; // Overrides previous points to be exactly 5
    }
    return points;
  }

  Future<void> submitBet(String homeScore, String awayScore) async {
    final url = Uri.parse('https://obstawiator.pages.dev/API/BetMatch');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'matchID': widget.matchID,
          'ID': main.userID,
          'homeScore': int.tryParse(homeScore),
          'awayScore': int.tryParse(awayScore),
        }),
      );
      if (response.statusCode == 201) {
        print('Bet placed successfully');
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

  void placeBet(BuildContext context) {
    print("Placing bet for match ID: ${widget.matchID}");

    // Example of how you might show a dialog to get input:
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController homeScoreController = TextEditingController();
        TextEditingController awayScoreController = TextEditingController();
        return AlertDialog(
          title: Text('Obstaw zakład'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: homeScoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Wynik ${widget.host}'),
              ),
              TextField(
                controller: awayScoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Wynik ${widget.guest}'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Anuluj'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Zatwierdź'),
              onPressed: () {
                final homeScore = homeScoreController.text;
                final awayScore = awayScoreController.text;
                if (homeScore.isNotEmpty && awayScore.isNotEmpty) {
                  submitBet(homeScore, awayScore);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
    fetchMatchBets(); // Keep this call if you also want to refresh on placeBet
  }  @override
  Widget build(BuildContext context) {
    final String? userBet = userBetData != null
        ? '${userBetData?['homeScore'] ?? '-'} : ${userBetData?['awayScore'] ?? '-'}'
        : null; // Null if no bet, otherwise the bet string.

    final timeToMatch = widget.matchStart.difference(DateTime.now());
    // Show warning if no bet is placed and the match is less than 2 hours away, but not if it's less than 0 minutes away
    final bool showWarning = userBet == null && timeToMatch.inHours < 2 && timeToMatch.inMinutes > 0;
    return Scaffold(
      appBar: main.titleBar(context),
      bottomNavigationBar: main.navigationBar(context),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 16.0), // Keep bottom padding, remove others for Container
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: double.infinity, // Make Container take full width
              padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 12.0), // Apply padding here
              decoration: BoxDecoration(
                color: Colors.blue[700], // Darker blue color
                // No border radius for top and side coverage
                // borderRadius: BorderRadius.circular(8.0),
              ),
              child: DefaultTextStyle(
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                          children: <TextSpan>[
                            TextSpan(text: '${widget.host} '),
                            TextSpan(
                              text: '${widget.homeScore ?? '-'} : ${widget.awayScore ?? '-'}',
                              style: TextStyle(color: Colors.amberAccent[100]), // Different color for scores
                            ),
                            TextSpan(text: ' ${widget.guest}'),
                          ],
                        ),
                        // Text(
                        //   // '$host vs $guest',
                        //   '$host ${homeScore ?? '-'} : ${awayScore ?? '-'} $guest',
                        //
                        //   style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                        // ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM HH:mm').format(widget.matchStart),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center( // Center the Tile horizontally
              child: Tooltip(
                message: 'Kliknij, aby dodać/zmienić swój zakład',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card( // Use Card for tile appearance
                      elevation: 4.0, // Add some shadow for depth
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Added rounded corners
                      child: InkWell( // Make the Card tappable
                        onTap: () => placeBet(context),
                        borderRadius: BorderRadius.circular(8.0), // Ensure hover effect respects rounded corners
                        child: Padding(
                          padding: const EdgeInsets.all(16.0), // Padding inside the tile
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // Row takes minimum space needed
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Mój zakład: ${userBet ?? "Nie obstawiono"}', // Display user's bet or "Not placed"
                                style: Theme.of(context).textTheme.titleMedium,
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
                    if (widget.homeScore != null && widget.awayScore != null && userBetData != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Card(
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Zdobyte punkty: ${calculatePoints(userBetData!['homeScore'], userBetData!['awayScore'], widget.homeScore!, widget.awayScore!)}',
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
                        if (widget.homeScore != null) 2: FixedColumnWidth(80.0), // Width for points, if shown
                      },
                      border: TableBorder.all(color: Colors.grey.shade300, width: 1), // Add border to table
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.blueGrey[50]), // Header row background
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Użytkownik', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Zakład', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            ),
                            if (widget.homeScore != null) // Conditionally add Points cell
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Punkty', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              ),
                          ],
                        ),
                        ...otherUsersBetsData.map((betData) {
                          final name = betData['name'] as String;
                          final homeScore = betData['homeScore'] as int?;
                          final awayScore = betData['awayScore'] as int?;
                          int? calculatedPoints;
                          if (widget.homeScore != null && widget.awayScore != null && homeScore != null && awayScore != null) {
                            calculatedPoints = calculatePoints(
                              homeScore,
                              awayScore,
                              widget.homeScore!,
                              widget.awayScore!,
                            );
                          }

                          final betDisplay = '${homeScore ?? '-'} : ${awayScore ?? '-'}';
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