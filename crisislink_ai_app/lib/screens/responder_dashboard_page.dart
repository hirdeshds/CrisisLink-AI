import 'package:flutter/material.dart';

import '../services/sos_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/incident_review_sheet.dart';

class ResponderDashboardPage extends StatefulWidget {
  const ResponderDashboardPage({
    super.key,
    required this.sosApiService,
    this.initialResponderId = '',
  });

  final SosApiService sosApiService;
  final String initialResponderId;

  @override
  State<ResponderDashboardPage> createState() => _ResponderDashboardPageState();
}

class _ResponderDashboardPageState extends State<ResponderDashboardPage> {
  late final TextEditingController _responderIdController;
  List<IncidentSummary> _incidents = const [];
  List<ResponderInfo> _availableResponders = const [];
  bool _isLoading = true;
  bool _isLoadingResponders = false;
  String? _error;
  String? _assigningIncidentId;
  bool _isReleasing = false;

  @override
  void initState() {
    super.initState();
    _responderIdController = TextEditingController(
      text: widget.initialResponderId,
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _responderIdController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _isLoadingResponders = true;
      _error = null;
    });

    try {
      final incidentsFuture = widget.sosApiService.fetchActiveIncidents();
      final respondersFuture = widget.sosApiService.fetchAvailableResponders();

      final incidentsResult = await incidentsFuture;
      final respondersResult = await respondersFuture;

      if (!mounted) {
        return;
      }

      setState(() {
        _incidents = incidentsResult;
        _availableResponders = respondersResult;
        _isLoading = false;
        _isLoadingResponders = false;
      });
    } on SosApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
        _isLoading = false;
        _isLoadingResponders = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Unable to load data right now.';
        _isLoading = false;
        _isLoadingResponders = false;
      });
    }
  }

  Future<void> _assignToIncident(IncidentSummary incident) async {
    final responderId = _responderIdController.text.trim();
    if (responderId.isEmpty) {
      _showErrorSnackBar('Please select or enter a responder ID');
      return;
    }

    setState(() {
      _assigningIncidentId = incident.id;
    });

    try {
      await widget.sosApiService.assignResponder(
        responderId: responderId,
        incidentId: incident.id,
      );

      if (!mounted) {
        return;
      }

      _showSuccessSnackBar(
        'Responder assigned to incident ${incident.id.substring(0, 8)}',
      );
      await _loadInitialData();
    } on SosApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _assigningIncidentId = null;
      });
      _showErrorSnackBar(_extractErrorMessage(error.message));
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _assigningIncidentId = null;
      });
      _showErrorSnackBar('Unable to assign responder: ${e.toString()}');
    }
  }

  Future<void> _releaseResponder() async {
    final responderId = _responderIdController.text.trim();
    if (responderId.isEmpty) {
      _showErrorSnackBar('Please select or enter a responder ID');
      return;
    }

    setState(() {
      _isReleasing = true;
    });

    try {
      await widget.sosApiService.releaseResponder(responderId);

      if (!mounted) {
        return;
      }

      _showSuccessSnackBar('Responder is now available');
      await _loadInitialData();
    } on SosApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isReleasing = false;
      });
      _showErrorSnackBar(_extractErrorMessage(error.message));
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isReleasing = false;
      });
      _showErrorSnackBar('Unable to release responder: ${e.toString()}');
    }
  }

  String _extractErrorMessage(String message) {
    // Extract user-friendly message from API error
    if (message.contains('Invalid UUID format')) {
      return 'Invalid responder ID format. Please use a valid UUID.';
    }
    if (message.contains('Responder not found')) {
      return 'Responder ID not found in the system.';
    }
    if (message.contains('already busy') || message.contains('offline')) {
      return 'Responder is not available for assignment.';
    }
    return message;
  }

  Future<void> _showResponderPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0C1016),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121821),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Select Responder',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingResponders
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentRed,
                        ),
                      )
                    : _availableResponders.isEmpty
                        ? const Center(
                            child: Text(
                              'No responders available',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _availableResponders.length,
                            itemBuilder: (context, index) {
                              final responder = _availableResponders[index];
                              final isSelected = _responderIdController.text ==
                                  responder.id;

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2F6BFF).withValues(
                                          alpha: 0.2,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2F6BFF)
                                        : Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    _responderIdController.text = responder.id;
                                    Navigator.pop(context);
                                  },
                                  leading: Icon(
                                    _getResponderIcon(responder.type),
                                    color: const Color(0xFF2F6BFF),
                                  ),
                                  title: Text(responder.name),
                                  subtitle: Text(
                                    responder.type,
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF2F6BFF),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getResponderIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
      case 'med':
        return Icons.local_hospital;
      case 'fire':
        return Icons.local_fire_department;
      case 'police':
        return Icons.security;
      default:
        return Icons.person;
    }
  }

  Future<void> _openIncidentReview(IncidentSummary incident) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0C1016),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: IncidentReviewSheet(
          sosApiService: widget.sosApiService,
          incident: incident,
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppTheme.accentRed,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF101521), AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.accentRed,
            onRefresh: _loadInitialData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                      ),
                      label: const Text('Back'),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadInitialData,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Responder Dispatch',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use a live responder ID to claim or release incidents from the backend.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121821),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Responder ID',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _responderIdController,
                              decoration: InputDecoration(
                                hintText: 'Select or enter responder ID',
                                prefixIcon: const Icon(Icons.badge_outlined),
                                suffixIcon: _responderIdController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _responderIdController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _isLoadingResponders
                                ? null
                                : _showResponderPicker,
                            tooltip: 'Select from available responders',
                            icon: const Icon(Icons.list),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: _isReleasing ? null : _releaseResponder,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: _isReleasing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Release Responder'),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_availableResponders.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_availableResponders.length} responders available',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          size: 18,
                          color: AppTheme.accentRed,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'No responders available',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFFF7675),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Active Incidents',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (_isLoading && _incidents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentRed,
                      ),
                    ),
                  )
                else if (_error != null)
                  _ResponderMessageCard(message: _error!)
                else if (_incidents.isEmpty)
                  const _ResponderMessageCard(
                    message:
                        'No active incidents are waiting for assignment right now.',
                  )
                else
                  ..._incidents.map(
                    (incident) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ResponderIncidentCard(
                        incident: incident,
                        busy: _assigningIncidentId == incident.id,
                        onReview: () => _openIncidentReview(incident),
                        onAssign: () => _assignToIncident(incident),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponderIncidentCard extends StatelessWidget {
  const _ResponderIncidentCard({
    required this.incident,
    required this.busy,
    required this.onReview,
    required this.onAssign,
  });

  final IncidentSummary incident;
  final bool busy;
  final VoidCallback onReview;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121821),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${incident.type.toUpperCase()} | ${incident.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _ResponderPill(
                label: incident.priority,
                color: _responderPriorityColor(incident.priority),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${incident.reporterCount} reporter(s)',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Lat ${incident.latitude.toStringAsFixed(5)} | Lng ${incident.longitude.toStringAsFixed(5)}',
            style: const TextStyle(color: Color(0xFFD8D4DD), fontSize: 14),
          ),
          if (incident.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reported ${_responderDate(incident.createdAt!)}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Inspect'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onAssign,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6BFF),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Assign Me'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponderMessageCard extends StatelessWidget {
  const _ResponderMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121821),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}

class _ResponderPill extends StatelessWidget {
  const _ResponderPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _responderPriorityColor(String priority) {
  switch (priority.toUpperCase()) {
    case 'CRITICAL':
      return const Color(0xFFFF5A5A);
    case 'HIGH':
      return const Color(0xFFFFA13D);
    case 'MEDIUM':
      return const Color(0xFF4F8FFF);
    default:
      return AppTheme.success;
  }
}

String _responderDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month ${local.year} $hour:$minute';
}
