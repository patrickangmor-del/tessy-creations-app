import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/payment.dart';
import '../../state/customers_controller.dart';
import '../../state/orders_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/cut_card.dart';

class _MonthlyRevenue {
  const _MonthlyRevenue(this.monthKey, this.amount);
  final String monthKey; // yyyy-MM
  final double amount;

  String get label {
    final parts = monthKey.split('-');
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[int.parse(parts[1]) - 1];
  }
}

class _Transaction {
  const _Transaction({
    required this.payment,
    required this.customerName,
    required this.dressType,
  });
  final Payment payment;
  final String customerName;
  final String dressType;
}

class FinancesScreen extends StatelessWidget {
  const FinancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersController = context.watch<OrdersController>();
    final customersController = context.watch<CustomersController>();

    if (ordersController.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final orders = ordersController.orders;

    final totalRevenue = orders.fold<double>(0, (sum, o) => sum + o.price);
    final totalCollected = orders.fold<double>(0, (sum, o) => sum + o.amountPaid);
    final outstanding = totalRevenue - totalCollected;

    final monthlyTotals = <String, double>{};
    final transactions = <_Transaction>[];
    for (final order in orders) {
      final customerName = customersController.byId(order.customerId)?.name ?? 'Unknown';
      for (final payment in order.payments) {
        final monthKey = payment.date.substring(0, 7);
        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + payment.amount;
        transactions.add(
          _Transaction(payment: payment, customerName: customerName, dressType: order.dressType),
        );
      }
    }

    final monthlyKeys = monthlyTotals.keys.toList()..sort();
    final monthly = monthlyKeys
        .skip(monthlyKeys.length > 6 ? monthlyKeys.length - 6 : 0)
        .map((k) => _MonthlyRevenue(k, monthlyTotals[k]!))
        .toList();

    transactions.sort((a, b) => b.payment.date.compareTo(a.payment.date));
    final recentTransactions = transactions.take(12).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Revenue',
                value: totalRevenue,
                accent: AppColors.thread,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Collected',
                value: totalCollected,
                accent: AppColors.gold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Outstanding',
                value: outstanding,
                accent: AppColors.pin,
                valueColor: outstanding > 0 ? AppColors.pin : AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('PAYMENTS COLLECTED BY MONTH', style: sectionLabelStyle),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: monthly.isEmpty
              ? const Center(
                  child: Text('No payments recorded yet.', style: TextStyle(color: AppColors.inkSoft)),
                )
              : _RevenueChart(data: monthly),
        ),
        const SizedBox(height: 24),
        const Text('RECENT TRANSACTIONS', style: sectionLabelStyle),
        const SizedBox(height: 8),
        if (recentTransactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No payments recorded yet.', style: TextStyle(color: AppColors.inkSoft)),
          )
        else
          for (final t in recentTransactions) _TransactionRow(transaction: t),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.accent,
    this.valueColor,
  });

  final String label;
  final double value;
  final Color accent;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return CutCard(
      accent: accent,
      padding: const EdgeInsets.all(10),
      // These three sit close together in a row; the corner icon would
      // overlap into the next card at this width, so it's turned off here.
      showIcon: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 4),
          Text(
            formatMoney(value),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.data});
  final List<_MonthlyRevenue> data;

  @override
  Widget build(BuildContext context) {
    final maxAmount = data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxAmount * 1.2,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.threadDark,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              formatMoney(rod.toY),
              const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[i].label,
                    style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].amount,
                  color: AppColors.thread,
                  width: 18,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});
  final _Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: transaction.customerName),
                  TextSpan(
                    text: ' · ${transaction.dressType}',
                    style: const TextStyle(color: AppColors.inkSoft),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${formatMoney(transaction.payment.amount)}  ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            formatDate(transaction.payment.date),
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
