class PontoConfig {
  final String branchId;
  final Map<String, dynamic> configJson; // dias_semana, hora_extra, vale_refeicao, etc.

  PontoConfig({required this.branchId, required this.configJson});

  factory PontoConfig.fromMap(Map<String, dynamic> map) {
    return PontoConfig(
      branchId: map['branch_id'],
      configJson: map['config_json'],
    );
  }
}