import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/attendee_models.dart';

class AttendeesService {
  static const String _baseUrl = 'https://eventbuster.com/api/attendees';

  Future<AttendeesPayload> fetchAttendees({
    required int page,
    required int limit,
    required String eventId,
    required String token,
  }) async {
    final Uri url = Uri.parse(
      '$_baseUrl?page=$page&limit=$limit&eventId=$eventId',
    );

    final http.Response response = await http.get(
      url,
      headers: <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load attendees (${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected API response format');
    }

    return AttendeesPayload.fromJson(decoded);
  }
}
