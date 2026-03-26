import 'package:flutter/material.dart';

import '../../models/event_models.dart';

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.events,
    required this.isLoading,
    required this.error,
    required this.selectedEventId,
    required this.onRefresh,
    required this.onSelectEvent,
  });

  final List<OrganizerEventSummary> events;
  final bool isLoading;
  final String? error;
  final String? selectedEventId;
  final Future<void> Function() onRefresh;
  final ValueChanged<OrganizerEventSummary> onSelectEvent;

  static const Color _orange = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Home',
            style: TextStyle(
              color: _orange,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose an event to manage attendees and check-ins.',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: _orange)),
            )
          else if (error != null)
            _buildErrorCard()
          else if (events.isEmpty)
            _buildEmptyCard()
          else
            _buildEventsTable(context),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7DCE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unable to load events.',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(error ?? 'Unknown error'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRefresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7DCE2)),
      ),
      child: const Text(
        'No events found for this organizer.',
        style: TextStyle(
          color: Color(0xFF475569),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEventsTable(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double tableWidth = constraints.maxWidth > 860
            ? constraints.maxWidth
            : 860;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD7DCE2)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 108, child: Text('Date', style: _headerStyle)),
                        Expanded(flex: 4, child: Text('Event', style: _headerStyle)),
                        Expanded(child: Center(child: Text('Sold', style: _headerStyle))),
                        Expanded(child: Center(child: Text('Remaining', style: _headerStyle))),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('Net Sales', style: _headerStyle),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...events.map(
                    (OrganizerEventSummary event) => _buildEventRow(context, event),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventRow(BuildContext context, OrganizerEventSummary event) {
    final bool isSelected = selectedEventId == event.id;

    return InkWell(
      onTap: () => onSelectEvent(event),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1E8) : Colors.white,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 108,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _DateBadge(date: event.startDate),
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  _EventThumbnail(imageUrl: event.imageUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _orange,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.venueLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(event.startDate, event.rawDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${event.soldCount}',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${event.remainingCount}',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatCurrency(event.currency, event.netSales),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final String month = date == null
        ? '--'
        : <String>[
            'JAN',
            'FEB',
            'MAR',
            'APR',
            'MAY',
            'JUN',
            'JUL',
            'AUG',
            'SEP',
            'OCT',
            'NOV',
            'DEC',
          ][date!.month - 1];
    final String day = date == null ? '--' : '${date!.day}'.padLeft(2, '0');

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            day,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventThumbnail extends StatelessWidget {
  const _EventThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imageUrl.isEmpty
            ? Container(
                color: const Color(0xFFFFF1E8),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.event_available_rounded,
                  color: HomeView._orange,
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                  return Container(
                    color: const Color(0xFFFFF1E8),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: HomeView._orange,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  color: Color(0xFF1E293B),
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

String _formatDateTime(DateTime? date, String rawDate) {
  if (date == null) {
    return rawDate.isEmpty ? '-' : rawDate;
  }

  String twoDigits(int value) => value.toString().padLeft(2, '0');

  return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}T${twoDigits(date.hour)}:${twoDigits(date.minute)}:${twoDigits(date.second)}';
}

String _formatCurrency(String currency, double amount) {
  final String symbol = <String, String>{
    'USD': '\$',
    'INR': '₹',
    'EUR': '€',
    'GBP': '£',
  }[currency.toUpperCase()] ?? '${currency.toUpperCase()} ';

  final String fixed = amount.toStringAsFixed(2);
  final List<String> parts = fixed.split('.');
  final String whole = parts.first;
  final String decimal = parts.last;
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < whole.length; i++) {
    final int reverseIndex = whole.length - i;
    buffer.write(whole[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return '$symbol${buffer.toString()}.$decimal';
}
