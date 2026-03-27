import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/constants.dart';
import '../../models/booking_models.dart';
import '../../services/auth_service.dart';
import '../../services/bookings_service.dart';
import '../../services/pdf_file_saver_stub.dart'
    if (dart.library.io) '../../services/pdf_file_saver_io.dart'
    if (dart.library.html) '../../services/pdf_file_saver_web.dart';
import '../ticket/ticket_detail_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  final String userName;
  final String userEmail;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthService _authService = AuthService();
  final BookingsService _bookingsService = BookingsService();

  bool _isLoading = true;
  String? _loadingQrOrderId;
  String? _downloadingPdfOrderId;
  String? _error;
  List<MyBookingOrder> _orders = <MyBookingOrder>[];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final String? token = await _authService.getToken();
      if (token == null || token.trim().isEmpty) {
        throw Exception('No auth token found. Please sign in again.');
      }

      final MyBookingsPayload payload = await _bookingsService.fetchMyBookings(
        token: token,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _orders = payload.orders;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _ProfileHeaderCard(
            userName: widget.userName,
            userEmail: widget.userEmail,
          ),
          const SizedBox(height: 20),
          const Text(
            'My Bookings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'All your booked events appear here.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: CircularProgressIndicator(color: AppConstants.appOrange),
              ),
            )
          else if (_error != null)
            _ProfileStateCard(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load bookings',
              message: _error!,
              actionLabel: 'Try Again',
              onTap: _loadBookings,
            )
          else if (_orders.isEmpty)
            const _ProfileStateCard(
              icon: Icons.event_busy_outlined,
              title: 'No bookings yet',
              message: 'Your booked events will appear here.',
            )
          else
            ..._orders.map(
              (MyBookingOrder order) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _BookingCard(
                  order: order,
                  onDownloadPdf: () => _handleDownloadPdf(order),
                  onShowQrCode: () => _showQrCodeDialog(order),
                  isShowingQrCode: _loadingQrOrderId == order.orderId,
                  isDownloadingPdf: _downloadingPdfOrderId == order.orderId,
                  onViewTicket: () => _openTicketDetails(order),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleDownloadPdf(MyBookingOrder order) async {
    if (_downloadingPdfOrderId != null) {
      return;
    }

    setState(() {
      _downloadingPdfOrderId = order.orderId;
    });

    try {
      final String? token = await _authService.getToken();
      if (token == null || token.trim().isEmpty) {
        throw Exception('No auth token found. Please sign in again.');
      }

      String eventId = order.event.id.trim();
      String paymentId = order.paymentId.trim();

      if (eventId.isEmpty || paymentId.isEmpty) {
        final VerifiedTicketPayload payload = await _bookingsService.verifyTicket(
          token: token,
          code: order.orderId,
        );

        if (payload.tickets.isEmpty) {
          throw Exception('No ticket details were returned for this booking.');
        }

        eventId = eventId.isEmpty ? payload.ticket.event.id.trim() : eventId;
        paymentId = paymentId.isEmpty ? payload.ticket.paymentId.trim() : paymentId;
      }

      if (eventId.isEmpty || paymentId.isEmpty) {
        throw Exception('Missing event or payment details for this booking.');
      }

      final List<int> pdfBytes = await _bookingsService.downloadTicketPdf(
        token: token,
        eventId: eventId,
        orderId: order.orderId,
        paymentId: paymentId,
      );

      final String savedPath = await savePdfBytes(
        bytes: pdfBytes,
        fileName: 'eventbuster-ticket-${order.orderId}.pdf',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF downloaded: $savedPath'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _downloadingPdfOrderId = null;
      });
    }
  }

  Future<void> _showQrCodeDialog(MyBookingOrder order) async {
    if (_loadingQrOrderId != null) {
      return;
    }

    setState(() {
      _loadingQrOrderId = order.orderId;
    });

    try {
      final String? token = await _authService.getToken();
      if (token == null || token.trim().isEmpty) {
        throw Exception('No auth token found. Please sign in again.');
      }

      final VerifiedTicketPayload payload = await _bookingsService.verifyTicket(
        token: token,
        code: order.orderId,
      );

      if (!mounted) {
        return;
      }

      if (payload.tickets.isEmpty) {
        throw Exception('No attendee QR codes were returned for this booking.');
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext dialogContext) {
          return _BookingQrSheet(
            order: order,
            tickets: payload.tickets,
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingQrOrderId = null;
      });
    }
  }

  Future<void> _openTicketDetails(MyBookingOrder order) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => TicketDetailView(order: order),
      ),
    );
  }
}

class _BookingQrSheet extends StatefulWidget {
  const _BookingQrSheet({
    required this.order,
    required this.tickets,
  });

  final MyBookingOrder order;
  final List<VerifiedTicket> tickets;

  @override
  State<_BookingQrSheet> createState() => _BookingQrSheetState();
}

class _BookingQrSheetState extends State<_BookingQrSheet> {
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

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.userName,
    required this.userEmail,
  });

  final String userName;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    final String displayName = userName.trim().isEmpty ? 'User' : userName.trim();
    final String displayEmail = userEmail.trim().isEmpty ? '-' : userEmail.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFF7A1A), Color(0xFFFF4D4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1FFF6A00),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Text(
              displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Profile',
                  style: TextStyle(
                    color: Color(0xFFFFEFE3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayEmail,
                  style: const TextStyle(
                    color: Color(0xFFFFF2EA),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.order,
    required this.onDownloadPdf,
    required this.onShowQrCode,
    required this.isShowingQrCode,
    required this.isDownloadingPdf,
    required this.onViewTicket,
  });

  final MyBookingOrder order;
  final VoidCallback onDownloadPdf;
  final VoidCallback onShowQrCode;
  final bool isShowingQrCode;
  final bool isDownloadingPdf;
  final VoidCallback onViewTicket;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD7BF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _BookingImage(imageUrl: order.event.imageUrl),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: _BookingOverflowMenu(
                  isDownloadingPdf: isDownloadingPdf,
                  isShowingQrCode: isShowingQrCode,
                  onDownloadPdf: onDownloadPdf,
                  onShowQrCode: onShowQrCode,
                  onViewTicket: onViewTicket,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusChip(label: order.statusLabel),
                const SizedBox(height: 10),
                Text(
                  order.event.title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _MetaLine(
                  icon: Icons.calendar_today_outlined,
                  text: _formatEventDate(order.event.startDate, order.event.date),
                ),
                const SizedBox(height: 6),
                _MetaLine(
                  icon: Icons.location_on_outlined,
                  text: order.event.locationLine,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _InfoTile(
                        label: 'Booking ID',
                        value: order.orderId,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _InfoDivider(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoTile(
                        label: 'Tickets',
                        value: _formatTicketCount(order.ticketQty),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _InfoDivider(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoTile(
                        label: 'Total',
                        value: _formatCurrency(order.event.currency, order.amount),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Ticket Types: ${order.ticketTypesLabel}',
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _BookingMenuAction {
  downloadPdf,
  showQrCode,
  viewTicket,
}

class _BookingOverflowMenu extends StatelessWidget {
  const _BookingOverflowMenu({
    required this.isDownloadingPdf,
    required this.isShowingQrCode,
    required this.onDownloadPdf,
    required this.onShowQrCode,
    required this.onViewTicket,
  });

  final bool isDownloadingPdf;
  final bool isShowingQrCode;
  final VoidCallback onDownloadPdf;
  final VoidCallback onShowQrCode;
  final VoidCallback onViewTicket;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: PopupMenuButton<_BookingMenuAction>(
        tooltip: 'More actions',
        onSelected: (_BookingMenuAction action) {
          switch (action) {
            case _BookingMenuAction.downloadPdf:
              onDownloadPdf();
              break;
            case _BookingMenuAction.showQrCode:
              onShowQrCode();
              break;
            case _BookingMenuAction.viewTicket:
              onViewTicket();
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<_BookingMenuAction>>[
          PopupMenuItem<_BookingMenuAction>(
            value: _BookingMenuAction.downloadPdf,
            enabled: !isDownloadingPdf,
            child: Text(isDownloadingPdf ? 'Downloading PDF...' : 'Download PDF'),
          ),
          PopupMenuItem<_BookingMenuAction>(
            value: _BookingMenuAction.showQrCode,
            enabled: !isShowingQrCode,
            child: Text(isShowingQrCode ? 'Loading QR Code...' : 'Show QR Code'),
          ),
          const PopupMenuItem<_BookingMenuAction>(
            value: _BookingMenuAction.viewTicket,
            child: Text('View Ticket'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        color: Colors.white,
        icon: const Icon(
          Icons.more_vert_rounded,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

class _BookingImage extends StatelessWidget {
  const _BookingImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFFFFF0E6),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          color: AppConstants.appOrange,
          size: 38,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
        return Container(
          color: const Color(0xFFFFF0E6),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppConstants.appOrange,
            size: 38,
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final String normalized = label.toLowerCase();
    final bool isRefunded = normalized.contains('refund');
    final bool isCompleted =
        normalized.contains('complete') || normalized.contains('paid') || normalized.contains('confirm');

    final Color backgroundColor = isRefunded
        ? const Color(0xFFFFE1E3)
        : isCompleted
            ? const Color(0xFFDDF8E7)
            : const Color(0xFFFFF0D8);
    final Color foregroundColor = isRefunded
        ? const Color(0xFFC81E1E)
        : isCompleted
            ? const Color(0xFF0C8A43)
            : const Color(0xFF9A6700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      color: const Color(0xFFE5E7EB),
    );
  }
}

class _ProfileStateCard extends StatelessWidget {
  const _ProfileStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppConstants.appOrange),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.appOrange,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
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

String _formatEventDate(DateTime? date, String rawDate) {
  if (date == null) {
    return rawDate.isEmpty ? '-' : rawDate;
  }

  const List<String> weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
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

  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
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

String _formatTicketCount(int count) {
  final int safeCount = count < 0 ? 0 : count;
  final String label = safeCount == 1 ? 'Ticket' : 'Tickets';
  return '$safeCount $label';
}
