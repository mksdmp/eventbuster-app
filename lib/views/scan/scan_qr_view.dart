import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/event_models.dart';
import '../../services/attendees_service.dart';
import '../../services/auth_service.dart';
import '../../utils/check_in_qr_parser.dart';

class ScanQrView extends StatefulWidget {
  const ScanQrView({
    super.key,
    required this.selectedEvent,
    required this.isEventsLoading,
    required this.hasEvents,
    required this.isActive,
  });

  final OrganizerEventSummary? selectedEvent;
  final bool isEventsLoading;
  final bool hasEvents;
  final bool isActive;

  @override
  State<ScanQrView> createState() => _ScanQrViewState();
}

class _ScanQrViewState extends State<ScanQrView> {
  static const Color _orange = Color(0xFFFF6A00);

  final TextEditingController _manualCodeController = TextEditingController();
  final AuthService _authService = AuthService();
  final AttendeesService _service = AttendeesService();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isSubmitting = false;
  bool _torchEnabled = false;
  String? _lastProcessedPayload;
  DateTime? _lastProcessedAt;
  String? _lastResolvedAttendeeId;

  bool get _supportsScanner {
    if (kIsWeb) {
      return true;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  @override
  void didUpdateWidget(covariant ScanQrView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedEvent?.id != widget.selectedEvent?.id) {
      _manualCodeController.clear();
      _lastProcessedPayload = null;
      _lastProcessedAt = null;
      _lastResolvedAttendeeId = null;
    }
    if (oldWidget.isActive && !widget.isActive && _torchEnabled) {
      _torchEnabled = false;
    }
  }

  @override
  void dispose() {
    _manualCodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_isSubmitting) {
      return;
    }

    for (final Barcode barcode in capture.barcodes) {
      final String rawValue = (barcode.rawValue ?? '').trim();
      if (rawValue.isEmpty) {
        continue;
      }

      if (_shouldIgnoreDuplicate(rawValue)) {
        return;
      }

      _submitCheckIn(rawValue);
      return;
    }
  }

  bool _shouldIgnoreDuplicate(String rawValue) {
    if (_lastProcessedPayload != rawValue) {
      return false;
    }

    final DateTime? lastProcessedAt = _lastProcessedAt;
    if (lastProcessedAt == null) {
      return false;
    }

    return DateTime.now().difference(lastProcessedAt) < const Duration(seconds: 3);
  }

  Future<void> _submitCheckIn(String rawValue) async {
    final String trimmed = rawValue.trim();
    if (trimmed.isEmpty || _isSubmitting) {
      return;
    }

    final ParsedCheckInQrPayload payload = CheckInQrParser.parse(trimmed);
    final String? attendeeId = payload.attendeeId;

    if (attendeeId == null || attendeeId.isEmpty) {
      final String message = payload.eventId != null
          ? 'This QR/manual code only contains event id. Check-in API requires attendee id.'
          : 'Unable to find attendee id in the scanned QR/manual code.';
      await _showResultDialog(
        title: 'Check-In Failed',
        message: message,
        isSuccess: false,
      );
      return;
    }

    if (widget.selectedEvent != null &&
        payload.eventId != null &&
        payload.eventId != widget.selectedEvent!.id) {
      await _showResultDialog(
        title: 'Check-In Failed',
        message: 'This QR code belongs to a different event.',
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _lastProcessedPayload = trimmed;
      _lastProcessedAt = DateTime.now();
    });

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
        return;
      }

      _manualCodeController.clear();
      setState(() {
        _lastResolvedAttendeeId = attendeeId;
      });

      await _showResultDialog(
        title: 'Check-In Successful',
        message: 'Attendee checked in successfully.',
        isSuccess: true,
      );
    } catch (e) {
      await _showResultDialog(
        title: 'Check-In Failed',
        message: e.toString(),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) async {
    if (!mounted) {
      return;
    }

    final Color accentColor = isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final IconData icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 34),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Scan attendee QR codes.',
          style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
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
          _buildScanPanel(),
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
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.venueLine,
            style: const TextStyle(color: Color(0xFF334155), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildScanPanel() {
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
            'Scanner',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _supportsScanner ? _buildScannerPreview() : _buildUnsupportedScannerCard(),
          const SizedBox(height: 16),
          if (_lastResolvedAttendeeId != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Last checked-in attendee id: $_lastResolvedAttendeeId',
                style: const TextStyle(
                  color: Color(0xFF9A3412),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                ),
              ),
          // const Text(
          //   'Manual code',
          //   style: TextStyle(
          //     color: Color(0xFF1E293B),
          //     fontWeight: FontWeight.w700,
          //   ),
          // ),
          // const SizedBox(height: 8),
          // const Text(
          //   'Paste the full QR payload or attendee id to use the same check-in API.',
          //   style: TextStyle(
          //     color: Color(0xFF64748B),
          //     fontSize: 12,
          //   ),
          // ),
          // const SizedBox(height: 10),
          // Row(
          //   children: [
          //     Expanded(
          //       child: TextField(
          //         controller: _manualCodeController,
          //         textInputAction: TextInputAction.done,
          //         onSubmitted: _isSubmitting ? null : (_) => _submitCheckIn(_manualCodeController.text),
          //         decoration: InputDecoration(
          //           hintText: 'Enter ticket QR code or attendee id',
          //           contentPadding: const EdgeInsets.symmetric(
          //             horizontal: 12,
          //             vertical: 12,
          //           ),
          //           border: OutlineInputBorder(
          //             borderRadius: BorderRadius.circular(10),
          //           ),
          //           focusedBorder: OutlineInputBorder(
          //             borderRadius: BorderRadius.circular(10),
          //             borderSide: const BorderSide(color: _orange),
          //           ),
          //         ),
          //       ),
          //     ),
          //     const SizedBox(width: 10),
          //     ElevatedButton(
          //       onPressed: _isSubmitting
          //           ? null
          //           : () {
          //               final String code = _manualCodeController.text.trim();
          //               if (code.isEmpty) {
          //                 _showMessage('Please enter ticket QR code');
          //                 return;
          //               }
          //               _submitCheckIn(code);
          //             },
          //       child: Text(_isSubmitting ? 'Checking...' : 'Check In'),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildScannerPreview() {
    if (!widget.isActive) {
      return Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 280,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleDetection,
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withOpacity(0.18),
                          Colors.transparent,
                          Colors.black.withOpacity(0.22),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                if (_isSubmitting)
                  Container(
                    color: Colors.black.withOpacity(0.42),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'Checking in attendee...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        try {
                          await _scannerController.switchCamera();
                        } catch (e) {
                          _showMessage(e.toString());
                        }
                      },
                icon: const Icon(Icons.cameraswitch_rounded),
                label: const Text('Switch Camera'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        try {
                          await _scannerController.toggleTorch();
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _torchEnabled = !_torchEnabled;
                          });
                        } catch (e) {
                          _showMessage(e.toString());
                        }
                      },
                icon: Icon(
                  _torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                ),
                label: Text(_torchEnabled ? 'Torch On' : 'Torch Off'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnsupportedScannerCard() {
    return Container(
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
            'Camera scanner is not supported on this platform.',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Camera scanning is required on this screen.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
