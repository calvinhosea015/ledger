enum EnvelopeType {
  income,
  fixed,
  variable,
  savings;

  String get wire => name;

  static EnvelopeType fromWire(String raw) {
    return EnvelopeType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => EnvelopeType.variable,
    );
  }

  bool get isExpense => this == fixed || this == variable;

  bool get usesPurchaseActual => isExpense;
}

class Category {
  const Category({
    required this.id,
    required this.userId,
    required this.name,
    this.color,
  });

  final String id;
  final String userId;
  final String name;
  final String? color;

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? color,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}

class Purchase {
  const Purchase({
    required this.id,
    required this.userId,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.currencyCode,
    required this.purchasedAt,
    required this.expectedFinishAt,
    this.expiresAt,
    this.finishedAt,
    this.notes,
  });

  final String id;
  final String userId;
  final String name;
  final String categoryId;
  final double price;
  final String currencyCode;
  final DateTime purchasedAt;
  final DateTime expectedFinishAt;
  final DateTime? expiresAt;
  final DateTime? finishedAt;
  final String? notes;

  bool get isFinished => finishedAt != null;

  Purchase copyWith({
    String? id,
    String? userId,
    String? name,
    String? categoryId,
    double? price,
    String? currencyCode,
    DateTime? purchasedAt,
    DateTime? expectedFinishAt,
    DateTime? expiresAt,
    DateTime? finishedAt,
    String? notes,
    bool clearExpiresAt = false,
    bool clearFinishedAt = false,
    bool clearNotes = false,
  }) {
    return Purchase(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      currencyCode: currencyCode ?? this.currencyCode,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      expectedFinishAt: expectedFinishAt ?? this.expectedFinishAt,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      finishedAt: clearFinishedAt ? null : (finishedAt ?? this.finishedAt),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }
}

class Profile {
  const Profile({
    required this.id,
    required this.userId,
    required this.currencyCode,
  });

  final String id;
  final String userId;
  final String currencyCode;

  Profile copyWith({
    String? id,
    String? userId,
    String? currencyCode,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}

class Envelope {
  const Envelope({
    required this.id,
    required this.userId,
    required this.year,
    required this.month,
    required this.name,
    required this.type,
    required this.budgeted,
    required this.actual,
    required this.currencyCode,
    this.categoryId,
  });

  final String id;
  final String userId;
  final int year;
  final int month;
  final String name;
  final EnvelopeType type;
  final double budgeted;
  final double actual;
  final String currencyCode;
  final String? categoryId;

  Envelope copyWith({
    String? id,
    String? userId,
    int? year,
    int? month,
    String? name,
    EnvelopeType? type,
    double? budgeted,
    double? actual,
    String? currencyCode,
    String? categoryId,
    bool clearCategoryId = false,
  }) {
    return Envelope(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      year: year ?? this.year,
      month: month ?? this.month,
      name: name ?? this.name,
      type: type ?? this.type,
      budgeted: budgeted ?? this.budgeted,
      actual: actual ?? this.actual,
      currencyCode: currencyCode ?? this.currencyCode,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
    );
  }
}

class NewCategory {
  const NewCategory({required this.name, this.color});

  final String name;
  final String? color;
}

class NewPurchase {
  const NewPurchase({
    required this.name,
    required this.categoryId,
    required this.price,
    required this.currencyCode,
    required this.purchasedAt,
    required this.expectedFinishAt,
    this.expiresAt,
    this.notes,
  });

  final String name;
  final String categoryId;
  final double price;
  final String currencyCode;
  final DateTime purchasedAt;
  final DateTime expectedFinishAt;
  final DateTime? expiresAt;
  final String? notes;
}

class NewEnvelope {
  const NewEnvelope({
    required this.year,
    required this.month,
    required this.name,
    required this.type,
    required this.budgeted,
    required this.currencyCode,
    this.actual = 0,
    this.categoryId,
  });

  final int year;
  final int month;
  final String name;
  final EnvelopeType type;
  final double budgeted;
  final double actual;
  final String currencyCode;
  final String? categoryId;
}
