import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:obstawiator/main.dart' as main;
import 'package:intl/intl.dart';
import 'package:obstawiator/pages/matches/match_list.dart' show Match;

class UserBetsView extends StatefulWidget {
  final int targetUserID;
  const UserBetsView({super.key, required this.targetUserID});

  @override
  State<UserBetsView> createState() => _UserBetsViewState();
}

class _UserBetsViewState extends State<UserBetsView> {
  String _userName = "";
  List<dynamic> _bets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserBets();
  }

  Future<void> _fetchUserBets() async {
    try {
      final response = await http.post(
        Uri.parse('https://obstawiator.pages.dev/API/GetUserBets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': main.sessionToken ?? '',
        },
        body: jsonEncode({
          'ID': main.userID,
          'sessionToken': main.sessionToken,
          'targetUserID': widget.targetUserID,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userName = data['userName'];
          _bets = data['bets'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nie udało się pobrać zakładów użytkownika')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd połączenia')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? "Ładowanie..." : "Typy: $_userName"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bets.isEmpty
              ? const Center(child: Text("Brak dostępnych zakładów"))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _bets.length,
                  itemBuilder: (context, index) {
                    final bet = _bets[index];
                    return _buildBetCard(bet);
                  },
                ),
    );
  }

  Widget _buildBetCard(dynamic bet) {
    final bool isFinished = bet['matchFinished'] == 1 || bet['matchFinished'] == true;
    final bool hasBet = bet['betHome'] != null;
    final DateTime matchDate = DateTime.fromMillisecondsSinceEpoch(bet['matchStart'], isUtc: true).toLocal();
    final bool isGroupStage = bet['isGroupStage'] == true || bet['isGroupStage'] == 1 || bet['isGroupStage'] == 'true';
    
    String? winnerDisplay;
    if (!isGroupStage && hasBet && bet['betWinner'] != null) {
      winnerDisplay = bet['betWinner'] == 0 ? bet['host'] : bet['guest'];
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd/MM HH:mm', 'pl_PL').format(matchDate),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      isGroupStage ? "Faza grupowa" : "Faza pucharowa",
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                if (isFinished && bet['points'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "+${bet['points']} pkt",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(Match.getFlag(bet['host']), style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Match.getShortName(bet['host']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    isFinished ? "${bet['actualHome']} : ${bet['actualAway']}" : "vs",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          Match.getShortName(bet['guest']),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(Match.getFlag(bet['guest']), style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Zakład: ", style: TextStyle(color: Colors.grey)),
                Column(
                  children: [
                    Text(
                      hasBet ? "${bet['betHome']} : ${bet['betAway']}" : "Brak typu",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasBet ? null : Colors.red,
                      ),
                    ),
                    if (winnerDisplay != null)
                      Text(
                        "Awans: $winnerDisplay",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
