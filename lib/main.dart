import 'package:flutter/material.dart';

void main() {
  runApp(const SyranoApp());
}

class SyranoApp extends StatelessWidget {
  const SyranoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '시라노',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _situationController = TextEditingController();
  bool _isLoading = false;
  List<String> _suggestions = [];

  @override
  void dispose() {
    _situationController.dispose();
    super.dispose();
  }

  void _generateDummySuggestions() {
    final text = _situationController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상황을 먼저 적어줘!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _suggestions = [];
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isLoading = false;
        _suggestions = [
          '어제 반가웠어! 오늘 하루는 어떻게 보내고 있어?',
          '어제 얘기하다 보니 시간 순삭이었어 ㅋㅋ 잘 들어가긴 했지?',
          '어제 재밌었어 :) 다음에 또 볼 수 있으면 좋겠다.',
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('시라노'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '상대에게 보내고 싶은 상황을 적어줘',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _situationController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '예) 어제 소개팅 했는데 오늘 첫 연락 뭐라고 보낼까?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateDummySuggestions,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('문장 만들어줘'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '추천 문장',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _suggestions.isEmpty
                    ? const Center(
                        child: Text(
                          '아직 추천이 없어.\n상황을 적고 버튼을 눌러봐!',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final s = _suggestions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(s),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  // TODO: 나중에 클립보드 복사 붙이기
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}