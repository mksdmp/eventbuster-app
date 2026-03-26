import 'dart:convert';

class ParsedCheckInQrPayload {
  const ParsedCheckInQrPayload({
    required this.rawValue,
    required this.attendeeId,
    required this.eventId,
  });

  final String rawValue;
  final String? attendeeId;
  final String? eventId;
}

class CheckInQrParser {
  static const List<String> _attendeeKeys = <String>[
    'attendeeId',
    'attendee_id',
    'ticketId',
    'ticket_id',
    'participantId',
    'participant_id',
    'bookingId',
    'booking_id',
    'id',
  ];

  static const List<String> _eventKeys = <String>[
    'eventId',
    'event_id',
  ];

  static ParsedCheckInQrPayload parse(String rawValue) {
    final String trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return const ParsedCheckInQrPayload(
        rawValue: '',
        attendeeId: null,
        eventId: null,
      );
    }

    final ParsedCheckInQrPayload? fromJson = _parseFromJson(trimmed);
    if (fromJson != null) {
      return fromJson;
    }

    final ParsedCheckInQrPayload? fromUri = _parseFromUri(trimmed);
    if (fromUri != null) {
      return fromUri;
    }

    return ParsedCheckInQrPayload(
      rawValue: trimmed,
      attendeeId: _extractLooseIdentifier(trimmed),
      eventId: null,
    );
  }

  static ParsedCheckInQrPayload? _parseFromJson(String rawValue) {
    try {
      final dynamic decoded = jsonDecode(rawValue);
      final String? attendeeId = _findFirstString(decoded, _attendeeKeys);
      final String? eventId = _findFirstString(decoded, _eventKeys);

      if (attendeeId != null || eventId != null) {
        return _buildPayload(
          rawValue: rawValue,
          attendeeId: attendeeId,
          eventId: eventId,
        );
      }
    } catch (_) {
      // Not JSON; continue with URI/plain-text parsing.
    }

    return null;
  }

  static ParsedCheckInQrPayload? _parseFromUri(String rawValue) {
    final Uri? uri = Uri.tryParse(rawValue);
    if (uri == null || (!uri.hasAuthority && uri.scheme.isEmpty)) {
      return null;
    }

    final String? attendeeId = _readUriValue(uri, _attendeeKeys) ??
        _extractPathIdentifier(uri, const <String>[
          'attendees',
          'attendee',
          'tickets',
          'ticket',
          'participants',
          'participant',
          'check-in',
          'checkin',
        ]);
    final String? eventId = _readUriValue(uri, _eventKeys) ??
        _extractPathIdentifier(uri, const <String>[
          'events',
          'event',
        ]);

    if (attendeeId == null && eventId == null) {
      return null;
    }

    return _buildPayload(
      rawValue: rawValue,
      attendeeId: attendeeId,
      eventId: eventId,
    );
  }

  static ParsedCheckInQrPayload _buildPayload({
    required String rawValue,
    required String? attendeeId,
    required String? eventId,
  }) {
    final String? normalizedAttendeeId = attendeeId?.trim();
    final String? normalizedEventId = eventId?.trim();

    return ParsedCheckInQrPayload(
      rawValue: rawValue,
      attendeeId: normalizedAttendeeId != null &&
              normalizedEventId != null &&
              normalizedAttendeeId == normalizedEventId
          ? null
          : normalizedAttendeeId,
      eventId: normalizedEventId,
    );
  }

  static String? _readUriValue(Uri uri, List<String> keys) {
    for (final String key in keys) {
      final String? value = uri.queryParameters[key]?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static String? _extractPathIdentifier(Uri uri, List<String> markers) {
    final List<String> segments = uri.pathSegments
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList();

    for (int i = 0; i < segments.length - 1; i++) {
      if (markers.contains(segments[i].toLowerCase())) {
        final String candidate = segments[i + 1];
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }
    }

    if (segments.isEmpty) {
      return null;
    }

    return _extractLooseIdentifier(segments.last);
  }

  static String? _findFirstString(dynamic source, List<String> keys) {
    if (source is Map) {
      final Map<dynamic, dynamic> map = source;

      for (final String key in keys) {
        final dynamic directValue = map[key];
        final String? candidate = _asNonEmptyString(directValue);
        if (candidate != null) {
          return candidate;
        }
      }

      for (final dynamic value in map.values) {
        final String? nested = _findFirstString(value, keys);
        if (nested != null) {
          return nested;
        }
      }
    } else if (source is List) {
      for (final dynamic item in source) {
        final String? nested = _findFirstString(item, keys);
        if (nested != null) {
          return nested;
        }
      }
    }

    return null;
  }

  static String? _asNonEmptyString(dynamic value) {
    if (value == null) {
      return null;
    }

    final String text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }

  static String? _extractLooseIdentifier(String rawValue) {
    final RegExp mongoIdPattern = RegExp(r'\b[a-fA-F0-9]{24}\b');
    final RegExp uuidPattern = RegExp(
      r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}\b',
    );

    final Match? mongoMatch = mongoIdPattern.firstMatch(rawValue);
    if (mongoMatch != null) {
      return mongoMatch.group(0);
    }

    final Match? uuidMatch = uuidPattern.firstMatch(rawValue);
    if (uuidMatch != null) {
      return uuidMatch.group(0);
    }

    if (!rawValue.contains(RegExp(r'\s')) &&
        rawValue.length >= 6 &&
        !rawValue.contains('://')) {
      return rawValue;
    }

    return null;
  }
}
