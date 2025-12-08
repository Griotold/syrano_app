class RizzResponse {
  final List<String> suggestions;

  const RizzResponse({required this.suggestions});

  factory RizzResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['suggestions'] as List?) ?? [];
    return RizzResponse(
      suggestions: list.map((e) => e.toString()).toList(),
    );
  }
}