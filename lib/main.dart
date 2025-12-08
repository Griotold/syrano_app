import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  bool _isInitializing = true; // 익명 로그인 중인지
  bool _isLoading = false;     // 문장 생성 요청 중인지
  String? _userId;
  bool _isPremium = false;
  List<String> _suggestions = [];

  static const String _baseUrl =
      'https://syrano-be-ekalw.ondigitalocean.app';

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  @override
  void dispose() {
    _situationController.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('user_id');
    final savedPremium = prefs.getBool('is_premium') ?? false;

    if (savedId != null) {
      setState(() {
        _userId = savedId;
        _isPremium = savedPremium;
        _isInitializing = false;
      });
      return;
    }

    try {
      final url = Uri.parse('$_baseUrl/auth/anonymous');

      // 스웨거 기준: body user_id가 없으면 새 익명 유저 생성
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}), // 빈 JSON
      );

      debugPrint(
          'Anon login response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final id = data['user_id'] as String;
        final isPremium = (data['is_premium'] as bool?) ?? false;

        await prefs.setString('user_id', id);
        await prefs.setBool('is_premium', isPremium);

        setState(() {
          _userId = id;
          _isPremium = isPremium;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('익명 로그인 실패: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('익명 로그인 중 오류가 발생했어: $e'),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _generateSuggestionsFromApi() async {
    final text = _situationController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상황을 먼저 적어줘!')),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('로그인 정보가 없어요. 잠시 후 다시 시도해줘!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _suggestions = [];
    });

    try {
      final url = Uri.parse('$_baseUrl/rizz/generate');

      final body = jsonEncode({
        'mode': 'conversation',
        'conversation': text,
        'platform': 'kakao',
        'relationship': 'first_meet',
        'style': 'banmal',
        'tone': 'friendly',
        'num_suggestions': 3,
        'user_id': _userId,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('API response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['suggestions'] as List?) ?? [];

        setState(() {
          _suggestions = list.map((e) => e.toString()).toList();
        });
      } else {
        // 백엔드에서 detail을 내려주면 메시지도 같이 보여주기
        String message = '서버 오류: ${response.statusCode}';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['detail'] != null) {
            message =
                '$message\n${data['detail'].toString()}';
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('요청 중 오류가 발생했어: $e'),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isInitializing || _isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('시라노'),
        centerTitle: true,
        actions: [
          if (_isPremium)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(
                  'PREMIUM',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isInitializing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('익명 로그인 중...'),
                    ],
                  ),
                ),
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
                  onPressed: isBusy ? null : _generateSuggestionsFromApi,
                  child: _isInitializing
                      ? const Text('로그인 중...')
                      : (_isLoading
                          ? const CircularProgressIndicator()
                          : const Text('문장 만들어줘')),
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
                            margin:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(s),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  // TODO: 클립보드 복사
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