import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_service.dart';
import '../models/correction_models.dart';
import '../models/user_profile.dart';
import '../theme.dart';
import 'slot_proposal_dialog.dart';

// Noms de jours et de mois en français, pour éviter d'ajouter une
// dépendance (intl) juste pour du formatage de dates.
const List<String> _weekdaysShort = [
  'LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM',
];
const List<String> _weekdaysLong = [
  'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche',
];
const List<String> _monthsLong = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

const String _knownSlotIdsKey = 'slots_tab_known_slot_ids';

String _formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Onglet affichant les disponibilités de correction proposées par
/// l'utilisateur connecté, organisées autour d'un calendrier de jours à venir.
class SlotsTab extends StatefulWidget {
  final UserProfile myProfile;

  const SlotsTab({super.key, required this.myProfile});

  @override
  State<SlotsTab> createState() => _SlotsTabState();
}

class _SlotsTabState extends State<SlotsTab> {
  /// Fenêtre de temps couverte par le calendrier : uniquement le futur,
  /// l'onglet sert à proposer des disponibilités, pas à consulter le passé.
  static const int _futureDays = 45;
  static const double _dayCellWidth = 62; // 54 px de cellule + 8 px de marge

  List<CorrectionSlot> _slots = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _slotsUnavailable = false;
  String? _errorMessage;

  late final List<DateTime> _calendarDays;
  DateTime _selectedDay = _dateOnly(DateTime.now());
  final ScrollController _calendarScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _calendarDays = List.generate(
      _futureDays + 1,
      (index) => today.add(Duration(days: index)),
    );
    _loadData();

    // Centre le calendrier sur le jour d'aujourd'hui une fois rendu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _scrollToDay(_selectedDay, animate: false);
      });
    });
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  /// IDs des slots créés depuis l'app (persistés) : permet de les
  /// récupérer via filter[id] quand les endpoints de listing plantent.
  Future<List<int>> _loadKnownSlotIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_knownSlotIdsKey);
    if (raw == null || raw.isEmpty) return const [];
    return raw.split(',').map(int.tryParse).whereType<int>().toList();
  }

  Future<void> _rememberSlotId(int slotId) async {
    final ids = await _loadKnownSlotIds();
    if (ids.contains(slotId)) return;
    final updated = [...ids, slotId];
    // Garde les 100 derniers IDs au maximum.
    final trimmed = updated.length > 100
        ? updated.sublist(updated.length - 100)
        : updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_knownSlotIdsKey, trimmed.join(','));
  }

  /// Réassemble les blocs contigus renvoyés par l'API (l'intra stocke les
  /// disponibilités en petits blocs) en créneaux entiers : même horaire
  /// collé + même statut (libre/réservé) = un seul créneau à l'affichage.
  List<CorrectionSlot> _mergeContiguousSlots(List<CorrectionSlot> slots) {
    final sorted = [...slots]..sort((a, b) => a.beginAt.compareTo(b.beginAt));
    final merged = <CorrectionSlot>[];
    for (final slot in sorted) {
      if (merged.isNotEmpty) {
        final last = merged.last;
        if (last.isBooked == slot.isBooked &&
            last.endAt.isAtSameMomentAs(slot.beginAt)) {
          merged[merged.length - 1] = CorrectionSlot(
            id: last.id,
            beginAt: last.beginAt,
            endAt: slot.endAt,
            isBooked: last.isBooked,
            chunkIds: [...last.chunkIds, ...slot.chunkIds],
          );
          continue;
        }
      }
      merged.add(slot);
    }
    return merged;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Slots : chaîne de repli — l'endpoint /v2/users/:id/slots renvoie 500
      // sur certains comptes (données anciennes cassées côté intra), donc :
      // 1) l'endpoint nominal, 2) /v2/me/slots, 3) l'index filtré par les
      // IDs des slots créés via l'app.
      final knownIds = await _loadKnownSlotIds();
      final rawSlots = await AuthService.getUserSlots(widget.myProfile.id) ??
          await AuthService.getMeSlots() ??
          await AuthService.getSlotsByIds(knownIds);

      if (rawSlots == null && _slots.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Impossible de charger tes créneaux.';
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _slotsUnavailable = rawSlots == null;
          if (rawSlots != null) {
            _slots = _mergeContiguousSlots(
              rawSlots
                  .whereType<Map<String, dynamic>>()
                  .map(CorrectionSlot.fromJson)
                  .toList(),
            );
          } else {
            // L'API n'a pas répondu : on garde les slots connus localement
            // (ceux créés depuis l'app pendant la session) plutôt que de
            // tout effacer.
          }
          _isLoading = false;
        });
        debugPrint(
          'Slots chargés : ${_slots.length} créneau(x) '
          '(source : ${rawSlots != null ? 'API' : 'cache local'}).',
        );
      }
    } catch (e) {
      debugPrint('Error loading slots: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement : $e';
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToDay(DateTime day, {bool animate = true}) {
    final index = _calendarDays.indexWhere((d) => _isSameDay(d, day));
    if (index == -1 || !_calendarScrollController.hasClients) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final offset =
        (index * _dayCellWidth) - (screenWidth / 2) + (_dayCellWidth / 2);
    final targetOffset = offset.clamp(
      _calendarScrollController.position.minScrollExtent,
      _calendarScrollController.position.maxScrollExtent,
    );

    if (animate) {
      _calendarScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _calendarScrollController.jumpTo(targetOffset);
    }
  }

  void _selectDay(DateTime day) {
    setState(() => _selectedDay = _dateOnly(day));
    _scrollToDay(day);
  }

  List<CorrectionSlot> get _slotsForSelectedDay => _slots
      .where((slot) => _isSameDay(slot.beginAt.toLocal(), _selectedDay))
      .toList();

  bool _hasActivity(DateTime day) =>
      _slots.any((s) => _isSameDay(s.beginAt.toLocal(), day));

  String _formatDayTitle(DateTime date) =>
      '${_weekdaysLong[date.weekday - 1]} ${date.day} ${_monthsLong[date.month - 1]}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 24),
        _buildCalendarHeader(),
        _buildCalendarStrip(),
        const SizedBox(height: 24),
        _buildDayContent(),
      ],
    );
  }

  /// Carte résumé : points de correction disponibles, ressources nécessaires
  /// pour réserver des évaluations sur l'intra.
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCard.decoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.handshake_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POINTS DE CORRECTION',
                  style: AppText.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${widget.myProfile.correctionPoints}',
                      style: AppText.mono(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'disponibles',
                      style: AppText.body(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'CALENDRIER',
            style: AppText.mono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
              letterSpacing: 2,
            ),
          ),
        ),
        Tooltip(
          message: 'Nouveau créneau',
          child: TextButton.icon(
            onPressed:
                (_isLoading || _isSubmitting) ? null : _handleCreateSlot,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Proposer',
              style: AppText.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Actualiser',
          onPressed: (_isLoading || _isSubmitting) ? null : _loadData,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          color: AppColors.muted,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Flux complet de proposition : dialog dédié (calendrier du mois, heure,
  /// durée), puis POST /v2/slots. Créer un créneau = se rendre disponible
  /// en tant que correcteur ; un étudiant viendra ensuite le réserver.
  Future<void> _handleCreateSlot() async {
    final SlotProposal? proposal = await SlotProposalDialog.show(context);
    if (proposal == null || !mounted) return;

    setState(() => _isSubmitting = true);
    final (String? error, CorrectionSlot? created) = await AuthService.createSlot(
      widget.myProfile.id,
      proposal.beginAt,
      proposal.endAt,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error == null && created != null) {
      _showSnack(
        'Créneau proposé : ${_formatTime(proposal.beginAt.toLocal())} — '
        '${_formatTime(proposal.endAt.toLocal())}.',
      );
      // Ajout optimiste : le slot reste visible même si le rechargement
      // échoue (l'endpoint de listing peut renvoyer 500). On fusionne
      // au cas où il prolonge une disponibilité existante.
      await _rememberSlotId(created.id);
      setState(() => _slots = _mergeContiguousSlots([..._slots, created]));
      _selectDay(proposal.beginAt.toLocal());
    } else {
      _showSnack('Échec de la proposition : ${error ?? 'réponse inattendue'}');
    }
    _loadData();
  }

  Widget _buildCalendarStrip() {
    final today = _dateOnly(DateTime.now());
    return SizedBox(
      height: 78,
      child: ListView.builder(
        controller: _calendarScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _calendarDays.length,
        itemBuilder: (context, index) =>
            _buildDayCell(_calendarDays[index], today),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, DateTime today) {
    final isSelected = _isSameDay(day, _selectedDay);
    final isToday = _isSameDay(day, today);
    final hasActivity = _hasActivity(day);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectDay(day),
      child: Container(
        width: 54,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isToday ? AppColors.primary : AppColors.hairline),
            width: isToday && !isSelected ? 1.2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weekdaysShort[day.weekday - 1],
              style: AppText.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.background : AppColors.muted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${day.day}',
              style: AppText.mono(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.background : AppColors.dark,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasActivity
                    ? (isSelected ? AppColors.background : AppColors.primary)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: AppText.body(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Réessayer',
                style: AppText.body(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final slots = _slotsForSelectedDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDayTitle(_selectedDay).toUpperCase(),
          style: AppText.mono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 14),
        _buildSlotsSection(slots),
      ],
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(title, style: AppText.heading(fontSize: 15)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Text(
            '$count',
            style: AppText.mono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotsSection(List<CorrectionSlot> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Mes disponibilités', slots.length),
        const SizedBox(height: 12),
        if (_slotsUnavailable)
          const _EmptyHint(
            icon: Icons.cloud_off_rounded,
            message:
                'L\'API 42 ne renvoie pas tes créneaux (bug connu côté '
                'intra) ; ceux créés ici restent visibles.',
          )
        else if (slots.isEmpty)
          const _EmptyHint(message: 'Aucune disponibilité ce jour-là.')
        else
          ...slots.map(_buildSlotCard),
      ],
    );
  }

  Widget _buildSlotCard(CorrectionSlot slot) {
    final bool isPast = slot.endAt.toLocal().isBefore(DateTime.now());
    final bool canDelete = !slot.isBooked && !isPast;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppCard.decoration(),
      child: Row(
        children: [
          Text(
            '${_formatTime(slot.beginAt.toLocal())} — '
            '${_formatTime(slot.endAt.toLocal())}',
            style: AppText.mono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const Spacer(),
          if (slot.isBooked)
            Text(
              'réservé',
              style: AppText.mono(fontSize: 11.5, color: AppColors.primary),
            )
          else if (canDelete)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: () async {
                if (await _confirmDeleteSlot(slot)) _deleteSlot(slot);
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              color: AppColors.muted,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteSlot(CorrectionSlot slot) async {
    final DateTime local = slot.beginAt.toLocal();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.hairline),
        ),
        title: Text(
          'Supprimer le créneau ?',
          style: AppText.heading(fontSize: 16),
        ),
        content: Text(
          'Créneau du ${_formatDayTitle(local)} à ${_formatTime(local)}.',
          style: AppText.body(fontSize: 14, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: AppText.body(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Supprimer',
              style: AppText.body(
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _deleteSlot(CorrectionSlot slot) async {
    setState(() => _isSubmitting = true);

    // Un créneau affiché peut fusionner plusieurs blocs API : on les
    // supprime tous, en espaçant les appels (limite de 2 req/s de l'API).
    var failures = 0;
    for (final (index, chunkId) in slot.chunkIds.indexed) {
      final String? error = await AuthService.deleteSlot(chunkId);
      if (error != null) {
        failures++;
        debugPrint('Échec de suppression du bloc $chunkId : $error');
      }
      if (index < slot.chunkIds.length - 1) {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      if (failures == 0) {
        // Retrait optimiste : le slot disparaît même si le rechargement
        // échoue (sinon il réapparaîtrait en fantôme).
        _slots.removeWhere((s) => s.id == slot.id);
      }
    });

    if (failures == 0) {
      _showSnack('Créneau supprimé.');
    } else {
      _showSnack(
        'Suppression partielle : $failures bloc(s) sur '
        '${slot.chunkIds.length} n\'ont pas pu être supprimés.',
      );
    }
    _loadData();
  }
}

/// Message d'absence de contenu de la section du jour.
class _EmptyHint extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyHint({
    required this.message,
    this.icon = Icons.event_busy_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: AppCard.decoration(),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mutedLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppText.body(fontSize: 13, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
