// lib/models/equipment.dart
class Equipment {
  final int? id;
  final String name;
  final String? model;
  final String? details;           // campo antigo (se ainda usar)
  final String? technicalDetails;  // ← NOVO CAMPO PARA INFORMAÇÕES TÉCNICAS LONGAS
  final int? brandId;
  final int? supplierId;
  final int? categoryId;
  final int currentQuantity;
  final int minQuantity;
  final int reservedQuantity;
  final int? unitId;
  final String? imagePath;
  final double? price;
  final bool hidePrice;

  Equipment({
    this.id,
    required this.name,
    this.model,
    this.details,
    this.technicalDetails,
    this.brandId,
    this.supplierId,
    this.categoryId,
    required this.currentQuantity,
    required this.minQuantity,
    this.reservedQuantity = 0,
    this.unitId,
    this.imagePath,
    this.price,
    this.hidePrice = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'models': model,
      'details': details,
      'technical_details': technicalDetails,  // ← nome da coluna no banco
      'brandid': brandId,
      'supplierid': supplierId,
      'categoryid': categoryId,
      'unitid': unitId,
      'currentquantity': currentQuantity,
      'minquantity': minQuantity,
      'reservedquantity': reservedQuantity,
      'imagepath': imagePath,
      'price': price,
      'hideprice': hidePrice,
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'] as int?,
      name: map['name'] as String,
      model: map['models'] as String?,
      details: map['details'] as String?,
      technicalDetails: map['technical_details'] as String?,  // ← novo
      brandId: map['brandid'] as int?,
      supplierId: map['supplierid'] as int?,
      categoryId: map['categoryid'] as int?,
      unitId: map['unitid'] as int?,
      currentQuantity: map['currentquantity'] as int,
      minQuantity: map['minquantity'] as int,
      reservedQuantity: map['reservedquantity'] as int? ?? 0,
      imagePath: map['imagepath'] as String?,
      price: map['price'] != null
          ? (map['price'] is int ? (map['price'] as int).toDouble() : map['price'] as double)
          : null,
      hidePrice: map['hideprice'] as bool? ?? false,
    );
  }

  Equipment copyWith({
    int? id,
    String? name,
    String? model,
    String? details,
    String? technicalDetails,
    int? brandId,
    int? supplierId,
    int? categoryId,
    int? currentQuantity,
    int? minQuantity,
    int? reservedQuantity,
    int? unitId,
    String? imagePath,
    double? price,
    bool? hidePrice,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      details: details ?? this.details,
      technicalDetails: technicalDetails ?? this.technicalDetails,
      brandId: brandId ?? this.brandId,
      supplierId: supplierId ?? this.supplierId,
      categoryId: categoryId ?? this.categoryId,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      minQuantity: minQuantity ?? this.minQuantity,
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      unitId: unitId ?? this.unitId,
      imagePath: imagePath ?? this.imagePath,
      price: price ?? this.price,
      hidePrice: hidePrice ?? this.hidePrice,
    );
  }
}