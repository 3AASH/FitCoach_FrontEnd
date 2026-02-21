import '../../models/subscription_plan.dart';
import '../demo_data.dart';

class DemoSubscriptionPlanRepository {
  Future<List<SubscriptionPlan>> getPlans() async {
    return DemoData.subscriptionPlans();
  }

  Future<SubscriptionPlan> createPlan(SubscriptionPlan plan) async {
    return plan;
  }

  Future<SubscriptionPlan> updatePlan(SubscriptionPlan plan) async {
    return plan;
  }

  Future<void> deletePlan(String id) async {
    return;
  }
}
