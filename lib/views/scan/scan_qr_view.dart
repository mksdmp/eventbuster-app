import 'package:flutter/material.dart';

import '../../models/event_models.dart';

class ScanQrView extends StatefulWidget {
  const ScanQrView({
    super.key,
    required this.selectedEvent,
    required this.isEventsLoading,
    required this.hasEvents,
  });

  final OrganizerEventSummary? selectedEvent;
  final bool isEventsLoading;
  final bool hasEvents;

  @override
  State<ScanQrView> createState() => _ScanQrViewState();
}

class _ScanQrViewState extends State<ScanQrView> {
  static const Color _orange = Color(0xFFFF6A00);
  final TextEditingController _manualCodeController = TextEditingController();

  @override
  void dispose() {
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Scan QR',
          style: TextStyle(
            color: _orange,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Check in attendees for the selected event.',
          style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
        ),
        const SizedBox(height: 16),
        if (widget.isEventsLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: _orange)),
          )
        else if (!widget.hasEvents)
          _buildInfoCard('No events available for QR check-in.')
        else if (widget.selectedEvent == null)
          _buildInfoCard('Select an event from Home first.')
        else ...[
          _buildSelectedEventCard(widget.selectedEvent!),
          const SizedBox(height: 16),
          _buildScanPanel(context),
        ],
      ],
    );
  }

  Widget _buildInfoCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7DCE2)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSelectedEventCard(OrganizerEventSummary event) {
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
            'Selected Event',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
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

  Widget _buildScanPanel(BuildContext context) {
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
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 56,
                  color: _orange,
                ),
                SizedBox(height: 12),
                Text(
                  'QR scanning not supported on this build.',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Use manual code entry below.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Manual code',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualCodeController,
                  decoration: InputDecoration(
                    hintText: 'Enter ticket QR code',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _orange),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  final String code = _manualCodeController.text.trim();
                  if (code.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter ticket QR code')),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Check In ($code) clicked')),
                  );
                },
                child: const Text('Check In'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
