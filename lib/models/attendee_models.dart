class AttendeesPayload {
  final List<AttendeeOrder> orders;
  final AttendeesPagination pagination;

  const AttendeesPayload({
    required this.orders,
    required this.pagination,
  });

  factory AttendeesPayload.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = _asMap(json['data']);
    final List<dynamic> rawAttendees = _asList(data['attendees']);

    final Map<String, _OrderAccumulator> grouped = <String, _OrderAccumulator>{};

    for (final dynamic item in rawAttendees) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final String orderId = _readString(
        item,
        <String>['orderId'],
        fallback: _readString(item, <String>['_id'], fallback: 'Unknown'),
      );

      final String eventName = _readString(
        _asMap(item['eventId']),
        <String>['title'],
      );
      final String buyerName = _readString(item, <String>['name']);
      final String date = _readString(
        item,
        <String>['createdAt', 'updatedAt'],
      );
      final String paymentStatus = _readString(
        item,
        <String>['paymentStatus'],
        fallback: 'pending',
      );
      final String normalizedStatus = paymentStatus.toLowerCase() == 'paid'
          ? 'completed'
          : paymentStatus;

      final _OrderAccumulator accumulator = grouped.putIfAbsent(
        orderId,
        () => _OrderAccumulator(
          orderId: orderId,
          status: normalizedStatus,
          eventName: eventName,
          buyerName: buyerName,
          date: date,
        ),
      );

      accumulator.ticketCount += _readInt(item, <String>['quantity'], fallback: 1);
      accumulator.attendees.add(AttendeeTicket.fromJson(item));
    }

    final List<AttendeeOrder> orders = grouped.values.map((e) {
      return AttendeeOrder(
        orderId: e.orderId,
        status: e.status,
        ticketCount: e.ticketCount,
        eventName: e.eventName,
        buyerName: e.buyerName,
        date: e.date,
        attendees: e.attendees,
      );
    }).toList();

    final Map<String, dynamic> paginationMap = _asMap(data['pagination']);

    return AttendeesPayload(
      orders: orders,
      pagination: AttendeesPagination.fromJson(paginationMap),
    );
  }
}

class AttendeesPagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  const AttendeesPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory AttendeesPagination.fromJson(Map<String, dynamic> json) {
    final int page = _readInt(
      json,
      <String>['page', 'currentPage', 'current_page'],
      fallback: 1,
    );
    final int limit = _readInt(
      json,
      <String>['limit', 'perPage', 'per_page', 'pageSize', 'page_size'],
      fallback: 20,
    );
    final int total = _readInt(
      json,
      <String>['total', 'count', 'totalCount', 'total_count'],
      fallback: 0,
    );
    final int parsedPages = _readInt(
      json,
      <String>['pages', 'totalPages', 'total_pages', 'pageCount', 'page_count'],
      fallback: 0,
    );
    final int derivedPages = total > 0 && limit > 0 ? (total / limit).ceil() : 1;

    return AttendeesPagination(
      page: page < 1 ? 1 : page,
      limit: limit < 1 ? 20 : limit,
      total: total < 0 ? 0 : total,
      pages: parsedPages > 0
          ? parsedPages
          : (derivedPages > 0 ? derivedPages : 1),
    );
  }
}

class AttendeeOrder {
  final String orderId;
  final String status;
  final int ticketCount;
  final String eventName;
  final String buyerName;
  final String date;
  final List<AttendeeTicket> attendees;

  const AttendeeOrder({
    required this.orderId,
    required this.status,
    required this.ticketCount,
    required this.eventName,
    required this.buyerName,
    required this.date,
    required this.attendees,
  });

  factory AttendeeOrder.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawAttendees = _asList(
      json['attendees'] ?? json['tickets'] ?? json['participants'],
    );
    final List<AttendeeTicket> parsedAttendees = rawAttendees
        .whereType<Map<String, dynamic>>()
        .map(AttendeeTicket.fromJson)
        .toList();

    final int ticketCount = _readInt(
      json,
      ['ticketCount', 'totalTickets', 'ticketsCount'],
      fallback: parsedAttendees.length,
    );

    return AttendeeOrder(
      orderId: _readString(json, ['orderId', 'orderNumber', '_id']),
      status: _readString(json, ['status'], fallback: 'pending'),
      ticketCount: ticketCount,
      eventName: _readString(
        json,
        ['eventName', 'eventTitle'],
        fallback: _readString(_asMap(json['event']), ['name', 'title']),
      ),
      buyerName: _readString(
        json,
        ['buyerName', 'customerName'],
        fallback: _readString(_asMap(json['buyer']), ['fullName', 'name']),
      ),
      date: _readString(json, ['date', 'createdAt', 'updatedAt']),
      attendees: parsedAttendees,
    );
  }
}

class AttendeeTicket {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String ticketType;
  final bool isCheckedIn;
  final String checkInStatus;
  final String? paymentStatus;
  final String? note;

  const AttendeeTicket({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.ticketType,
    required this.isCheckedIn,
    required this.checkInStatus,
    required this.paymentStatus,
    required this.note,
  });

  factory AttendeeTicket.fromJson(Map<String, dynamic> json) {
    final bool isCheckedIn = json['checkIn'] == true;

    return AttendeeTicket(
      id: _readString(json, ['_id', 'id', 'attendeeId'], fallback: ''),
      name: _readString(json, ['name', 'fullName']),
      email: _readString(json, ['email']),
      phone: _readString(json, ['phone'], fallback: ''),
      ticketType: _readString(json, ['ticketType', 'type'], fallback: 'General'),
      isCheckedIn: isCheckedIn,
      checkInStatus: isCheckedIn ? 'Checked In' : 'Pending',
      paymentStatus: _readNullableString(json, ['paymentStatus']),
      note: _readNullableString(json, ['note']),
    );
  }
}

class _OrderAccumulator {
  final String orderId;
  final String status;
  final String eventName;
  final String buyerName;
  final String date;
  int ticketCount;
  final List<AttendeeTicket> attendees;

  _OrderAccumulator({
    required this.orderId,
    required this.status,
    required this.eventName,
    required this.buyerName,
    required this.date,
  })  : ticketCount = 0,
        attendees = <AttendeeTicket>[];
}

List<dynamic> _asList(dynamic value) {
  if (value is List<dynamic>) {
    return value;
  }
  return <dynamic>[];
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return <String, dynamic>{};
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '-',
}) {
  for (final String key in keys) {
    final dynamic value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return fallback;
}

String? _readNullableString(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final String key in keys) {
    final dynamic value = json[key];
    if (value == null) {
      continue;
    }

    final String text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }

  return null;
}

int _readInt(
  Map<String, dynamic> json,
  List<String> keys, {
  int fallback = 0,
}) {
  for (final String key in keys) {
    final dynamic value = json[key];
    if (value is int) {
      return value;
    }
    if (value is String) {
      final int? parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return fallback;
}
