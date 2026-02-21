import '../../models/inbody_model.dart';

class DemoMetricsRepository {
  List<InBodyScan> _buildScans(String userId) {
    final now = DateTime.now();
    return [
      _buildScan(userId, now.subtract(const Duration(days: 14)), 75.2, 22.8),
      _buildScan(userId, now.subtract(const Duration(days: 7)), 74.4, 22.1),
      _buildScan(userId, now, 73.8, 21.5),
    ];
  }

  InBodyScan _buildScan(
    String userId,
    DateTime date,
    double weight,
    double percentBodyFat,
  ) {
    return InBodyScan(
      userId: userId,
      totalBodyWater: 34.2,
      intracellularWater: 21.4,
      extracellularWater: 12.8,
      dryLeanMass: 27.3,
      bodyFatMass: weight * (percentBodyFat / 100),
      weight: weight,
      skeletalMuscleMass: 30.4,
      bodyShape: InBodyScan.calculateBodyShape(weight, 30.4, weight * (percentBodyFat / 100)),
      bmi: 24.2,
      percentBodyFat: percentBodyFat,
      segmentalLean: SegmentalLean(
        leftArm: 102,
        rightArm: 101,
        trunk: 100,
        leftLeg: 98,
        rightLeg: 99,
      ),
      basalMetabolicRate: 1530,
      visceralFatLevel: 9,
      ecwTbwRatio: 0.39,
      inBodyScore: 82,
      scanDate: date,
      scanLocation: 'Demo Lab',
      notes: 'Demo scan',
      extractedViaAi: false,
      createdAt: date,
      updatedAt: date,
    );
  }

  Future<List<InBodyScan>> getAllInBodyScans({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    final scans = _buildScans(userId);
    if (offset >= scans.length) {
      return [];
    }
    return scans.skip(offset).take(limit).toList();
  }

  Future<InBodyScan?> getLatestInBodyScan({required String userId}) async {
    final scans = _buildScans(userId);
    if (scans.isEmpty) return null;
    return scans.last;
  }

  Future<Map<String, dynamic>> getInBodyStatistics({required String userId}) async {
    final latest = await getLatestInBodyScan(userId: userId);
    if (latest == null) {
      return {};
    }
    return {
      'weight': latest.weight,
      'bmi': latest.bmi,
      'percentBodyFat': latest.percentBodyFat,
      'skeletalMuscleMass': latest.skeletalMuscleMass,
      'visceralFatLevel': latest.visceralFatLevel,
    };
  }

  Future<List<Map<String, dynamic>>> getInBodyTrends({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final scans = _buildScans(userId).where((scan) {
      if (startDate != null && scan.scanDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && scan.scanDate.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();

    return scans
        .map((scan) => {
              'date': scan.scanDate.toIso8601String(),
              'weight': scan.weight,
              'percentBodyFat': scan.percentBodyFat,
            })
        .toList();
  }

  Future<InBodyProgress?> getInBodyProgress({required String userId}) async {
    final scans = _buildScans(userId);
    if (scans.length < 2) return null;
    final first = scans.first;
    final last = scans.last;
    return InBodyProgress(
      daysElapsed: last.scanDate.difference(first.scanDate).inDays,
      weightLost: first.weight - last.weight,
      bodyFatReduced: first.percentBodyFat - last.percentBodyFat,
      muscleGained: 0.4,
      progressPercentage: 0.52,
    );
  }
}
