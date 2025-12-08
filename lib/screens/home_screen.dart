import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_session.dart';
import '../services/api_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _situationController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  bool _isInitializing = true;
  bool _isLoading = false;
  UserSession? _session;
  List<String> _suggestions = [];

  String? get _userId => _session?.userId;
  bool get _isPremium => _session?.isPremium ?? false;

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
    final savedUserId = prefs.getString('user_id');
    final savedPremium = prefs.getBool('is_premium') ?? false;

    if (savedUserId != null) {
      setState(() {
        _session = UserSession(
          userId: savedUserId,
          isPremium: savedPremium,
        );
        _isInitializing = false;
      });
      return;
    }

    try {
      final newSession = await _apiClient.anonymousLogin();

      await prefs.setString('user_id', newSession.userId);
      await prefs.setBool('is_premium', newSession.isPremium);

      setState(() {
        _session = newSession;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('익명 로그인 실패: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _generateSuggestions() async {
    final text = _situationController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상황을 먼저 적어줘!')),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보를 불러오지 못했어. 다시 시도해줘!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _suggestions = [];
    });

    try {
      final res = await _apiClient.generateRizz(
        conversation: text,
        userId: _userId!,
      );

      setState(() {
        _suggestions = res.suggestions;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문장 생성 중 오류: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSubscription() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('user_id가 없어요. 다시 시도해줘!')),
      );
      return;
    }

    try {
      final session = await _apiClient.fetchSubscription(_userId!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', session.isPremium);

      setState(() {
        _session = session;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            session.isPremium
                ? '프리미엄 구독 상태입니다 ✨'
                : '프리미엄이 아닌 상태입니다.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구독 조회 중 오류: $e')),
      );
    }
  }

  Future<void> _subscribeMonthly() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('user_id가 없어요. 다시 시도해줘!')),
      );
      return;
    }

    try {
      await _apiClient.subscribeMonthly(_userId!);
      await _refreshSubscription();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구독 신청 중 오류: $e')),
      );
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
                  onPressed: isBusy ? null : _generateSuggestions,
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

              const SizedBox(height: 8),
              const Divider(),
              const Text(
                '테스트용 구독 제어',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _refreshSubscription,
                      child: const Text('구독 상태 새로고침'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _subscribeMonthly,
                      child: const Text('월 구독 신청'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}