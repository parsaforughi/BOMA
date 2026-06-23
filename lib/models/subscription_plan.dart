class SubscriptionPlan {
  final String id;
  final String name;
  final String displayName;
  final int months;
  final int price;
  final int? originalPrice;
  final int? discountPercent;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.displayName,
    required this.months,
    required this.price,
    this.originalPrice,
    this.discountPercent,
  });

  bool get hasDiscount => discountPercent != null && discountPercent! > 0;

  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: '3month',
      name: '3 Months',
      displayName: '۳ ماهه',
      months: 3,
      price: 290000,
    ),
    SubscriptionPlan(
      id: '6month',
      name: '6 Months',
      displayName: '۶ ماهه',
      months: 6,
      price: 390000,
    ),
    SubscriptionPlan(
      id: '12month',
      name: '12 Months',
      displayName: '۱۲ ماهه',
      months: 12,
      price: 490000,
    ),
  ];
}
