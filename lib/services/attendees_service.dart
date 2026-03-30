import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/attendee_models.dart';

class CheckInStatusUpdateResult {
  const CheckInStatusUpdateResult({
    required this.message,
    required this.alreadyCheckedIn,
  });

  final String message;
  final bool alreadyCheckedIn;
}

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

  Future<CheckInStatusUpdateResult> updateCheckInStatus({
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

    final String? responseMessage = _extractApiMessage(response.body);
    final bool alreadyCheckedIn = checkedIn && _isAlreadyCheckedInMessage(responseMessage);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (alreadyCheckedIn) {
        return CheckInStatusUpdateResult(
          message: _normalizeCheckInMessage(
            message: responseMessage,
            checkedIn: checkedIn,
            alreadyCheckedIn: true,
          ),
          alreadyCheckedIn: true,
        );
      }

      throw Exception(
        responseMessage ?? 'Failed to update check-in (${response.statusCode})',
      );
    }

    return CheckInStatusUpdateResult(
      message: _normalizeCheckInMessage(
        message: responseMessage,
        checkedIn: checkedIn,
        alreadyCheckedIn: alreadyCheckedIn,
      ),
      alreadyCheckedIn: alreadyCheckedIn,
    );
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

String? _extractApiMessage(String responseBody) {
  final String trimmed = responseBody.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  try {
    final dynamic decoded = jsonDecode(trimmed);
    return _findMessageInDecoded(decoded);
  } catch (_) {
    return trimmed;
  }
}

String? _findMessageInDecoded(dynamic value) {
  if (value is Map<String, dynamic>) {
    for (final String key in <String>['message', 'msg', 'error']) {
      final dynamic candidate = value[key];
      final String? message = _asNonEmptyString(candidate);
      if (message != null) {
        return message;
      }
    }

    for (final String key in <String>['data', 'result']) {
      final String? nestedMessage = _findMessageInDecoded(value[key]);
      if (nestedMessage != null) {
        return nestedMessage;
      }
    }
  }

  if (value is List) {
    for (final dynamic item in value) {
      final String? nestedMessage = _findMessageInDecoded(item);
      if (nestedMessage != null) {
        return nestedMessage;
      }
    }
  }

  return null;
}

String? _asNonEmptyString(dynamic value) {
  if (value == null) {
    return null;
  }

  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _isAlreadyCheckedInMessage(String? message) {
  if (message == null) {
    return false;
  }

  final String normalized = message.toLowerCase();
  return normalized.contains('already') &&
      (normalized.contains('check in') ||
          normalized.contains('checked in') ||
          normalized.contains('check-in') ||
          normalized.contains('checkin'));
}

String _normalizeCheckInMessage({
  required String? message,
  required bool checkedIn,
  required bool alreadyCheckedIn,
}) {
  if (alreadyCheckedIn) {
    return 'You have already checked in. Try another.';
  }

  final String? normalizedMessage = _asNonEmptyString(message);
  if (normalizedMessage != null) {
    return normalizedMessage;
  }

  if (checkedIn) {
    return 'Attendee checked in successfully.';
  }

  return 'Check-in undone successfully.';
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
