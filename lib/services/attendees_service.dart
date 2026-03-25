import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/attendee_models.dart';

class AttendeesService {
  static const String _baseUrl = 'https://eventbuster.com/api/attendees';
  static const String _myEventsUrl = 'https://eventbuster.com/api/events/my-events';
  static const String _orderActionsBaseUrl = 'https://eventbuster.com/api/order-actions';

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
        'cookie': 'lmt_token=$token',
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

  Future<void> updateCheckInStatus({
    required String attendeeId,
    required bool checkedIn,
    required String token,
  }) async {
    final Uri url = Uri.parse('$_baseUrl/$attendeeId/check-in');

    final http.Response response = await http.patch(
      url,
      headers: <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer $token',
        'cookie': 'lmt_token=$token',
        'content-type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'checkedIn': checkedIn,
        'method': 'manual',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update check-in (${response.statusCode})');
    }
  }

  Future<List<OrganizerEventOption>> fetchMyEvents({
    required String token,
    int page = 1,
    int limit = 200,
  }) async {
    final Uri url = Uri.parse('$_myEventsUrl?page=$page&limit=$limit');

    final http.Response response = await http.get(
      url,
      headers: <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer $token',
        'cookie': 'lmt_token=$token',
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
      return <OrganizerEventOption>[];
    }

    final dynamic rawEvents = data['events'];
    if (rawEvents is! List) {
      return <OrganizerEventOption>[];
    }

    return rawEvents
        .whereType<Map<String, dynamic>>()
        .map(OrganizerEventOption.fromJson)
        .where((OrganizerEventOption event) => event.id.isNotEmpty && event.title.isNotEmpty)
        .toList();
  }

  Future<void> addAttendee({
    required String token,
    required String eventId,
    required String name,
    required String email,
    required String phone,
    required String ticketType,
    required String paymentStatus,
    required int quantity,
  }) async {
    final Uri url = Uri.parse(_baseUrl);

    final http.Response response = await http.post(
      url,
      headers: <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'eventId': eventId,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'ticketType': ticketType.trim(),
        'paymentStatus': paymentStatus.trim().toLowerCase(),
        'quantity': quantity,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to add attendee (${response.statusCode})');
    }
  }

  Future<void> updateAttendeeInfo({
    required String token,
    required String attendeeId,
    required String name,
    required String email,
    required String phone,
  }) async {
    final Uri url = Uri.parse(
      '$_orderActionsBaseUrl/attendees/$attendeeId/info',
    );

    final http.Response response = await http.patch(
      url,
      headers: <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update attendee info (${response.statusCode})');
    }
  }

  Future<void> refundAttendee({
    required String token,
    required String attendeeId,
  }) async {
    final Uri url = Uri.parse(
      '$_orderActionsBaseUrl/attendees/$attendeeId/refund',
    );

    final http.Response response = await http.post(
      url,
      headers: <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to refund ticket (${response.statusCode})');
    }
  }

  Future<void> transferAttendee({
    required String token,
    required String attendeeId,
    required String newName,
    required String newEmail,
  }) async {
    final Uri url = Uri.parse(
      '$_orderActionsBaseUrl/attendees/$attendeeId/transfer',
    );

    final http.Response response = await http.post(
      url,
      headers: <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'newName': newName.trim(),
        'newEmail': newEmail.trim(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to transfer ticket (${response.statusCode})');
    }
  }

  Future<void> addAttendeeNote({
    required String token,
    required String attendeeId,
    required String note,
  }) async {
    final Uri url = Uri.parse(
      '$_orderActionsBaseUrl/attendees/$attendeeId/note',
    );

    final http.Response response = await http.patch(
      url,
      headers: <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'note': note.trim(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to save attendee note (${response.statusCode})');
    }
  }
}

class OrganizerEventOption {
  final String id;
  final String title;

  const OrganizerEventOption({
    required this.id,
    required this.title,
  });

  factory OrganizerEventOption.fromJson(Map<String, dynamic> json) {
    return OrganizerEventOption(
      id: (json['_id'] ?? json['id'] ?? '').toString().trim(),
      title: (json['title'] ?? '').toString().trim(),
    );
  }
}
