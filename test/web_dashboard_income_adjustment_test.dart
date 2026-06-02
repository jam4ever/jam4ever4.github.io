import 'package:flutter_test/flutter_test.dart';
import 'package:income_dashboard_pages/web_dashboard/main.dart';

void main() {
  test(
    'applies configured display share after June first to matching income only',
    () {
      final data = IncomeDashboardData.fromJson({
        'title': '历史收益看板',
        'monthKey': '2026-06',
        'generatedAtIso': '2026-06-02T00:00:00Z',
        'summary': {
          'totalBeans': 70000,
          'billCount': 7,
          'accountCount': 2,
          'giftBeans': 0,
          'messageBeans': 0,
          'otherBeans': 0,
        },
        'countryTotals': [
          {
            'countryIso': 'BR',
            'totalBeans': 70000,
            'billCount': 7,
            'accountCount': 2,
          },
        ],
        'dailyTotals': [
          {'date': '2026-05-31', 'totalBeans': 20000, 'billCount': 2},
          {'date': '2026-06-01', 'totalBeans': 20000, 'billCount': 2},
          {'date': '2026-06-02', 'totalBeans': 30000, 'billCount': 3},
        ],
        'accounts': [
          {
            'id': 'acct-648439',
            'displayName': 'Target',
            'countryIso': 'BR',
            'totalBeans': 60000,
            'billCount': 6,
            'days': {
              '2026-05-31': {'totalBeans': 20000, 'billCount': 2},
              '2026-06-01': {'totalBeans': 20000, 'billCount': 2},
              '2026-06-02': {'totalBeans': 20000, 'billCount': 2},
            },
          },
          {
            'id': 'normal',
            'displayName': 'Normal',
            'countryIso': 'BR',
            'address': 'another-address',
            'totalBeans': 10000,
            'billCount': 1,
            'days': {
              '2026-06-02': {'totalBeans': 10000, 'billCount': 1},
            },
          },
        ],
      });

      final target = data.accounts.singleWhere(
        (item) => item.id == 'acct-648439',
      );
      final normal = data.accounts.singleWhere((item) => item.id == 'normal');

      expect(target.totalBeans, 50000);
      expect(target.days['2026-05-31']!.totalBeans, 20000);
      expect(target.days['2026-06-01']!.totalBeans, 20000);
      expect(target.days['2026-06-02']!.totalBeans, 10000);
      expect(normal.totalBeans, 10000);
      expect(normal.days['2026-06-02']!.totalBeans, 10000);
      expect(data.summary.totalBeans, 60000);
      expect(data.countryTotals.single.totalBeans, 60000);
      expect(
        data.dailyTotals
            .singleWhere((item) => item.date == '2026-05-31')
            .totalBeans,
        20000,
      );
      expect(
        data.dailyTotals
            .singleWhere((item) => item.date == '2026-06-01')
            .totalBeans,
        20000,
      );
      expect(
        data.dailyTotals
            .singleWhere((item) => item.date == '2026-06-02')
            .totalBeans,
        20000,
      );
      expect(
        data
            .dailyTotalsFor(data.accounts)
            .singleWhere((item) => item.date == '2026-06-02')
            .totalBeans,
        20000,
      );
    },
  );

  test('groups daily income into monthly history archives', () {
    final data = IncomeDashboardData.fromJson({
      'title': '历史收益看板',
      'monthKey': '2026-06',
      'generatedAtIso': '2026-06-02T00:00:00Z',
      'summary': {
        'totalBeans': 45000,
        'billCount': 9,
        'accountCount': 1,
        'giftBeans': 0,
        'messageBeans': 0,
        'otherBeans': 0,
      },
      'accounts': [
        {
          'id': 'normal',
          'displayName': 'Normal',
          'countryIso': 'BR',
          'address': 'another-address',
          'totalBeans': 45000,
          'billCount': 9,
          'days': {
            '2026-05-01': {'totalBeans': 10000, 'billCount': 2},
            '2026-05-02': {'totalBeans': 15000, 'billCount': 3},
            '2026-06-01': {'totalBeans': 20000, 'billCount': 4},
          },
        },
      ],
    });

    final archives = data.monthlyArchives;

    expect(archives.map((item) => item.monthKey), ['2026-06', '2026-05']);
    expect(archives.first.totalBeans, 20000);
    expect(archives.first.billCount, 4);
    expect(archives.last.totalBeans, 25000);
    expect(archives.last.billCount, 5);
    expect(archives.last.dayCount, 2);
  });
}
