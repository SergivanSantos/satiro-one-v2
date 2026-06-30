class BankHour {
  final String id;
  final String employeeId;
  final String branchId;
  final double balance;
  final DateTime lastUpdated;

  BankHour({
    required this.id,
    required this.employeeId,
    required this.branchId,
    required this.balance,
    required this.lastUpdated,
  });

  factory BankHour.fromMap(Map<String, dynamic> map) {
    return BankHour(
      id: map['id'],
      employeeId: map['employee_id'],
      branchId: map['branch_id'],
      balance: (map['balance'] as num).toDouble(),
      lastUpdated: DateTime.parse(map['last_updated']),
    );
  }
}