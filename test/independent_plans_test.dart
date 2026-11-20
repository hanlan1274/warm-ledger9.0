import 'package:flutter_test/flutter_test.dart';
import 'package:warm_ledger/model.dart';
import 'ui_review_test.dart' show sample;

void main() {
  test(
    'overlapping plans remain independent, negative balances persist and reverse',
    () {
      final b = sample();
      final a = b.plans.first;
      final second = Plan.fromJson(a.toJson())
        ..id = 'other'
        ..name = '另一个计划';
      second.budget = 5000;
      second.reservations.clear();
      b.plans.add(second);
      final before = b.spendable(a);
      final w = b.wallets.first.id;
      b.consume(w, 8000, '餐饮', today(), '', planId: second.id);
      expect(b.spendable(second), -3000);
      expect(b.spendable(a), before);
      b.receiveIncome(
        wallet: w,
        amount: 1000,
        date: today(),
        category: '收入',
        planId: second.id,
      );
      expect(b.spendable(second), -2000);
      expect(b.entries.last.planAfter, -2000);
      final saved = Book.fromJson(b.toJson());
      expect(saved.spendable(saved.plans.last), -2000);
      expect(saved.spendable(saved.plans.first), before);
      saved.voidEntry(saved.entries.last, '撤销收入');
      expect(saved.spendable(saved.plans.last), -3000);
      saved.voidEntry(saved.entries[saved.entries.length - 2], '撤销支出');
      expect(saved.spendable(saved.plans.last), 5000);
      b.consume(w, 4000, '住房', today(), '', planId: '');
      expect(b.spendable(a), before);
      expect(b.spendable(second), -2000);
    },
  );
  test('legacy overlap is assigned once and never reapplied on restore', () {
    final b = sample();
    b.plans.add(Plan.fromJson(b.plans.first.toJson())..id = 'second');
    final j = b.toJson()..['schema'] = 4;
    for (final e in j['entries'] as List) {
      (e as Map).remove('planId');
      e.remove('planName');
    }
    final migrated = Book.fromJson(j);
    expect(migrated.plans.fold(0, (n, p) => n + migrated.spent(p)), 1800);
    final again = Book.fromJson(migrated.toJson());
    expect(again.plans.fold(0, (n, p) => n + again.spent(p)), 1800);
  });
}
