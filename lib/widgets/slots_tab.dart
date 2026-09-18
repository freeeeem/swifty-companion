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

  /// Filtre d'affichage des créneaux du jour : 0 tous, 1 libres, 2 réservés.
  int _dayFilter = 0;

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
    // Pull-to-refresh natif : les onglets Profil/Recherche sont des colonnes
    // non scrollables, mais les créneaux méritent un rechargement gestuel.
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardElevated,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildCalendarHeader(),
            _buildCalendarStrip(),
            const SizedBox(height: 24),
            _buildDayContent(),
            // Espace pour que le dernier slot ne soit pas masqué et que
            // le RefreshIndicator ait toujours une zone à tirer.
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  /// Carte résumé : points de correction + compteur de disponibilités à
  /// venir (libres / réservées). Sobre : texte + chiffres, pas d'icône
  /// décorative ni de pastille colorée.
  Widget _buildSummaryCard() {
    final now = DateTime.now();
    final upcoming = _slots
        .where((s) => s.endAt.toLocal().isAfter(now))
        .toList();
    final freeCount = upcoming.where((s) => !s.isBooked).length;
    final bookedCount = upcoming.length - freeCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCard.decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Points de correction',
                      style: AppText.body(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.myProfile.correctionPoints} disponibles',
                      style: AppText.body(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
              ),
              // CTA compact : la proposition reste accessible sans scroller.
              _CompactProposeButton(
                busy: _isLoading || _isSubmitting,
                onPressed: _handleCreateSlot,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          // Compteurs de disponibilités à venir (temps réel local).
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  value: '${upcoming.length}',
                  label: 'À venir',
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.divider),
              Expanded(
                child: _summaryStat(
                  value: '$freeCount',
                  label: 'Libres',
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.divider),
              Expanded(
                child: _summaryStat(
                  value: '$bookedCount',
                  label: 'Réservés',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat({
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppText.body(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppText.body(
            fontSize: 12,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }

  /// En-tête du calendrier : le CTA « Proposer » vit désormais dans la
  /// carte résumé (toujours visible) ; ici ne reste que l'actualisation.
  Widget _buildCalendarHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Calendrier',
            style: AppText.body(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
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

    if (error != null) {
      _showSnack('Échec de la proposition : $error');
    } else {
      // Succès : created peut être null si l'API a renvoyé un corps vide
      // ou non conforme alors que le créneau a bien été créé (comportement
      // connu de l'intra) — on affiche quand même la confirmation.
      _showSnack(
        'Créneau proposé : ${_formatTime(proposal.beginAt.toLocal())} — '
        '${_formatTime(proposal.endAt.toLocal())}.',
      );
      // Ajout optimiste : le slot reste visible même si le rechargement
      // échoue (l'endpoint de listing peut renvoyer 500). On fusionne
      // au cas où il prolonge une disponibilité existante.
      final slot = created;
      if (slot != null) {
        await _rememberSlotId(slot.id);
        setState(() => _slots = _mergeContiguousSlots([..._slots, slot]));
        _selectDay(slot.beginAt.toLocal());
      }
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
          color: isSelected ? AppColors.dark : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.dark
                : (isToday ? AppColors.muted : AppColors.hairline),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weekdaysShort[day.weekday - 1],
              style: AppText.body(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: isSelected
                    ? AppColors.background.withValues(alpha: 0.7)
                    : AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.day}',
              style: AppText.body(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.background : AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasActivity
                    ? (isSelected
                        ? AppColors.background
                        : AppColors.primary)
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
            SizedBox(
              width: 220,
              child: PrimaryButton(
                label: 'Réessayer',
                icon: Icons.refresh_rounded,
                onPressed: _loadData,
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
          _formatDayTitle(_selectedDay),
          style: AppText.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 12),
        _buildSlotsSection(slots),
      ],
    );
  }

  /// Crénaux du jour après application du filtre Tous / Libres / Réservés.
  List<CorrectionSlot> _filteredDaySlots(List<CorrectionSlot> slots) {
    return switch (_dayFilter) {
      1 => slots.where((s) => !s.isBooked).toList(),
      2 => slots.where((s) => s.isBooked).toList(),
      _ => slots,
    };
  }

  Widget _dayFilterChip(int value, String label) {
    final selected = _dayFilter == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _dayFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.dark : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.dark : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppText.body(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.background : AppColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(title, style: AppText.heading(fontSize: 15)),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: AppText.body(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildSlotsSection(List<CorrectionSlot> slots) {
    final visible = _filteredDaySlots(slots);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Mes disponibilités', visible.length),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _dayFilterChip(0, 'Tous'),
            _dayFilterChip(1, 'Libres'),
            _dayFilterChip(2, 'Réservés'),
          ],
        ),
        const SizedBox(height: 12),
        if (_slotsUnavailable)
          const _EmptyHint(
            icon: Icons.cloud_off_rounded,
            message:
                'L\'API 42 ne renvoie pas tes créneaux (bug connu côté '
                'intra) ; ceux créés ici restent visibles.',
          )
        else if (visible.isEmpty)
          _EmptyHint(
            message: _dayFilter == 0
                ? 'Aucune disponibilité ce jour-là.'
                : 'Aucun créneau dans ce filtre ce jour-là.',
          )
        else
          ...visible.map(_buildSlotCard),
      ],
    );
  }

  Widget _buildSlotCard(CorrectionSlot slot) {
    final bool isPast = slot.endAt.toLocal().isBefore(DateTime.now());
    final bool canDelete = !slot.isBooked && !isPast;
    final bool canSwipe = canDelete && !_isSubmitting;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppCard.decoration(),
      child: Row(
        children: [
          Text(
            '${_formatTime(slot.beginAt.toLocal())} — '
            '${_formatTime(slot.endAt.toLocal())}',
            style: AppText.body(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.dark,
            ),
          ),
          const Spacer(),
          if (slot.isBooked)
            const StatusPill(label: 'Réservé', color: AppColors.primary)
          else if (isPast)
            const StatusPill(label: 'Passé', color: AppColors.muted)
          else
            const StatusPill(label: 'Libre', color: AppColors.success),
          if (canDelete) ...[
            const SizedBox(width: 8),
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
        ],
      ),
    );

    // Swipe-to-delete natif sur les créneaux supprimables ; les autres
    // restent des cartes statiques (pas de Dismissible fantôme).
    if (!canSwipe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: card,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('slot-${slot.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 18),
          decoration: BoxDecoration(
            color: AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.danger),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.danger,
          ),
        ),
        confirmDismiss: (_) => _confirmDeleteSlot(slot),
        onDismissed: (_) => _deleteSlot(slot),
        child: card,
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

/// Bouton compact « Proposer » : fond accent uni, texte blanc, coins 8px.
class _CompactProposeButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onPressed;

  const _CompactProposeButton({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Nouveau créneau',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: busy ? null : onPressed,
        child: Opacity(
          opacity: busy ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:
                  busy ? AppColors.cardElevated : AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                const SizedBox(width: 6),
                Text(
                  'Proposer',
                  style: AppText.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: busy
                        ? AppColors.mutedLight
                        : Colors.white,
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
