import 'package:flutter/widgets.dart';
import '../data/seed_data.dart';
import '../models/models.dart';
import 'energy_service.dart';
import 'water_api_client.dart';

/// ONE data-access pattern for all modules: shared in-memory ChangeNotifier.
/// Use `RepositoryScope.of(context)`. Every mutation notifies listeners.
/// Method names mirror INTEGRATION_CONTRACT.md. Do not change signatures without Person 1.
class AppRepository extends ChangeNotifier {
  static const energyStatuses = {'active', 'resolved', 'dismissed'};
  static const waterStatuses = {'open', 'in_progress', 'resolved', 'dismissed'};

  /// Energy data is owned by Person 2's EnergyService (singleton). The repository
  /// exposes it through the shared interface and re-notifies when it changes.
  final EnergyService _energySvc = EnergyService();
  Map<String, String> _energySnapshot = {};

  final List<WaterIncident> _water;
  final List<DigitalSubmission> _subs;
  final List<SustainabilityRecommendation> _recs = [];
  final List<ActivityEntry> _log = [];
  String _waterApiBaseUrl = WaterApiClient.defaultBaseUrl;

  String get waterApiBaseUrl => _waterApiBaseUrl;

  /// Share the server address across the student report and admin workflows.
  void setWaterApiBaseUrl(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == _waterApiBaseUrl) return;
    _waterApiBaseUrl = normalized;
    notifyListeners();
  }

  /// [emptyEnergy] clears the energy service (empty-state demo/tests).
  AppRepository({List<WaterIncident>? water, List<DigitalSubmission>? submissions, bool emptyEnergy = false, bool resetEnergy = false})
      : _water = [...?water],
        _subs = [...?submissions] {
    if (emptyEnergy) {
      _energySvc.clearAll();
    } else if (resetEnergy) {
      _energySvc.resetToDefaults();
    }
    _energySnapshot = {for (final a in _energySvc.getAlerts()) a.id: a.status};
    _energySvc.addListener(_onEnergyChanged);
  }

  factory AppRepository.seeded() =>
      AppRepository(water: SeedData.water(), submissions: SeedData.submissions(), resetEnergy: true);

  @override
  void dispose() {
    _energySvc.removeListener(_onEnergyChanged);
    super.dispose();
  }

  void _record(String msg) => _log.add(ActivityEntry(DateTime.now(), msg));

  /// Logs energy changes (including those made directly inside EnergyScreen), then notifies.
  void _onEnergyChanged() {
    for (final a in _energySvc.getAlerts()) {
      final prev = _energySnapshot[a.id];
      if (prev == null) {
        _record('Energy alert added: ${a.roomName}');
      } else if (prev != a.status) {
        _record('${a.roomName} energy alert → ${a.status}');
      }
    }
    _energySnapshot = {for (final a in _energySvc.getAlerts()) a.id: a.status};
    notifyListeners();
  }

  // ---- Energy (delegates to EnergyService) ----
  List<EnergyAlert> getAlerts() => _energySvc.getAlerts();
  Future<void> addAlert(EnergyAlert a) async => _energySvc.addAlert(a);

  /// Throws ArgumentError on invalid status.
  Future<void> updateAlertStatus(String id, String status) => _energySvc.updateAlertStatus(id, status);

  // ---- Water ----
  List<WaterIncident> getIncidents() => List.unmodifiable(_water);

  /// Replace the local/demo water snapshot with the records returned by Flask.
  /// A successful empty response is meaningful: it clears the seeded demo list.
  void replaceWaterIncidents(List<WaterIncident> incidents) {
    _water
      ..clear()
      ..addAll(incidents);
    notifyListeners();
  }

  /// Insert/update a server-created incident in the shared app state.
  Future<void> upsertWaterIncident(WaterIncident incident) async {
    final index = _water.indexWhere((item) => item.id == incident.id);
    if (index == -1) {
      _water.add(incident);
      _record('Water incident reported: ${incident.locationName}');
    } else {
      _water[index] = incident;
      _record('${incident.locationName} water incident refreshed');
    }
    notifyListeners();
  }

  Future<void> addIncident(WaterIncident i) async {
    _water.add(i);
    _record('Water incident reported: ${i.locationName}');
    notifyListeners();
  }

  Future<void> updateIncidentStatus(String id, String status) async {
    if (!waterStatuses.contains(status)) throw ArgumentError('Invalid water status: $status');
    final i = _water.indexWhere((e) => e.id == id);
    if (i < 0) throw ArgumentError('Unknown incident id: $id');
    _water[i] = _water[i].copyWith(status: status);
    _record('${_water[i].locationName} water incident → $status');
    notifyListeners();
  }

  // ---- Submissions ----
  List<DigitalSubmission> getSubmissions() => List.unmodifiable(_subs);
  Future<void> addSubmission(DigitalSubmission s) async {
    _subs.add(s);
    _record('Digital submission ${s.id}${s.duplicateDetected ? ' (duplicate flagged)' : ''}');
    notifyListeners();
  }

  // ---- Recommendations (agent writes; dashboard falls back to rules) ----
  List<SustainabilityRecommendation> getRecommendations() => List.unmodifiable(_recs);
  void setRecommendations(List<SustainabilityRecommendation> r) {
    _recs..clear()..addAll(r);
    notifyListeners();
  }

  // ---- Activity log ----
  List<ActivityEntry> getActivityLog() => List.unmodifiable(_log.reversed);
}

class RepositoryScope extends InheritedNotifier<AppRepository> {
  const RepositoryScope({super.key, required AppRepository repository, required super.child})
      : super(notifier: repository);

  static AppRepository of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RepositoryScope>()!.notifier!;
}
