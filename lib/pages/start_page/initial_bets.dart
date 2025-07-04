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

  Future<void> _submitBets() async
  {
    var headers =
    {
      'Content-Type': 'application/json'
    };
    var url = Uri.parse("https://obstawiator.pages.dev/API/InitialBets");
    var request = http.Request('POST', url);
    request.body = json.encode({"ID": main.userID, "championBet": _championBet, "topScorerBet": _topScorerBet});
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    var result = await response.stream.bytesToString();
    var resultJSON = json.decode(result);
    if(response.statusCode == 201)
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultJSON['message'])),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const main_table.MyHomePage()),
      );
    }
    else
    {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultJSON['message'])),
      );
    }
    print('Champion Bet: $_championBet');
    print('Top Scorer Bet: $_topScorerBet');
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: main.titleBar(context),
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
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Kto zostanie mistrzem?',
                  border: OutlineInputBorder(),
                ),
                validator: (value)
                {
                  if (value == null || value.isEmpty)
                  {
                    return 'Proszę podać swojego faworyta do mistrzostwa';
                  }
                  return null;
                },
                onSaved: (value) {
                  _championBet = value;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Kto zostanie królem strzelców?',
                  border: OutlineInputBorder(),
                ),
                validator: (value)
                {
                  if (value == null || value.isEmpty) {
                    return 'Proszę podać swojego faworyta do tytułu króla strzelców';
                  }
                  return null;
                },
                onSaved: (value)
                {
                  _topScorerBet = value;
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () async
                  {
                    if (_formKey.currentState!.validate())
                    {
                      _formKey.currentState!.save();
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