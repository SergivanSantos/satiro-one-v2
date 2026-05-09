class OvertimeRequest {
  final String id;
  final String employeeId;
  final String branchId;
  final DateTime date;
  final double hoursRequested;
  final String reason;
  final String status; // pending, approved, rejected
  final String? supervisorId;
  final DateTime? approvedAt;
  final String? rejectionReason;

  OvertimeRequest({
    required this.id,
    required this.employeeId,
    required this.branchId,
    required this.date,
    required this.hoursRequested,
    required this.reason,
    required this.status,
    this.supervisorId,
    this.approvedAt,
    this.rejectionReason,
  });

  factory OvertimeRequest.fromMap(Map<String, dynamic> map) {
    return OvertimeRequest(
      id: map['id'],
      employeeId: map['employee_id'],
      branchId: map['branch_id'],
      date: DateTime.parse(map['date']),
      hoursRequested: (map['hours_requested'] as num).toDouble(),
      reason: map['reason'],
      status: map['status'],
      supervisorId: map['supervisor_id'],
      approvedAt: map['approved_at'] != null ? DateTime.parse(map['approved_at']) : null,
      rejectionReason: map['rejection_reason'],
    );
  }
}