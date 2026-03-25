import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event_models.dart';

class EventsService {
  static const String _myEventsUrl = 'https://eventbuster.com/api/events/my-events';
  static const String _organizerHomeUrl = 'https://eventbuster.com/organizer/home';

  Future<List<OrganizerEventSummary>> fetchMyEvents({
    required String token,
    int page = 1,
    int limit = 200,
  }) async {
    final Uri url = Uri.parse('$_myEventsUrl?page=$page&limit=$limit');

    final http.Response response = await http.get(
      url,
      headers: <String, String>{
        'accept': 'application/json',
        'accept-language': 'en-US,en;q=0.9',
        'authorization': 'Bearer $token',
        'cookie': 'lmt_token=$token',
        'referer': _organizerHomeUrl,
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load events (${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected events API response format');
    }

    final dynamic data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      return <OrganizerEventSummary>[];
    }

    final dynamic rawEvents = data['events'];
    if (rawEvents is! List) {
      return <OrganizerEventSummary>[];
    }

    final List<OrganizerEventSummary> events = <OrganizerEventSummary>[];
    for (final dynamic item in rawEvents) {
      if (item is Map) {
        final OrganizerEventSummary event = OrganizerEventSummary.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        if (event.id.isNotEmpty) {
          events.add(event);
        }
      }
    }

    return events;
  }
}
