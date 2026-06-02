import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _incomeDisplaySharesByAddress = {
  '0x80ff32f2772d875d50737fd5c7f9225795497db2': 0.5,
};

void main() {
  runApp(const IncomeDashboardApp());
}

class IncomeDashboardApp extends StatelessWidget {
  const IncomeDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '历史收益看板',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F7F6),
        fontFamilyFallback: const [
          'PingFang SC',
          'Microsoft YaHei',
          'Noto Sans CJK SC',
        ],
      ),
      home: const DashboardPasswordGate(),
    );
  }
}

class DashboardPasswordGate extends StatefulWidget {
  const DashboardPasswordGate({super.key});

  @override
  State<DashboardPasswordGate> createState() => _DashboardPasswordGateState();
}

class _DashboardPasswordGateState extends State<DashboardPasswordGate> {
  static const _password = 'baby0301';
  final TextEditingController _controller = TextEditingController();
  bool _unlocked = false;
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final unlocked = _controller.text.trim() == _password;
    setState(() {
      _unlocked = unlocked;
      _invalid = !unlocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return const IncomeDashboardPage();
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF073B3A), Color(0xFF0F766E), Color(0xFF236B8E)],
          ),
        ),
        child: Center(
          child: Container(
            width: 360,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDCE7E6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Color(0xFF0F766E)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '历史收益看板',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF102A2A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  obscureText: true,
                  autofocus: true,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: '访问密码',
                    errorText: _invalid ? '密码不正确' : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('进入看板'),
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

class IncomeDashboardPage extends StatefulWidget {
  const IncomeDashboardPage({super.key});

  @override
  State<IncomeDashboardPage> createState() => _IncomeDashboardPageState();
}

class _IncomeDashboardPageState extends State<IncomeDashboardPage> {
  late Future<IncomeDashboardData> _future;
  String _countryFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _future = IncomeDashboardData.load();
  }

  Future<void> _reload() async {
    setState(() {
      _future = IncomeDashboardData.load(cacheBust: true);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<IncomeDashboardData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          return RefreshIndicator(
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroHeader(
                    data: data,
                    loading: snapshot.connectionState != ConnectionState.done,
                    error: snapshot.error?.toString(),
                    onReload: _reload,
                  ),
                ),
                if (snapshot.hasError && data == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(message: snapshot.error.toString()),
                  )
                else if (data == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  SliverToBoxAdapter(
                    child: _DashboardContent(
                      data: data,
                      countryFilter: _countryFilter,
                      onCountryChanged: (value) {
                        setState(() => _countryFilter = value);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.data,
    required this.loading,
    required this.error,
    required this.onReload,
  });

  final IncomeDashboardData? data;
  final bool loading;
  final String? error;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    final title = data?.title.trim().isNotEmpty == true
        ? data!.title
        : '历史收益看板';
    final month = data?.monthKey.trim().isNotEmpty == true
        ? data!.monthKey
        : '本地预览';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF073B3A), Color(0xFF0F766E), Color(0xFF236B8E)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$month / 更新 ${_formatDateTime(data?.generatedAt)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: '刷新数据',
                      onPressed: loading ? null : onReload,
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  _InlineNotice(text: '读取失败：$error'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.countryFilter,
    required this.onCountryChanged,
  });

  final IncomeDashboardData data;
  final String countryFilter;
  final ValueChanged<String> onCountryChanged;

  @override
  Widget build(BuildContext context) {
    final countries = <String>{
      'ALL',
      ...data.accounts
          .map((item) => item.countryIso)
          .where((v) => v.isNotEmpty),
    }.toList()..sort((a, b) => a == 'ALL' ? -1 : a.compareTo(b));
    final accounts = data.filteredAccounts(countryFilter);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryGrid(data: data, accounts: accounts),
              const SizedBox(height: 18),
              _SectionBand(
                title: '每日走势',
                trailing: _CountryFilter(
                  countries: countries,
                  value: countryFilter,
                  onChanged: onCountryChanged,
                ),
                child: _DailyBars(days: data.dailyTotalsFor(accounts)),
              ),
              const SizedBox(height: 18),
              _SectionBand(
                title: '计划拟合差异',
                child: _PlanFitPanel(rows: data.planFitRowsFor(accounts)),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  if (!wide) {
                    return Column(
                      children: [
                        _SectionBand(
                          title: '地区合计',
                          child: _CountryTotals(items: data.countryTotals),
                        ),
                        const SizedBox(height: 18),
                        _SectionBand(
                          title: '主播排行',
                          child: _AccountRanking(accounts: accounts),
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _SectionBand(
                          title: '地区合计',
                          child: _CountryTotals(items: data.countryTotals),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 6,
                        child: _SectionBand(
                          title: '主播排行',
                          child: _AccountRanking(accounts: accounts),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              _SectionBand(
                title: '历史收益明细',
                child: _IncomeTable(data: data, accounts: accounts),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data, required this.accounts});

  final IncomeDashboardData data;
  final List<IncomeAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final total = accounts.fold<double>(
      0,
      (sum, item) => sum + item.totalBeans,
    );
    final billCount = accounts.fold<int>(
      0,
      (sum, item) => sum + item.billCount,
    );
    final onlineCount = accounts.where((item) => item.online).length;
    final planned = accounts.fold<double>(
      0,
      (sum, item) =>
          sum +
          item.plans.values.fold<double>(
            0,
            (planSum, plan) => planSum + plan.targetBeans,
          ),
    );
    final cards = [
      _MetricData('总收益', _formatBeans(total), Icons.savings_rounded),
      _MetricData('计划收益', _formatBeans(planned), Icons.flag_rounded),
      _MetricData('收益笔数', _formatInt(billCount), Icons.receipt_long_rounded),
      _MetricData(
        '账号数',
        '${accounts.length}/${data.summary.accountCount}',
        Icons.groups_rounded,
      ),
      _MetricData('在线', _formatInt(onlineCount), Icons.bolt_rounded),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1040
            ? 5
            : width >= 760
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) => _MetricCard(data: cards[index]),
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 19, color: const Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF5E6F70),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: const TextStyle(
                color: Color(0xFF102A2A),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBand extends StatelessWidget {
  const _SectionBand({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A2A),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CountryFilter extends StatelessWidget {
  const _CountryFilter({
    required this.countries,
    required this.value,
    required this.onChanged,
  });

  final List<String> countries;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: countries.contains(value) ? value : 'ALL',
        borderRadius: BorderRadius.circular(8),
        items: countries
            .map(
              (country) => DropdownMenuItem(
                value: country,
                child: Text(country == 'ALL' ? '全部地区' : country),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _DailyBars extends StatelessWidget {
  const _DailyBars({required this.days});

  final List<DailyIncomeTotal> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const _EmptyState(text: '暂无每日收益数据');
    final maxValue = days.fold<double>(
      0,
      (max, item) =>
          math.max(max, math.max(item.totalBeans, item.plannedBeans)),
    );
    return SizedBox(
      height: 230,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final day in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Tooltip(
                  message:
                      '${day.date}\n实际 ${_formatBeans(day.totalBeans)}\n计划 ${_formatBeans(day.plannedBeans)}\n差异 ${_formatBeans(day.totalBeans - day.plannedBeans)}\n笔数 ${day.billCount}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              FractionallySizedBox(
                                heightFactor: maxValue <= 0
                                    ? 0
                                    : (day.plannedBeans / maxValue).clamp(
                                        0.05,
                                        1,
                                      ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF4D7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFE9C56A),
                                    ),
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              FractionallySizedBox(
                                heightFactor: maxValue <= 0
                                    ? 0
                                    : (day.totalBeans / maxValue).clamp(
                                        0.05,
                                        1,
                                      ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F766E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        day.date.substring(math.max(0, day.date.length - 2)),
                        style: const TextStyle(
                          color: Color(0xFF657475),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CountryTotals extends StatelessWidget {
  const _CountryTotals({required this.items});

  final List<CountryIncomeTotal> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyState(text: '暂无地区数据');
    final maxValue = items.fold<double>(
      0,
      (max, item) => math.max(max, item.totalBeans),
    );
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(
                    item.countryIso,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: maxValue <= 0 ? 0 : item.totalBeans / maxValue,
                      backgroundColor: const Color(0xFFE2EBEA),
                      color: const Color(0xFF236B8E),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 96,
                  child: Text(
                    _formatBeans(item.totalBeans),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanFitPanel extends StatelessWidget {
  const _PlanFitPanel({required this.rows});

  final List<PlanFitRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const _EmptyState(text: '暂无计划对比数据');
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _PlanFitDayCard(row: row),
          ),
      ],
    );
  }
}

class _PlanFitDayCard extends StatelessWidget {
  const _PlanFitDayCard({required this.row});

  final PlanFitRow row;

  @override
  Widget build(BuildContext context) {
    final diff = row.actualBeans - row.plannedBeans;
    final completion = row.plannedBeans <= 0
        ? 0.0
        : (row.actualBeans / row.plannedBeans).clamp(0.0, 1.4);
    final diffColor = diff >= 0
        ? const Color(0xFF0F766E)
        : const Color(0xFFB42318);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFB),
        border: Border.all(color: const Color(0xFFE1E7E4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                row.date,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF102A2A),
                ),
              ),
              _PlanFitPill(label: '预估', value: _formatBeans(row.plannedBeans)),
              _PlanFitPill(label: '实际', value: _formatBeans(row.actualBeans)),
              _PlanFitPill(
                label: '差额',
                value: _signedBeans(diff),
                valueColor: diffColor,
              ),
              _PlanFitPill(
                label: '拟合',
                value: '${(row.fitRatio * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: completion.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE9EFEA),
              color: diff >= 0
                  ? const Color(0xFF0F766E)
                  : const Color(0xFFE9A23B),
            ),
          ),
          if (row.accounts.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final account in row.accounts.take(8))
              _PlanFitAccountLine(account: account),
          ],
        ],
      ),
    );
  }
}

class _PlanFitPill extends StatelessWidget {
  const _PlanFitPill({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF20372F),
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E7E4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Color(0xFF657475)),
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: TextStyle(fontWeight: FontWeight.w800, color: valueColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanFitAccountLine extends StatelessWidget {
  const _PlanFitAccountLine({required this.account});

  final AccountPlanVariance account;

  @override
  Widget build(BuildContext context) {
    final diff = account.actualBeans - account.plannedBeans;
    final diffColor = diff >= 0
        ? const Color(0xFF0F766E)
        : const Color(0xFFB42318);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${account.displayName} · ${account.countryIso}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF20372F),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${_formatBeans(account.actualBeans)} / ${_formatBeans(account.plannedBeans)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF657475)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              _signedBeans(diff),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: diffColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRanking extends StatelessWidget {
  const _AccountRanking({required this.accounts});

  final List<IncomeAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final sorted = [...accounts]
      ..sort((a, b) => b.totalBeans.compareTo(a.totalBeans));
    final top = sorted.take(8).toList();
    if (top.isEmpty) return const _EmptyState(text: '暂无主播数据');
    return Column(
      children: [
        for (var i = 0; i < top.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i < 3
                        ? const Color(0xFFFFF4D7)
                        : const Color(0xFFE8F1F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: i < 3
                          ? const Color(0xFF9A5B00)
                          : const Color(0xFF315253),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        top[i].displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${top[i].countryIso} / ${top[i].billCount} 笔',
                        style: const TextStyle(
                          color: Color(0xFF657475),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatBeans(top[i].totalBeans),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _IncomeTable extends StatefulWidget {
  const _IncomeTable({required this.data, required this.accounts});

  final IncomeDashboardData data;
  final List<IncomeAccount> accounts;

  @override
  State<_IncomeTable> createState() => _IncomeTableState();
}

class _IncomeTableState extends State<_IncomeTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_horizontalController.hasClients) {
      return;
    }
    final position = _horizontalController.position;
    final next = (_horizontalController.offset + event.scrollDelta.dy)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (next != _horizontalController.offset) {
      _horizontalController.jumpTo(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accounts.isEmpty) return const _EmptyState(text: '暂无明细数据');
    final days = widget.data.days.reversed.toList(growable: false);
    final sorted = [...widget.accounts]
      ..sort((a, b) => b.totalBeans.compareTo(a.totalBeans));
    final width = _historicalIncomeTableWidth(days.length);
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        interactive: true,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                _HistoricalIncomeHeader(days: days),
                const SizedBox(height: 8),
                for (final account in sorted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _HistoricalIncomeAccountRow(
                      account: account,
                      days: days,
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double _historicalIncomeTableWidth(int dayCount) {
  const fixedCellWidth = 252 + 58 + 92 + 60;
  const cellGap = 6;
  const horizontalListPadding = 28;
  return (fixedCellWidth +
          dayCount * _historicalIncomeDayCellWidth +
          (4 + dayCount) * cellGap +
          horizontalListPadding)
      .toDouble();
}

const double _historicalIncomeDayCellWidth = 88;

class _HistoricalIncomeHeader extends StatelessWidget {
  const _HistoricalIncomeHeader({required this.days});

  final List<String> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _HistoricalIncomeCell(text: '主播', width: 252, header: true),
        const _HistoricalIncomeCell(text: '地区', width: 58, header: true),
        const _HistoricalIncomeCell(text: '合计', width: 92, header: true),
        const _HistoricalIncomeCell(text: '笔数', width: 60, header: true),
        for (final day in days) _HistoricalDateHeaderCell(day: _dayLabel(day)),
      ],
    );
  }
}

class _HistoricalIncomeAccountRow extends StatelessWidget {
  const _HistoricalIncomeAccountRow({
    required this.account,
    required this.days,
  });

  final IncomeAccount account;
  final List<String> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HistoricalHostCell(account: account),
        _HistoricalIncomeCell(text: account.countryIso, width: 58),
        _HistoricalIncomeCell(
          text: _formatBeans(account.totalBeans),
          width: 92,
          strong: account.totalBeans > 0,
        ),
        _HistoricalIncomeCell(text: '${account.billCount}', width: 60),
        for (final day in days)
          _HistoricalDailyCell(
            date: day,
            value: account.days[day] ?? DailyIncomeBreakdown.empty,
            plan: account.plans[day],
          ),
      ],
    );
  }
}

class _HistoricalHostCell extends StatelessWidget {
  const _HistoricalHostCell({required this.account});

  final IncomeAccount account;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      height: 42,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E7E4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFEAF8F4),
            child: Text(
              _avatarFallback(account),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF246B60),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              account.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF20372F),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: '刷新该主播历史收益',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 17,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请在 Mac app 内刷新该主播历史收益')),
              ),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoricalDateHeaderCell extends StatelessWidget {
  const _HistoricalDateHeaderCell({required this.day});

  final String day;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _historicalIncomeDayCellWidth,
      height: 34,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.only(left: 8, right: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFEC),
        border: Border.all(color: const Color(0xFFE1E7E4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              day,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF20372F),
              ),
            ),
          ),
          Tooltip(
            message: 'Mac app 内可刷新所有主播该日收益',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 15,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 26, height: 26),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请在 Mac app 内刷新所有主播该日收益')),
              ),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoricalDailyCell extends StatelessWidget {
  const _HistoricalDailyCell({
    required this.date,
    required this.value,
    required this.plan,
  });

  final String date;
  final DailyIncomeBreakdown value;
  final IncomeStrategyPlanBreakdown? plan;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.totalBeans > 0;
    final plannedBeans = plan?.targetBeans ?? 0;
    final hasPlan = plannedBeans > 0;
    return Tooltip(
      message:
          '$date\n实际 ${_formatBeans(value.totalBeans)}\n计划 ${_formatBeans(plannedBeans)}\n差异 ${_formatBeans(value.totalBeans - plannedBeans)}\n账单 ${value.billCount}',
      child: _HistoricalIncomeSplitCell(
        value: DailyIncomeBreakdown(
          totalBeans: value.totalBeans,
          billCount: value.billCount,
          plannedBeans: plannedBeans,
        ),
        width: _historicalIncomeDayCellWidth,
        muted: !hasValue && !hasPlan,
        fill: hasPlan
            ? const Color(0xFFFFFAE8)
            : hasValue
            ? const Color(0xFFEAF8F4)
            : null,
      ),
    );
  }
}

class _HistoricalIncomeSplitCell extends StatelessWidget {
  const _HistoricalIncomeSplitCell({
    required this.value,
    required this.width,
    this.muted = false,
    this.fill,
  });

  final DailyIncomeBreakdown value;
  final double width;
  final bool muted;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.totalBeans > 0;
    final hasPlan = value.plannedBeans > 0;
    return Container(
      width: width,
      height: 50,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill ?? Colors.white,
        border: Border.all(color: const Color(0xFFE1E7E4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: hasValue || hasPlan
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasPlan)
                  Text(
                    _formatBeans(value.plannedBeans),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9A5B00),
                    ),
                  ),
                Text(
                  hasValue ? _formatBeans(value.totalBeans) : '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20372F),
                  ),
                ),
              ],
            )
          : Text(
              '-',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: muted
                    ? const Color(0xFF9AA7A1)
                    : const Color(0xFF20372F),
              ),
            ),
    );
  }
}

class _HistoricalIncomeCell extends StatelessWidget {
  const _HistoricalIncomeCell({
    required this.text,
    required this.width,
    this.header = false,
    this.strong = false,
  });

  final String text;
  final double width;
  final bool header;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: header ? 34 : 42,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: header ? const Color(0xFFE8EFEC) : Colors.white,
        border: Border.all(color: const Color(0xFFE1E7E4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: header ? 12 : 11,
          fontWeight: header || strong ? FontWeight.w800 : FontWeight.w500,
          color: const Color(0xFF20372F),
        ),
      ),
    );
  }
}

String _dayLabel(String date) {
  if (date.length >= 10) {
    return int.tryParse(date.substring(8, 10))?.toString() ?? date;
  }
  return date;
}

String _avatarFallback(IncomeAccount account) {
  final text = account.displayName.trim();
  if (text.isEmpty) return account.countryIso.characters.take(1).toString();
  return text.characters.take(1).toString().toUpperCase();
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _InlineNotice(text: '数据读取失败：$message'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(minHeight: 120),
      child: Text(text, style: const TextStyle(color: Color(0xFF657475))),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7C46B)),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF6B4C00))),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFDCE7E6)),
    boxShadow: const [
      BoxShadow(color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 8)),
    ],
  );
}

class IncomeDashboardData {
  const IncomeDashboardData({
    required this.title,
    required this.monthKey,
    required this.generatedAt,
    required this.summary,
    required this.dailyTotals,
    required this.countryTotals,
    required this.accounts,
  });

  final String title;
  final String monthKey;
  final DateTime? generatedAt;
  final IncomeSummary summary;
  final List<DailyIncomeTotal> dailyTotals;
  final List<CountryIncomeTotal> countryTotals;
  final List<IncomeAccount> accounts;

  List<String> get days {
    final values = <String>{
      ...dailyTotals.map((item) => item.date),
      for (final account in accounts) ...account.days.keys,
      for (final account in accounts) ...account.plans.keys,
    }.toList()..sort();
    return values;
  }

  List<IncomeAccount> filteredAccounts(String country) {
    if (country == 'ALL') return accounts;
    return accounts.where((item) => item.countryIso == country).toList();
  }

  List<DailyIncomeTotal> dailyTotalsFor(List<IncomeAccount> visibleAccounts) {
    final totals = {for (final day in days) day: DailyIncomeTotal(date: day)};
    for (final account in visibleAccounts) {
      for (final entry in account.days.entries) {
        final current = totals[entry.key] ?? DailyIncomeTotal(date: entry.key);
        totals[entry.key] = current.copyWith(
          totalBeans: current.totalBeans + entry.value.totalBeans,
          billCount: current.billCount + entry.value.billCount,
        );
      }
      for (final entry in account.plans.entries) {
        final current = totals[entry.key] ?? DailyIncomeTotal(date: entry.key);
        totals[entry.key] = current.copyWith(
          plannedBeans: current.plannedBeans + entry.value.targetBeans,
        );
      }
    }
    return totals.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  List<PlanFitRow> planFitRowsFor(List<IncomeAccount> visibleAccounts) {
    final visibleDays = <String>{
      for (final account in visibleAccounts) ...account.days.keys,
      for (final account in visibleAccounts) ...account.plans.keys,
    }.toList()..sort();
    final rows = <PlanFitRow>[];
    for (final day in visibleDays) {
      var actualBeans = 0.0;
      var plannedBeans = 0.0;
      final accountRows = <AccountPlanVariance>[];
      for (final account in visibleAccounts) {
        final actual = account.days[day]?.totalBeans ?? 0;
        final planned = account.plans[day]?.targetBeans ?? 0;
        actualBeans += actual;
        plannedBeans += planned;
        if (actual > 0 || planned > 0) {
          accountRows.add(
            AccountPlanVariance(
              displayName: account.displayName,
              countryIso: account.countryIso,
              actualBeans: actual,
              plannedBeans: planned,
            ),
          );
        }
      }
      if (actualBeans <= 0 && plannedBeans <= 0) continue;
      accountRows.sort(
        (a, b) => b.absoluteDiffBeans.compareTo(a.absoluteDiffBeans),
      );
      rows.add(
        PlanFitRow(
          date: day,
          actualBeans: actualBeans,
          plannedBeans: plannedBeans,
          accounts: accountRows,
        ),
      );
    }
    return rows.reversed.take(7).toList().reversed.toList();
  }

  static Future<IncomeDashboardData> load({bool cacheBust = false}) async {
    final uri = Uri.base.resolve(
      'data/income.json?t=${DateTime.now().millisecondsSinceEpoch}',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) throw const FormatException('income.json 不是对象');
    return IncomeDashboardData.fromJson(Map<String, dynamic>.from(decoded));
  }

  factory IncomeDashboardData.fromJson(Map<String, dynamic> json) {
    final accounts =
        _list(
            json['accounts'],
          ).map((item) => IncomeAccount.fromJson(item)).toList()
          ..sort((a, b) => b.totalBeans.compareTo(a.totalBeans));
    final countryTotals = _countryTotalsFromAccounts(accounts)
      ..sort((a, b) => b.totalBeans.compareTo(a.totalBeans));
    final dailyTotals = _dailyTotalsFromAccounts(accounts)
      ..sort((a, b) => a.date.compareTo(b.date));
    final summary = IncomeSummary.fromJson(_map(json['summary']))
        .withTotalBeans(
          accounts.fold<double>(0, (sum, account) => sum + account.totalBeans),
        );
    return IncomeDashboardData(
      title: json['title']?.toString() ?? '历史收益看板',
      monthKey: json['monthKey']?.toString() ?? '',
      generatedAt: DateTime.tryParse(json['generatedAtIso']?.toString() ?? ''),
      summary: summary,
      dailyTotals: dailyTotals,
      countryTotals: countryTotals,
      accounts: accounts,
    );
  }
}

class PlanFitRow {
  const PlanFitRow({
    required this.date,
    required this.actualBeans,
    required this.plannedBeans,
    required this.accounts,
  });

  final String date;
  final double actualBeans;
  final double plannedBeans;
  final List<AccountPlanVariance> accounts;

  double get fitRatio {
    if (plannedBeans <= 0) return actualBeans > 0 ? 1 : 0;
    return actualBeans / plannedBeans;
  }
}

class AccountPlanVariance {
  const AccountPlanVariance({
    required this.displayName,
    required this.countryIso,
    required this.actualBeans,
    required this.plannedBeans,
  });

  final String displayName;
  final String countryIso;
  final double actualBeans;
  final double plannedBeans;

  double get absoluteDiffBeans => (actualBeans - plannedBeans).abs();
}

class IncomeSummary {
  const IncomeSummary({
    required this.totalBeans,
    required this.billCount,
    required this.accountCount,
    required this.giftBeans,
    required this.messageBeans,
    required this.otherBeans,
  });

  final double totalBeans;
  final int billCount;
  final int accountCount;
  final double giftBeans;
  final double messageBeans;
  final double otherBeans;

  factory IncomeSummary.fromJson(Map<String, dynamic> json) {
    return IncomeSummary(
      totalBeans: _double(json['totalBeans']),
      billCount: _int(json['billCount']),
      accountCount: _int(json['accountCount']),
      giftBeans: _double(json['giftBeans']),
      messageBeans: _double(json['messageBeans']),
      otherBeans: _double(json['otherBeans']),
    );
  }

  IncomeSummary withTotalBeans(double value) {
    return IncomeSummary(
      totalBeans: value,
      billCount: billCount,
      accountCount: accountCount,
      giftBeans: giftBeans,
      messageBeans: messageBeans,
      otherBeans: otherBeans,
    );
  }
}

class DailyIncomeTotal {
  const DailyIncomeTotal({
    required this.date,
    this.totalBeans = 0,
    this.plannedBeans = 0,
    this.billCount = 0,
  });

  final String date;
  final double totalBeans;
  final double plannedBeans;
  final int billCount;

  DailyIncomeTotal copyWith({
    double? totalBeans,
    double? plannedBeans,
    int? billCount,
  }) {
    return DailyIncomeTotal(
      date: date,
      totalBeans: totalBeans ?? this.totalBeans,
      plannedBeans: plannedBeans ?? this.plannedBeans,
      billCount: billCount ?? this.billCount,
    );
  }

  factory DailyIncomeTotal.fromJson(Map<String, dynamic> json) {
    return DailyIncomeTotal(
      date: json['date']?.toString() ?? '',
      totalBeans: _double(json['totalBeans']),
      plannedBeans: _double(json['plannedBeans']),
      billCount: _int(json['billCount']),
    );
  }
}

class CountryIncomeTotal {
  const CountryIncomeTotal({
    required this.countryIso,
    required this.totalBeans,
    required this.billCount,
    required this.accountCount,
  });

  final String countryIso;
  final double totalBeans;
  final int billCount;
  final int accountCount;

  factory CountryIncomeTotal.fromJson(Map<String, dynamic> json) {
    return CountryIncomeTotal(
      countryIso: json['countryIso']?.toString() ?? '-',
      totalBeans: _double(json['totalBeans']),
      billCount: _int(json['billCount']),
      accountCount: _int(json['accountCount']),
    );
  }
}

class IncomeAccount {
  const IncomeAccount({
    required this.id,
    required this.displayName,
    required this.countryIso,
    required this.address,
    required this.totalBeans,
    required this.billCount,
    required this.days,
    required this.plans,
    required this.online,
  });

  final String id;
  final String displayName;
  final String countryIso;
  final String address;
  final double totalBeans;
  final int billCount;
  final Map<String, DailyIncomeBreakdown> days;
  final Map<String, IncomeStrategyPlanBreakdown> plans;
  final bool online;

  factory IncomeAccount.fromJson(Map<String, dynamic> json) {
    final address = json['address']?.toString() ?? '';
    final displayShare = _incomeDisplayShareForAddress(address);
    final days = <String, DailyIncomeBreakdown>{};
    final rawDays = json['days'];
    if (rawDays is Map) {
      for (final entry in rawDays.entries) {
        days[entry.key.toString()] = DailyIncomeBreakdown.fromJson(
          entry.value,
        ).scaled(displayShare);
      }
    }
    final plans = <String, IncomeStrategyPlanBreakdown>{};
    final rawPlans = json['plans'];
    if (rawPlans is Map) {
      for (final entry in rawPlans.entries) {
        plans[entry.key.toString()] = IncomeStrategyPlanBreakdown.fromJson(
          entry.value,
        );
      }
    }
    return IncomeAccount(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '未命名主播',
      countryIso: json['countryIso']?.toString() ?? '-',
      address: address,
      totalBeans: _double(json['totalBeans']) * displayShare,
      billCount: _int(json['billCount']),
      days: days,
      plans: plans,
      online: json['online'] == true,
    );
  }
}

class IncomeStrategyPlanBreakdown {
  const IncomeStrategyPlanBreakdown({
    required this.targetBeans,
    required this.targetUsd,
    required this.tier,
  });

  final double targetBeans;
  final double targetUsd;
  final String tier;

  factory IncomeStrategyPlanBreakdown.fromJson(Object? value) {
    if (value is! Map) {
      return const IncomeStrategyPlanBreakdown(
        targetBeans: 0,
        targetUsd: 0,
        tier: '',
      );
    }
    final map = Map<String, dynamic>.from(value);
    return IncomeStrategyPlanBreakdown(
      targetBeans: _double(map['targetBeans']),
      targetUsd: _double(map['targetUsd']),
      tier: map['tier']?.toString() ?? '',
    );
  }
}

class DailyIncomeBreakdown {
  const DailyIncomeBreakdown({
    required this.totalBeans,
    required this.billCount,
    this.plannedBeans = 0,
  });

  static const empty = DailyIncomeBreakdown(totalBeans: 0, billCount: 0);

  final double totalBeans;
  final int billCount;
  final double plannedBeans;

  factory DailyIncomeBreakdown.fromJson(Object? value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return DailyIncomeBreakdown(
        totalBeans: _double(map['totalBeans']),
        billCount: _int(map['billCount']),
        plannedBeans: _double(map['plannedBeans']),
      );
    }
    return DailyIncomeBreakdown(totalBeans: _double(value), billCount: 0);
  }

  DailyIncomeBreakdown scaled(double factor) {
    if (factor == 1) return this;
    return DailyIncomeBreakdown(
      totalBeans: totalBeans * factor,
      billCount: billCount,
      plannedBeans: plannedBeans,
    );
  }
}

List<CountryIncomeTotal> _countryTotalsFromAccounts(
  List<IncomeAccount> accounts,
) {
  final grouped = <String, List<IncomeAccount>>{};
  for (final account in accounts) {
    grouped.putIfAbsent(account.countryIso, () => []).add(account);
  }
  return [
    for (final entry in grouped.entries)
      CountryIncomeTotal(
        countryIso: entry.key,
        totalBeans: entry.value.fold<double>(
          0,
          (sum, account) => sum + account.totalBeans,
        ),
        billCount: entry.value.fold<int>(
          0,
          (sum, account) => sum + account.billCount,
        ),
        accountCount: entry.value.length,
      ),
  ];
}

List<DailyIncomeTotal> _dailyTotalsFromAccounts(List<IncomeAccount> accounts) {
  final totals = <String, DailyIncomeTotal>{};
  for (final account in accounts) {
    for (final entry in account.days.entries) {
      final current = totals[entry.key] ?? DailyIncomeTotal(date: entry.key);
      totals[entry.key] = current.copyWith(
        totalBeans: current.totalBeans + entry.value.totalBeans,
        billCount: current.billCount + entry.value.billCount,
      );
    }
    for (final entry in account.plans.entries) {
      final current = totals[entry.key] ?? DailyIncomeTotal(date: entry.key);
      totals[entry.key] = current.copyWith(
        plannedBeans: current.plannedBeans + entry.value.targetBeans,
      );
    }
  }
  return totals.values.toList();
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) return const {};
  return Map<String, dynamic>.from(value);
}

double _double(Object? value) => double.tryParse(value?.toString() ?? '') ?? 0;

int _int(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;

double _incomeDisplayShareForAddress(String address) {
  return _incomeDisplaySharesByAddress[address.trim().toLowerCase()] ?? 1;
}

String _formatBeans(double value) {
  return '\$${(value / 1000).toStringAsFixed(2)}';
}

String _signedBeans(double value) {
  if (value == 0) return _formatBeans(0);
  final dollars = (value.abs() / 1000).toStringAsFixed(2);
  return value > 0 ? '+\$$dollars' : '-\$$dollars';
}

String _formatInt(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final indexFromEnd = raw.length - i;
    buffer.write(raw[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  String two(int n) => n.toString().padLeft(2, '0');
  final local = value.toLocal();
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
