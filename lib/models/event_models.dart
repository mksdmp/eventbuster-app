class OrganizerEventSummary {
  static const String _baseUrl = 'https://eventbuster.com';

  final String id;
  final String title;
  final String venue;
  final String city;
  final String state;
  final String country;
  final String currency;
  final String imageUrl;
  final String rawDate;
  final DateTime? startDate;
  final int soldCount;
  final int remainingCount;
  final double netSales;

  const OrganizerEventSummary({
    required this.id,
    required this.title,
    required this.venue,
    required this.city,
    required this.state,
    required this.country,
    required this.currency,
    required this.imageUrl,
    required this.rawDate,
    required this.startDate,
    required this.soldCount,
    required this.remainingCount,
    required this.netSales,
  });

  String get venueLine {
    final List<String> parts = <String>[
      venue,
      city,
      state,
    ].where((String value) => value.trim().isNotEmpty).toList();

    if (parts.isNotEmpty) {
      return parts.join(' · ');
    }

    return country.trim().isNotEmpty ? country : '-';
  }

  factory OrganizerEventSummary.fromJson(Map<String, dynamic> json) {
    final List<dynamic> ticketTiers = _asList(json['ticketTiers']);
    final int remainingFromTiers = ticketTiers
        .whereType<Map<String, dynamic>>()
        .fold<int>(0, (int total, Map<String, dynamic> tier) {
          return total + _readInt(tier, <String>['quantity', 'remaining', 'available']);
        });

    final Map<String, dynamic> stats = _asMap(json['stats']);
    final DateTime? parsedStartDate = _parseDate(
      _readString(
        json,
        <String>['startDate', 'date', 'eventDate', 'saleStartDate'],
        fallback: '',
      ),
    );

    return OrganizerEventSummary(
      id: _readString(json, <String>['_id', 'id'], fallback: ''),
      title: _readString(json, <String>['title', 'name'], fallback: 'Untitled Event'),
      venue: _readString(json, <String>['venue'], fallback: ''),
      city: _readString(json, <String>['city'], fallback: ''),
      state: _readString(json, <String>['state'], fallback: ''),
      country: _readString(json, <String>['country'], fallback: ''),
      currency: _readString(json, <String>['currency'], fallback: 'USD'),
      imageUrl: _resolveImageUrl(
        _readString(
          json,
          <String>[
            'featuredImage',
            'coverImage',
            'bannerImage',
            'imageUrl',
            'image',
            'thumbnail',
          ],
          fallback: '',
        ),
      ),
      rawDate: _readString(
        json,
        <String>['startDate', 'date', 'eventDate'],
        fallback: '',
      ),
      startDate: parsedStartDate,
      soldCount: _readInt(
        json,
        <String>[
          'sold',
          'soldCount',
          'soldTickets',
          'ticketsSold',
          'totalSold',
          'bookedTickets',
        ],
        fallback: _readInt(
          stats,
          <String>[
            'sold',
            'soldCount',
            'soldTickets',
            'ticketsSold',
            'totalSold',
          ],
        ),
      ),
      remainingCount: _readInt(
        json,
        <String>[
          'remaining',
          'remainingCount',
          'remainingTickets',
          'ticketsRemaining',
          'availableTickets',
        ],
        fallback: _readInt(
          stats,
          <String>[
            'remaining',
            'remainingCount',
            'remainingTickets',
            'ticketsRemaining',
          ],
          fallback: remainingFromTiers,
        ),
      ),
      netSales: _readDouble(
        json,
        <String>[
          'netSales',
          'grossSales',
          'salesAmount',
          'revenue',
          'totalSales',
        ],
        fallback: _readDouble(
          stats,
          <String>[
            'netSales',
            'grossSales',
            'salesAmount',
            'revenue',
            'totalSales',
          ],
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
      final int? parsed = int.tryParse(value);
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
      final double? parsed = double.tryParse(value);
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
