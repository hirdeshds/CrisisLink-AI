import 'package:flutter/material.dart';

import '../services/emergency_call_service.dart';
import '../theme/app_theme.dart';

class OfflineEmergencyPage extends StatefulWidget {
  const OfflineEmergencyPage({super.key});

  static const routeName = '/offline-emergency';

  @override
  State<OfflineEmergencyPage> createState() => _OfflineEmergencyPageState();
}

class _OfflineEmergencyPageState extends State<OfflineEmergencyPage> {
  @override
  void initState() {
    super.initState();
    // Automatically trigger 112 call when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiateEmergencyCall();
    });
  }

  Future<void> _initiateEmergencyCall() async {
    await EmergencyCallService.callEmergency();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.05),
            radius: 1.05,
            colors: [Color(0xFF2A090A), Color(0xFF120809), AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 38,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFC9C5CF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                        ),
                        label: const Text(
                          'Exit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const _StatusPill(
                        icon: Icons.signal_wifi_off_rounded,
                        label: 'Offline',
                        color: Color(0xFFFF8A3D),
                      ),
                    ],
                  ),
                  const SizedBox(height: 120),
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'Offline Emergency Mode',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Network unavailable. Triggering automatic 112 emergency call...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _EmergencyActionCard(
                    title: 'Calling 112',
                    description:
                        'Launch emergency dial flow as the primary offline response.',
                    icon: Icons.call_rounded,
                    color: const Color(0xFFD92D20),
                    onTap: _initiateEmergencyCall,
                  ),
                  const SizedBox(height: 12),
                  _EmergencyActionCard(
                    title: 'Sending Family Alert',
                    description:
                        'Send emergency message with SOS status and last known details.',
                    icon: Icons.sms_rounded,
                    color: const Color(0xFF275DF5),
                    onTap: () {
                      // SMS functionality can be expanded later
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SMS alert feature coming soon'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _EmergencyActionCard(
                    title: 'Sharing Last Known Location',
                    description:
                        'Queue the last available location snapshot for trusted contacts.',
                    icon: Icons.location_on_rounded,
                    color: const Color(0xFFF08400),
                    onTap: () {
                      // Location sharing functionality can be expanded later
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location sharing feature coming soon'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17181E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Text(
                      'Device is offline. Emergency call to 112 is initiated automatically. Tap the cards above to retry or trigger manual actions.',
                      style: TextStyle(
                        color: Color(0xFFC8C3CD),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyActionCard extends StatefulWidget {
  const _EmergencyActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_EmergencyActionCard> createState() => _EmergencyActionCardState();
}

class _EmergencyActionCardState extends State<_EmergencyActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _isPressed
              ? widget.color.withValues(alpha: 0.1)
              : const Color(0xFF121318),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isPressed
                ? widget.color.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.description,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
