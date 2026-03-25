import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../models/event_models.dart';
import '../../services/auth_service.dart';
import '../../services/events_service.dart';
import '../attendees/attendees_view.dart';
import '../home/home_view.dart';
import '../scan/scan_qr_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  static const Color _orange = Color(0xFFFF6A00);

  final AuthService _authService = AuthService();
  final EventsService _eventsService = EventsService();

  int _currentIndex = 0;
  bool _isLoadingEvents = true;
  String? _eventsError;
  String _organizerName = 'Organizer';
  List<OrganizerEventSummary> _events = <OrganizerEventSummary>[];
  OrganizerEventSummary? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _loadOrganizer();
    _loadEvents();
  }

  Future<void> _loadOrganizer() async {
    final Map<String, dynamic>? user = await _authService.getUser();
    if (!mounted || user == null) {
      return;
    }

    setState(() {
      _organizerName = _resolveOrganizerName(user);
    });
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoadingEvents = true;
      _eventsError = null;
    });

    try {
      final String? token = await _authService.getToken();
      if (token == null || token.trim().isEmpty) {
        throw Exception('No auth token found. Please sign in again.');
      }

      final List<OrganizerEventSummary> events = await _eventsService.fetchMyEvents(
        token: token,
      );
      final String? persistedEventId = await _authService.getSelectedEventId();

      OrganizerEventSummary? selectedEvent;
      if (persistedEventId != null && persistedEventId.trim().isNotEmpty) {
        for (final OrganizerEventSummary event in events) {
          if (event.id == persistedEventId) {
            selectedEvent = event;
            break;
          }
        }
      }

      if (selectedEvent == null && (_currentIndex == 1 || _currentIndex == 2) && events.isNotEmpty) {
        selectedEvent = events.first;
        await _authService.setSelectedEventId(selectedEvent.id);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _events = events;
        _selectedEvent = selectedEvent;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _eventsError = e.toString();
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  Future<void> _selectEvent(
    OrganizerEventSummary event, {
    bool switchToAttendees = false,
  }) async {
    await _authService.setSelectedEventId(event.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedEvent = event;
      if (switchToAttendees) {
        _currentIndex = 2;
      }
    });
  }

  Future<void> _handleTabTap(int index) async {
    OrganizerEventSummary? selectedEvent = _selectedEvent;

    if ((index == 1 || index == 2) && selectedEvent == null && _events.isNotEmpty) {
      selectedEvent = _events.first;
      await _authService.setSelectedEventId(selectedEvent.id);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = index;
      _selectedEvent = selectedEvent;
    });
  }

  Future<void> _handleProfileMenuSelection(String value) async {
    if (value != 'sign_out') {
      return;
    }

    await _authService.signOut();

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.login,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Image.asset(
          'assets/images/logo-transparent.png',
          height: 36,
          fit: BoxFit.contain,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 44),
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: _handleProfileMenuSelection,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: '__profile_header__',
                  enabled: false,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    _organizerName,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const PopupMenuDivider(height: 1),
                const PopupMenuItem<String>(
                  value: 'sign_out',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: Color(0xFFB91C1C)),
                      SizedBox(width: 10),
                      Text(
                        'Sign out',
                        style: TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 16,
                backgroundColor: _orange,
                child: Text(
                  _organizerName.isNotEmpty
                      ? _organizerName.substring(0, 1).toUpperCase()
                      : 'O',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeView(
            events: _events,
            isLoading: _isLoadingEvents,
            error: _eventsError,
            selectedEventId: _selectedEvent?.id,
            onRefresh: _loadEvents,
            onSelectEvent: (OrganizerEventSummary event) {
              _selectEvent(event, switchToAttendees: true);
            },
          ),
          ScanQrView(
            selectedEvent: _selectedEvent,
            isEventsLoading: _isLoadingEvents,
            hasEvents: _events.isNotEmpty,
          ),
          AttendeesView(
            selectedEvent: _selectedEvent,
            onOpenHome: () {
              _handleTabTap(0);
            },
            onOpenScanQr: () {
              _handleTabTap(1);
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFE3CF),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: _orange,
                fontWeight: FontWeight.w700,
              );
            }
            return const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            );
          },
        ),
        onDestinationSelected: (int index) {
          _handleTabTap(index);
        },
        height: 70,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.home_rounded, color: _orange),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded, color: _orange),
            label: 'Scan QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.groups_rounded, color: _orange),
            label: 'Attendee',
          ),
        ],
      ),
    );
  }

  String _resolveOrganizerName(Map<String, dynamic> user) {
    final String fullName = _readUserValue(user, <String>[
      'organizerName',
      'organizer_name',
      'name',
      'fullName',
      'full_name',
      'displayName',
      'display_name',
    ]);
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final String firstName = _readUserValue(user, <String>['firstName', 'first_name']);
    final String lastName = _readUserValue(user, <String>['lastName', 'last_name']);
    final String combinedName = '$firstName $lastName'.trim();
    if (combinedName.isNotEmpty) {
      return combinedName;
    }

    final String email = _readUserValue(user, <String>['email']);
    if (email.isNotEmpty) {
      return email;
    }

    return 'Organizer';
  }

  String _readUserValue(Map<String, dynamic> user, List<String> keys) {
    for (final String key in keys) {
      final String value = (user[key] ?? '').toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }
}
