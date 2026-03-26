import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/constants.dart';
import '../../models/booking_models.dart';
import '../../services/auth_service.dart';
import '../../services/bookings_service.dart';

class TicketDetailView extends StatefulWidget {
  const TicketDetailView({
    super.key,
    required this.order,
  });

  final MyBookingOrder order;

  @override
  State<TicketDetailView> createState() => _TicketDetailViewState();
}

class _TicketDetailViewState extends State<TicketDetailView> {
  final AuthService _authService = AuthService();
  final BookingsService _bookingsService = BookingsService();

  bool _isLoading = true;
  VerifiedTicket? _verifiedTicket;
  List<VerifiedTicket> _verifiedTickets = <VerifiedTicket>[];
  EventDetails? _eventDetails;
  bool _hasPoppedForVerifyError = false;

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
  }

  Future<void> _loadTicketDetails() async {
    try {
      final String? token = await _authService.getToken();
      if (token == null || token.trim().isEmpty) {
        await _popBack();
        return;
      }

      final VerifiedTicketPayload verified = await _bookingsService.verifyTicket(
        token: token,
        code: widget.order.orderId,
      );

      EventDetails? eventDetails;
      final String eventId = verified.ticket.event.id.isNotEmpty
          ? verified.ticket.event.id
          : widget.order.event.id;
      if (eventId.isNotEmpty) {
        try {
          eventDetails = await _bookingsService.fetchEventDetails(
            token: token,
            eventId: eventId,
          );
        } catch (_) {
          eventDetails = null;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _verifiedTicket = verified.ticket;
        _verifiedTickets = verified.tickets;
        _eventDetails = eventDetails;
        _isLoading = false;
      });
    } catch (_) {
      await _popBack();
    }
  }

  Future<void> _popBack() async {
    if (!mounted || _hasPoppedForVerifyError) {
      return;
    }

    _hasPoppedForVerifyError = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFF111827),
        ),
      ),
      body: _isLoading || _verifiedTicket == null
          ? const Center(
              child: CircularProgressIndicator(color: AppConstants.appOrange),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _eventTitle,
                        style: const TextStyle(
                          color: AppConstants.appOrange,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 2.25,
                          child: _TicketHeroImage(imageUrl: _eventImageUrl),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _TopInfoSection(
                        ticketCountText: _formatTicketCount(
                          widget.order.ticketQty > 0
                              ? widget.order.ticketQty
                              : _verifiedTicket!.quantity,
                        ),
                        totalText: 'Order total: ${_formatCurrency(_currency, widget.order.amount)}',
                        dateText: _formatTicketDateTime(_eventStartDate, _eventRawDate),
                        venueTitle: _venueName,
                        venueAddress: _venueAddressLine,
                        venueRegion: _venueRegionLine,
                        onAddToGoogle: _showCalendarMessage,
                        onViewOnMap: _showMapMessage,
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _showContactMessage,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text(
                          'Contact the organizer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _organizerEmail,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Divider(color: Color(0xFFE5E7EB), height: 1),
                      const SizedBox(height: 28),
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Order #${widget.order.orderId} - ${_formatOrderDate(widget.order.orderDate ?? _verifiedTicket!.createdAt)}',
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _paymentHeadline,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'This charge will appear on your statement as eventbuster.com',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Color(0xFFE5E7EB), height: 1),
                      const SizedBox(height: 14),
                      _SummaryLineRow(
                        leftText: _customerName,
                        middleText: '${_verifiedTicket!.quantity} x ${_verifiedTicket!.ticketType.toLowerCase()}',
                        rightText: _formatCurrency(_currency, widget.order.amount),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFFE5E7EB), height: 1),
                      const SizedBox(height: 16),
                      _SummaryValueRow(
                        label: 'Tickets Subtotal',
                        value: _formatCurrency(_currency, widget.order.amount),
                      ),
                      const SizedBox(height: 12),
                      _SummaryValueRow(
                        label: 'Total',
                        value: _formatCurrency(_currency, widget.order.amount),
                        isTotal: true,
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _refundNote,
                          style: const TextStyle(
                            color: AppConstants.appOrange,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This order is subject to Eventbuster Terms of Service and Privacy Policy.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 34),
                      const Divider(color: Color(0xFFE5E7EB), height: 1),
                      const SizedBox(height: 28),
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          color: Color(0xFF5B21B6),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'The event organizer has provided the following information:',
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _additionalInformation,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Age Restriction: ${_ageRestriction}',
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 34),
                      _BottomActionRow(
                        onDownloadPdf: _showPdfMessage,
                        onShowQrCode: _showQrCodeDialog,
                        onBrowseMoreEvents: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String get _eventTitle {
    return _eventDetails?.title ??
        _verifiedTicket?.event.title ??
        widget.order.event.title;
  }

  String get _eventImageUrl {
    final String image = _eventDetails?.imageUrl ?? widget.order.event.imageUrl;
    return image.trim();
  }

  String get _currency {
    return (_eventDetails?.currency ?? widget.order.event.currency).trim().isEmpty
        ? 'USD'
        : (_eventDetails?.currency ?? widget.order.event.currency).trim();
  }

  DateTime? get _eventStartDate {
    return _eventDetails?.startDate ??
        _verifiedTicket?.event.startDate ??
        widget.order.event.startDate;
  }

  String get _eventRawDate {
    return _eventDetails?.date ?? widget.order.event.date;
  }

  String get _venueName {
    final String value =
        _eventDetails?.venue ?? _verifiedTicket?.event.venue ?? widget.order.event.venue;
    return value.trim().isEmpty ? '-' : value.trim();
  }

  String get _venueAddressLine {
    final String value =
        _eventDetails?.address ?? _verifiedTicket?.event.address ?? widget.order.event.address;
    return value.trim().isEmpty ? '-' : value.trim();
  }

  String get _venueRegionLine {
    final String city = (_eventDetails?.city ?? _verifiedTicket?.event.city ?? widget.order.event.city).trim();
    final String state = (_eventDetails?.state ?? _verifiedTicket?.event.state ?? widget.order.event.state).trim();
    final String zipCode =
        (_eventDetails?.zipCode ?? _verifiedTicket?.event.zipCode ?? widget.order.event.zipCode).trim();

    return <String>[city, state, zipCode]
        .where((String part) => part.isNotEmpty)
        .join(', ');
  }

  String get _organizerEmail {
    final String value = (_eventDetails?.organizerEmail).toString().trim();
    return value.isEmpty || value == 'null' ? '-' : value;
  }

  String get _customerName {
    final String value = widget.order.customerName.trim().isNotEmpty
        ? widget.order.customerName.trim()
        : _verifiedTicket!.name.trim();
    return value.isEmpty ? '-' : value;
  }

  String get _refundNote {
    final String normalizedStatus = widget.order.statusLabel.toLowerCase();
    if (normalizedStatus.contains('refund')) {
      return 'This ticket has been refunded';
    }
    return 'Tickets are non refundable';
  }

  String get _paymentHeadline {
    final String normalized = widget.order.paymentStatus.trim().toLowerCase();
    final String amount = _formatCurrency(_currency, widget.order.amount);
    if (normalized == 'paid') {
      return '$amount paid by Card';
    }
    if (normalized.isEmpty) {
      return amount;
    }
    return '$amount ${_capitalizeWords(normalized)}';
  }

  String get _additionalInformation {
    final String note = _stripHtml(_eventDetails?.emailNote ?? '');
    if (note.isNotEmpty) {
      return note;
    }

    final String description = _stripHtml(_eventDetails?.description ?? '');
    if (description.isNotEmpty) {
      return description;
    }

    return 'No additional information provided.';
  }

  String get _ageRestriction {
    final String value =
        (_eventDetails?.ageRestriction ?? _verifiedTicket?.event.ageRestriction ?? '').trim();
    return value.isEmpty ? 'Not specified' : value;
  }

  void _showCalendarMessage() {
    _showSnackBar('Google Calendar integration is not connected yet.');
  }

  void _showContactMessage() {
    _showSnackBar('Organizer contact actions are not connected yet.');
  }

  void _showMapMessage() {
    _showSnackBar('Map integration is not connected yet.');
  }

  void _showPdfMessage() {
    _showSnackBar('PDF download is not connected yet.');
  }

  void _showQrCodeDialog() {
    if (_verifiedTickets.isEmpty) {
      _showSnackBar('No attendee QR codes were returned for this booking.');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return _TicketQrSheet(
          order: widget.order,
          tickets: _verifiedTickets,
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _TicketHeroImage extends StatelessWidget {
  const _TicketHeroImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFFFFF3E7),
        alignment: Alignment.center,
        child: const Icon(
          Icons.event_rounded,
          size: 56,
          color: AppConstants.appOrange,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
        return Container(
          color: const Color(0xFFFFF3E7),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            size: 56,
            color: AppConstants.appOrange,
          ),
        );
      },
    );
  }
}

class _TicketQrSheet extends StatefulWidget {
  const _TicketQrSheet({
    required this.order,
    required this.tickets,
  });

  final MyBookingOrder order;
  final List<VerifiedTicket> tickets;

  @override
  State<_TicketQrSheet> createState() => _TicketQrSheetState();
}

class _TicketQrSheetState extends State<_TicketQrSheet> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.84;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
        child: Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x220F172A),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ticket QR Codes',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.order.event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF111827),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4EA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Swipe left or right to view all ${widget.tickets.length} ticket QR codes.',
                    style: const TextStyle(
                      color: Color(0xFF9A3412),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.tickets.length,
                  onPageChanged: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final VerifiedTicket ticket = widget.tickets[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _TicketQrCard(
                        ticket: ticket,
                        pageIndex: index,
                        totalCount: widget.tickets.length,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(widget.tickets.length, (int index) {
                  final bool isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppConstants.appOrange : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketQrCard extends StatelessWidget {
  const _TicketQrCard({
    required this.ticket,
    required this.pageIndex,
    required this.totalCount,
  });

  final VerifiedTicket ticket;
  final int pageIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFF7A1A), Color(0xFFFF4D4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Ticket ${pageIndex + 1} of $totalCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                ticket.ticketType.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: ticket.id,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF111827),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'QR payload',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      ticket.id,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            ticket.name.trim().isEmpty ? _fallbackAttendeeName(ticket.email) : ticket.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ticket.email.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFF3EA),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _TopInfoSection extends StatelessWidget {
  const _TopInfoSection({
    required this.ticketCountText,
    required this.totalText,
    required this.dateText,
    required this.venueTitle,
    required this.venueAddress,
    required this.venueRegion,
    required this.onAddToGoogle,
    required this.onViewOnMap,
  });

  final String ticketCountText;
  final String totalText;
  final String dateText;
  final String venueTitle;
  final String venueAddress;
  final String venueRegion;
  final VoidCallback onAddToGoogle;
  final VoidCallback onViewOnMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoIconBlock(
          icon: Icons.confirmation_num_outlined,
          iconColor: AppConstants.appOrange,
          title: ticketCountText,
          subtitle: totalText,
        ),
        const SizedBox(height: 22),
        _InfoIconBlock(
          icon: Icons.calendar_today_outlined,
          iconColor: const Color(0xFF9CA3AF),
          title: dateText,
          actionText: 'Add to Google',
          onActionTap: onAddToGoogle,
        ),
        const SizedBox(height: 22),
        _InfoIconBlock(
          icon: Icons.location_on,
          iconColor: AppConstants.appOrange,
          title: venueTitle,
          subtitle: venueAddress,
          detailText: venueRegion,
          actionText: 'View on map',
          onActionTap: onViewOnMap,
        ),
      ],
    );
  }
}

class _InfoIconBlock extends StatelessWidget {
  const _InfoIconBlock({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.detailText,
    this.actionText,
    this.onActionTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? detailText;
  final String? actionText;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 15,
                  ),
                ),
              ],
              if (detailText != null && detailText!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  detailText!,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 15,
                  ),
                ),
              ],
              if (actionText != null && onActionTap != null) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionText!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryLineRow extends StatelessWidget {
  const _SummaryLineRow({
    required this.leftText,
    required this.middleText,
    required this.rightText,
  });

  final String leftText;
  final String middleText;
  final String rightText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            leftText,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: Text(
            middleText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            rightText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryValueRow extends StatelessWidget {
  const _SummaryValueRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: const Color(0xFF1F2937),
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 130,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: const Color(0xFF111827),
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomActionRow extends StatelessWidget {
  const _BottomActionRow({
    required this.onDownloadPdf,
    required this.onShowQrCode,
    required this.onBrowseMoreEvents,
  });

  final VoidCallback onDownloadPdf;
  final VoidCallback onShowQrCode;
  final VoidCallback onBrowseMoreEvents;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton(
          onPressed: onDownloadPdf,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.appOrange,
            side: const BorderSide(color: Color(0xFFFFB37A)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Download PDF',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFFFF8A1F), Color(0xFFFF3B3F)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33FF6A00),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onShowQrCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Show QR Code',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        // TextButton(
        //   onPressed: onBrowseMoreEvents,
        //   style: TextButton.styleFrom(
        //     foregroundColor: Colors.white,
        //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        //   ),
        //   child: const Text(
        //     'Browse More Events',
        //     style: TextStyle(
        //       fontWeight: FontWeight.w700,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

String _formatTicketCount(int count) {
  final int safeCount = count < 0 ? 0 : count;
  return '$safeCount x Tickets';
}

String _formatTicketDateTime(DateTime? date, String rawDate) {
  if (date == null) {
    return rawDate.isEmpty ? '-' : rawDate;
  }

  const List<String> months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final int hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final String minute = date.minute.toString().padLeft(2, '0');
  final String meridiem = date.hour >= 12 ? 'PM' : 'AM';

  return '${months[date.month - 1]} ${_withOrdinal(date.day)}, ${date.year} at $hour:$minute$meridiem';
}

String _formatOrderDate(DateTime? date) {
  if (date == null) {
    return '-';
  }

  const List<String> months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatCurrency(String currency, double amount) {
  final String symbol = <String, String>{
        'USD': '\$',
        'INR': '₹',
        'EUR': '€',
        'GBP': '£',
      }[currency.toUpperCase()] ??
      '${currency.toUpperCase()} ';

  final String fixed = amount.toStringAsFixed(2);
  final List<String> parts = fixed.split('.');
  final String whole = parts.first;
  final String decimal = parts.last;
  final StringBuffer buffer = StringBuffer();

  for (int index = 0; index < whole.length; index++) {
    final int reverseIndex = whole.length - index;
    buffer.write(whole[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return '$symbol${buffer.toString()}.$decimal';
}

String _stripHtml(String input) {
  return input
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _capitalizeWords(String value) {
  return value
      .split(' ')
      .where((String part) => part.trim().isNotEmpty)
      .map((String part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _fallbackAttendeeName(String email) {
  final String trimmed = email.trim();
  if (trimmed.isEmpty) {
    return 'Attendee';
  }

  final int splitIndex = trimmed.indexOf('@');
  if (splitIndex <= 0) {
    return trimmed;
  }

  return trimmed.substring(0, splitIndex);
}

String _withOrdinal(int day) {
  if (day >= 11 && day <= 13) {
    return '${day}th';
  }

  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}
