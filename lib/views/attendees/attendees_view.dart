import 'package:flutter/material.dart';

import '../../models/attendee_models.dart';
import '../../models/event_models.dart';
import '../../services/auth_service.dart';
import '../../services/attendees_service.dart';
import '../../utils/check_in_qr_parser.dart';

class AttendeesView extends StatefulWidget {
  const AttendeesView({
    super.key,
    this.selectedEvent,
    this.onOpenHome,
    this.onOpenScanQr,
  });

  final OrganizerEventSummary? selectedEvent;
  final VoidCallback? onOpenHome;
  final VoidCallback? onOpenScanQr;

  @override
  State<AttendeesView> createState() => _AttendeesViewState();
}

class _AttendeesViewState extends State<AttendeesView> {
  static const Color _orange = Color(0xFFFF6A00);
  static const String _allTicketTypesValue = '__all_ticket_types__';
  static const String _allTicketTypesLabel = 'All Ticket Types';

  final AttendeesService _service = AttendeesService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<AttendeeOrder> _orders = <AttendeeOrder>[];
  AttendeesPagination _pagination = const AttendeesPagination(
    page: 1,
    limit: 20,
    total: 0,
    pages: 1,
  );
  String _selectedStatus = 'All Status';
  String _selectedTicketType = _allTicketTypesValue;
  String? _expandedOrderId;

  @override
  void initState() {
    super.initState();
    _loadAttendees();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant AttendeesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedEvent?.id != widget.selectedEvent?.id) {
      _resetViewState();
      _loadAttendees();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetViewState() {
    _orders = <AttendeeOrder>[];
    _error = null;
    _expandedOrderId = null;
    _selectedStatus = 'All Status';
    _selectedTicketType = _allTicketTypesValue;
    _pagination = const AttendeesPagination(
      page: 1,
      limit: 20,
      total: 0,
      pages: 1,
    );
  }

  Future<void> _loadAttendees() async {
    if (widget.selectedEvent == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _resetViewState();
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final String? token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found. Please sign in again.');
      }

      final AttendeesPayload payload = await _service.fetchAttendees(
        page: _pagination.page,
        limit: _pagination.limit,
        eventId: widget.selectedEvent!.id,
        token: token,
      );

      setState(() {
        _orders = payload.orders;
        _pagination = payload.pagination;
        final List<_FilteredOrderResult> sortedOrders = _buildFilteredOrders(
          payload.orders,
        );
        _expandedOrderId = sortedOrders.isNotEmpty
            ? sortedOrders.first.order.orderId
            : null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F5F7),
      child: widget.selectedEvent == null
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Attendees',
                  style: TextStyle(
                    color: _orange,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage and track event attendees',
                  style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildNoEventSelected(),
              ],
            )
          : RefreshIndicator(
              onRefresh: _loadAttendees,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Attendees',
                    style: TextStyle(
                      color: _orange,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage and track event attendees',
                    style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _buildSelectedEventBanner(widget.selectedEvent!),
                  const SizedBox(height: 14),
                  _buildToolbar(context),
                  const SizedBox(height: 14),
                  _buildFilters(),
                  const SizedBox(height: 14),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(color: _orange),
                      ),
                    )
                  else if (_error != null)
                    _buildError()
                  else ...[
                    ..._buildOrderCards(),
                    const SizedBox(height: 10),
                    _buildPagination(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildNoEventSelected() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7DCE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No event selected',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open Home and choose an event first. If you tap the attendee tab after events load, the first event will be selected automatically.',
            style: TextStyle(color: Color(0xFF475569)),
          ),
          if (widget.onOpenHome != null) ...[
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: widget.onOpenHome,
              child: const Text('Go to Home'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedEventBanner(OrganizerEventSummary event) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7DCE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Event',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.title,
            style: const TextStyle(
              color: _orange,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.venueLine,
            style: const TextStyle(color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final bool hasPreviousPage = _pagination.page > 1 && !_isLoading;
    final bool hasNextByPages = _pagination.page < _pagination.pages;
    final bool hasNextByTotal = _pagination.limit > 0 &&
        (_pagination.page * _pagination.limit) < _pagination.total;
    final bool hasNextPage = (hasNextByPages || hasNextByTotal) && !_isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7DCE2)),
      ),
      child: Row(
        children: [
          Text(
            'Page ${_pagination.page} of ${_pagination.pages}',
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: hasPreviousPage
                ? () {
                    _changePage(_pagination.page - 1);
                  }
                : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
            ),
            child: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
            onPressed: hasNextPage
                ? () {
                    _changePage(_pagination.page + 1);
                  }
                : null,
            child: const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _changePage(int nextPage) async {
    setState(() {
      _pagination = AttendeesPagination(
        page: nextPage,
        limit: _pagination.limit,
        total: _pagination.total,
        pages: _pagination.pages,
      );
    });
    await _loadAttendees();
  }

  Widget _buildToolbar(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        _actionButton(
          label: 'Add Attendee',
          icon: Icons.add,
          filled: true,
          onTap: _openAddAttendeeDialog,
        ),
        _actionButton(
          label: 'Scan QR',
          icon: Icons.qr_code_scanner,
          filled: true,
          red: true,
          onTap: widget.onOpenScanQr ?? _openScanQrDialog,
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
    bool red = false,
  }) {
    final Color color = red ? const Color(0xFFFF3D32) : _orange;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: filled ? Colors.white : const Color(0xFF334155),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : const Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7DCE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statusDropdown(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ticketDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusDropdown() {
    final Set<String> statusSet = _orders
        .expand((AttendeeOrder order) => order.attendees)
        .map((AttendeeTicket attendee) => _normalizeFilterLabel(attendee.checkInStatus))
        .where((String status) => status.isNotEmpty)
        .toSet();
    final List<String> sortedStatuses = statusSet.toList()..sort();
    final List<String> statuses = <String>[
      'All Status',
      ...sortedStatuses,
    ];

    return DropdownButtonFormField<String>(
      value: statuses.contains(_selectedStatus) ? _selectedStatus : 'All Status',
      isExpanded: true,
      decoration: _dropdownDecoration(),
      items: statuses
          .map(
            (String e) => DropdownMenuItem<String>(
              value: e,
              child: Text(
                e,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      selectedItemBuilder: (BuildContext context) {
        return statuses
            .map(
              (String e) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  e,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList();
      },
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            _selectedStatus = value;
          });
        }
      },
    );
  }

  Widget _ticketDropdown() {
    final Map<String, String> ticketTypeLabels = <String, String>{};

    for (final AttendeeTicket attendee in _orders.expand(
      (AttendeeOrder order) => order.attendees,
    )) {
      final String key = _normalizeTicketType(attendee.ticketType);
      if (key.isEmpty) {
        continue;
      }
      ticketTypeLabels.putIfAbsent(
        key,
        () => _displayTicketTypeLabel(attendee.ticketType),
      );
    }

    final List<String> sortedTypes = ticketTypeLabels.keys.toList()
      ..sort((String left, String right) {
        return _compareTicketTypes(
          ticketTypeLabels[left],
          ticketTypeLabels[right],
        );
      });

    return DropdownButtonFormField<String>(
      value: _selectedTicketType == _allTicketTypesValue ||
              ticketTypeLabels.containsKey(_selectedTicketType)
          ? _selectedTicketType
          : _allTicketTypesValue,
      isExpanded: true,
      decoration: _dropdownDecoration(),
      items: <DropdownMenuItem<String>>[
        const DropdownMenuItem<String>(
          value: _allTicketTypesValue,
          child: Text(
            _allTicketTypesLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...sortedTypes.map(
          (String key) => DropdownMenuItem<String>(
            value: key,
            child: Text(
              ticketTypeLabels[key] ?? key,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      selectedItemBuilder: (BuildContext context) {
        return <String>[_allTicketTypesValue, ...sortedTypes]
            .map(
              (String key) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  key == _allTicketTypesValue
                      ? _allTicketTypesLabel
                      : (ticketTypeLabels[key] ?? key),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList();
      },
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            _selectedTicketType = value;
          });
        }
      },
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7DCE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unable to load attendees.',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadAttendees,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderCards() {
    final List<_FilteredOrderResult> filteredOrders = _filteredOrders();
    if (filteredOrders.isEmpty) {
      return <Widget>[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD7DCE2)),
          ),
          child: const Center(child: Text('No attendees found')),
        ),
      ];
    }

    return filteredOrders.map((_FilteredOrderResult filteredOrder) {
      final AttendeeOrder order = filteredOrder.order;
      final bool expanded = _expandedOrderId == order.orderId;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD7DCE2)),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _expandedOrderId = expanded ? null : order.orderId;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Order #${order.orderId}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _orange,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _titleCase(order.status),
                                  style: const TextStyle(
                                    color: Color(0xFF166534),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${filteredOrder.attendees.length} Tickets',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Event: ${order.eventName} · Buyer: ${order.buyerName} · ${_formatDate(order.date)}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              _buildExpandedTable(filteredOrder.attendees),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildExpandedTable(List<AttendeeTicket> attendees) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: attendees.map(_buildAttendeeRow).toList(),
      ),
    );
  }

  Widget _buildAttendeeRow(AttendeeTicket attendee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendee.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  attendee.email,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _displayTicketTypeLabel(attendee.ticketType),
                        style: const TextStyle(color: Color(0xFF1D4ED8)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _titleCase(attendee.checkInStatus),
                        style: const TextStyle(color: Color(0xFF92400E)),
                      ),
                    ),
                    if (_isRefundedTicket(attendee))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Refunded',
                          style: TextStyle(color: Color(0xFFB91C1C)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Align(
            alignment: Alignment.topRight,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              splashRadius: 18,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: Colors.white,
              icon: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1F2937), width: 2),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Color(0xFF475569),
                  size: 18,
                ),
              ),
              onSelected: (String value) {
                _handleAttendeeMenuSelection(attendee, value);
              },
              itemBuilder: (BuildContext context) => _buildAttendeeMenuItems(attendee),
            ),
          ),
        ],
      ),
    );
  }

  List<_FilteredOrderResult> _filteredOrders() {
    return _buildFilteredOrders(_orders);
  }

  List<_FilteredOrderResult> _buildFilteredOrders(List<AttendeeOrder> orders) {
    final String search = _searchController.text.trim().toLowerCase();
    final List<_FilteredOrderResult> filtered = <_FilteredOrderResult>[];

    for (final AttendeeOrder order in orders) {
      final bool orderMatchesSearch = search.isEmpty ||
          order.orderId.toLowerCase().contains(search) ||
          order.buyerName.toLowerCase().contains(search) ||
          order.eventName.toLowerCase().contains(search);

      final List<AttendeeTicket> visibleAttendees = order.attendees.where((
        AttendeeTicket attendee,
      ) {
        final bool statusOk = _selectedStatus == 'All Status' ||
            _normalizeFilterLabel(attendee.checkInStatus) == _selectedStatus;
        final bool ticketOk = _selectedTicketType == _allTicketTypesValue ||
            _normalizeTicketType(attendee.ticketType) == _selectedTicketType;
        final bool attendeeMatchesSearch = search.isEmpty ||
            attendee.name.toLowerCase().contains(search) ||
            attendee.email.toLowerCase().contains(search);

        return statusOk && ticketOk && (orderMatchesSearch || attendeeMatchesSearch);
      }).toList()
        ..sort((AttendeeTicket left, AttendeeTicket right) {
          return _compareTicketTypes(left.ticketType, right.ticketType);
        });

      if (visibleAttendees.isNotEmpty) {
        filtered.add(
          _FilteredOrderResult(
            order: order,
            attendees: visibleAttendees,
          ),
        );
      }
    }

    filtered.sort((_FilteredOrderResult left, _FilteredOrderResult right) {
      final int rankCompare = _ticketSortRank(left.attendees).compareTo(
        _ticketSortRank(right.attendees),
      );
      if (rankCompare != 0) {
        return rankCompare;
      }
      return _compareOrderDatesDescending(left.order.date, right.order.date);
    });

    return filtered;
  }

  String _normalizeTicketType(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  Map<String, int> _buildTicketTypeOrder(List<String> ticketTiers) {
    final Map<String, int> order = <String, int>{};

    for (int i = 0; i < ticketTiers.length; i++) {
      final String key = _normalizeTicketType(ticketTiers[i]);
      if (key.isNotEmpty && !order.containsKey(key)) {
        order[key] = i;
      }
    }

    return order;
  }

  int _compareTicketTypes(String? left, String? right) {
    final String leftKey = _normalizeTicketType(left);
    final String rightKey = _normalizeTicketType(right);
    final Map<String, int> ticketTypeOrder = _buildTicketTypeOrder(
      widget.selectedEvent?.ticketTiers ?? <String>[],
    );

    final int? leftRank = ticketTypeOrder[leftKey];
    final int? rightRank = ticketTypeOrder[rightKey];

    if (leftRank != null || rightRank != null) {
      if (leftRank == null) {
        return 1;
      }
      if (rightRank == null) {
        return -1;
      }
      if (leftRank != rightRank) {
        return leftRank.compareTo(rightRank);
      }
    }

    return (left ?? '').toLowerCase().compareTo((right ?? '').toLowerCase());
  }

  int _ticketSortRank(List<AttendeeTicket> attendees) {
    if (attendees.isEmpty) {
      return 1 << 30;
    }

    final Map<String, int> ticketTypeOrder = _buildTicketTypeOrder(
      widget.selectedEvent?.ticketTiers ?? <String>[],
    );

    return ticketTypeOrder[_normalizeTicketType(attendees.first.ticketType)] ??
        (1 << 30);
  }

  int _compareOrderDatesDescending(String left, String right) {
    final DateTime? leftDate = DateTime.tryParse(left.trim());
    final DateTime? rightDate = DateTime.tryParse(right.trim());

    if (leftDate != null || rightDate != null) {
      if (leftDate == null) {
        return 1;
      }
      if (rightDate == null) {
        return -1;
      }
      return rightDate.compareTo(leftDate);
    }

    return right.toLowerCase().compareTo(left.toLowerCase());
  }

  String _displayTicketTypeLabel(String value) {
    final String key = _normalizeTicketType(value);
    for (final String tier in widget.selectedEvent?.ticketTiers ?? <String>[]) {
      if (_normalizeTicketType(tier) == key) {
        return tier.trim();
      }
    }
    return _normalizeFilterLabel(value);
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }

    final List<String> parts = value.trim().split(' ');
    return parts
        .map(
          (String e) =>
              e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _normalizeFilterLabel(String value) {
    return _titleCase(
      value
          .trim()
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .toLowerCase(),
    );
  }

  bool _isRefundedTicket(AttendeeTicket attendee) {
    return _normalizeStatusKey(attendee.paymentStatus) == 'refunded';
  }

  bool _isCheckedInTicket(AttendeeTicket attendee) {
    return attendee.isCheckedIn;
  }

  String _normalizeStatusKey(Object? value) {
    return (value ?? '')
        .toString()
        .trim()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  List<PopupMenuEntry<String>> _buildAttendeeMenuItems(AttendeeTicket attendee) {
    return <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: _isCheckedInTicket(attendee) ? 'Undo Check In' : 'Check In',
        child: Text(
          _isCheckedInTicket(attendee) ? 'Undo Check In' : 'Check In',
          style: TextStyle(
            color: Color(0xFFFF6A00),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const PopupMenuItem<String>(
        value: 'Edit Attendee info',
        child: Text('Edit Attendee info'),
      ),
      // const PopupMenuItem<String>(
      //   value: 'Refund Ticket',
      //   child: Text('Refund Ticket'),
      // ),
      // const PopupMenuItem<String>(
      //   value: 'Transfer Ticket',
      //   child: Text('Transfer Ticket'),
      // ),
      // const PopupMenuItem<String>(
      //   value: 'Add Attendee Note',
      //   child: Text('Add Attendee Note'),
      // ),
    ];
  }

  Future<void> _handleAttendeeMenuSelection(
    AttendeeTicket attendee,
    String value,
  ) async {
    if (value == 'Check In' || value == 'Undo Check In') {
      await _toggleAttendeeCheckIn(
        attendee: attendee,
        checkedIn: value == 'Check In',
      );
      return;
    }
    if (value == 'Edit Attendee info') {
      await _openEditAttendeeDialog(attendee);
      return;
    }
    // if (value == 'Refund Ticket') {
    //   await _openRefundTicketDialog(attendee);
    //   return;
    // }
    // if (value == 'Transfer Ticket') {
    //   await _openTransferTicketDialog(attendee);
    //   return;
    // }
    // if (value == 'Add Attendee Note') {
    //   await _openAttendeeNoteDialog(attendee);
    //   return;
    // }
    _showPlaceholderAction(context, value);
  }

  Future<void> _toggleAttendeeCheckIn({
    required AttendeeTicket attendee,
    required bool checkedIn,
  }) async {
    if (attendee.id.isEmpty) {
      _showPlaceholderAction(context, 'Missing attendee ID');
      return;
    }

    try {
      final String? token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found. Please sign in again.');
      }

      await _service.updateCheckInStatus(
        attendeeId: attendee.id,
        checkedIn: checkedIn,
        token: token,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            checkedIn ? 'Attendee checked in successfully' : 'Check-in undone successfully',
          ),
        ),
      );

      await _loadAttendees();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String _formatDate(String value) {
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  void _showPlaceholderAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action clicked')),
    );
  }

  Future<bool> _checkInFromQrPayload(String rawValue) async {
    final ParsedCheckInQrPayload payload = CheckInQrParser.parse(rawValue);
    final String? attendeeId = payload.attendeeId;

    if (attendeeId == null || attendeeId.isEmpty) {
      final String message = payload.eventId != null
          ? 'This QR/manual code only contains event id. Check-in API requires attendee id.'
          : 'Unable to find attendee id in the scanned QR/manual code.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      return false;
    }

    if (widget.selectedEvent != null &&
        payload.eventId != null &&
        payload.eventId != widget.selectedEvent!.id) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This QR code belongs to a different event.')),
        );
      }
      return false;
    }

    try {
      final String? token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found. Please sign in again.');
      }

      await _service.updateCheckInStatus(
        attendeeId: attendeeId,
        checkedIn: true,
        token: token,
      );

      if (!mounted) {
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendee checked in successfully')),
      );

      await _loadAttendees();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      return false;
    }
  }

  Future<void> _openAddAttendeeDialog() async {
    final BuildContext pageContext = context;

    final String? token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('No auth token found. Please sign in again.')),
        );
      }
      return;
    }

    List<OrganizerEventOption> events = <OrganizerEventOption>[];

    try {
      events = await _service.fetchMyEvents(token: token);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      return;
    }

    if (events.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('No events found for this organizer.')),
        );
      }
      return;
    }

    final _AddAttendeeSubmission? submission = await showDialog<_AddAttendeeSubmission>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black45,
      builder: (BuildContext dialogContext) => _AddAttendeeDialog(
        events: events,
        initialEventId: widget.selectedEvent?.id,
      ),
    );

    if (submission == null) {
      return;
    }

    try {
      await _service.addAttendee(
        token: token,
        eventId: submission.eventId,
        name: submission.name,
        email: submission.email,
        phone: submission.phone,
        ticketType: submission.ticketType,
        paymentStatus: submission.paymentStatus,
        quantity: submission.quantity,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(content: Text('Attendee added successfully')),
      );

      await _loadAttendees();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(pageContext).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openEditAttendeeDialog(AttendeeTicket attendee) async {
    final BuildContext pageContext = context;

    final _EditAttendeeSubmission? submission =
        await showDialog<_EditAttendeeSubmission>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black45,
      builder: (BuildContext dialogContext) {
        return _EditAttendeeDialog(attendee: attendee);
      },
    );

    if (submission == null) {
      return;
    }

    if (attendee.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('Missing attendee ID')),
        );
      }
      return;
    }

    final String? token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('No auth token found. Please sign in again.')),
        );
      }
      return;
    }

    try {
      await _service.updateAttendeeInfo(
        token: token,
        attendeeId: attendee.id,
        name: submission.name,
        email: submission.email,
        phone: submission.phone,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(content: Text('Attendee info updated successfully')),
      );

      await _loadAttendees();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(pageContext).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openRefundTicketDialog(AttendeeTicket attendee) async {
    final BuildContext pageContext = context;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black45,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Refund Ticket',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 14),
                Text(
                  'Are you sure you want to refund this ticket for ${attendee.name}?',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 18,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: _orange),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Yes, Refund Ticket'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (attendee.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('Missing attendee ID')),
        );
      }
      return;
    }

    final String? token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('No auth token found. Please sign in again.')),
        );
      }
      return;
    }

    try {
      await _service.refundAttendee(
        token: token,
        attendeeId: attendee.id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(content: Text('Ticket refunded successfully')),
      );

      await _loadAttendees();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(pageContext).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openTransferTicketDialog(AttendeeTicket attendee) async {
    final BuildContext pageContext = context;
    final _TransferAttendeeSubmission? submission =
        await showDialog<_TransferAttendeeSubmission>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black45,
      builder: (BuildContext dialogContext) => const _TransferTicketDialog(),
    );

    if (submission == null) {
      return;
    }

    if (attendee.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('Missing attendee ID')),
        );
      }
      return;
    }

    final String? token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('No auth token found. Please sign in again.')),
        );
      }
      return;
    }

    try {
      await _service.transferAttendee(
        token: token,
        attendeeId: attendee.id,
        newName: submission.newName,
        newEmail: submission.newEmail,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(content: Text('Ticket transferred successfully')),
      );

      await _loadAttendees();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(pageContext).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openAttendeeNoteDialog(AttendeeTicket attendee) async {
    final BuildContext pageContext = context;
    final String? note = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black45,
      builder: (BuildContext dialogContext) {
        return _AttendeeNoteDialog(
          attendeeName: attendee.name,
          initialNote: attendee.note,
        );
      },
    );

    if (note == null) {
      return;
    }

    if (attendee.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('Missing attendee ID')),
        );
      }
      return;
    }

    final String? token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('No auth token found. Please sign in again.')),
        );
      }
      return;
    }

    try {
      await _service.addAttendeeNote(
        token: token,
        attendeeId: attendee.id,
        note: note,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(content: Text('Attendee note saved successfully')),
      );

      await _loadAttendees();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(pageContext).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  InputDecoration _dialogInputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF6A00)),
      ),
    );
  }

  Widget _dialogLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _openScanQrDialog() async {
    final TextEditingController manualCodeController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black45,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 620),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Scan QR',
                        style: TextStyle(
                          color: _orange,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Container(
                  height: 210,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'QR scanning not supported on this browser. Use manual code.',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Manual code',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: manualCodeController,
                        decoration: InputDecoration(
                          hintText: 'Enter ticket QR code or attendee id',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _orange),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final String code = manualCodeController.text.trim();
                        if (code.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter ticket QR code')),
                          );
                          return;
                        }
                        final bool success = await _checkInFromQrPayload(code);
                        if (success && mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Check In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    manualCodeController.dispose();
  }
}

class _FilteredOrderResult {
  final AttendeeOrder order;
  final List<AttendeeTicket> attendees;

  const _FilteredOrderResult({
    required this.order,
    required this.attendees,
  });
}

class _AddAttendeeDialog extends StatefulWidget {
  const _AddAttendeeDialog({
    required this.events,
    this.initialEventId,
  });

  final List<OrganizerEventOption> events;
  final String? initialEventId;

  @override
  State<_AddAttendeeDialog> createState() => _AddAttendeeDialogState();
}

class _AddAttendeeDialogState extends State<_AddAttendeeDialog> {
  static const Color _orange = Color(0xFFFF6A00);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ticketTypeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');

  late String _selectedEventId;
  String _selectedPaymentStatus = 'Paid';

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.events.any(
          (OrganizerEventOption event) => event.id == widget.initialEventId,
        )
        ? widget.initialEventId!
        : widget.events.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ticketTypeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add Attendee',
                      style: TextStyle(
                        color: _orange,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildDialogLabel('Event'),
              DropdownButtonFormField<String>(
                value: _selectedEventId,
                isExpanded: true,
                decoration: _dialogInputDecoration(),
                items: widget.events
                    .map(
                      (OrganizerEventOption event) => DropdownMenuItem<String>(
                        value: event.id,
                        child: Text(
                          event.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                selectedItemBuilder: (BuildContext context) {
                  return widget.events
                      .map(
                        (OrganizerEventOption event) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList();
                },
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedEventId = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              _buildDialogLabel('Name'),
              TextField(
                controller: _nameController,
                decoration: _dialogInputDecoration(),
              ),
              const SizedBox(height: 14),
              _buildDialogLabel('Email'),
              TextField(
                controller: _emailController,
                decoration: _dialogInputDecoration(),
              ),
              const SizedBox(height: 14),
              _buildDialogLabel('Phone'),
              TextField(
                controller: _phoneController,
                decoration: _dialogInputDecoration(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDialogLabel('Ticket Type'),
                        TextField(
                          controller: _ticketTypeController,
                          decoration: _dialogInputDecoration(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDialogLabel('Quantity'),
                        TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: _dialogInputDecoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildDialogLabel('Payment Status'),
              DropdownButtonFormField<String>(
                value: _selectedPaymentStatus,
                decoration: _dialogInputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'Refunded', child: Text('Refunded')),
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Free', child: Text('Free')),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedPaymentStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Add Attendee'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    final String ticketType = _ticketTypeController.text.trim();
    final int? quantity = int.tryParse(_quantityController.text.trim());

    if (name.isEmpty || email.isEmpty || phone.isEmpty || ticketType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    Navigator.of(context).pop(
      _AddAttendeeSubmission(
        eventId: _selectedEventId,
        name: name,
        email: email,
        phone: phone,
        ticketType: ticketType,
        paymentStatus: _selectedPaymentStatus,
        quantity: quantity,
      ),
    );
  }

  InputDecoration _dialogInputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF6A00)),
      ),
    );
  }

  Widget _buildDialogLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AddAttendeeSubmission {
  final String eventId;
  final String name;
  final String email;
  final String phone;
  final String ticketType;
  final String paymentStatus;
  final int quantity;

  const _AddAttendeeSubmission({
    required this.eventId,
    required this.name,
    required this.email,
    required this.phone,
    required this.ticketType,
    required this.paymentStatus,
    required this.quantity,
  });
}

class _EditAttendeeDialog extends StatefulWidget {
  const _EditAttendeeDialog({
    required this.attendee,
  });

  final AttendeeTicket attendee;

  @override
  State<_EditAttendeeDialog> createState() => _EditAttendeeDialogState();
}

class _EditAttendeeDialogState extends State<_EditAttendeeDialog> {
  static const Color _orange = Color(0xFFFF6A00);

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.attendee.name);
    _emailController = TextEditingController(text: widget.attendee.email);
    _phoneController = TextEditingController(text: widget.attendee.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Edit Buyer Info',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 14),
            _buildDialogLabel('Name'),
            TextField(
              controller: _nameController,
              decoration: _dialogInputDecoration(),
            ),
            const SizedBox(height: 12),
            _buildDialogLabel('Email'),
            TextField(
              controller: _emailController,
              decoration: _dialogInputDecoration(),
            ),
            const SizedBox(height: 12),
            _buildDialogLabel('Phone'),
            TextField(
              controller: _phoneController,
              decoration: _dialogInputDecoration(),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required')),
      );
      return;
    }

    Navigator.of(context).pop(
      _EditAttendeeSubmission(
        name: name,
        email: email,
        phone: phone,
      ),
    );
  }

  InputDecoration _dialogInputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF6A00)),
      ),
    );
  }

  Widget _buildDialogLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EditAttendeeSubmission {
  final String name;
  final String email;
  final String phone;

  const _EditAttendeeSubmission({
    required this.name,
    required this.email,
    required this.phone,
  });
}

class _TransferAttendeeSubmission {
  final String newName;
  final String newEmail;

  const _TransferAttendeeSubmission({
    required this.newName,
    required this.newEmail,
  });
}

class _TransferTicketDialog extends StatefulWidget {
  const _TransferTicketDialog();

  @override
  State<_TransferTicketDialog> createState() => _TransferTicketDialogState();
}

class _TransferTicketDialogState extends State<_TransferTicketDialog> {
  static const Color _orange = Color(0xFFFF6A00);

  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerEmailController = TextEditingController();

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Transfer Ticket',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 14),
            const Text(
              'Transfer this ticket to a new attendee.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildDialogLabel('New Owner Name'),
            TextField(
              controller: _ownerNameController,
              decoration: _dialogInputDecoration(),
            ),
            const SizedBox(height: 12),
            _buildDialogLabel('New Owner Email'),
            TextField(
              controller: _ownerEmailController,
              decoration: _dialogInputDecoration(),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: _orange),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Transfer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final String newName = _ownerNameController.text.trim();
    final String newEmail = _ownerEmailController.text.trim();

    if (newName.isEmpty || newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter new owner name and email')),
      );
      return;
    }

    Navigator.of(context).pop(
      _TransferAttendeeSubmission(
        newName: newName,
        newEmail: newEmail,
      ),
    );
  }

  InputDecoration _dialogInputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF6A00)),
      ),
    );
  }

  Widget _buildDialogLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AttendeeNoteDialog extends StatefulWidget {
  const _AttendeeNoteDialog({
    required this.attendeeName,
    required this.initialNote,
  });

  final String attendeeName;
  final String? initialNote;

  @override
  State<_AttendeeNoteDialog> createState() => _AttendeeNoteDialogState();
}

class _AttendeeNoteDialogState extends State<_AttendeeNoteDialog> {
  static const Color _orange = Color(0xFFFF6A00);

  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Note for ${widget.attendeeName}',
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Add a note...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _orange),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: _orange),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final String note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a note')),
      );
      return;
    }

    Navigator.of(context).pop(note);
  }
}
