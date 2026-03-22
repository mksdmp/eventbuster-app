import 'package:flutter/material.dart';

import '../../models/attendee_models.dart';
import '../../services/auth_service.dart';
import '../../services/attendees_service.dart';

class AttendeesView extends StatefulWidget {
  const AttendeesView({super.key});

  @override
  State<AttendeesView> createState() => _AttendeesViewState();
}

class _AttendeesViewState extends State<AttendeesView> {
  static const Color _orange = Color(0xFFFF6A00);
  static const String _eventId = '69b78c891ab12ddc76e7ac86';

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
  String _selectedTicketType = 'All Ticket Types';
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendees() async {
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
        eventId: _eventId,
        token: token,
      );

      setState(() {
        _orders = payload.orders;
        _pagination = payload.pagination;
        if (_orders.isNotEmpty) {
          _expandedOrderId = _orders.first.orderId;
        }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'EventBuster',
          style: TextStyle(
            color: Color(0xFF1A2E7A),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: _orange,
              child: const Text(
                'A',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAttendees,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Attendees',
              style: TextStyle(
                color: _orange,
                fontSize: 40,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage and track event attendees',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildToolbar(context),
            const SizedBox(height: 14),
            _buildFilters(),
            const SizedBox(height: 14),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: _orange)),
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

  Widget _buildPagination() {
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
            'Page ${_pagination.page} of ${_pagination.pages} · Total ${_pagination.total}',
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: _pagination.page > 1 && !_isLoading
                ? () {
                    _changePage(_pagination.page - 1);
                  }
                : null,
            child: const Text('Previous'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            onPressed: _pagination.page < _pagination.pages && !_isLoading
                ? () {
                    _changePage(_pagination.page + 1);
                  }
                : null,
            child: const Text(
              'Next',
              style: TextStyle(color: Colors.white),
            ),
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
          label: 'Export CSV',
          icon: Icons.file_download_outlined,
          onTap: () => _showPlaceholderAction(context, 'Export CSV'),
        ),
        _actionButton(
          label: 'Scan QR',
          icon: Icons.qr_code_scanner,
          filled: true,
          red: true,
          onTap: _openScanQrDialog,
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
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(
            width: 700,
            child: TextField(
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
          ),
          _statusDropdown(),
          _ticketDropdown(),
        ],
      ),
    );
  }

  Widget _statusDropdown() {
    const List<String> statuses = <String>[
      'All Status',
      'Checked In',
      'Pending',
    ];

    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedStatus,
        decoration: _dropdownDecoration(),
        items: statuses
            .map((String e) => DropdownMenuItem<String>(value: e, child: Text(e)))
            .toList(),
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _selectedStatus = value;
            });
          }
        },
      ),
    );
  }

  Widget _ticketDropdown() {
    final Set<String> ticketTypeSet = _orders
        .expand((AttendeeOrder order) => order.attendees)
        .map((AttendeeTicket attendee) => attendee.ticketType.trim())
        .where((String type) => type.isNotEmpty)
        .map((String type) => _titleCase(type.toLowerCase()))
        .toSet();
    final List<String> sortedTypes = ticketTypeSet.toList()..sort();
    final List<String> ticketTypes = <String>[
      'All Ticket Types',
      ...sortedTypes,
    ];

    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedTicketType,
        decoration: _dropdownDecoration(),
        items: ticketTypes
            .map((String e) => DropdownMenuItem<String>(value: e, child: Text(e)))
            .toList(),
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              _selectedTicketType = value;
            });
          }
        },
      ),
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
    final List<AttendeeOrder> filteredOrders = _filteredOrders();
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

    return filteredOrders.map((AttendeeOrder order) {
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
                              Text(
                                'Order #${order.orderId}',
                                style: const TextStyle(
                                  color: _orange,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
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
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${order.ticketCount} Tickets',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Event: ${order.eventName} · Buyer: ${order.buyerName} · ${_formatDate(order.date)}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 16,
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
              _buildExpandedTable(order),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildExpandedTable(AttendeeOrder order) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1050,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Attendee',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Ticket Type',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Check-in Status',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 6),
              ...order.attendees.map(_buildAttendeeRow),
            ],
          ),
        ),
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
        children: [
          Expanded(
            flex: 4,
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
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  attendee.ticketType.toLowerCase(),
                  style: const TextStyle(color: Color(0xFF1D4ED8)),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _titleCase(attendee.checkInStatus),
                  style: const TextStyle(color: Color(0xFF92400E)),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: Colors.white,
                icon: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1F2937), width: 2),
                  ),
                  child: const Icon(Icons.menu_rounded, color: Color(0xFF475569), size: 18),
                ),
                onSelected: (String value) {
                  if (value == 'Edit Attendee info') {
                    _openEditAttendeeDialog(attendee);
                    return;
                  }
                  if (value == 'Refund Ticket') {
                    _openRefundTicketDialog(attendee);
                    return;
                  }
                  if (value == 'Transfer Ticket') {
                    _openTransferTicketDialog(attendee);
                    return;
                  }
                  if (value == 'Add Attendee Note') {
                    _openAttendeeNoteDialog(attendee);
                    return;
                  }
                  _showPlaceholderAction(context, value);
                },
                itemBuilder: (BuildContext context) => const [
                  PopupMenuItem(
                    value: 'Check In',
                    child: Text(
                      'Check In',
                      style: TextStyle(
                        color: Color(0xFFFF6A00),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Edit Attendee info',
                    child: Text('Edit Attendee info'),
                  ),
                  PopupMenuItem(value: 'Refund Ticket', child: Text('Refund Ticket')),
                  PopupMenuItem(
                    value: 'Transfer Ticket',
                    child: Text('Transfer Ticket'),
                  ),
                  PopupMenuItem(
                    value: 'Add Attendee Note',
                    child: Text('Add Attendee Note'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<AttendeeOrder> _filteredOrders() {
    final String search = _searchController.text.trim().toLowerCase();

    return _orders.where((AttendeeOrder order) {
      final bool statusOk = _selectedStatus == 'All Status' ||
          order.attendees.any(
            (AttendeeTicket attendee) =>
                _titleCase(attendee.checkInStatus) == _selectedStatus,
          );

      final bool ticketOk = _selectedTicketType == 'All Ticket Types' ||
          order.attendees.any(
            (AttendeeTicket attendee) {
              final String normalizedType =
                  _titleCase(attendee.ticketType.trim().toLowerCase());
              return normalizedType == _selectedTicketType;
            },
          );

      final bool searchOk = search.isEmpty ||
          order.orderId.toLowerCase().contains(search) ||
          order.buyerName.toLowerCase().contains(search) ||
          order.eventName.toLowerCase().contains(search) ||
          order.attendees.any(
            (AttendeeTicket attendee) =>
                attendee.name.toLowerCase().contains(search) ||
                attendee.email.toLowerCase().contains(search),
          );

      return statusOk && ticketOk && searchOk;
    }).toList();
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

  Future<void> _openAddAttendeeDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController ticketTypeController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(text: '1');

    final List<String> events = _orders
        .map((AttendeeOrder order) => order.eventName)
        .toSet()
        .where((String e) => e.trim().isNotEmpty)
        .toList();

    if (events.isEmpty) {
      events.add('Virtual Networking for Women Entrepreneurs');
    }

    String selectedEvent = events.first;
    String selectedPaymentStatus = 'Paid';

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black45,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
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
                                fontSize: 32,
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
                      const SizedBox(height: 8),
                      _dialogLabel('Event'),
                      DropdownButtonFormField<String>(
                        initialValue: selectedEvent,
                        decoration: _dialogInputDecoration(),
                        items: events
                            .map(
                              (String e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setModalState(() {
                              selectedEvent = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      _dialogLabel('Name'),
                      TextField(
                        controller: nameController,
                        decoration: _dialogInputDecoration(),
                      ),
                      const SizedBox(height: 14),
                      _dialogLabel('Email'),
                      TextField(
                        controller: emailController,
                        decoration: _dialogInputDecoration(),
                      ),
                      const SizedBox(height: 14),
                      _dialogLabel('Phone'),
                      TextField(
                        controller: phoneController,
                        decoration: _dialogInputDecoration(),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _dialogLabel('Ticket Type'),
                                TextField(
                                  controller: ticketTypeController,
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
                                _dialogLabel('Quantity'),
                                TextField(
                                  controller: quantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: _dialogInputDecoration(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _dialogLabel('Payment Status'),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPaymentStatus,
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
                            setModalState(() {
                              selectedPaymentStatus = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9),
                              foregroundColor: const Color(0xFF334155),
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
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _showPlaceholderAction(context, 'Add Attendee');
                            },
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
              );
            },
          ),
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    ticketTypeController.dispose();
    quantityController.dispose();
  }

  Future<void> _openEditAttendeeDialog(AttendeeTicket attendee) async {
    final TextEditingController nameController = TextEditingController(
      text: attendee.name,
    );
    final TextEditingController emailController = TextEditingController(
      text: attendee.email,
    );
    final TextEditingController phoneController = TextEditingController(
      text: attendee.phone,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black45,
      builder: (BuildContext dialogContext) {
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
                          fontSize: 30,
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
                _dialogLabel('Name'),
                TextField(
                  controller: nameController,
                  decoration: _dialogInputDecoration(),
                ),
                const SizedBox(height: 12),
                _dialogLabel('Email'),
                TextField(
                  controller: emailController,
                  decoration: _dialogInputDecoration(),
                ),
                const SizedBox(height: 12),
                _dialogLabel('Phone'),
                TextField(
                  controller: phoneController,
                  decoration: _dialogInputDecoration(),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF334155),
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
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _showPlaceholderAction(context, 'Save Attendee Info');
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
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  Future<void> _openRefundTicketDialog(AttendeeTicket attendee) async {
    await showDialog<void>(
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
                          fontSize: 30,
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
                    fontSize: 24,
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
                        backgroundColor: const Color(0xFFF8FAFC),
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
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
                        Navigator.of(dialogContext).pop();
                        _showPlaceholderAction(context, 'Yes, Refund Ticket');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
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
  }

  Future<void> _openTransferTicketDialog(AttendeeTicket attendee) async {
    final TextEditingController ownerNameController = TextEditingController();
    final TextEditingController ownerEmailController = TextEditingController();

    await showDialog<void>(
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
                        'Transfer Ticket',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w700,
                          fontSize: 30,
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
                const Text(
                  'Transfer this ticket to a new attendee.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                _dialogLabel('New Owner Name'),
                TextField(
                  controller: ownerNameController,
                  decoration: _dialogInputDecoration(),
                ),
                const SizedBox(height: 12),
                _dialogLabel('New Owner Email'),
                TextField(
                  controller: ownerEmailController,
                  decoration: _dialogInputDecoration(),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC),
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
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
                        final String newName = ownerNameController.text.trim();
                        final String newEmail = ownerEmailController.text.trim();

                        if (newName.isEmpty || newEmail.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter new owner name and email'),
                            ),
                          );
                          return;
                        }

                        Navigator.of(dialogContext).pop();
                        _showPlaceholderAction(
                          context,
                          'Transfer Ticket (${attendee.name} -> $newName)',
                        );
                      },
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
      },
    );

    ownerNameController.dispose();
    ownerEmailController.dispose();
  }

  Future<void> _openAttendeeNoteDialog(AttendeeTicket attendee) async {
    final TextEditingController noteController = TextEditingController();

    await showDialog<void>(
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
                    Expanded(
                      child: Text(
                        'Note for ${attendee.name}',
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w700,
                          fontSize: 30,
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
                TextField(
                  controller: noteController,
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
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC),
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
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
                        final String note = noteController.text.trim();
                        if (note.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please add a note')),
                          );
                          return;
                        }

                        Navigator.of(dialogContext).pop();
                        _showPlaceholderAction(context, 'Save Note (${attendee.name})');
                      },
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
      },
    );

    noteController.dispose();
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
                          fontSize: 30,
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
                          hintText: 'Enter ticket QR code',
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
                      onPressed: () {
                        final String code = manualCodeController.text.trim();
                        if (code.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter ticket QR code')),
                          );
                          return;
                        }
                        Navigator.of(dialogContext).pop();
                        _showPlaceholderAction(context, 'Check In ($code)');
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
