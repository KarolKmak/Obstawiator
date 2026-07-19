import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:obstawiator/main.dart' as main;
import 'package:intl/intl.dart';
import 'package:obstawiator/pages/matches/match_list.dart' show Match;
import 'package:obstawiator/pages/matches/match_bets.dart';

class UserBetsView extends StatefulWidget {
  final int targetUserID;
  const UserBetsView({super.key, required this.targetUserID});

  @override
  State<UserBetsView> createState() => _UserBetsViewState();
}

class _UserBetsViewState extends State<UserBetsView> {
  String _userName = "";
  List<dynamic> _bets = [];
  Map<String, dynamic>? _longTermBets;
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
          _longTermBets = data['longTermBets'];
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
          : _bets.isEmpty && _longTermBets == null
              ? const Center(child: Text("Brak dostępnych zakładów"))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 100.0),
                  itemCount: _bets.length + (_longTermBets != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_longTermBets != null && index == 0) {
                      return _buildLongTermBetCard(_longTermBets!);
                    }
                    final bet = _bets[_longTermBets != null ? index - 1 : index];
                    return _buildBetCard(bet);
                  },
                ),
    );
  }

  Widget _buildLongTermBetCard(Map<String, dynamic> data) {
    final bool isSettled = data['isSettled'] == true;
    
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Typy Długoterminowe",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (isSettled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "+${data['totalPoints']} pkt",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            _buildLongTermRow(
              "Mistrz", 
              data['userChampion'], 
              data['actualChampion'], 
              data['championPoints'], 
              isSettled
            ),
            const SizedBox(height: 12),
            _buildLongTermRow(
              "Król Strzelców", 
              data['userTopScorer'], 
              data['actualTopScorer'], 
              data['topScorerPoints'], 
              isSettled
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLongTermRow(String label, String? userPick, String? actual, int points, bool isSettled) {
    final bool isCorrect = isSettled && userPick != null && actual != null && 
                          userPick.toLowerCase().trim() == actual.toLowerCase().trim();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                userPick ?? "brak typu",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: userPick == null ? Colors.red : null,
                ),
              ),
            ),
            if (isSettled)
              Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red.withOpacity(0.5),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "+$points pkt",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: points > 0 ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (isSettled && !isCorrect && actual != null)
          Text(
            "Rozstrzygnięcie: $actual",
            style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
          ),
      ],
    );
  }

  void _showPointBreakdown(dynamic bet) {
    final bool isFinished = bet['matchFinished'] == 1 || bet['matchFinished'] == true;
    if (!isFinished) return;

    final bool isGroupStage = bet['isGroupStage'] == true || bet['isGroupStage'] == 1 || bet['isGroupStage'] == 'true';
    final int betHome = bet['betHome'] ?? 0;
    final int betAway = bet['betAway'] ?? 0;
    final int? betWinner = bet['betWinner'];
    final int actualHome = bet['actualHome'] ?? 0;
    final int actualAway = bet['actualAway'] ?? 0;
    final int? actualWinner = bet['actualWinner'];

    List<Widget> breakdownItems = [];

    if (isGroupStage) {
      // 1. Rozstrzygnięcie (1 pkt)
      bool result = (betHome > betAway && actualHome > actualAway) ||
                   (betHome < betAway && actualHome < actualAway) ||
                   (betHome == betAway && actualHome == actualAway);
      breakdownItems.add(_buildBreakdownRow("Poprawne rozstrzygnięcie", result ? 1 : 0, result));

      // 2. Różnica bramek (+1 pkt = łącznie 2)
      bool diff = result && (betHome - betAway) == (actualHome - actualAway);
      breakdownItems.add(_buildBreakdownRow("Poprawna różnica bramek", diff ? 1 : 0, diff));

      // 3. Dokładny wynik (+3 pkt = łącznie 5)
      bool exactScore = diff && betHome == actualHome && betAway == actualAway;
      breakdownItems.add(_buildBreakdownRow("Dokładny wynik", exactScore ? 3 : 0, exactScore));
    } else {
      // Pucharowa
      // 1. Dokładny wynik (4 pkt)
      bool exactScore = betHome == actualHome && betAway == actualAway;
      breakdownItems.add(_buildBreakdownRow("Dokładny wynik (90 min)", exactScore ? 4 : 0, exactScore));

      // 2. Awans (2 pkt)
      bool winnerMatch = betWinner != null && actualWinner != null && betWinner == actualWinner;
      breakdownItems.add(_buildBreakdownRow("Wybór awansu", winnerMatch ? 2 : 0, winnerMatch));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Szczegóły punktacji",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "${bet['host']} vs ${bet['guest']}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ...breakdownItems,
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Suma punktów:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      "${bet['points'] ?? 0} pkt",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreakdownRow(String label, int points, bool success) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.cancel,
                color: success ? Colors.green : Colors.red.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 15)),
            ],
          ),
          Text(
            "+$points pkt",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: points > 0 ? Colors.green : Colors.grey,
            ),
          ),
        ],
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
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isFinished 
            ? () => _showPointBreakdown(bet) 
            : (widget.targetUserID == main.userID 
                ? () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchBets(
                          matchID: bet['matchID'],
                          host: bet['host'],
                          guest: bet['guest'],
                          matchStart: matchDate,
                          homeScore: bet['actualHome'],
                          awayScore: bet['actualAway'],
                          betVisible: bet['betVisible'] ?? 0,
                          isGroupStage: isGroupStage,
                          winner: bet['actualWinner'],
                        ),
                      ),
                    );
                    _fetchUserBets(); // Refresh after returning from MatchBets
                  }
                : null),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, dd/MM HH:mm', 'pl_PL').format(matchDate),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        isGroupStage ? "Faza grupowa" : "Faza pucharowa",
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  if (isFinished && bet['points'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "+${bet['points']} pkt",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(Match.getFlag(bet['host']), style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          Match.getShortName(bet['host']),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        Text(
                          isFinished ? "${bet['actualHome']} : ${bet['actualAway']}" : "vs",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                        if (isFinished && !isGroupStage && bet['actualWinner'] != null)
                          Text(
                            bet['actualWinner'] == 0 ? "awans: ${bet['host']}" : "awans: ${bet['guest']}",
                            style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(Match.getFlag(bet['guest']), style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          Match.getShortName(bet['guest']),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit_note, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text("Typ: $_userName ", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(
                      hasBet ? "${bet['betHome']} : ${bet['betAway']}" : "Brak typu",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: hasBet ? Theme.of(context).colorScheme.primary : Colors.red,
                      ),
                    ),
                    if (winnerDisplay != null)
                      Text(
                        " (Awans: $winnerDisplay)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
