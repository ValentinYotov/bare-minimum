import '../models/crop_model.dart';

class CropRepository {
  static const List<CropModel> crops = [
    CropModel(
      name: 'Tomatoes',
      imageUrl:
          'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=1200&q=80',
      description:
          'Perfect NPK balance for tomato cultivation. High potassium levels promote fruit development.',
      waterNeeds: 'Medium (25-30mm/week)',
      growthTime: '60-85 days',
      expectedYield: '8-15 kg/plant',
      idealNitrogen: 70,
      idealPhosphorus: 50,
      idealPotassium: 80,
      idealPhMin: 6.0,
      idealPhMax: 6.8,
      suitableSoil: 'Loamy',
      details:
          'Tomatoes grow best in fertile, well-drained loamy soil with balanced nutrients. Potassium is especially important for flowering and fruiting. Consistent watering and good sun exposure improve yield and fruit quality.',
    ),
    CropModel(
      name: 'Potatoes',
      imageUrl:
          'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=1200&q=80',
      description:
          'Potatoes perform well in slightly acidic soil with moderate nitrogen and high potassium support.',
      waterNeeds: 'Medium (20-25mm/week)',
      growthTime: '80-110 days',
      expectedYield: '2-4 kg/plant',
      idealNitrogen: 60,
      idealPhosphorus: 45,
      idealPotassium: 75,
      idealPhMin: 5.2,
      idealPhMax: 6.4,
      suitableSoil: 'Sandy Loam',
      details:
          'Potatoes prefer loose, well-aerated soil that allows tubers to expand easily. Excess nitrogen can cause too much leaf growth and reduce tuber formation, so balanced feeding is important.',
    ),
    CropModel(
      name: 'Lettuce',
      imageUrl:
          'https://images.unsplash.com/photo-1622206151246-1c66d9c17208?auto=format&fit=crop&w=1200&q=80',
      description:
          'Lettuce thrives in mild nutrient conditions and slightly moist soil with good nitrogen availability.',
      waterNeeds: 'High (30-35mm/week)',
      growthTime: '30-45 days',
      expectedYield: '0.3-0.7 kg/plant',
      idealNitrogen: 65,
      idealPhosphorus: 40,
      idealPotassium: 50,
      idealPhMin: 6.0,
      idealPhMax: 7.0,
      suitableSoil: 'Loamy',
      details:
          'Lettuce grows quickly and prefers consistently moist soil. It responds well to nitrogen-rich soil, which supports rapid leaf production. Heat and drought can reduce quality.',
    ),
    CropModel(
      name: 'Peppers',
      imageUrl:
          'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?auto=format&fit=crop&w=1200&q=80',
      description:
          'Peppers benefit from warm conditions, balanced phosphorus, and increased potassium for healthy fruiting.',
      waterNeeds: 'Medium (25-30mm/week)',
      growthTime: '70-95 days',
      expectedYield: '6-10 kg/plant',
      idealNitrogen: 55,
      idealPhosphorus: 50,
      idealPotassium: 78,
      idealPhMin: 6.0,
      idealPhMax: 6.8,
      suitableSoil: 'Loamy',
      details:
          'Peppers prefer warm, fertile soils with consistent moisture. Potassium supports fruit size, firmness, and overall plant strength. They do best when nutrient levels stay stable.',
    ),
    CropModel(
      name: 'Cucumbers',
      imageUrl:
          'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?auto=format&fit=crop&w=1200&q=80',
      description:
          'Cucumbers prefer fertile soil, moderate nitrogen, and steady moisture for rapid vine growth.',
      waterNeeds: 'High (35-40mm/week)',
      growthTime: '50-70 days',
      expectedYield: '10-20 fruits/plant',
      idealNitrogen: 60,
      idealPhosphorus: 45,
      idealPotassium: 70,
      idealPhMin: 5.8,
      idealPhMax: 6.8,
      suitableSoil: 'Loamy',
      details:
          'Cucumbers need moist, nutrient-rich soil and regular watering. They grow fast and benefit from soils with enough organic matter and balanced mineral content.',
    ),
    CropModel(
      name: 'Spinach',
      imageUrl:
          'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=1200&q=80',
      description:
          'Spinach grows quickly in cool weather with steady moisture and moderate potassium support.',
      waterNeeds: 'High (30-35mm/week)',
      growthTime: '35-50 days',
      expectedYield: '1-2 kg/m²',
      idealNitrogen: 70,
      idealPhosphorus: 35,
      idealPotassium: 55,
      idealPhMin: 6.2,
      idealPhMax: 7.0,
      suitableSoil: 'Loamy',
      details:
          'Spinach prefers fertile, moisture-retentive soil with good drainage. Consistent nitrogen helps leaf growth, while cool temperatures preserve flavor and texture.',
    ),
    CropModel(
      name: 'Carrots',
      imageUrl:
          'https://images.unsplash.com/photo-1447175008436-170170753d52?auto=format&fit=crop&w=1200&q=80',
      description:
          'Carrots develop best in loose soil with balanced phosphorus and potassium for strong root formation.',
      waterNeeds: 'Medium (20-25mm/week)',
      growthTime: '70-90 days',
      expectedYield: '3-6 kg/m²',
      idealNitrogen: 50,
      idealPhosphorus: 45,
      idealPotassium: 60,
      idealPhMin: 6.0,
      idealPhMax: 6.8,
      suitableSoil: 'Sandy Loam',
      details:
          'Carrots need stone-free, well-aerated soil so roots can grow straight. Excess nitrogen can cause leafy tops with smaller roots, so balanced nutrition is important.',
    ),
    CropModel(
      name: 'Onions',
      imageUrl:
          'https://images.unsplash.com/photo-1508747703725-719777637510?auto=format&fit=crop&w=1200&q=80',
      description:
          'Onions favor moderate nitrogen and sufficient potassium to improve bulb size and storage quality.',
      waterNeeds: 'Medium (20-25mm/week)',
      growthTime: '100-130 days',
      expectedYield: '2-4 kg/m²',
      idealNitrogen: 55,
      idealPhosphorus: 40,
      idealPotassium: 65,
      idealPhMin: 6.0,
      idealPhMax: 7.0,
      suitableSoil: 'Silty Loam',
      details:
          'Onions thrive in fertile, well-drained soil with steady moisture during bulb development. Proper potassium levels help improve bulb firmness and post-harvest shelf life.',
    ),
    CropModel(
      name: 'Cabbage',
      imageUrl:
          'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&w=1200&q=80',
      description:
          'Cabbage is a heavy feeder that needs strong nitrogen support and regular moisture for dense heads.',
      waterNeeds: 'High (30-35mm/week)',
      growthTime: '75-110 days',
      expectedYield: '3-6 kg/plant',
      idealNitrogen: 75,
      idealPhosphorus: 45,
      idealPotassium: 70,
      idealPhMin: 6.0,
      idealPhMax: 7.2,
      suitableSoil: 'Loamy',
      details:
          'Cabbage grows best in nutrient-rich loam with consistent irrigation. Uneven watering can split heads, while balanced nutrients improve size and texture.',
    ),
    CropModel(
      name: 'Eggplant',
      imageUrl:
          'https://images.unsplash.com/photo-1601493700631-2b16ec4b4716?auto=format&fit=crop&w=1200&q=80',
      description:
          'Eggplant needs warm soil, moderate nitrogen, and high potassium for flowering and fruit set.',
      waterNeeds: 'Medium (25-30mm/week)',
      growthTime: '80-120 days',
      expectedYield: '4-8 kg/plant',
      idealNitrogen: 60,
      idealPhosphorus: 50,
      idealPotassium: 75,
      idealPhMin: 5.8,
      idealPhMax: 6.8,
      suitableSoil: 'Loamy',
      details:
          'Eggplant performs well in warm climates with fertile soil and consistent watering. Potassium supports fruit quality, while stable phosphorus helps strong root and flower development.',
    ),
    CropModel(
      name: 'Maize',
      imageUrl:
          'https://images.unsplash.com/photo-1551754655-cd27e38d2076?auto=format&fit=crop&w=1200&q=80',
      description:
          'Maize requires higher nitrogen and steady nutrient availability during rapid vegetative growth.',
      waterNeeds: 'Medium (25-30mm/week)',
      growthTime: '90-120 days',
      expectedYield: '6-10 tons/hectare',
      idealNitrogen: 85,
      idealPhosphorus: 50,
      idealPotassium: 70,
      idealPhMin: 5.8,
      idealPhMax: 7.0,
      suitableSoil: 'Sandy Loam',
      details:
          'Maize benefits from well-drained soils with good organic matter. Nitrogen demand is highest before tasseling, and timely irrigation helps maintain grain fill.',
    ),
    CropModel(
      name: 'Rice',
      imageUrl:
          'https://images.unsplash.com/photo-1536304993881-ff6e9eefa2a6?auto=format&fit=crop&w=1200&q=80',
      description:
          'Rice thrives in water-retentive soils with strong nitrogen support and moderate potassium.',
      waterNeeds: 'High (40-50mm/week)',
      growthTime: '100-150 days',
      expectedYield: '4-8 tons/hectare',
      idealNitrogen: 80,
      idealPhosphorus: 45,
      idealPotassium: 60,
      idealPhMin: 5.5,
      idealPhMax: 6.5,
      suitableSoil: 'Clay Loam',
      details:
          'Rice production relies on dependable water supply and nutrient timing. Nitrogen boosts tillering, while balanced phosphorus and potassium improve root strength and grain quality.',
    ),
    CropModel(
      name: 'Wheat',
      imageUrl:
          'https://images.unsplash.com/photo-1471193945509-9ad0617afabf?auto=format&fit=crop&w=1200&q=80',
      description:
          'Wheat grows well with moderate nitrogen and phosphorus in cool-season, well-structured soils.',
      waterNeeds: 'Medium (20-25mm/week)',
      growthTime: '110-140 days',
      expectedYield: '3-7 tons/hectare',
      idealNitrogen: 70,
      idealPhosphorus: 50,
      idealPotassium: 60,
      idealPhMin: 6.0,
      idealPhMax: 7.0,
      suitableSoil: 'Loam',
      details:
          'Wheat prefers fertile soil with good drainage and moderate moisture. Splitting nitrogen applications improves tiller development and final grain protein.',
    ),
    CropModel(
      name: 'Soybeans',
      imageUrl:
          'https://images.unsplash.com/photo-1603048719539-9ecb4f439f5c?auto=format&fit=crop&w=1200&q=80',
      description:
          'Soybeans fix nitrogen but still need phosphorus and potassium for pod development and seed quality.',
      waterNeeds: 'Medium (25-30mm/week)',
      growthTime: '90-130 days',
      expectedYield: '2-4 tons/hectare',
      idealNitrogen: 40,
      idealPhosphorus: 50,
      idealPotassium: 70,
      idealPhMin: 6.0,
      idealPhMax: 6.8,
      suitableSoil: 'Silty Loam',
      details:
          'Soybeans perform best in warm, well-drained soils with proper inoculation and balanced P-K nutrition. Good moisture at flowering improves pod set.',
    ),
    CropModel(
      name: 'Green Beans',
      imageUrl:
          'https://images.unsplash.com/photo-1464226184884-fa280b87c399?auto=format&fit=crop&w=1200&q=80',
      description:
          'Green beans prefer mild fertility and consistent moisture for healthy pods and continuous harvest.',
      waterNeeds: 'Medium (20-25mm/week)',
      growthTime: '50-65 days',
      expectedYield: '0.6-1.2 kg/plant',
      idealNitrogen: 45,
      idealPhosphorus: 45,
      idealPotassium: 60,
      idealPhMin: 6.0,
      idealPhMax: 7.0,
      suitableSoil: 'Loamy',
      details:
          'Beans are sensitive to water stress during flowering and pod fill. Over-fertilizing with nitrogen can reduce pod production, so balanced feeding is key.',
    ),
    CropModel(
      name: 'Peas',
      imageUrl:
          'https://images.unsplash.com/photo-1587735243615-c03f25aaff15?auto=format&fit=crop&w=1200&q=80',
      description:
          'Peas grow best in cool weather with moderate phosphorus and potassium for pod formation.',
      waterNeeds: 'Medium (20-25mm/week)',
      growthTime: '55-75 days',
      expectedYield: '0.5-1.0 kg/plant',
      idealNitrogen: 35,
      idealPhosphorus: 45,
      idealPotassium: 55,
      idealPhMin: 6.0,
      idealPhMax: 7.5,
      suitableSoil: 'Loamy',
      details:
          'Peas prefer cool temperatures and well-drained soil. They do not need heavy nitrogen inputs, but phosphorus supports root vigor and early flowering.',
    ),
    CropModel(
      name: 'Strawberries',
      imageUrl:
          'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?auto=format&fit=crop&w=1200&q=80',
      description:
          'Strawberries require regular moisture and higher potassium to improve fruit sweetness and firmness.',
      waterNeeds: 'High (30-35mm/week)',
      growthTime: '90-120 days',
      expectedYield: '0.5-1.5 kg/plant',
      idealNitrogen: 60,
      idealPhosphorus: 50,
      idealPotassium: 80,
      idealPhMin: 5.5,
      idealPhMax: 6.5,
      suitableSoil: 'Sandy Loam',
      details:
          'Strawberries thrive in slightly acidic, organic-rich soil with drip irrigation. Potassium contributes to fruit quality, color, and improved shelf life.',
    ),
    CropModel(
      name: 'Watermelon',
      imageUrl:
          'https://images.unsplash.com/photo-1563114773-84221bd62daa?auto=format&fit=crop&w=1200&q=80',
      description:
          'Watermelon needs warm temperatures, steady moisture, and strong potassium for fruit expansion.',
      waterNeeds: 'High (35-40mm/week)',
      growthTime: '80-100 days',
      expectedYield: '20-35 tons/hectare',
      idealNitrogen: 65,
      idealPhosphorus: 45,
      idealPotassium: 85,
      idealPhMin: 6.0,
      idealPhMax: 6.8,
      suitableSoil: 'Sandy Loam',
      details:
          'Watermelon vines grow rapidly in warm, sunny fields with well-drained soil. Reducing excess nitrogen near fruiting helps focus energy on fruit size and sweetness.',
    ),
    CropModel(
      name: 'Pumpkin',
      imageUrl:
          'https://images.unsplash.com/photo-1502741126161-b048400d85a6?auto=format&fit=crop&w=1200&q=80',
      description:
          'Pumpkin responds well to balanced fertility and increased potassium during fruit development.',
      waterNeeds: 'Medium-High (30-35mm/week)',
      growthTime: '90-120 days',
      expectedYield: '15-25 tons/hectare',
      idealNitrogen: 60,
      idealPhosphorus: 50,
      idealPotassium: 80,
      idealPhMin: 6.0,
      idealPhMax: 7.5,
      suitableSoil: 'Loam',
      details:
          'Pumpkin plants need open sunlight, well-drained fertile soil, and regular watering. Potassium is especially important for fruit shape, color, and storage performance.',
    ),
    CropModel(
      name: 'Sunflower',
      imageUrl:
          'https://images.unsplash.com/photo-1470509037663-253afd7f0f51?auto=format&fit=crop&w=1200&q=80',
      description:
          'Sunflower performs best with moderate nitrogen and high potassium for strong stalks and seed filling.',
      waterNeeds: 'Low-Medium (15-25mm/week)',
      growthTime: '80-110 days',
      expectedYield: '1.5-3 tons/hectare',
      idealNitrogen: 70,
      idealPhosphorus: 50,
      idealPotassium: 90,
      idealPhMin: 6.0,
      idealPhMax: 7.5,
      suitableSoil: 'Sandy Loam',
      details:
          'Sunflower tolerates drier periods better than many crops, but performs best with moisture at flowering. Balanced nutrition reduces lodging and improves oil content.',
    ),
    CropModel(
      name: 'Cotton',
      imageUrl:
          'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=1200&q=80',
      description:
          'Cotton requires sustained nutrients across a long season, with good potassium for boll quality.',
      waterNeeds: 'Medium (25-30mm/week)',
      growthTime: '150-180 days',
      expectedYield: '1.5-3.5 tons/hectare',
      idealNitrogen: 75,
      idealPhosphorus: 50,
      idealPotassium: 85,
      idealPhMin: 5.8,
      idealPhMax: 7.0,
      suitableSoil: 'Clay Loam',
      details:
          'Cotton grows best in deep, well-drained soils with warm temperatures. Potassium is critical for fiber strength and boll retention, especially late in the season.',
    ),
    CropModel(
      name: 'Sugarcane',
      imageUrl:
          'https://images.unsplash.com/photo-1578797777363-4f3d6b5dd2f2?auto=format&fit=crop&w=1200&q=80',
      description:
          'Sugarcane is nutrient-demanding and benefits from high nitrogen and potassium over a long cycle.',
      waterNeeds: 'High (35-45mm/week)',
      growthTime: '300-365 days',
      expectedYield: '60-100 tons/hectare',
      idealNitrogen: 90,
      idealPhosphorus: 45,
      idealPotassium: 100,
      idealPhMin: 6.0,
      idealPhMax: 7.5,
      suitableSoil: 'Loam',
      details:
          'Sugarcane requires deep fertile soil, warm weather, and consistent irrigation. Potassium supports cane weight and sugar accumulation, while split nitrogen improves efficiency.',
    ),
    CropModel(
      name: 'Barley',
      imageUrl:
          'https://images.unsplash.com/photo-1464226184884-fa280b87c300?auto=format&fit=crop&w=1200&q=80',
      description:
          'Barley grows in cooler seasons with moderate fertility and lower water demand than many cereals.',
      waterNeeds: 'Low-Medium (15-20mm/week)',
      growthTime: '90-120 days',
      expectedYield: '2-6 tons/hectare',
      idealNitrogen: 60,
      idealPhosphorus: 45,
      idealPotassium: 55,
      idealPhMin: 6.0,
      idealPhMax: 7.5,
      suitableSoil: 'Loam',
      details:
          'Barley adapts well to different environments but prefers well-drained soil. Excess nitrogen can increase lodging risk, so rates should match expected yield targets.',
    ),
    CropModel(
      name: 'Groundnuts',
      imageUrl:
          'https://images.unsplash.com/photo-1622396483646-91b6f95f47e6?auto=format&fit=crop&w=1200&q=80',
      description:
          'Groundnuts prefer sandy soils with moderate phosphorus and calcium support for pod filling.',
      waterNeeds: 'Medium (20-25mm/week)',
      growthTime: '110-140 days',
      expectedYield: '2-4 tons/hectare',
      idealNitrogen: 35,
      idealPhosphorus: 45,
      idealPotassium: 60,
      idealPhMin: 5.8,
      idealPhMax: 6.5,
      suitableSoil: 'Sandy Loam',
      details:
          'Groundnuts develop best in loose soils that allow pegging and pod expansion. Balanced moisture and phosphorus help increase pod number and kernel development.',
    ),
    CropModel(
      name: 'Okra',
      imageUrl:
          'https://images.unsplash.com/photo-1592921870789-04563d55041c?auto=format&fit=crop&w=1200&q=80',
      description:
          'Okra is heat-tolerant and benefits from moderate nitrogen and potassium for continuous pod harvest.',
      waterNeeds: 'Medium (20-30mm/week)',
      growthTime: '50-70 days',
      expectedYield: '4-8 tons/hectare',
      idealNitrogen: 55,
      idealPhosphorus: 40,
      idealPotassium: 65,
      idealPhMin: 6.0,
      idealPhMax: 7.0,
      suitableSoil: 'Loamy',
      details:
          'Okra performs well in warm climates with full sun and regular picking. Consistent irrigation and balanced nutrients improve pod tenderness and plant productivity.',
    ),
  ];
}
