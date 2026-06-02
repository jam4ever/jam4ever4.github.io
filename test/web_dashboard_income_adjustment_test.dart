import 'package:flutter_test/flutter_test.dart';
import 'package:income_dashboard_pages/web_dashboard/main.dart';

void main() {
  test('applies configured display share to matching address income only', () {
    final data = IncomeDashboardData.fromJson({
      'title': '历史收益看板',
      'monthKey': '2026-06',
      'generatedAtIso': '2026-06-02T00:00:00Z',
      'summary': {
        'totalBeans': 30000,
        'billCount': 3,
        'accountCount': 2,
        'giftBeans': 0,
        'messageBeans': 0,
        'otherBeans': 0,
      },
      'countryTotals': [
        {
          'countryIso': 'BR',
          'totalBeans': 30000,
          'billCount': 3,
          'accountCount': 2,
        },
      ],
      'dailyTotals': [
        {'date': '2026-06-01', 'totalBeans': 30000, 'billCount': 3},
      ],
      'accounts': [
        {
          'id': 'target',
          'displayName': 'Target',
          'countryIso': 'BR',
          'address': '0x80ff32f2772d875d50737fd5c7f9225795497db2',
          'totalBeans': 20000,
          'billCount': 2,
          'days': {
            '2026-06-01': {'totalBeans': 20000, 'billCount': 2},
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
            '2026-06-01': {'totalBeans': 10000, 'billCount': 1},
          },
        },
      ],
    });

    final target = data.accounts.singleWhere((item) => item.id == 'target');
    final normal = data.accounts.singleWhere((item) => item.id == 'normal');

    expect(target.totalBeans, 10000);
    expect(target.days['2026-06-01']!.totalBeans, 10000);
    expect(normal.totalBeans, 10000);
    expect(normal.days['2026-06-01']!.totalBeans, 10000);
    expect(data.summary.totalBeans, 20000);
    expect(data.countryTotals.single.totalBeans, 20000);
    expect(data.dailyTotals.single.totalBeans, 20000);
    expect(data.dailyTotalsFor(data.accounts).single.totalBeans, 20000);
  });
}
