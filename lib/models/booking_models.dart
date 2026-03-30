class MyBookingsPayload {
  final List<MyBookingOrder> orders;
  final BookingsPagination pagination;

  const MyBookingsPayload({
    required this.orders,
    required this.pagination,
  });

  factory MyBookingsPayload.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = _asMap(json['data']);
    final List<MyBookingOrder> orders = _asList(data['orders'])
        .whereType<Map<String, dynamic>>()
        .map(MyBookingOrder.fromJson)
        .toList();
    final Map<String, dynamic> paginationMap = _asMap(data['pagination']);

    return MyBookingsPayload(
      orders: orders,
      pagination: BookingsPagination.fromJson(
        paginationMap,
        fallbackCount: orders.length,
      ),
    );
  }
}

class BookingsPagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  const BookingsPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory BookingsPagination.fromJson(
    Map<String, dynamic> json, {
    int fallbackCount = 0,
  }) {
    final int page = _readInt(
      json,
      <String>['page', 'currentPage', 'current_page'],
      fallback: 1,
    );
    final int limit = _readInt(
      json,
      <String>['limit', 'perPage', 'per_page', 'pageSize', 'page_size'],
      fallback: fallbackCount > 0 ? fallbackCount : 10,
    );
    final int total = _readInt(
      json,
      <String>['total', 'count', 'totalCount', 'total_count'],
      fallback: fallbackCount,
    );
    final int parsedPages = _readInt(
      json,
      <String>['pages', 'totalPages', 'total_pages', 'pageCount', 'page_count'],
      fallback: 0,
    );
    final int derivedPages = total > 0 && limit > 0 ? (total / limit).ceil() : 1;

    return BookingsPagination(
      page: page < 1 ? 1 : page,
      limit: limit < 1 ? (fallbackCount > 0 ? fallbackCount : 10) : limit,
      total: total < 0 ? 0 : total,
      pages: parsedPages > 0
          ? parsedPages
          : (derivedPages > 0 ? derivedPages : 1),
    );
  }
}

class MyBookingOrder {
  final String orderId;
  final String paymentId;
  final DateTime? orderDate;
  final BookedEventSummary event;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final Map<String, int> ticketTypes;
  final int ticketQty;
  final double amount;
  final double discountAmount;
  final double serviceFees;
  final double convenienceFees;
  final String paymentStatus;
  final String orderStatus;

  const MyBookingOrder({
    required this.orderId,
    required this.paymentId,
    required this.orderDate,
    required this.event,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.ticketTypes,
    required this.ticketQty,
    required this.amount,
    required this.discountAmount,
    required this.serviceFees,
    required this.convenienceFees,
    required this.paymentStatus,
    required this.orderStatus,
  });

  String get statusLabel {
    final String status = orderStatus.trim().isNotEmpty ? orderStatus : paymentStatus;
    if (status.trim().isEmpty) {
      return 'Pending';
    }

    final String normalized = status
        .trim()
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .toLowerCase();

    return normalized
        .split(' ')
        .where((String part) => part.isNotEmpty)
        .map((String part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String get ticketTypesLabel {
    if (ticketTypes.isEmpty) {
      return '-';
    }

    return ticketTypes.entries.map((MapEntry<String, int> entry) {
      final String label = entry.key.trim().isEmpty ? 'Ticket' : entry.key.trim();
      return '$label x${entry.value}';
    }).join(', ');
  }

  factory MyBookingOrder.fromJson(Map<String, dynamic> json) {
    return MyBookingOrder(
      orderId: _readString(json, <String>['orderId', '_id'], fallback: '-'),
      paymentId: _readString(json, <String>['paymentId'], fallback: ''),
      orderDate: _parseDate(
        _readString(json, <String>['orderDate', 'createdAt'], fallback: ''),
      ),
      event: BookedEventSummary.fromJson(_asMap(json['event'])),
      customerName: _readString(
        json,
        <String>['customerName', 'name'],
        fallback: '',
      ),
      customerEmail: _readString(
        json,
        <String>['customerEmail', 'email'],
        fallback: '',
      ),
      customerPhone: _readString(
        json,
        <String>['customerPhone', 'phone'],
        fallback: '',
      ),
      ticketTypes: _readTicketTypes(json['ticketTypes']),
      ticketQty: _readInt(json, <String>['ticketQty', 'quantity'], fallback: 0),
      amount: _readDouble(json, <String>['amount', 'totalAmount'], fallback: 0),
      discountAmount: _readDouble(
        json,
        <String>['discountAmount', 'discount'],
        fallback: 0,
      ),
      serviceFees: _readDouble(
        json,
        <String>['serviceFees', 'serviceFee'],
        fallback: 0,
      ),
      convenienceFees: _readDouble(
        json,
        <String>['convenienceFees', 'convenienceFee'],
        fallback: 0,
      ),
      paymentStatus: _readString(
        json,
        <String>['paymentStatus'],
        fallback: '',
      ),
      orderStatus: _readString(
        json,
        <String>['orderStatus', 'status'],
        fallback: '',
      ),
    );
  }
}

class BookedEventSummary {
  static const String _baseUrl = 'https://eventbuster.com';

  final String id;
  final String title;
  final String date;
  final DateTime? startDate;
  final String venue;
  final String address;
  final String country;
  final String currency;
  final String state;
  final String city;
  final String zipCode;
  final double price;
  final String imageUrl;

  const BookedEventSummary({
    required this.id,
    required this.title,
    required this.date,
    required this.startDate,
    required this.venue,
    required this.address,
    required this.country,
    required this.currency,
    required this.state,
    required this.city,
    required this.zipCode,
    required this.price,
    required this.imageUrl,
  });

  String get locationLine {
    final List<String> parts = <String>[
      address,
      city,
      state,
      zipCode,
      country,
    ].where((String value) => value.trim().isNotEmpty).toList();

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return venue.trim().isNotEmpty ? venue : '-';
  }

  factory BookedEventSummary.fromJson(Map<String, dynamic> json) {
    return BookedEventSummary(
      id: _readString(json, <String>['_id', 'id'], fallback: ''),
      title: _readString(
        json,
        <String>['title', 'name'],
        fallback: 'Untitled Event',
      ),
      date: _readString(json, <String>['date', 'startDate'], fallback: ''),
      startDate: _parseDate(
        _readString(json, <String>['startDate', 'date'], fallback: ''),
      ),
      venue: _readString(json, <String>['venue'], fallback: ''),
      address: _readString(json, <String>['address'], fallback: ''),
      country: _readString(json, <String>['country'], fallback: ''),
      currency: _readString(json, <String>['currency'], fallback: 'USD'),
      state: _readString(json, <String>['state'], fallback: ''),
      city: _readString(json, <String>['city'], fallback: ''),
      zipCode: _readString(json, <String>['zipCode', 'zip'], fallback: ''),
      price: _readDouble(json, <String>['price'], fallback: 0),
      imageUrl: _resolveImageUrl(
        _readString(
          json,
          <String>['image', 'imageUrl', 'featuredImage'],
          fallback: '',
        ),
      ),
    );
  }

  static String _resolveImageUrl(String value) {
    final String image = value.trim();
    if (image.isEmpty) {
      return '';
    }
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }
    if (image.startsWith('/')) {
      return '$_baseUrl$image';
    }
    return '$_baseUrl/$image';
  }
}

class VerifiedTicketPayload {
  final List<VerifiedTicket> tickets;

  const VerifiedTicketPayload({
    required this.tickets,
  });

  VerifiedTicket get ticket {
    if (tickets.isEmpty) {
      throw StateError('No verified tickets available');
    }
    return tickets.first;
  }

  factory VerifiedTicketPayload.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    final List<VerifiedTicket> tickets;

    if (rawData is List) {
      tickets = rawData
          .whereType<Map<String, dynamic>>()
          .map(VerifiedTicket.fromJson)
          .toList();
    } else {
      final Map<String, dynamic> data = _asMap(rawData);
      tickets = data.isEmpty ? <VerifiedTicket>[] : <VerifiedTicket>[VerifiedTicket.fromJson(data)];
    }

    return VerifiedTicketPayload(
      tickets: tickets,
    );
  }
}

class VerifiedTicket {
  final String id;
  final VerifiedTicketEvent event;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String ticketType;
  final String paymentStatus;
  final int quantity;
  final double price;
  final String ticketCode;
  final bool checkIn;
  final String orderId;
  final String paymentId;
  final double refundAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VerifiedTicket({
    required this.id,
    required this.event,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.ticketType,
    required this.paymentStatus,
    required this.quantity,
    required this.price,
    required this.ticketCode,
    required this.checkIn,
    required this.orderId,
    required this.paymentId,
    required this.refundAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VerifiedTicket.fromJson(Map<String, dynamic> json) {
    return VerifiedTicket(
      id: _readString(json, <String>['_id', 'id'], fallback: ''),
      event: VerifiedTicketEvent.fromJson(_asMap(json['eventId'])),
      userId: _readString(json, <String>['userId'], fallback: ''),
      name: _readString(json, <String>['name'], fallback: ''),
      email: _readString(json, <String>['email'], fallback: ''),
      phone: _readString(json, <String>['phone'], fallback: ''),
      ticketType: _readString(json, <String>['ticketType'], fallback: 'General'),
      paymentStatus: _readString(json, <String>['paymentStatus'], fallback: ''),
      quantity: _readInt(json, <String>['quantity'], fallback: 0),
      price: _readDouble(json, <String>['price'], fallback: 0),
      ticketCode: _readString(json, <String>['ticketCode'], fallback: ''),
      checkIn: json['checkIn'] == true,
      orderId: _readString(json, <String>['orderId'], fallback: ''),
      paymentId: _readString(json, <String>['paymentId'], fallback: ''),
      refundAmount: _readDouble(json, <String>['refundAmount'], fallback: 0),
      createdAt: _parseDate(
        _readString(json, <String>['createdAt'], fallback: ''),
      ),
      updatedAt: _parseDate(
        _readString(json, <String>['updatedAt'], fallback: ''),
      ),
    );
  }
}

class VerifiedTicketEvent {
  final String id;
  final String title;
  final String category;
  final DateTime? startDate;
  final DateTime? endDate;
  final String venue;
  final String address;
  final String state;
  final String city;
  final String zipCode;
  final String ageRestriction;
  final List<String> languages;
  final List<String> formats;

  const VerifiedTicketEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.venue,
    required this.address,
    required this.state,
    required this.city,
    required this.zipCode,
    required this.ageRestriction,
    required this.languages,
    required this.formats,
  });

  factory VerifiedTicketEvent.fromJson(Map<String, dynamic> json) {
    return VerifiedTicketEvent(
      id: _readString(json, <String>['_id', 'id'], fallback: ''),
      title: _readString(json, <String>['title', 'name'], fallback: 'Untitled Event'),
      category: _readString(json, <String>['category'], fallback: ''),
      startDate: _parseDate(
        _readString(json, <String>['startDate', 'date'], fallback: ''),
      ),
      endDate: _parseDate(
        _readString(json, <String>['endDate'], fallback: ''),
      ),
      venue: _readString(json, <String>['venue'], fallback: ''),
      address: _readString(json, <String>['address'], fallback: ''),
      state: _readString(json, <String>['state'], fallback: ''),
      city: _readString(json, <String>['city'], fallback: ''),
      zipCode: _readString(json, <String>['zipCode'], fallback: ''),
      ageRestriction: _readString(json, <String>['ageRestriction'], fallback: ''),
      languages: _readStringList(json['languages']),
      formats: _readStringList(json['formats']),
    );
  }
}

class EventDetails {
  static const String _baseUrl = 'https://eventbuster.com';

  final String id;
  final String title;
  final String category;
  final String description;
  final String longDescription;
  final String emailNote;
  final String date;
  final DateTime? startDate;
  final DateTime? endDate;
  final String doorsOpenTime;
  final String venue;
  final String address;
  final String country;
  final String currency;
  final String state;
  final String city;
  final String zipCode;
  final double price;
  final String imageUrl;
  final String organizerEmail;
  final String ageRestriction;
  final String status;
  final List<String> languages;

  const EventDetails({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.longDescription,
    required this.emailNote,
    required this.date,
    required this.startDate,
    required this.endDate,
    required this.doorsOpenTime,
    required this.venue,
    required this.address,
    required this.country,
    required this.currency,
    required this.state,
    required this.city,
    required this.zipCode,
    required this.price,
    required this.imageUrl,
    required this.organizerEmail,
    required this.ageRestriction,
    required this.status,
    required this.languages,
  });

  String get locationLine {
    final List<String> parts = <String>[
      address,
      city,
      state,
      zipCode,
    ].where((String value) => value.trim().isNotEmpty).toList();

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return venue.trim().isNotEmpty ? venue : '-';
  }

  factory EventDetails.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = _asMap(json['data']);

    return EventDetails(
      id: _readString(data, <String>['_id', 'id'], fallback: ''),
      title: _readString(data, <String>['title', 'name'], fallback: 'Untitled Event'),
      category: _readString(data, <String>['category'], fallback: ''),
      description: _readString(data, <String>['description'], fallback: ''),
      longDescription: _readString(
        data,
        <String>['longDescription', 'descriptionRichText'],
        fallback: '',
      ),
      emailNote: _readString(data, <String>['emailNote'], fallback: ''),
      date: _readString(data, <String>['date', 'startDate'], fallback: ''),
      startDate: _parseDate(
        _readString(data, <String>['startDate', 'date'], fallback: ''),
      ),
      endDate: _parseDate(
        _readString(data, <String>['endDate'], fallback: ''),
      ),
      doorsOpenTime: _readString(data, <String>['doorsOpenTime'], fallback: ''),
      venue: _readString(data, <String>['venue'], fallback: ''),
      address: _readString(data, <String>['address'], fallback: ''),
      country: _readString(data, <String>['country'], fallback: ''),
      currency: _readString(data, <String>['currency'], fallback: 'USD'),
      state: _readString(data, <String>['state'], fallback: ''),
      city: _readString(data, <String>['city'], fallback: ''),
      zipCode: _readString(data, <String>['zipCode'], fallback: ''),
      price: _readDouble(data, <String>['price'], fallback: 0),
      imageUrl: _resolveImageUrl(
        _readString(
          data,
          <String>['image', 'imageUrl', 'featuredImage'],
          fallback: '',
        ),
      ),
      organizerEmail: _readString(
        data,
        <String>['organizerEmail'],
        fallback: _readString(_asMap(data['createdBy']), <String>['email'], fallback: ''),
      ),
      ageRestriction: _readString(data, <String>['ageRestriction'], fallback: ''),
      status: _readString(data, <String>['status'], fallback: ''),
      languages: _readStringList(data['languages']),
    );
  }

  static String _resolveImageUrl(String value) {
    final String image = value.trim();
    if (image.isEmpty) {
      return '';
    }
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }
    if (image.startsWith('/')) {
      return '$_baseUrl$image';
    }
    return '$_baseUrl/$image';
  }
}

Map<String, int> _readTicketTypes(dynamic value) {
  if (value is! Map) {
    return <String, int>{};
  }

  final Map<String, int> parsed = <String, int>{};
  value.forEach((dynamic key, dynamic rawValue) {
    final String label = key.toString().trim();
    if (label.isEmpty) {
      return;
    }

    if (rawValue is int) {
      parsed[label] = rawValue;
      return;
    }

    if (rawValue is double) {
      parsed[label] = rawValue.round();
      return;
    }

    if (rawValue is String) {
      final int? count = int.tryParse(rawValue.trim());
      if (count != null) {
        parsed[label] = count;
      }
    }
  });

  return parsed;
}

List<String> _readStringList(dynamic value) {
  if (value is! List) {
    return <String>[];
  }

  return value
      .map((dynamic item) => item.toString().trim())
      .where((String item) => item.isNotEmpty)
      .toList();
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
  String fallback = '',
}) {
  for (final String key in keys) {
    final dynamic value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return fallback;
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
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      final int? parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return fallback;
}

double _readDouble(
  Map<String, dynamic> json,
  List<String> keys, {
  double fallback = 0,
}) {
  for (final String key in keys) {
    final dynamic value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final double? parsed = double.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return fallback;
}

DateTime? _parseDate(String value) {
  if (value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
