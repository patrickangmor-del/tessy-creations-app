import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/order.dart';
import '../../state/customers_controller.dart';
import '../../state/orders_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/cut_card.dart';

const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _cursor = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedDate;

  void _shiftMonth(int delta) {
    setState(() {
      _cursor = DateTime(_cursor.year, _cursor.month + delta);
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersController>().orders;

    final dueMap = <String, List<Order>>{};
    for (final order in orders) {
      final due = order.dueDate;
      if (due == null) continue;
      dueMap.putIfAbsent(due, () => []).add(order);
    }

    final upcoming = orders.where((o) => o.dueDate != null && o.status != orderStatuses.last).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final monthGrid = _MonthGrid(
      cursor: _cursor,
      dueMap: dueMap,
      selectedDate: _selectedDate,
      onPrev: () => _shiftMonth(-1),
      onNext: () => _shiftMonth(1),
      onSelectDate: (key) => setState(() => _selectedDate = _selectedDate == key ? null : key),
    );

    final upcomingList = _UpcomingList(orders: upcoming);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 640;
        if (wide) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: monthGrid),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: upcomingList),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [monthGrid, const SizedBox(height: 20), upcomingList],
        );
      },
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.cursor,
    required this.dueMap,
    required this.selectedDate,
    required this.onPrev,
    required this.onNext,
    required this.onSelectDate,
  });

  final DateTime cursor;
  final Map<String, List<Order>> dueMap;
  final String? selectedDate;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<String> onSelectDate;

  String _dateKey(int day) {
    return '${cursor.year.toString().padLeft(4, '0')}-${cursor.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(cursor.year, cursor.month, 1).weekday % 7; // 0 = Sunday
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;

    final cells = <int?>[
      for (var i = 0; i < firstWeekday; i++) null,
      for (var d = 1; d <= daysInMonth; d++) d,
    ];

    final monthLabel = '${_monthName(cursor.month)} ${cursor.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
            Text(
              monthLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
          ],
        ),
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (final day in cells)
              if (day == null)
                const SizedBox.shrink()
              else
                _DayCell(
                  day: day,
                  dateKey: _dateKey(day),
                  hasOrders: dueMap.containsKey(_dateKey(day)),
                  selected: selectedDate == _dateKey(day),
                  onTap: () => onSelectDate(_dateKey(day)),
                ),
          ],
        ),
        if (selectedDate != null && dueMap[selectedDate] != null) ...[
          const SizedBox(height: 16),
          Text('DUE ${formatDate(selectedDate).toUpperCase()}', style: sectionLabelStyle),
          const SizedBox(height: 8),
          for (final order in dueMap[selectedDate]!) _SelectedDayOrder(order: order),
        ],
      ],
    );
  }

  static String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.dateKey,
    required this.hasOrders,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final String dateKey;
  final bool hasOrders;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: hasOrders ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.thread : (hasOrders ? AppColors.paperDark : Colors.transparent),
          borderRadius: BorderRadius.circular(4),
          border: hasOrders ? Border.all(color: AppColors.gold, width: 1) : null,
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
            if (hasOrders)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? Colors.white : AppColors.pin,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectedDayOrder extends StatelessWidget {
  const _SelectedDayOrder({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final customerName = context.watch<CustomersController>().byId(order.customerId)?.name ?? 'Unknown';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CutCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${order.dressType} — $customerName', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(order.status, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({required this.orders});
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('UPCOMING PICKUPS', style: sectionLabelStyle),
        const SizedBox(height: 8),
        if (orders.isEmpty)
          const Text('Nothing scheduled.', style: TextStyle(color: AppColors.inkSoft))
        else
          for (final order in orders) _UpcomingCard(order: order),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final customerName = context.watch<CustomersController>().byId(order.customerId)?.name ?? 'Unknown';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CutCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(
              '${order.dressType} · ${formatDate(order.dueDate)}',
              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
