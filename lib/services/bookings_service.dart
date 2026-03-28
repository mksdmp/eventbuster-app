import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/booking_models.dart';

class BookingsService {
  static const String _myBookingsUrl =
      'https://eventbuster.com/api/attendees/my-bookings';
  static const String _verifyTicketUrl =
      'https://eventbuster.com/api/attendees/verify';
  static const String _eventsBaseUrl = 'https://eventbuster.com/api/events';
  static const String _ticketPdfUrl = 'https://eventbuster.com/api/tickets/pdf';

  Future<MyBookingsPayload> fetchMyBookings({
    required String token,
  }) async {
    final http.Response response = await http.get(
      Uri.parse(_myBookingsUrl),
      headers: <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer $token',
        'cookie': 'lmt_token=$token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load bookings (${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected bookings API response format');
    }

    return MyBookingsPayload.fromJson(decoded);
  }

  Future<VerifiedTicketPayload> verifyTicket({
    required String token,
    required String code,
  }) async {
    final Uri url = Uri.parse(
      '$_verifyTicketUrl?code=${Uri.encodeQueryComponent(code)}',
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
      throw Exception('Failed to verify ticket (${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected ticket verification response format');
    }

    if (decoded['success'] != true) {
      throw Exception((decoded['message'] ?? 'Ticket verification failed').toString());
    }

    return VerifiedTicketPayload.fromJson(decoded);
  }

  Future<EventDetails> fetchEventDetails({
    required String token,
    required String eventId,
  }) async {
    final http.Response response = await http.get(
      Uri.parse('$_eventsBaseUrl/$eventId'),
      headers: <String, String>{
        'accept': 'application/json',
        'authorization': 'Bearer $token',
        'cookie': 'lmt_token=$token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load event details (${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected event details response format');
    }

    if (decoded['success'] != true) {
      throw Exception((decoded['message'] ?? 'Unable to load event details').toString());
    }

    return EventDetails.fromJson(decoded);
  }

  Future<List<int>> downloadTicketPdf({
    required String token,
    required String eventId,
    required String orderId,
    required String paymentId,
  }) async {
    final Uri url = buildTicketPdfUri(
      eventId: eventId,
      orderId: orderId,
      paymentId: paymentId,
    );

    final http.Response response = await http.get(
      url,
      headers: ticketPdfHeaders(token: token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractPdfErrorMessage(response));
    }

    if (response.bodyBytes.isEmpty) {
      throw Exception('Received an empty PDF response.');
    }

    return response.bodyBytes;
  }

  Uri buildTicketPdfUri({
    required String eventId,
    required String orderId,
    required String paymentId,
  }) {
    return Uri.parse(_ticketPdfUrl).replace(
      queryParameters: <String, String>{
        'eventId': eventId,
        'orderId': orderId,
        'paymentId': paymentId,
      },
    );
  }

  Map<String, String> ticketPdfHeaders({
    required String token,
  }) {
    return <String, String>{
      'accept': 'application/pdf',
      'authorization': 'Bearer $token',
      'cookie': 'lmt_token=$token',
    };
  }

  String _extractPdfErrorMessage(http.Response response) {
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final String message = (decoded['message'] ?? '').toString().trim();
        if (message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Ignore parse failures and fall back to a generic message.
    }

    return 'Failed to download ticket PDF (${response.statusCode})';
  }
}
