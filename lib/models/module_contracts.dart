import 'digital_submission.dart';
import 'energy_alert.dart';
import 'sustainability_recommendation.dart';
import 'water_incident.dart';

abstract class EnergyModuleContract {
  List<EnergyAlert> getAlerts();
  double getEstimatedExcessKwh();
  double getEstimatedCost();
  double getEstimatedCo2Kg();
  Future<void> updateAlertStatus(String id, String status);
}

abstract class WaterModuleContract {
  List<WaterIncident> getIncidents();
  Future<void> addIncident(WaterIncident incident);
  Future<void> updateIncidentStatus(String id, String status);
  double getEstimatedWaterLossLitres();
}

abstract class SubmissionModuleContract {
  List<DigitalSubmission> getSubmissions();
  Future<void> addSubmission(DigitalSubmission s); // Person 4 builds processSubmission on top
  int getEstimatedPagesAvoided();
}

abstract class AgentContract {
  Future<List<SustainabilityRecommendation>> generateRecommendations({
    required List<EnergyAlert> energyAlerts,
    required List<WaterIncident> waterIncidents,
    required List<DigitalSubmission> submissions,
  });
}
