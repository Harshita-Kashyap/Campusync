import 'package:flutter/widgets.dart';
import '../data/seed_data.dart';
import '../models/models.dart';

/// ONE data-access pattern for all modules: shared in-memory ChangeNotifier.
/// Use `RepositoryScope.of(context)`. Every mutation notifies listeners.
/// Method names mirror INTEGRATION_CONTRACT.md. Do not change signatures without Person 1.
class AppRepository extends ChangeNotifier {
  static const energyStatuses = {'active', 'resolved', 'dismissed'};
  static const waterStatuses = {'open', 'in_progress', 'resolved', 'dismissed'};

  final List<EnergyAlert> _energy;
  final List<WaterIncident> _water;
  final List<DigitalSubmission> _subs;
  final List<SustainabilityRecommendation> _recs = [];
  final List<ActivityEntry> _log = [];

  AppRepository({List<EnergyAlert>? energy, List<WaterIncident>? water, List<DigitalSubmission>? submissions})
      : _energy = [...?energy],
        _water = [...?water],
        _subs = [...?submissions];

  factory AppRepository.seeded() =>
      AppRepository(energy: SeedData.energy(), water: SeedData.water(), submissions: SeedData.submissions());

  void _record(String msg) => _log.add(ActivityEntry(DateTime.now(), msg));

  // ---- Energy ----
  List<EnergyAlert> getAlerts() => List.unmodifiable(_energy);
  Future<void> addAlert(EnergyAlert a) async {
    _energy.add(a);
    _record('Energy alert added: ${a.roomName}');
    notifyListeners();
  }

  /// Throws ArgumentError on unknown id/status (never silently accepted).
  Future<void> updateAlertStatus(String id, String status) async {
    if (!energyStatuses.contains(status)) throw ArgumentError('Invalid energy status: $status');
    final i = _energy.indexWhere((e) => e.id == id);
    if (i < 0) throw ArgumentError('Unknown alert id: $id');
    _energy[i] = _energy[i].copyWith(status: status);
    _record('${_energy[i].roomName} energy alert → $status');
    notifyListeners();
  }

  // ---- Water ----
  List<WaterIncident> getIncidents() => List.unmodifiable(_water);
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
