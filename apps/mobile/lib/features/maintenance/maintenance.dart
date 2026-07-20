enum MaintenanceStatus {
  unknown,
  current,
  soon,
  overdue,
  completed,
  notApplicable,
  unrecognized,
}

enum MaintenanceImportance {
  info,
  recommended,
  required,
  criticalAttention,
  unrecognized,
}

enum MaintenanceSourceKind {
  editorialBaseline,
  officialOem,
  regulatory,
  unrecognized,
}

enum ConsumableKind { intervalBased, conditionBased, unrecognized }

enum InspectionState { completed, unknown, checkRequired, unrecognized }

enum MaintenanceCriticality { low, medium, high, safetyCritical, unrecognized }

enum MaintenanceUrgency { none, low, medium, high, immediate, unrecognized }

enum ConditionObservationSource { self, workshop, unrecognized }

enum TimelineActionLevel {
  info,
  recommendation,
  attention,
  required,
  critical,
  unrecognized,
}

enum PresentationBasis { confirmed, forecast, missingData, unrecognized }

enum HistoryAnswerValue {
  doneKnown,
  doneUnknown,
  notDone,
  unknown,
  notApplicable,
  unrecognized,
}

extension HistoryAnswerValueWire on HistoryAnswerValue {
  String get wireValue => switch (this) {
    HistoryAnswerValue.doneKnown => 'done_known',
    HistoryAnswerValue.doneUnknown => 'done_unknown',
    HistoryAnswerValue.notDone => 'not_done',
    HistoryAnswerValue.unknown => 'unknown',
    HistoryAnswerValue.notApplicable => 'not_applicable',
    HistoryAnswerValue.unrecognized => 'unknown',
  };
}

T _enum<T>(String? value, Map<String, T> values, T fallback) =>
    values[value] ?? fallback;

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<dynamic> _list(Object? value) => value is List ? value : const [];

class MaintenanceSource {
  const MaintenanceSource({
    required this.title,
    required this.publisher,
    required this.kind,
    required this.methodologyNote,
    required this.officialOem,
  });

  final String title;
  final String publisher;
  final MaintenanceSourceKind kind;
  final String methodologyNote;
  final bool officialOem;

  factory MaintenanceSource.fromJson(Object? value) {
    final json = _map(value);
    return MaintenanceSource(
      title: json['title'] is String ? json['title'] as String : '',
      publisher: json['publisher'] is String ? json['publisher'] as String : '',
      kind: _enum(json['source_kind'] as String?, const {
        'editorial_baseline': MaintenanceSourceKind.editorialBaseline,
        'official_oem': MaintenanceSourceKind.officialOem,
        'regulatory': MaintenanceSourceKind.regulatory,
      }, MaintenanceSourceKind.unrecognized),
      methodologyNote: json['methodology_note'] is String
          ? json['methodology_note'] as String
          : '',
      officialOem: json['official_oem'] == true,
    );
  }
}

class MaintenanceDue {
  const MaintenanceDue({this.mileage, this.unit, this.date});

  final int? mileage;
  final String? unit;
  final DateTime? date;

  factory MaintenanceDue.fromJson(Object? value) {
    final json = _map(value);
    final mileage = _map(json['mileage']);
    return MaintenanceDue(
      mileage: (mileage['value'] as num?)?.toInt(),
      unit: mileage['unit'] is String ? mileage['unit'] as String : null,
      date: json['date'] is String
          ? DateTime.tryParse(json['date'] as String)
          : null,
    );
  }
}

class MaintenanceInterval {
  const MaintenanceInterval({this.mileageKm, this.days});

  final int? mileageKm;
  final int? days;

  factory MaintenanceInterval.fromJson(Object? value) {
    final json = _map(value);
    return MaintenanceInterval(
      mileageKm: (json['mileage_km'] as num?)?.toInt(),
      days: (json['days'] as num?)?.toInt(),
    );
  }
}

class HistoryState {
  const HistoryState({
    this.answer,
    this.performedDate,
    this.performedMileageKm,
  });

  final HistoryAnswerValue? answer;
  final DateTime? performedDate;
  final int? performedMileageKm;

  factory HistoryState.fromJson(Object? value) {
    final json = _map(value);
    final rawAnswer = json['answer'];
    return HistoryState(
      answer: rawAnswer is String
          ? _enum(rawAnswer, const {
              'done_known': HistoryAnswerValue.doneKnown,
              'done_unknown': HistoryAnswerValue.doneUnknown,
              'not_done': HistoryAnswerValue.notDone,
              'unknown': HistoryAnswerValue.unknown,
              'not_applicable': HistoryAnswerValue.notApplicable,
            }, HistoryAnswerValue.unrecognized)
          : null,
      performedDate: json['performed_date'] is String
          ? DateTime.tryParse(json['performed_date'] as String)
          : null,
      performedMileageKm: (json['performed_mileage_km'] as num?)?.toInt(),
    );
  }
}

class HistoryAnswerWrite {
  const HistoryAnswerWrite({
    required this.workCode,
    required this.answer,
    this.performedDate,
    this.performedMileageKm,
  });

  final String workCode;
  final HistoryAnswerValue answer;
  final DateTime? performedDate;
  final int? performedMileageKm;

  Map<String, Object?> toJson() => {
    'work_code': workCode,
    'answer': answer.wireValue,
    if (answer == HistoryAnswerValue.doneKnown && performedDate != null)
      'performed_date':
          '${performedDate!.year.toString().padLeft(4, '0')}-'
          '${performedDate!.month.toString().padLeft(2, '0')}-'
          '${performedDate!.day.toString().padLeft(2, '0')}',
    if (answer == HistoryAnswerValue.doneKnown && performedMileageKm != null)
      'performed_mileage_km': performedMileageKm,
  };
}

class MaintenanceItem {
  const MaintenanceItem({
    required this.id,
    required this.workCode,
    required this.title,
    required this.status,
    required this.importance,
    required this.basis,
    required this.source,
    required this.due,
    required this.interval,
    this.historyImpact = '',
    this.ruleType = '',
    this.ruleLevel = '',
    this.requiresCheckNow = false,
    this.historyState = const HistoryState(),
    this.criticality = MaintenanceCriticality.unrecognized,
    this.urgency = MaintenanceUrgency.unrecognized,
  });

  final String id;
  final String workCode;
  final String title;
  final MaintenanceStatus status;
  final MaintenanceImportance importance;
  final String basis;
  final String historyImpact;
  final String ruleType;
  final String ruleLevel;
  final bool requiresCheckNow;
  final HistoryState historyState;
  final MaintenanceSource source;
  final MaintenanceDue due;
  final MaintenanceInterval interval;
  final MaintenanceCriticality criticality;
  final MaintenanceUrgency urgency;

  factory MaintenanceItem.fromJson(Object? value) {
    final json = _map(value);
    return MaintenanceItem(
      id: json['id'] is String ? json['id'] as String : '',
      workCode: json['work_code'] is String
          ? json['work_code'] as String
          : 'unknown',
      title: json['title'] is String ? json['title'] as String : '',
      status: _enum(json['status'] as String?, const {
        'unknown': MaintenanceStatus.unknown,
        'current': MaintenanceStatus.current,
        'soon': MaintenanceStatus.soon,
        'overdue': MaintenanceStatus.overdue,
        'completed': MaintenanceStatus.completed,
        'not_applicable': MaintenanceStatus.notApplicable,
      }, MaintenanceStatus.unrecognized),
      importance: _enum(
        (json['presentation_importance'] ?? json['future_importance'])
            as String?,
        const {
          'info': MaintenanceImportance.info,
          'recommended': MaintenanceImportance.recommended,
          'required': MaintenanceImportance.required,
          'critical_attention': MaintenanceImportance.criticalAttention,
        },
        MaintenanceImportance.unrecognized,
      ),
      basis: json['basis'] is String ? json['basis'] as String : '',
      historyImpact: json['history_impact'] is String
          ? json['history_impact'] as String
          : '',
      ruleType: json['rule_type'] is String ? json['rule_type'] as String : '',
      ruleLevel: json['rule_level'] is String
          ? json['rule_level'] as String
          : '',
      requiresCheckNow: json['requires_check_now'] == true,
      historyState: HistoryState.fromJson(json['history_state']),
      source: MaintenanceSource.fromJson(json['source']),
      due: MaintenanceDue.fromJson(json['due']),
      interval: MaintenanceInterval.fromJson(json['interval']),
      criticality: _enum(json['criticality'] as String?, const {
        'low': MaintenanceCriticality.low,
        'medium': MaintenanceCriticality.medium,
        'high': MaintenanceCriticality.high,
        'safety_critical': MaintenanceCriticality.safetyCritical,
      }, MaintenanceCriticality.unrecognized),
      urgency: _enum(json['urgency'] as String?, const {
        'none': MaintenanceUrgency.none,
        'low': MaintenanceUrgency.low,
        'medium': MaintenanceUrgency.medium,
        'high': MaintenanceUrgency.high,
        'immediate': MaintenanceUrgency.immediate,
      }, MaintenanceUrgency.unrecognized),
    );
  }
}

class MaintenancePlan {
  const MaintenancePlan({
    required this.id,
    required this.vehicleId,
    required this.rulesetVersion,
    required this.items,
    required this.warnings,
    this.algorithmVersion = '',
    this.configVersion = '',
  });

  final String id;
  final String vehicleId;
  final String rulesetVersion;
  final List<MaintenanceItem> items;
  final List<String> warnings;
  final String algorithmVersion;
  final String configVersion;

  MaintenanceSource? get primarySource =>
      items.isEmpty ? null : items.first.source;

  factory MaintenancePlan.fromJson(Map<String, dynamic> json) =>
      MaintenancePlan(
        id: json['id'] is String ? json['id'] as String : '',
        vehicleId: json['vehicle_id'] is String
            ? json['vehicle_id'] as String
            : '',
        rulesetVersion: json['ruleset_version'] is String
            ? json['ruleset_version'] as String
            : '',
        algorithmVersion: json['algorithm_version'] is String
            ? json['algorithm_version'] as String
            : '',
        configVersion: json['config_version'] is String
            ? json['config_version'] as String
            : '',
        items: _list(
          json['items'],
        ).map(MaintenanceItem.fromJson).toList(growable: false),
        warnings: _list(
          json['warnings'],
        ).whereType<String>().toList(growable: false),
      );
}

class TimelineItem {
  const TimelineItem({
    required this.item,
    required this.primaryCategory,
    required this.status,
    required this.importance,
    this.actionLevel = TimelineActionLevel.info,
    this.basis = PresentationBasis.confirmed,
  });

  final MaintenanceItem item;
  final String primaryCategory;
  final MaintenanceStatus status;
  final MaintenanceImportance importance;
  final TimelineActionLevel actionLevel;
  final PresentationBasis basis;

  factory TimelineItem.fromJson(Object? value) {
    final json = _map(value);
    final presentation = _map(json['presentation']);
    final item = MaintenanceItem.fromJson(json['plan_item']);
    final status = _enum(presentation['status'] as String?, const {
      'unknown': MaintenanceStatus.unknown,
      'current': MaintenanceStatus.current,
      'soon': MaintenanceStatus.soon,
      'overdue': MaintenanceStatus.overdue,
      'completed': MaintenanceStatus.completed,
      'not_applicable': MaintenanceStatus.notApplicable,
    }, item.status);
    final importance = _enum(presentation['importance'] as String?, const {
      'info': MaintenanceImportance.info,
      'recommended': MaintenanceImportance.recommended,
      'required': MaintenanceImportance.required,
      'critical_attention': MaintenanceImportance.criticalAttention,
    }, item.importance);
    return TimelineItem(
      item: item,
      primaryCategory: presentation['primary_category'] is String
          ? presentation['primary_category'] as String
          : 'unknown',
      status: status,
      importance: importance,
      actionLevel: presentation.containsKey('action_level')
          ? _enum(
              presentation['action_level'] as String?,
              const {
                'info': TimelineActionLevel.info,
                'recommendation': TimelineActionLevel.recommendation,
                'attention': TimelineActionLevel.attention,
                'required': TimelineActionLevel.required,
                'critical': TimelineActionLevel.critical,
              },
              TimelineActionLevel.unrecognized,
            )
          : deriveTimelineActionLevel(
              urgency: item.urgency,
              status: status,
              importance: importance,
              requiresCheckNow: item.requiresCheckNow,
            ),
      basis: presentation.containsKey('basis')
          ? _enum(presentation['basis'] as String?, const {
              'confirmed': PresentationBasis.confirmed,
              'forecast': PresentationBasis.forecast,
              'missing_data': PresentationBasis.missingData,
            }, PresentationBasis.unrecognized)
          : derivePresentationBasis(
              status: status,
              historyAnswer: item.historyState.answer,
              requiresCheckNow: item.requiresCheckNow,
              hasLatestObservation:
                  presentation['latest_observation'] != null ||
                  _map(json['plan_item'])['latest_observation'] != null,
            ),
    );
  }
}

TimelineActionLevel deriveTimelineActionLevel({
  required MaintenanceUrgency urgency,
  required MaintenanceStatus status,
  required MaintenanceImportance importance,
  required bool requiresCheckNow,
}) {
  if (urgency == MaintenanceUrgency.immediate ||
      importance == MaintenanceImportance.criticalAttention) {
    return TimelineActionLevel.critical;
  }
  if (urgency == MaintenanceUrgency.high ||
      status == MaintenanceStatus.overdue ||
      requiresCheckNow) {
    return TimelineActionLevel.required;
  }
  if (urgency == MaintenanceUrgency.medium ||
      status == MaintenanceStatus.soon) {
    return TimelineActionLevel.attention;
  }
  if (importance == MaintenanceImportance.recommended) {
    return TimelineActionLevel.recommendation;
  }
  return TimelineActionLevel.info;
}

PresentationBasis derivePresentationBasis({
  required MaintenanceStatus status,
  required HistoryAnswerValue? historyAnswer,
  required bool requiresCheckNow,
  required bool hasLatestObservation,
}) {
  if (hasLatestObservation || historyAnswer == HistoryAnswerValue.doneKnown) {
    return PresentationBasis.confirmed;
  }
  if (requiresCheckNow ||
      status == MaintenanceStatus.unknown ||
      historyAnswer == HistoryAnswerValue.unknown ||
      historyAnswer == HistoryAnswerValue.unrecognized) {
    return PresentationBasis.missingData;
  }
  return PresentationBasis.confirmed;
}

class ServiceWork {
  const ServiceWork({required this.workCode, required this.title});

  final String workCode;
  final String title;

  factory ServiceWork.fromJson(Object? value) {
    final json = _map(value);
    return ServiceWork(
      workCode: json['work_code'] is String ? json['work_code'] as String : '',
      title: json['title'] is String ? json['title'] as String : '',
    );
  }
}

class ServiceRecord {
  const ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.serviceDate,
    required this.items,
    this.mileage,
    this.mileageUnit,
    this.note,
    this.title,
  });

  final String id;
  final String vehicleId;
  final DateTime serviceDate;
  final int? mileage;
  final String? mileageUnit;
  final String? note;
  final String? title;
  final List<ServiceWork> items;

  factory ServiceRecord.fromJson(Object? value, {String? title}) {
    final json = _map(value);
    final mileage = _map(json['mileage']);
    final serviceDate = DateTime.tryParse(
      json['service_date'] as String? ?? '',
    );
    if (serviceDate == null) throw const FormatException();
    return ServiceRecord(
      id: json['id'] is String ? json['id'] as String : '',
      vehicleId: json['vehicle_id'] is String
          ? json['vehicle_id'] as String
          : '',
      serviceDate: serviceDate,
      mileage: (mileage['value'] as num?)?.toInt(),
      mileageUnit: mileage['unit'] is String ? mileage['unit'] as String : null,
      note: json['note'] is String ? json['note'] as String : null,
      title: title,
      items: _list(
        json['items'],
      ).map(ServiceWork.fromJson).toList(growable: false),
    );
  }
}

class ServiceRecordWrite {
  const ServiceRecordWrite({
    required this.serviceDate,
    required this.workCode,
    this.mileage,
    this.mileageUnit = 'km',
    this.note,
  });

  final DateTime serviceDate;
  final String workCode;
  final int? mileage;
  final String mileageUnit;
  final String? note;

  Map<String, Object?> toJson() => {
    'service_date':
        '${serviceDate.year.toString().padLeft(4, '0')}-'
        '${serviceDate.month.toString().padLeft(2, '0')}-'
        '${serviceDate.day.toString().padLeft(2, '0')}',
    'work_codes': [workCode],
    if (mileage != null) 'mileage': {'value': mileage, 'unit': mileageUnit},
    'evidence_source': 'self',
    if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
  };

  Map<String, Object?> toUpdateJson() => {
    'service_date':
        '${serviceDate.year.toString().padLeft(4, '0')}-'
        '${serviceDate.month.toString().padLeft(2, '0')}-'
        '${serviceDate.day.toString().padLeft(2, '0')}',
    if (mileage != null) 'mileage': {'value': mileage, 'unit': mileageUnit},
    'note': note?.trim().isNotEmpty == true ? note!.trim() : null,
  };
}

class ServiceRecordList {
  const ServiceRecordList({required this.items});

  final List<ServiceRecord> items;

  factory ServiceRecordList.fromJson(Map<String, dynamic> json) =>
      ServiceRecordList(
        items: _list(
          json['items'],
        ).map(ServiceRecord.fromJson).toList(growable: false),
      );
}

class VehicleTimeline {
  const VehicleTimeline({
    required this.vehicleId,
    required this.items,
    this.serviceRecords = const [],
    this.currentMileage,
    this.currentMileageUnit,
  });

  final String vehicleId;
  final int? currentMileage;
  final String? currentMileageUnit;
  final List<TimelineItem> items;
  final List<ServiceRecord> serviceRecords;

  factory VehicleTimeline.fromJson(Map<String, dynamic> json) {
    final observation = _map(json['last_confirmed_observation']);
    final mileage = _map(observation['mileage']);
    return VehicleTimeline(
      vehicleId: json['vehicle_id'] is String
          ? json['vehicle_id'] as String
          : '',
      currentMileage: (mileage['value'] as num?)?.toInt(),
      currentMileageUnit: mileage['unit'] is String
          ? mileage['unit'] as String
          : null,
      items: _list(json['items'])
          .where((item) => _map(item)['type'] == 'plan_item')
          .map(TimelineItem.fromJson)
          .toList(growable: false),
      serviceRecords: _list(json['items'])
          .where((item) => _map(item)['type'] == 'service_record')
          .map((item) {
            final wrapper = _map(item);
            final presentation = _map(wrapper['presentation']);
            return ServiceRecord.fromJson(
              wrapper['service_record'],
              title: presentation['title'] is String
                  ? presentation['title'] as String
                  : null,
            );
          })
          .toList(growable: false),
    );
  }
}

class Consumable {
  const Consumable({
    required this.id,
    required this.title,
    required this.kind,
    required this.status,
    required this.importance,
    required this.basis,
    required this.source,
    required this.due,
    required this.inspectionState,
    this.usedFraction,
    this.effectiveTrigger = '',
    this.timeFraction,
    this.mileageFraction,
    this.timeDue,
    this.mileageDue,
    this.inspectedAt,
    this.nextInspection,
    this.requiresCheckNow = false,
    this.historyState = const HistoryState(),
    this.workCode = '',
    this.latestObservation,
  });

  final String id;
  final String title;
  final ConsumableKind kind;
  final MaintenanceStatus status;
  final MaintenanceImportance importance;
  final String basis;
  final MaintenanceSource source;
  final MaintenanceDue due;
  final InspectionState inspectionState;
  final double? usedFraction;
  final String effectiveTrigger;
  final double? timeFraction;
  final double? mileageFraction;
  final MaintenanceDue? timeDue;
  final MaintenanceDue? mileageDue;
  final DateTime? inspectedAt;
  final MaintenanceDue? nextInspection;
  final bool requiresCheckNow;
  final HistoryState historyState;
  final String workCode;
  final ConditionObservation? latestObservation;

  factory Consumable.fromJson(Object? value) {
    final json = _map(value);
    final presentation = _map(json['presentation']);
    final time = _map(presentation['time']);
    final mileage = _map(presentation['mileage']);
    return Consumable(
      id: json['id'] is String ? json['id'] as String : '',
      title: json['title'] is String ? json['title'] as String : '',
      kind: _enum(json['kind'] as String?, const {
        'interval_based': ConsumableKind.intervalBased,
        'condition_based': ConsumableKind.conditionBased,
      }, ConsumableKind.unrecognized),
      status: MaintenanceItem.fromJson(json).status,
      importance: MaintenanceItem.fromJson(json).importance,
      basis: json['basis'] is String ? json['basis'] as String : '',
      source: MaintenanceSource.fromJson(json['source']),
      due: MaintenanceDue.fromJson(json['due']),
      inspectionState:
          _enum(presentation['inspection_state'] as String?, const {
            'completed': InspectionState.completed,
            'unknown': InspectionState.unknown,
            'check_required': InspectionState.checkRequired,
          }, InspectionState.unrecognized),
      usedFraction: (presentation['effective_used_fraction'] as num?)
          ?.toDouble(),
      effectiveTrigger: presentation['effective_trigger'] is String
          ? presentation['effective_trigger'] as String
          : '',
      timeFraction: (time['used_fraction'] as num?)?.toDouble(),
      mileageFraction: (mileage['used_fraction'] as num?)?.toDouble(),
      timeDue: time['due'] == null
          ? null
          : MaintenanceDue.fromJson(time['due']),
      mileageDue: mileage['due'] == null
          ? null
          : MaintenanceDue.fromJson(mileage['due']),
      inspectedAt: presentation['inspected_at'] is String
          ? DateTime.tryParse(presentation['inspected_at'] as String)
          : null,
      nextInspection: presentation['next_inspection'] == null
          ? null
          : MaintenanceDue.fromJson(presentation['next_inspection']),
      requiresCheckNow: json['requires_check_now'] == true,
      historyState: HistoryState.fromJson(json['history_state']),
      workCode: json['work_code'] is String ? json['work_code'] as String : '',
      latestObservation: presentation['latest_observation'] == null
          ? null
          : ConditionObservation.fromJson(presentation['latest_observation']),
    );
  }
}

class ConsumableList {
  const ConsumableList({required this.items, required this.warnings});

  final List<Consumable> items;
  final List<String> warnings;

  factory ConsumableList.fromJson(Map<String, dynamic> json) => ConsumableList(
    items: _list(
      json['items'],
    ).map(Consumable.fromJson).toList(growable: false),
    warnings: _list(
      json['warnings'],
    ).whereType<String>().toList(growable: false),
  );
}

class MileageForecastWindow {
  const MileageForecastWindow({
    required this.planItemId,
    required this.title,
    this.from,
    this.to,
    this.dueMileage,
    this.dueMileageUnit,
  });

  final String planItemId;
  final String title;
  final DateTime? from;
  final DateTime? to;
  final int? dueMileage;
  final String? dueMileageUnit;

  factory MileageForecastWindow.fromJson(Object? value) {
    final json = _map(value);
    final mileage = _map(json['due_mileage']);
    return MileageForecastWindow(
      planItemId: json['plan_item_id'] is String
          ? json['plan_item_id'] as String
          : '',
      title: json['title'] is String ? json['title'] as String : '',
      from: json['from'] is String
          ? DateTime.tryParse(json['from'] as String)
          : null,
      to: json['to'] is String ? DateTime.tryParse(json['to'] as String) : null,
      dueMileage: (mileage['value'] as num?)?.toInt(),
      dueMileageUnit: mileage['unit'] is String
          ? mileage['unit'] as String
          : null,
    );
  }
}

class MileageForecast {
  const MileageForecast({
    required this.vehicleId,
    required this.annualDistance,
    required this.annualDistanceUnit,
    required this.method,
    required this.confidence,
    required this.observationCount,
    required this.estimateLabel,
    this.nextWorkWindow,
  });

  final String vehicleId;
  final int annualDistance;
  final String annualDistanceUnit;
  final String method;
  final String confidence;
  final int observationCount;
  final String estimateLabel;
  final MileageForecastWindow? nextWorkWindow;

  bool get isDefaultAssumption => method == 'default_assumption';

  factory MileageForecast.fromJson(Map<String, dynamic> json) {
    final annual = _map(json['annual_distance']);
    return MileageForecast(
      vehicleId: json['vehicle_id'] is String
          ? json['vehicle_id'] as String
          : '',
      annualDistance: (annual['value'] as num?)?.toInt() ?? 10000,
      annualDistanceUnit: annual['unit'] is String
          ? annual['unit'] as String
          : 'km',
      method: json['method'] is String ? json['method'] as String : '',
      confidence: json['confidence'] is String
          ? json['confidence'] as String
          : '',
      observationCount: (json['observation_count'] as num?)?.toInt() ?? 0,
      estimateLabel: json['estimate_label'] is String
          ? json['estimate_label'] as String
          : '',
      nextWorkWindow: json['next_work_window'] == null
          ? null
          : MileageForecastWindow.fromJson(json['next_work_window']),
    );
  }
}

class ConditionObservation {
  const ConditionObservation({
    required this.id,
    required this.vehicleId,
    required this.workCode,
    required this.wearPercent,
    required this.remainingPercent,
    required this.observedAt,
    required this.source,
    this.mileage,
    this.mileageUnit,
    this.note,
  });

  final String id;
  final String vehicleId;
  final String workCode;
  final int wearPercent;
  final int remainingPercent;
  final DateTime observedAt;
  final int? mileage;
  final String? mileageUnit;
  final ConditionObservationSource source;
  final String? note;

  factory ConditionObservation.fromJson(Object? value) {
    final json = _map(value);
    final mileage = _map(json['mileage']);
    final observedAt = DateTime.tryParse(json['observed_at'] as String? ?? '');
    if (observedAt == null) throw const FormatException();
    final wear = (json['wear_percent'] as num?)?.toInt();
    final remaining = (json['remaining_percent'] as num?)?.toInt();
    if (wear == null || wear < 0 || wear > 100) {
      throw const FormatException();
    }
    return ConditionObservation(
      id: json['id'] is String ? json['id'] as String : '',
      vehicleId: json['vehicle_id'] is String
          ? json['vehicle_id'] as String
          : '',
      workCode: json['work_code'] is String ? json['work_code'] as String : '',
      wearPercent: wear,
      remainingPercent: remaining?.clamp(0, 100) ?? 100 - wear,
      observedAt: observedAt,
      mileage: (mileage['value'] as num?)?.toInt(),
      mileageUnit: mileage['unit'] is String ? mileage['unit'] as String : null,
      source: _enum(json['source'] as String?, const {
        'self': ConditionObservationSource.self,
        'workshop': ConditionObservationSource.workshop,
      }, ConditionObservationSource.unrecognized),
      note: json['note'] is String ? json['note'] as String : null,
    );
  }
}

class ConditionObservationWrite {
  const ConditionObservationWrite({
    required this.workCode,
    required this.wearPercent,
    required this.observedAt,
    required this.source,
    this.mileage,
    this.mileageUnit = 'km',
    this.note,
  });

  final String workCode;
  final int wearPercent;
  final DateTime observedAt;
  final int? mileage;
  final String mileageUnit;
  final ConditionObservationSource source;
  final String? note;

  Map<String, Object?> toJson() => {
    'work_code': workCode,
    'wear_percent': wearPercent,
    'observed_at':
        '${observedAt.year.toString().padLeft(4, '0')}-'
        '${observedAt.month.toString().padLeft(2, '0')}-'
        '${observedAt.day.toString().padLeft(2, '0')}',
    if (mileage != null) 'mileage': {'value': mileage, 'unit': mileageUnit},
    'source': source == ConditionObservationSource.workshop
        ? 'workshop'
        : 'self',
    if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
  };

  Map<String, Object?> toUpdateJson() => {
    'wear_percent': wearPercent,
    'observed_at':
        '${observedAt.year.toString().padLeft(4, '0')}-'
        '${observedAt.month.toString().padLeft(2, '0')}-'
        '${observedAt.day.toString().padLeft(2, '0')}',
    if (mileage != null) 'mileage': {'value': mileage, 'unit': mileageUnit},
    'source': source == ConditionObservationSource.workshop
        ? 'workshop'
        : 'self',
    'note': note?.trim().isNotEmpty == true ? note!.trim() : null,
  };
}

class ConditionObservationList {
  const ConditionObservationList({required this.items});
  final List<ConditionObservation> items;

  factory ConditionObservationList.fromJson(Map<String, dynamic> json) =>
      ConditionObservationList(
        items: _list(
          json['items'],
        ).map(ConditionObservation.fromJson).toList(growable: false),
      );

  ConditionObservation? latestFor(String workCode) =>
      items.where((item) => item.workCode == workCode).firstOrNull;
}

double? effectiveLifecycleFraction(Consumable item) {
  final value = item.usedFraction ?? item.timeFraction;
  return value?.clamp(0.0, 1.0);
}

bool supportsWearMeasurement(String workCode) => const {
  'brake_pads',
  'brake_discs',
  'tire_condition_inspection',
}.contains(workCode);

bool isHistoryAnswerResolved(HistoryAnswerValue? answer) =>
    answer != null &&
    answer != HistoryAnswerValue.unknown &&
    answer != HistoryAnswerValue.unrecognized;

int historyCompletenessPercent(Iterable<MaintenanceItem> items) {
  final applicable = items
      .where((item) => item.status != MaintenanceStatus.notApplicable)
      .toList(growable: false);
  if (applicable.isEmpty) return 100;
  final resolved = applicable
      .where((item) => isHistoryAnswerResolved(item.historyState.answer))
      .length;
  return ((resolved / applicable.length) * 100).round().clamp(0, 100);
}

bool hasHonestDue(MaintenanceItem item) {
  final hasDue = item.due.date != null || item.due.mileage != null;
  final intervalKnown =
      item.interval.mileageKm != null || item.interval.days != null;
  final doneKnown = item.historyState.answer == HistoryAnswerValue.doneKnown;
  if (doneKnown && hasDue) return true;
  if (intervalKnown && hasDue) return true;
  if (intervalKnown && doneKnown) return true;
  return false;
}

bool isShowableFuturePlanItem(TimelineItem item) {
  if (item.status == MaintenanceStatus.notApplicable ||
      item.status == MaintenanceStatus.completed) {
    return false;
  }
  if (item.item.requiresCheckNow) return false;
  if (item.basis == PresentationBasis.missingData) return false;
  return hasHonestDue(item.item);
}

List<TimelineItem> showableFuturePlanItems(Iterable<TimelineItem> items) =>
    sortPlanV3Items(items.where(isShowableFuturePlanItem));

List<Consumable> sortStateTiles(Iterable<Consumable> items) {
  final result = items
      .where((item) => item.status != MaintenanceStatus.notApplicable)
      .toList();
  int rank(MaintenanceStatus status) => switch (status) {
    MaintenanceStatus.overdue => 0,
    MaintenanceStatus.soon => 1,
    MaintenanceStatus.current => 2,
    MaintenanceStatus.unknown => 3,
    MaintenanceStatus.completed => 4,
    MaintenanceStatus.notApplicable => 5,
    MaintenanceStatus.unrecognized => 6,
  };
  result.sort((a, b) {
    final requiredA =
        a.requiresCheckNow ||
        a.importance == MaintenanceImportance.required ||
        a.importance == MaintenanceImportance.criticalAttention;
    final requiredB =
        b.requiresCheckNow ||
        b.importance == MaintenanceImportance.required ||
        b.importance == MaintenanceImportance.criticalAttention;
    if (requiredA != requiredB) return requiredA ? -1 : 1;
    final status = rank(a.status).compareTo(rank(b.status));
    if (status != 0) return status;
    return a.title.compareTo(b.title);
  });
  return result;
}

List<TimelineItem> sortPlanV3Items(Iterable<TimelineItem> items) {
  final result = items.toList();
  int rank<T>(T value, List<T> values) {
    final index = values.indexOf(value);
    return index < 0 ? values.length : index;
  }

  result.sort((a, b) {
    final ah = a.item.requiresCheckNow ? 0 : 1;
    final bh = b.item.requiresCheckNow ? 0 : 1;
    if (ah != bh) return ah.compareTo(bh);
    final criticality =
        rank(a.item.criticality, const [
          MaintenanceCriticality.safetyCritical,
          MaintenanceCriticality.high,
          MaintenanceCriticality.medium,
          MaintenanceCriticality.low,
          MaintenanceCriticality.unrecognized,
        ]).compareTo(
          rank(b.item.criticality, const [
            MaintenanceCriticality.safetyCritical,
            MaintenanceCriticality.high,
            MaintenanceCriticality.medium,
            MaintenanceCriticality.low,
            MaintenanceCriticality.unrecognized,
          ]),
        );
    if (criticality != 0) return criticality;
    final status =
        rank(a.status, const [
          MaintenanceStatus.overdue,
          MaintenanceStatus.soon,
          MaintenanceStatus.current,
          MaintenanceStatus.unknown,
          MaintenanceStatus.completed,
          MaintenanceStatus.notApplicable,
          MaintenanceStatus.unrecognized,
        ]).compareTo(
          rank(b.status, const [
            MaintenanceStatus.overdue,
            MaintenanceStatus.soon,
            MaintenanceStatus.current,
            MaintenanceStatus.unknown,
            MaintenanceStatus.completed,
            MaintenanceStatus.notApplicable,
            MaintenanceStatus.unrecognized,
          ]),
        );
    if (status != 0) return status;
    final urgency =
        rank(a.item.urgency, const [
          MaintenanceUrgency.immediate,
          MaintenanceUrgency.high,
          MaintenanceUrgency.medium,
          MaintenanceUrgency.low,
          MaintenanceUrgency.none,
          MaintenanceUrgency.unrecognized,
        ]).compareTo(
          rank(b.item.urgency, const [
            MaintenanceUrgency.immediate,
            MaintenanceUrgency.high,
            MaintenanceUrgency.medium,
            MaintenanceUrgency.low,
            MaintenanceUrgency.none,
            MaintenanceUrgency.unrecognized,
          ]),
        );
    if (urgency != 0) return urgency;
    final importance =
        rank(a.importance, const [
          MaintenanceImportance.criticalAttention,
          MaintenanceImportance.required,
          MaintenanceImportance.recommended,
          MaintenanceImportance.info,
          MaintenanceImportance.unrecognized,
        ]).compareTo(
          rank(b.importance, const [
            MaintenanceImportance.criticalAttention,
            MaintenanceImportance.required,
            MaintenanceImportance.recommended,
            MaintenanceImportance.info,
            MaintenanceImportance.unrecognized,
          ]),
        );
    if (importance != 0) return importance;
    final ad = a.item.due.date;
    final bd = b.item.due.date;
    if (ad != null || bd != null) {
      if (ad == null) return 1;
      if (bd == null) return -1;
      final date = ad.compareTo(bd);
      if (date != 0) return date;
    }
    final work = a.item.workCode.compareTo(b.item.workCode);
    return work != 0 ? work : a.item.id.compareTo(b.item.id);
  });
  return result;
}

abstract interface class MaintenanceRepository {
  Future<MaintenancePlan> getPlan(String vehicleId, {required String locale});
  Future<VehicleTimeline> getTimeline(
    String vehicleId, {
    required String locale,
  });
  Future<ConsumableList> getConsumables(
    String vehicleId, {
    required String locale,
  });
  Future<ServiceRecordList> getServiceRecords(
    String vehicleId, {
    required String locale,
  });
  Future<ServiceRecord> createServiceRecord(
    String vehicleId, {
    required String locale,
    required ServiceRecordWrite record,
  });
  Future<ServiceRecord> updateServiceRecord(
    String vehicleId,
    String recordId, {
    required String locale,
    required ServiceRecordWrite record,
  });
  Future<void> deleteServiceRecord(
    String vehicleId,
    String recordId, {
    required String locale,
  });
  Future<void> submitHistoryAnswers(
    String vehicleId, {
    required String locale,
    required List<HistoryAnswerWrite> answers,
  });
  Future<MileageForecast> getMileageForecast(
    String vehicleId, {
    required String locale,
  });
  Future<ConditionObservationList> getConditionObservations(
    String vehicleId, {
    required String locale,
  });
  Future<ConditionObservation> createConditionObservation(
    String vehicleId, {
    required String locale,
    required ConditionObservationWrite observation,
  });
  Future<ConditionObservation> updateConditionObservation(
    String vehicleId,
    String observationId, {
    required String locale,
    required ConditionObservationWrite observation,
  });
  Future<void> deleteConditionObservation(
    String vehicleId,
    String observationId, {
    required String locale,
  });
}

class MaintenanceFailure implements Exception {
  const MaintenanceFailure({
    this.code,
    this.requestId,
    this.statusCode,
    this.safeMessage = '',
  });

  final String? code;
  final String? requestId;
  final int? statusCode;
  final String safeMessage;

  bool get isPlanPreparing => statusCode == 409 && code == 'PLAN_PREPARING';
}
