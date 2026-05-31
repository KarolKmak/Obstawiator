import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:obstawiator/main.dart' as main;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:obstawiator/pages/main_table/main_table.dart' as main_table;

class InitialBets extends StatefulWidget
{
  const InitialBets({super.key});

  @override
  State<InitialBets> createState() => _InitialBetsState();
}

class _InitialBetsState extends State<InitialBets>
{
  final _formKey = GlobalKey<FormState>();
  String? _championBet;
  String? _topScorerBet;
  List<String> _championSuggestions = [];
  List<String> _topScorerSuggestions = [];

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': main.sessionToken ?? '',
    };
    var url = Uri.parse("https://obstawiator.pages.dev/API/GetMainTable");
    try {
      var response = await http.post(
        url,
        headers: headers,
        body: json.encode({"ID": main.userID}),
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body) as List;
        setState(() {
          _championSuggestions = jsonData
              .map((item) => item['championBet'] as String?)
              .where((s) => s != null && s != 'empty' && s.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();
          _topScorerSuggestions = jsonData
              .map((item) => item['topScorerBet'] as String?)
              .where((s) => s != null && s != 'empty' && s.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching suggestions: $e");
    }
  }

  Future<void> _submitBets() async {
    var url = Uri.parse("https://obstawiator.pages.dev/API/InitialBets");
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': main.sessionToken ?? '',
        },
        body: json.encode({
          "ID": main.userID,
          "championBet": _championBet,
          "topScorerBet": _topScorerBet
        }),
      );

      var resultJSON = json.decode(response.body);
      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultJSON['message'])),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const main_table.MyHomePage()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultJSON['message'])),
        );
      }
    } catch (e) {
      if (kDebugMode) print("Submit initial bets error: $e");
    }
    print('Champion Bet: $_championBet');
    print('Top Scorer Bet: $_topScorerBet');
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: const main.ObstawiatorAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Postaw swoje typy na turniej!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _championSuggestions;
                  }
                  return _championSuggestions.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _championBet = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Kto zostanie mistrzem?',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _championBet = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Proszę podać swojego faworyta do mistrzostwa';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _topScorerSuggestions;
                  }
                  return _topScorerSuggestions.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _topScorerBet = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Kto zostanie królem strzelców?',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _topScorerBet = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Proszę podać swojego faworyta do tytułu króla strzelców';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () async
                  {
                    if (_formKey.currentState!.validate())
                    {
                      // Process the bets (e.g., save to database, navigate to next screen)
                      await _submitBets();
                    }
                  },
                  child: const Text('Zatwierdź typy'),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: ()
                  {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const main_table.MyHomePage()));
                  },
                  child: const Text('Pomiń typowanie'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}