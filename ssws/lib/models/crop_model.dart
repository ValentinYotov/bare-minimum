class CropModel {
  final String name;
  final String description;
  final String waterNeeds;
  final String growthTime;
  final String expectedYield;
  final int idealNitrogen;
  final int idealPhosphorus;
  final int idealPotassium;
  final double idealPhMin;
  final double idealPhMax;
  final String suitableSoil;
  final String imageUrl;
  final String details;
  final int score;

  const CropModel({
    required this.name,
    required this.description,
    required this.waterNeeds,
    required this.growthTime,
    required this.expectedYield,
    required this.idealNitrogen,
    required this.idealPhosphorus,
    required this.idealPotassium,
    required this.idealPhMin,
    required this.idealPhMax,
    required this.suitableSoil,
    required this.imageUrl,
    required this.details,
    this.score = 0,
  });

  CropModel copyWith({
    String? name,
    String? description,
    String? waterNeeds,
    String? growthTime,
    String? expectedYield,
    int? idealNitrogen,
    int? idealPhosphorus,
    int? idealPotassium,
    double? idealPhMin,
    double? idealPhMax,
    String? suitableSoil,
    String? imageUrl,
    String? details,
    int? score,
  }) {
    return CropModel(
      name: name ?? this.name,
      description: description ?? this.description,
      waterNeeds: waterNeeds ?? this.waterNeeds,
      growthTime: growthTime ?? this.growthTime,
      expectedYield: expectedYield ?? this.expectedYield,
      idealNitrogen: idealNitrogen ?? this.idealNitrogen,
      idealPhosphorus: idealPhosphorus ?? this.idealPhosphorus,
      idealPotassium: idealPotassium ?? this.idealPotassium,
      idealPhMin: idealPhMin ?? this.idealPhMin,
      idealPhMax: idealPhMax ?? this.idealPhMax,
      suitableSoil: suitableSoil ?? this.suitableSoil,
      imageUrl: imageUrl ?? this.imageUrl,
      details: details ?? this.details,
      score: score ?? this.score,
    );
  }
}