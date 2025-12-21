import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user_session.dart';
import '../models/rizz_response.dart';

class ApiClient {
  static const String _baseUrl =
      'https://syrano-be-sjtv2.ondigitalocean.app';

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path, {Map<String, String>? query}) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
  }

  /// POST /auth/anonymous
  Future<UserSession> anonymousLogin({String? existingUserId}) async {
    final url = _uri('/auth/anonymous');

    final body = existingUserId == null
        ? <String, dynamic>{}
        : <String, dynamic>{'user_id': existingUserId};

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'anonymousLogin failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return UserSession.fromJson(data);
  }

  /// GET /auth/me/subscription?user_id=...
  Future<UserSession> fetchSubscription(String userId) async {
    final url = _uri(
      '/auth/me/subscription',
      query: {'user_id': userId},
    );

    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception(
          'fetchSubscription failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return UserSession.fromJson(data);
  }

  /// POST /billing/subscribe
  Future<void> subscribeMonthly(String userId) async {
    final url = _uri('/billing/subscribe');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'plan_type': 'monthly',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'subscribeMonthly failed: ${response.statusCode} ${response.body}');
    }
  }

  /// POST /rizz/generate
  Future<RizzResponse> generateRizz({
    required String conversation,
    required String userId,
    String mode = 'conversation',
    String platform = 'kakao',
    String relationship = 'first_meet',
    String style = 'banmal',
    String tone = 'friendly',
    int numSuggestions = 3,
  }) async {
    final url = _uri('/rizz/generate');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mode': mode,
        'conversation': conversation,
        'platform': platform,
        'relationship': relationship,
        'style': style,
        'tone': tone,
        'num_suggestions': numSuggestions,
        'user_id': userId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'generateRizz failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return RizzResponse.fromJson(data);
  }

  /// POST /rizz/analyze-image - 이미지 업로드 및 OCR + 추천 생성
  /// 백엔드에서 OCR과 LLM 처리를 모두 수행
  Future<RizzResponse> analyzeImage({
    required String imagePath,
    required String userId,
    String platform = 'kakao',
    String relationship = 'first_meet',
    String style = 'banmal',
    String tone = 'friendly',
    int numSuggestions = 3,
  }) async {
    final url = _uri('/rizz/analyze-image');

    final request = http.MultipartRequest('POST', url);

    // 이미지 파일 추가
    request.files.add(
      await http.MultipartFile.fromPath('image', imagePath),
    );

    // 메타데이터 추가
    request.fields['user_id'] = userId;
    request.fields['platform'] = platform;
    request.fields['relationship'] = relationship;
    request.fields['style'] = style;
    request.fields['tone'] = tone;
    request.fields['num_suggestions'] = numSuggestions.toString();

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
          'analyzeImage failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return RizzResponse.fromJson(data);
  }
}