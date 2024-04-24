import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cody Tour Guide',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 12, 109, 17)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Cody Tour Guide'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _aiResponse = '';
  final bool _isLoading = false;

  Future<void> _sendMessageToAI() async {
    final response = await sendToOpenAI(_controller.text);
    setState(() {
      _aiResponse = response;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Ask a question',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.question_answer),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendMessageToAI,
              icon: const Icon(Icons.send),
              label: const Text('Ask your question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800], 
                foregroundColor: Colors.white, 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                elevation: 5.0, 
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 24.0),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your guide says:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(_aiResponse),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> sendToOpenAI(String message) async {
  final apiKey = dotenv.env['OPENAI_API_KEY'];
  if (apiKey == null) {
    throw Exception(
        'API key not found. Ensure OPENAI_API_KEY is set in your .env file.');
  }

  final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  final body = json.encode({
    'model': 'gpt-3.5-turbo',
    'messages': [
      {'role': 'system', 'content': 'You are an a helpful tour guide for Cody, Wyoming and Yellowstone and the East Gate Entrance. You help by answering tourist questions.'},
      {'role': 'user', 'content': message},
    ],
  });

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['choices'][0]['message']['content'];
  } else {
    throw Exception(
        'Failed to fetch AI response: ${response.statusCode} ${response.body}');
  }
}
