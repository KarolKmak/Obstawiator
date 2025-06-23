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
  MatchBets({
    super.key,
    required this.matchID,
    required this.host,
    required this.guest,
    required this.matchStart,
    this.homeScore,
    this.awayScore,
  })  : otherUsersBetsData = [],
        userBetData = null; // Removed const from constructor

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
    fetchMatchBets(); // Call fetchMatchBets when the widget is initialized
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
          title: Text('Place Your Bet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: homeScoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Home Score'),
              ),
              TextField(
                controller: awayScoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Away Score'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Submit'),
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
    // Show warning if no bet is placed and the match is less than 2 hours away, but not if it's less than 10 minutes away
    final bool showWarning = userBet == null && timeToMatch.inHours < 2 && timeToMatch.inMinutes > 10;
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
                message: 'Click to add/change your bet', // Tooltip message
                child: Card( // Use Card for tile appearance
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
                            'My Bet: ${userBet ?? "Not placed"}', // Display user's bet or "Not placed"
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
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            Text('Other Users\' Bets:', style: Theme.of(context).textTheme.titleMedium),
            Expanded(
              child: ListView.builder(
                itemCount: otherUsersBetsData.length,
                itemBuilder: (context, index) {
                  final betData = otherUsersBetsData[index];
                  final name = betData['name'] as String;
                  final homeScore = betData['homeScore'] as int?;
                  final awayScore = betData['awayScore'] as int?;
                  final betDisplay = '$name: ${homeScore ?? '-'} : ${awayScore ?? '-'}';
                  return Align( // Align the Card to the center
                    alignment: Alignment.center,
                    child: Card(
                      elevation: 2.0,
                      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: Padding( // Add padding inside the Card
                        padding: const EdgeInsets.all(8.0), // Adjust padding as needed
                        child: Text(betDisplay, textAlign: TextAlign.center),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
                        ),
      ),
    );
  }
}