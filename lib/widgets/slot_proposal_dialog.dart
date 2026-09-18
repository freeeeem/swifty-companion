import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Résultat du dialog de proposition : créneau début -> fin.
class SlotProposal {
  final DateTime beginAt;
  final DateTime endAt;

  const SlotProposal({required this.beginAt, required this.endAt});
}

const List<String> _dialogMonths = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// Dialog de proposition d'un créneau : mini-calendrier du mois, choix de
/// l'heure de début (pas de 30 min) et de la durée — dans le design dark
/// de l'app, à la place des sélecteurs Material par défaut.
class SlotProposalDialog extends StatefulWidget {
  const SlotProposalDialog({super.key});

  /// Ouvre le dialog et retourne la proposition (null si annulé).
  static Future<SlotProposal?> show(BuildContext context) {
    return showDialog<SlotProposal>(
      context: context,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        child: SlotProposalDialog(),
      ),
    );
  }

  @override
  State<SlotProposalDialog> createState() => _SlotProposalDialogState();
}

class _SlotProposalDialogState extends State<SlotProposalDialog> {
  /// Fenêtre de choix d'heure : de 08:00 à 22:30, par pas de 30 min.
  static const int _firstMinutes = 8 * 60;
  static const int _lastMinutes = 22 * 60 + 30;

  static const List<(String, Duration)> _durations = [
    ('30 min', Duration(minutes: 30)),
    ('1 h', Duration(hours: 1)),
    ('1 h 30', Duration(hours: 1, minutes: 30)),
    ('2 h', Duration(hours: 2)),
  ];

  late DateTime _visibleMonth;
  int? _selectedDay;
  int _startMinutes = _firstMinutes;
  Duration _duration = const Duration(minutes: 30);

  /// Défilement de la liste des heures : contrôlé manuellement pour
  /// centrer l'heure sélectionnée et mapper la molette (sinon la liste
  /// horizontale ne réagit pas au wheel et le scroll est "bugué").
  final ScrollController _timeScrollController = ScrollController();

  /// Largeur fixe d'une puce d'heure ("08:00" en mono 12 + padding) :
  /// permet de calculer la position exacte de chaque puce.
  static const double _timeChipWidth = 56;
  static const double _timeChipGap = 6;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = now.day;
    // Prochaine demi-heure entamée (si la journée est finie, on repart à 08:00).
    int minutes = ((now.hour * 60 + now.minute) ~/ 30 + 1) * 30;
    if (minutes > _lastMinutes) minutes = _firstMinutes;
    _startMinutes = minutes;
    // Centre l'heure présélectionnée dès l'ouverture du dialog.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToSelectedChip(animate: false);
    });
  }

  @override
  void dispose() {
    _timeScrollController.dispose();
    super.dispose();
  }

  /// Fait défiler la liste des heures pour centrer la puce sélectionnée.
  void _scrollToSelectedChip({required bool animate}) {
    if (!_timeScrollController.hasClients) return;
    final int index = (_startMinutes - _firstMinutes) ~/ 30;
    final double itemExtent = _timeChipWidth + _timeChipGap;
    final double viewport =
        _timeScrollController.position.viewportDimension;
    final double target = (index * itemExtent + _timeChipWidth / 2 - viewport / 2)
        .clamp(0.0, _timeScrollController.position.maxScrollExtent);
    if (animate) {
      _timeScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _timeScrollController.jumpTo(target);
    }
  }

  int get _daysInMonth => DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;

  int get _firstWeekdayOffset => DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday - 1;

  DateTime? get _selectedDate => _selectedDay == null
      ? null
      : DateTime(_visibleMonth.year, _visibleMonth.month, _selectedDay!);

  DateTime? get _beginAt {
    final date = _selectedDate;
    if (date == null) return null;
    final begin = DateTime(
      date.year,
      date.month,
      date.day,
      _startMinutes ~/ 60,
      _startMinutes % 60,
    );
    return begin.isAfter(DateTime.now()) ? begin : null;
  }

  void _shiftMonth(int direction) {
    // Le calendrier des créneaux couvre J → J+45 : le dialog ne propose
    // pas de mois passé ni de mois entièrement hors fenêtre.
    final now = DateTime.now();
    final firstMonth = DateTime(now.year, now.month);
    final lastDay = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 45));
    final lastMonth = DateTime(lastDay.year, lastDay.month);
    final target =
        DateTime(_visibleMonth.year, _visibleMonth.month + direction);
    if (target.isBefore(firstMonth) || target.isAfter(lastMonth)) return;
    setState(() {
      _visibleMonth = target;
      final isCurrentMonth =
          _visibleMonth.year == now.year && _visibleMonth.month == now.month;
      if (isCurrentMonth) {
        _selectedDay = now.day;
      } else {
        _selectedDay = null;
      }
    });
  }

  String _formatTime(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  String _formatSummary(DateTime begin, DateTime end) {
    const weekdays = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
    return '${weekdays[begin.weekday - 1]} ${begin.day} '
        '${_dialogMonths[begin.month - 1].substring(0, 3).toUpperCase()} '
        '· ${_formatTime(begin.hour * 60 + begin.minute)} → '
        '${_formatTime(end.hour * 60 + end.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final begin = _beginAt;
    final end = begin?.add(_duration);
    final isCurrentMonth =
        _visibleMonth.year == now.year && _visibleMonth.month == now.month;

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildMonthNav(isCurrentMonth),
            const SizedBox(height: 12),
            _buildCalendarGrid(today),
            const SizedBox(height: 16),
            _buildSectionLabel('HEURE DE DÉBUT'),
            const SizedBox(height: 8),
            _buildTimeChips(),
            const SizedBox(height: 16),
            _buildSectionLabel('DURÉE'),
            const SizedBox(height: 8),
            _buildDurationChips(),
            const SizedBox(height: 20),
            _buildFooter(begin, end),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'PROPOSER UNE DISPONIBILITÉ',
            style: AppText.mono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 2,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppText.mono(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildMonthNav(bool isCurrentMonth) {
    return Row(
      children: [
        _buildMonthArrow(
          Icons.chevron_left_rounded,
          !isCurrentMonth,
          () => _shiftMonth(-1),
        ),
        Expanded(
          child: Text(
            '${_dialogMonths[_visibleMonth.month - 1]} ${_visibleMonth.year}'
                .toUpperCase(),
            textAlign: TextAlign.center,
            style: AppText.mono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
              letterSpacing: 1.5,
            ),
          ),
        ),
        _buildMonthArrow(
          Icons.chevron_right_rounded,
          true,
          () => _shiftMonth(1),
        ),
      ],
    );
  }

  Widget _buildMonthArrow(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? AppColors.muted : AppColors.mutedLight,
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime today) {
    const weekdayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: AppText.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedLight,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ...List.generate(
          ((_firstWeekdayOffset + _daysInMonth) / 7).ceil(),
          (row) => Row(
            children: List.generate(7, (col) {
              final dayNumber = row * 7 + col - _firstWeekdayOffset + 1;
              if (dayNumber < 1 || dayNumber > _daysInMonth) {
                return const Expanded(child: SizedBox(height: 38));
              }
              return Expanded(
                child: _buildDayCell(
                  DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber),
                  today,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime day, DateTime today) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    final isPast = dateOnly.isBefore(today);
    // Hors fenêtre J → J+45 : même traitement visuel que le passé.
    final maxDay = DateTime(today.year, today.month, today.day)
        .add(const Duration(days: 45));
    final isBeyondWindow = dateOnly.isAfter(maxDay);
    final isDisabled = isPast || isBeyondWindow;
    final isSelected = _selectedDay == day.day;
    final isToday = dateOnly == today;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          isDisabled ? null : () => setState(() => _selectedDay = day.day),
      child: SizedBox(
        height: 38,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected ? AppColors.primaryGradient : null,
              border: !isSelected && isToday
                  ? Border.all(color: AppColors.primary, width: 1.2)
                  : null,
            ),
            child: Text(
              '${day.day}',
              style: AppText.mono(
                fontSize: 12.5,
                fontWeight: isSelected || isToday
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isSelected
                    ? AppColors.background
                    : (isDisabled ? AppColors.mutedLight : AppColors.dark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChips() {
    return SizedBox(
      height: 38,
      // La molette sur une liste horizontale est ignorée par défaut (le
      // scroll vertical passe au SingleChildScrollView parent) : on la
      // convertit explicitement en défilement horizontal.
      child: Listener(
        onPointerSignal: (event) {
          if (event is! PointerScrollEvent) return;
          if (!_timeScrollController.hasClients) return;
          final position = _timeScrollController.position;
          final double target = (position.pixels + event.scrollDelta.dy)
              .clamp(0.0, position.maxScrollExtent);
          position.animateTo(
            target,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
          );
        },
        child: ListView.separated(
          controller: _timeScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: ((_lastMinutes - _firstMinutes) ~/ 30) + 1,
          separatorBuilder: (_, _) => const SizedBox(width: _timeChipGap),
          itemBuilder: (context, index) {
            final minutes = _firstMinutes + index * 30;
            return _buildChip(
              label: _formatTime(minutes),
              width: _timeChipWidth,
              selected: minutes == _startMinutes,
              onTap: () {
                setState(() => _startMinutes = minutes);
                // Recentre la puce choisie pour qu'elle reste bien visible.
                _scrollToSelectedChip(animate: true);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDurationChips() {
    return Row(
      children: [
        for (final (index, option) in _durations.indexed) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: _buildChip(
              label: option.$1,
              selected: option.$2 == _duration,
              onTap: () => setState(() => _duration = option.$2),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    double? width,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardElevated,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppText.mono(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.background : AppColors.darkSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(DateTime? begin, DateTime? end) {
    final isValid = begin != null && end != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Text(
            isValid
                ? _formatSummary(begin, end)
                : 'Choisis un jour et une heure',
            style: AppText.mono(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isValid ? AppColors.primary : AppColors.muted,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: PrimaryButton(
            label: 'Proposer',
            icon: Icons.add_rounded,
            onPressed: isValid
                ? () => Navigator.pop(
                    context,
                    SlotProposal(beginAt: begin, endAt: end),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
