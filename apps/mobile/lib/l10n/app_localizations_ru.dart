// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'АвтоДоктор';

  @override
  String get language => 'Язык';

  @override
  String get system => 'Системный';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'Английский';

  @override
  String get navPlan => 'План';

  @override
  String get maintenancePlanTitle => 'План обслуживания';

  @override
  String get navJournal => 'Журнал';

  @override
  String get navAssistant => 'AI';

  @override
  String get navState => 'Состояние';

  @override
  String get navAnalytics => 'Аналитика';

  @override
  String get navMore => 'Ещё';

  @override
  String historyCompletenessBanner(int percent) {
    return 'Данные об обслуживании заполнены на $percent%. Уточнить — ~3 мин';
  }

  @override
  String historyCompletenessBannerShort(int percent) {
    return 'Заполнено $percent%';
  }

  @override
  String get historyCompletenessCta => 'Уточнить историю';

  @override
  String get historyCompletenessCtaShort => 'Уточнить';

  @override
  String get historyCompletenessFill => 'Заполнить';

  @override
  String get historyCompletenessCollapse => 'Свернуть';

  @override
  String get historyCompletenessAlarmTitle =>
      'Можно уточнить историю обслуживания';

  @override
  String get garageAddBlocked => 'Добавление авто недоступно';

  @override
  String get profileStatsTitle => 'Ваша активность';

  @override
  String get profileStatsVehicles => 'Авто';

  @override
  String get profileStatsActions => 'Записи';

  @override
  String get profileStatsChats => 'Чаты';

  @override
  String get journalColDate => 'Дата';

  @override
  String get journalColEvent => 'Событие';

  @override
  String get journalColType => 'Тип';

  @override
  String get journalEditTitle => 'Запись журнала';

  @override
  String get journalIconsLegendTitle => 'Иконки типов работ';

  @override
  String get journalIconsLegendBody =>
      'У каждой записи — иконка узла обслуживания (масло, фильтры, тормоза, осмотр и т.д.). Нажмите запись, чтобы открыть карточку этого узла.';

  @override
  String get journalOpenNodeMissing =>
      'Для этой записи узел состояния пока не найден';

  @override
  String get journalLegendOil => 'Масло / фильтры';

  @override
  String get journalLegendBrakes => 'Тормоза';

  @override
  String get journalLegendInspect => 'Осмотр';

  @override
  String get journalLegendOther => 'Прочие работы';

  @override
  String get openState => 'Открыть Состояние';

  @override
  String get openAnalytics => 'Перейти в аналитику';

  @override
  String get stateTitle => 'Состояние';

  @override
  String get stateSubtitle =>
      'Шкала ресурса и износа. Откройте карточку, чтобы обновить.';

  @override
  String get stateNeedsData => 'Нужны данные';

  @override
  String get stateNeedsDataUrgent => 'Обязательно заполнить';

  @override
  String get stateNeedsDataBadge => 'нет данных';

  @override
  String stateUsedPercent(int percent) {
    return 'Использовано $percent%';
  }

  @override
  String stateUsedPercentShort(int percent) {
    return '$percent%';
  }

  @override
  String stateWearRemaining(int wear, int remaining) {
    return 'Износ $wear% · остаток $remaining%';
  }

  @override
  String get stateWearCaption => 'износ';

  @override
  String get stateTriggerTime => 'По времени';

  @override
  String get stateTriggerMileage => 'По пробегу';

  @override
  String get stateTriggerTimeHint =>
      'Сейчас интервал упирается в календарь: срок по дате наступит раньше, чем по пробегу.';

  @override
  String get stateTriggerMileageHint =>
      'Сейчас интервал упирается в пробег: лимит километров будет раньше календарной даты.';

  @override
  String get stateWearCaptionHint =>
      'Показан износ по последней оценке. 0% — как новый, 100% — нужна замена.';

  @override
  String get stateCurrentFactsInfo =>
      'Сводка по узлу: сколько ресурса уже использовано и что сейчас ограничивает срок (время или пробег).';

  @override
  String get stateUpdateSectionInfo =>
      'Здесь вы фиксируете обслуживание или проверку: дату, пробег, износ и стоимость. Данные остаются в вашем автомобиле.';

  @override
  String get stateServiceHistoryInfo =>
      'Последние записи по этому узлу. Можно открыть для правки или удаления.';

  @override
  String get mileageTimelineInconsistentLater =>
      'Проверьте данные: есть более поздняя запись с меньшим пробегом. Дата и пробег должны расти согласованно.';

  @override
  String get mileageTimelineInconsistentEarlier =>
      'Проверьте данные: есть более ранняя запись с большим пробегом. Дата и пробег должны расти согласованно.';

  @override
  String get stateScaleCaption => 'ресурс';

  @override
  String stateLastServiceShort(String date) {
    return 'обслуж. $date';
  }

  @override
  String get stateLastServiceUnknownShort => 'обслуж. неизвестно';

  @override
  String stateNextDueShort(String label) {
    return 'далее $label';
  }

  @override
  String get stateNextDueUnknown => 'срок не определён';

  @override
  String intervalEveryKm(int value) {
    return 'раз в $value км';
  }

  @override
  String intervalEveryDays(int value) {
    return 'раз в $value дн.';
  }

  @override
  String get intervalEveryYear => 'раз в год';

  @override
  String get planPastLabel => 'Уже было';

  @override
  String get planFutureLabel => 'Предстоит';

  @override
  String get stateUpdateSection => 'Обновить данные';

  @override
  String get stateNoteField => 'Примечание';

  @override
  String get stateNoteHint => 'Замена, долив, комментарий…';

  @override
  String get stateWearField => 'Износ, %';

  @override
  String get stateWearHint => '0 — новые или без износа';

  @override
  String get stateLaborCost => 'Работы';

  @override
  String get statePartsCost => 'Запчасти';

  @override
  String get stateCostSection => 'Стоимость';

  @override
  String get stateUpdateDate => 'Дата';

  @override
  String get stateUpdateMileage => 'Пробег';

  @override
  String get stateUpdateSave => 'Сохранить';

  @override
  String get stateUpdateSaveEdit => 'Сохранить изменения';

  @override
  String get stateCancelEdit => 'Отменить правку';

  @override
  String get stateEditRecord => 'Изменить запись';

  @override
  String get stateDeleteRecord => 'Удалить запись';

  @override
  String get stateDeleteConfirm => 'Удалить эту запись обслуживания?';

  @override
  String get stateServiceHistory => 'Даты обслуживания';

  @override
  String get stateServiceHistoryEmpty => 'Записей пока нет';

  @override
  String get stateUpdateError =>
      'Не удалось сохранить. Проверьте поля и попробуйте снова.';

  @override
  String stateEditingBanner(String date) {
    return 'Редактирование записи от $date';
  }

  @override
  String get stateCurrentFacts => 'Текущие данные';

  @override
  String get stateInspectionStatus => 'Состояние проверки';

  @override
  String get stateEmpty => 'Пока нет пунктов состояния для этого автомобиля.';

  @override
  String get stateGate =>
      'Плитки состояния появятся после добавления автомобиля.';

  @override
  String get planNearestWork => 'Ближайшая работа';

  @override
  String get planRoadLabel => 'Дорога обслуживания';

  @override
  String get planTimelineLabel => 'Таймлайн';

  @override
  String get planRemainingList => 'Позже';

  @override
  String get planAnalyticsStrip => 'Кратко';

  @override
  String planNearestCount(int count) {
    return 'Ближайших: $count';
  }

  @override
  String get historySaveAndNext => 'Сохранить и далее';

  @override
  String get historyFinishLater => 'Завершить позже';

  @override
  String get historySkipQuestion => 'Пропустить';

  @override
  String get historyAnswerLater => 'Отвечу позже';

  @override
  String get historyIntroGotIt => 'Понятно';

  @override
  String get historyWizardFriendlyHint =>
      'Ответьте, как помните. Если не уверены — выберите «Не знаю» или «Отвечу позже».';

  @override
  String get historyWizardIntroDetail =>
      'Эти данные нужны, чтобы точнее рассчитать персональный план обслуживания: сроки работ и остаток ресурса именно для вашего автомобиля. Информация хранится только в вашем приложении и никуда не передаётся третьим лицам.';

  @override
  String get historyLastServicePrompt =>
      'Когда последний раз обслуживали или меняли?';

  @override
  String get historyChooseAnswer => 'Выберите вариант';

  @override
  String get historyDoneKnownShort => 'Да, помню когда';

  @override
  String get historyDoneKnownHint => 'Укажите дату или пробег';

  @override
  String get historyUnknownShort => 'Не помню / не знаю';

  @override
  String get historyUnknownHint => 'Это нормально — можно уточнить позже';

  @override
  String get historyNeverHint => 'Эту работу ещё не делали';

  @override
  String get historyNotApplicableHint => 'Для этой машины не актуально';

  @override
  String get historyKnownDetailsTitle => 'Когда это было?';

  @override
  String get historyNever => 'Никогда';

  @override
  String get historyAdditional => 'Дополнительно';

  @override
  String get historyWearToggle => 'Указать износ';

  @override
  String get historyWearHint => 'Износ 80% означает остаток 20%.';

  @override
  String get historyRemainingPercent => 'Остаток, %';

  @override
  String get historyInstallDate => 'Дата установки';

  @override
  String get historyInstallMileage => 'Пробег установки, км';

  @override
  String get historyNoteOptional => 'Заметка (необязательно)';

  @override
  String get historyReplacementDate => 'Дата замены';

  @override
  String get historyReplacementMileage => 'Пробег замены, км';

  @override
  String get historyCheckDate => 'Дата проверки';

  @override
  String get moreAnalytics => 'Аналитика';

  @override
  String get moreAnalyticsDetail => 'Подтверждённые суммы, категории, пробег';

  @override
  String get close => 'Закрыть';

  @override
  String get back => 'Назад';

  @override
  String get understood => 'Понятно';

  @override
  String get example => 'Пример';

  @override
  String get exampleSemantics => 'Демонстрационный пример';

  @override
  String previewNoCar(String message) {
    return 'Предпросмотр без автомобиля. $message';
  }

  @override
  String get previewGarageEmpty => 'Предпросмотр · гараж пуст';

  @override
  String get addVehicle => 'Добавить автомобиль';

  @override
  String get previewUnavailableHint =>
      'Пример. Действие недоступно без автомобиля';

  @override
  String get demoEntry => 'Демо · запись';

  @override
  String get vehicleStatusNoCar => 'Статус автомобиля · нет автомобиля';

  @override
  String get garageEmpty => 'Гараж пуст';

  @override
  String get garageTitle => 'Гараж';

  @override
  String get garageSecondCarTitle => 'Второе авто';

  @override
  String get garageSecondCarLocked =>
      'Добавление второго автомобиля — после подписки';

  @override
  String get garageOneCarHint =>
      'Сейчас работаем с одним автомобилем. Второе место зарезервировано под подписку.';

  @override
  String get garageOpenAnalytics => 'Аналитика';

  @override
  String get garageOpenNotes => 'Заметки';

  @override
  String get garageSelect => 'Выбрать';

  @override
  String get garageSelected => 'Выбрано';

  @override
  String get vehiclePassport => 'Техпаспорт';

  @override
  String get passportIdentity => 'Идентификация';

  @override
  String get passportPowertrain => 'Силовая установка';

  @override
  String get passportUsage => 'Эксплуатация';

  @override
  String get passportSections => 'Разделы';

  @override
  String get garageVehicleNotes => 'Заметки по авто';

  @override
  String get garageVehicleNotesEmpty =>
      'Пока нет сохранённых заметок по этой машине.';

  @override
  String get addVehicleSemantics =>
      'Добавить автомобиль. Открыть начало добавления';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notificationsEmpty =>
      'История уведомлений появится после добавления автомобиля.';

  @override
  String notificationsForVehicle(String make, String model) {
    return 'Уведомления · $make $model';
  }

  @override
  String get notificationsNoNew => 'Новых уведомлений нет';

  @override
  String get guestProfile => 'Гостевой профиль';

  @override
  String get openGuestProfile => 'Открыть гостевой профиль';

  @override
  String get guestProfileInitial => 'Г';

  @override
  String get guestProfileFuture =>
      'Вход и синхронизация будут доступны в следующих этапах.';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileGuestHint =>
      'Вы в гостевом режиме. Войдите через Google, чтобы сохранить имя, предпочтения и диалоги между устройствами.';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String get signOut => 'Выйти';

  @override
  String get profileSignedIn => 'Вход выполнен';

  @override
  String get profileSignedOut => 'Вы вышли из аккаунта';

  @override
  String get profileError => 'Не удалось загрузить профиль';

  @override
  String get addEvent => 'Добавить событие';

  @override
  String get addEventJournalSemantics => 'Добавить событие в журнал';

  @override
  String get quickAddTechnical => 'Меню команд · требуется автомобиль';

  @override
  String get quickAddPreview =>
      'Предпросмотр следующего шага. Выберите автомобиль, чтобы открыть форму и сохранить запись.';

  @override
  String get quickAddFuel => 'Заправка';

  @override
  String get quickAddService => 'Обслуживание или ремонт';

  @override
  String get quickAddExpense => 'Другой расход';

  @override
  String get quickAddMileage => 'Обновить пробег';

  @override
  String unavailableWithoutVehicle(String label) {
    return '$label. Недоступно без автомобиля';
  }

  @override
  String get addVehicleFirst => 'Сначала добавьте автомобиль';

  @override
  String get aiCentralTab => 'AI, центральная вкладка';

  @override
  String get aiAssistant => 'AI-ассистент';

  @override
  String get cockpitDemo => 'Модуль кокпита · деморежим';

  @override
  String get planPreviewGate =>
      'Ниже — только обзор дизайна. Персональный план появится после добавления автомобиля.';

  @override
  String get consumablesRailSemantics =>
      'Расходники, демонстрационная вертикальная область с независимой прокруткой';

  @override
  String get timelineSemantics =>
      'Подробная демонстрационная временная шкала с независимой прокруткой';

  @override
  String get closeConsumablesBarrier => 'Закрыть список расходников';

  @override
  String get consumables => 'Расходники';

  @override
  String get consumablesSheetSemantics =>
      'Расходники. Модальная панель. Демонстрационный список';

  @override
  String get consumablesProjection => 'Проекция · демо / нет автомобиля';

  @override
  String get closeConsumables => 'Закрыть панель расходников';

  @override
  String get consumablesDisclaimer =>
      'Примеры ниже не относятся к реальному автомобилю и не являются рекомендациями.';

  @override
  String selectedConsumable(String label) {
    return 'Выбран расходник: $label';
  }

  @override
  String consumableRailSemantics(String title, String state) {
    return '$title. $state. Пример без автомобиля. Открыть полный список и детали';
  }

  @override
  String consumableRowSemantics(String title, String state) {
    return '$title. $state';
  }

  @override
  String intervalFraction(int percent) {
    return 'Использована демонстрационная доля регламентного интервала: $percent%. Это не физический износ.';
  }

  @override
  String conditionNoPercent(String state) {
    return '$state. Процент и значение не показываются.';
  }

  @override
  String get oilTitle => 'Моторное масло';

  @override
  String get oilState => 'Предупреждение: близко к сроку';

  @override
  String get oilDue => 'Пример: через 1 200 км или 2 месяца';

  @override
  String get intervalEarlierBasis =>
      'Интервал по времени и пробегу; действует более ранний порог.';

  @override
  String get manufacturerSource =>
      'Основание примера: проверенный регламент производителя.';

  @override
  String get triggerMileage => 'Эффективный триггер: пробег';

  @override
  String get brakesTitle => 'Тормозные колодки';

  @override
  String get brakesState => 'Требуется проверка, измерение отсутствует';

  @override
  String get brakesDue => 'Следующая инспекция: при добавлении автомобиля';

  @override
  String get conditionBasis =>
      'Пункт по состоянию; процент без фактического измерения не строится.';

  @override
  String get inspectionRuleSource =>
      'Основание примера: правило периодической инспекции.';

  @override
  String get triggerInspection => 'Эффективный триггер: инспекция';

  @override
  String get lastInspectionUnknown => 'Последняя инспекция: неизвестно';

  @override
  String get coolantTitle => 'Охлаждающая жидкость';

  @override
  String get coolantState => 'Опасная близость к сроку';

  @override
  String get coolantDue => 'Пример: через 3 недели или 600 км';

  @override
  String get publishedRuleSource =>
      'Основание примера: опубликованное правило обслуживания.';

  @override
  String get triggerTime => 'Эффективный триггер: время';

  @override
  String get airFilterTitle => 'Воздушный фильтр';

  @override
  String get normalInterval => 'Обычный интервал';

  @override
  String get airFilterDue => 'Пример: через 7 500 км';

  @override
  String get verifiedMileageBasis => 'Пробеговая доля проверенного интервала.';

  @override
  String get tiresTitle => 'Шины';

  @override
  String get tiresState =>
      'Состояние инспекции неизвестно, измерение отсутствует';

  @override
  String get tiresDue => 'Следующая инспекция: срок не рассчитан';

  @override
  String get tiresBasis =>
      'Пункт по состоянию; расчёт физического износа не выполняется.';

  @override
  String get inspectionRecommendationSource =>
      'Основание примера: универсальная рекомендация по осмотру.';

  @override
  String get triggerUnknown => 'Эффективный триггер: неизвестно';

  @override
  String get categoryMaintenance => 'Обслуживание и ремонт';

  @override
  String get categoryParts => 'Детали';

  @override
  String get categoryFuel => 'Топливо';

  @override
  String get categoryInspection => 'Инспекция';

  @override
  String get categoryDocument => 'Документ';

  @override
  String get categoryMileage => 'Пробег';

  @override
  String get categoryExpense => 'Расход';

  @override
  String get categoryReminder => 'Напоминание';

  @override
  String get indicatorVerified => 'Источник проверен';

  @override
  String get indicatorCost => 'Есть стоимость';

  @override
  String get indicatorGrouped => 'Группа событий';

  @override
  String get indicatorForecast => 'Оценочный период';

  @override
  String get indicatorUnknownHistory => 'История неизвестна';

  @override
  String get importanceInformation => 'Информация';

  @override
  String get importanceRecommendation => 'Рекомендация';

  @override
  String get importanceRequired => 'Обязательно';

  @override
  String get importanceCritical => 'Критическое внимание';

  @override
  String importanceSemantics(String label) {
    return 'Важность: $label';
  }

  @override
  String eventCategorySemantics(String event, String category) {
    return '$event. Категория: $category';
  }

  @override
  String get overdue => 'Просрочено';

  @override
  String get demoNotVehicleData =>
      'Демонстрационный пример, не данные автомобиля';

  @override
  String get nowSemantics =>
      'Сейчас. Демонстрационная точка расчёта, реальный пробег отсутствует';

  @override
  String get nowExample => 'Сейчас · пример без показания одометра';

  @override
  String get timelineFuelTime => 'Пример · 14 июля, 18:40';

  @override
  String get demoMileage84120 => '84 120 км';

  @override
  String get demoMileage83900 => '83 900 км';

  @override
  String get timelineFuelTitle => 'Заправка';

  @override
  String get timelineFuelDetail =>
      'Демонстрация сгруппированной фактической записи';

  @override
  String get timelineServiceTime => 'Пример · 10 июля';

  @override
  String get timelineServiceTitle => 'Плановое обслуживание';

  @override
  String get timelineServiceDetail => 'Прошлое событие без будущей важности';

  @override
  String get timelineExpenseTime => 'Пример · 8 июля';

  @override
  String get timelineExpenseTitle => 'Другой расход';

  @override
  String get timelineExpenseDetail =>
      'Категория показана отдельной главной эмблемой';

  @override
  String get timelineMileageTime => 'Пример · примерно через 9–12 месяцев';

  @override
  String get timelineMileageTitle => 'Ориентир обновления пробега';

  @override
  String get timelineMileageDetail => 'Широкий прогноз, не показание одометра';

  @override
  String get statusEstimate => 'Статус: ориентир';

  @override
  String get timelineBrakesTime => 'Пример · в следующем месяце';

  @override
  String get timelineBrakesTitle => 'Осмотр тормозной системы';

  @override
  String get timelineBrakesDetail =>
      'Измерение отсутствует; требуется физическая проверка';

  @override
  String get statusSoon => 'Статус: скоро';

  @override
  String get timelineFilterTime => 'Пример · до 30 сентября';

  @override
  String get timelineFilterTitle => 'Замена воздушного фильтра';

  @override
  String get timelineFilterDetail =>
      'Регламентный пример; персональный срок не рассчитан';

  @override
  String get mileageThreshold => 'или при пороге пробега';

  @override
  String get statusCurrent => 'Статус: актуально';

  @override
  String get timelineDocumentTime => 'Пример · срок уже прошёл';

  @override
  String get timelineDocumentTitle => 'Проверить обязательный документ';

  @override
  String get timelineDocumentDetail =>
      'Просрочка показана отдельно от уровня важности';

  @override
  String get statusOverdue => 'Статус: просрочено';

  @override
  String get timelineReminderTime => 'Пример · выбранная дата';

  @override
  String get timelineReminderTitle => 'Личное напоминание';

  @override
  String get timelineReminderDetail =>
      'Создаётся пользователем и не является регламентом';

  @override
  String get statusPlanned => 'Статус: запланировано';

  @override
  String get journalGate =>
      'Общая хронология появится после добавления автомобиля и подтверждённых записей.';

  @override
  String get filterAll => 'Все';

  @override
  String get filterService => 'Обслуживание';

  @override
  String get filterFuel => 'Заправки';

  @override
  String get filterOther => 'Прочие';

  @override
  String get journalDemoDisclaimer =>
      'Ниже показана только приглушённая структура примера — это не история вашего автомобиля.';

  @override
  String get journalServiceTitle => 'Пример · Обслуживание';

  @override
  String get journalServiceSubtitle => 'Подтверждённая работа, дата и пробег';

  @override
  String get journalFuelTitle => 'Пример · Заправка';

  @override
  String get journalFuelSubtitle => 'Расход и дополнительные топливные данные';

  @override
  String get journalExpenseTitle => 'Пример · Прочий расход';

  @override
  String get journalExpenseSubtitle => 'Категория, дата и подтверждённая сумма';

  @override
  String get topicsExample => 'Темы · пример';

  @override
  String get topicSuspension => 'Подвеска';

  @override
  String get topicPaint => 'Покраска';

  @override
  String get topicElectronics => 'Электроника';

  @override
  String get assistantGate =>
      'AI учитывает данные машины. Сначала добавьте автомобиль.';

  @override
  String get topics => 'Темы';

  @override
  String get chatQuestion =>
      'Что проверить сначала и насколько срочно ехать в сервис?';

  @override
  String get chatAnswer =>
      'Здесь появится ответ с учётом истории конкретного автомобиля.';

  @override
  String get messageFieldUnavailable =>
      'Поле сообщения недоступно. Сначала добавьте автомобиль';

  @override
  String get message => 'Сообщение';

  @override
  String get sendingDisabled =>
      'Отправка отключена: нет выбранного автомобиля.';

  @override
  String selectedVehicleContext(String make, String model) {
    return 'Выбранный автомобиль · $make $model';
  }

  @override
  String get aiUnavailable => 'AI-ассистент пока не подключён';

  @override
  String get aiAvailableAfterConnection =>
      'Будет доступно после подключения AI';

  @override
  String get aiTopicsUnavailable =>
      'Темы станут доступны после подключения AI-ассистента.';

  @override
  String get assistantNewChat => 'Новый чат';

  @override
  String get assistantTopicsTitle => 'Темы';

  @override
  String get assistantTopicsEmpty =>
      'Пока нет диалогов. Нажмите «Новый чат», чтобы начать.';

  @override
  String get assistantEmptyTitle => 'Пока нет диалогов';

  @override
  String get assistantEmptySubtitle =>
      'Начните чат — ассистент ответит с учётом вашей машины и настроек.';

  @override
  String get assistantEmptyCta => 'Начать диалог';

  @override
  String get agentIntroSubtitle => 'Умный помощник по вашему авто';

  @override
  String get agentIntroBody =>
      'Знает данные вашей машины, помнит важное из разговоров и отвечает в вашем стиле — поможет с советом по ТО, разобраться в симптоме, сроках расходников, проверкой перед поездкой и вопросами для сервиса.';

  @override
  String get agentIntroExamples =>
      'Знает данные вашей машины, помнит важное из разговоров и отвечает в вашем стиле — поможет с советом по ТО, разобраться в симптоме, сроках расходников, проверкой перед поездкой и вопросами для сервиса.';

  @override
  String get assistantQuickStartsHint => 'С чего начать';

  @override
  String get agentIntroTipCar => 'Контекст авто';

  @override
  String get agentIntroTipMemory => 'Память из чата';

  @override
  String get agentIntroTipEnergy => 'AI-токены на ответы';

  @override
  String get agentIntroOpenProfile => 'Профиль и настройки';

  @override
  String get agentIntroCollapse => 'Свернуть';

  @override
  String get agentIntroExpand => 'Подробнее';

  @override
  String get agentIntroChatsLabel => 'Ваши чаты';

  @override
  String agentIntroRepliesLeft(int count) {
    return '≈ $count ответов';
  }

  @override
  String agentTypicalReplyCost(int amount) {
    return 'типичный вопрос ≈ $amount ток.';
  }

  @override
  String get assistantQuickStartsLabel => 'Быстрый старт';

  @override
  String get assistantQuickStartService => 'Что важнее проверить по ТО';

  @override
  String get assistantQuickStartServicePrompt =>
      'Что у меня по обслуживанию сейчас важнее всего проверить?';

  @override
  String get assistantQuickStartSymptom =>
      'Разобрать посторонний звук или симптом';

  @override
  String get assistantQuickStartSymptomPrompt =>
      'Есть посторонний звук в машине. Помоги разобраться, с чего начать проверку.';

  @override
  String get assistantQuickStartWorkshop => 'Подготовить вопросы для сервиса';

  @override
  String get assistantQuickStartWorkshopPrompt =>
      'Помоги подготовить короткий список вопросов и проверок для визита в сервис.';

  @override
  String assistantChatEmptyHistory(int percent) {
    return 'История обслуживания заполнена на $percent%.';
  }

  @override
  String get assistantChatEmptyHistoryUnknown =>
      'Чем полнее история обслуживания, тем точнее подсказки агента.';

  @override
  String get assistantChatEmptyHistoryCta => 'Дополнить историю';

  @override
  String get assistantChatEmptyIntro =>
      'Можно выбрать одну из тем ниже — или просто напишите свой вопрос в поле сообщения.';

  @override
  String get assistantChatEmptyTopicsLabel => 'Темы на выбор:';

  @override
  String get assistantChatEmptyOwnHint =>
      'Не обязательно выбирать из списка — опишите свою ситуацию своими словами.';

  @override
  String assistantTokensSpent(int amount) {
    return '−$amount ток.';
  }

  @override
  String get agentNoteForget => 'Забыть';

  @override
  String get agentNoteForgetDone => 'Заметка удалена';

  @override
  String get assistantWelcomeTitle => 'Знакомство';

  @override
  String assistantWelcomeMessage(String vehicle) {
    return 'Здравствуйте! Я ваш помощник по $vehicle. Чем могу помочь — симптом, обслуживание или просто разобраться с машиной?';
  }

  @override
  String get ownerSkillQuizTitle => 'Пару простых вопросов';

  @override
  String get ownerSkillQuizHint =>
      'Это поможет объяснять понятнее — без лишней техники.';

  @override
  String get ownerSkillQ1 => 'Насколько вы разбираетесь в машинах?';

  @override
  String get ownerSkillQ1Novice => 'Почти не разбираюсь';

  @override
  String get ownerSkillQ1Basic => 'Знаю основы';

  @override
  String get ownerSkillQ1Confident => 'Хорошо разбираюсь';

  @override
  String get ownerSkillQ2 =>
      'Если что-то не так, вы сами заглянете под капот или к колёсам?';

  @override
  String get ownerSkillQ2Never => 'Нет, только сервис';

  @override
  String get ownerSkillQ2Sometimes => 'Иногда простое';

  @override
  String get ownerSkillQ2Yes => 'Да, могу проверить';

  @override
  String get ownerSkillQ3 => 'Что вам ближе?';

  @override
  String get ownerSkillQ3Simple => 'Объясняйте максимально просто';

  @override
  String get ownerSkillQ3Detailed => 'Можно чуть подробнее';

  @override
  String get agentProfileTitle => 'Профиль агента';

  @override
  String get agentProfileSaved => 'Настройки сохранены';

  @override
  String agentFuelLevel(String amount) {
    return 'AI-токены: $amount';
  }

  @override
  String get agentFuelLiters => 'Остаток AI-токенов без лимита накопления';

  @override
  String get agentTokensBalanceLabel => 'AI-токены';

  @override
  String get agentTokensAdd => 'Добавить';

  @override
  String get agentTokensTapHint => 'Нажмите — как расходуются';

  @override
  String get agentTokensGuideTitle => 'Как расходуются AI-токены';

  @override
  String get agentTokensGuideIntro =>
      'Каждый ответ ассистента тратит AI-токены с вашего баланса. Ниже — ориентиры (примерно):';

  @override
  String agentTokensGuideOneReply(int amount) {
    return 'Один ответ ≈ $amount ток.';
  }

  @override
  String agentTokensGuideShort(int amount) {
    return 'Короткий диалог (2–3 ответа) ≈ $amount ток.';
  }

  @override
  String agentTokensGuideMedium(int amount) {
    return 'Обычный диалог (8–10 ответов) ≈ $amount ток.';
  }

  @override
  String agentTokensGuideLong(int amount) {
    return 'Длинный разбор (20+ ответов) ≈ $amount ток.';
  }

  @override
  String get agentTokensGuideSeeUsage => 'Смотреть расход';

  @override
  String agentApproxReplies(int count) {
    return 'Хватит примерно на $count ответов';
  }

  @override
  String get assistantChatGuideTitle => 'Важно знать';

  @override
  String get assistantChatGuideAction => 'Инструкция';

  @override
  String get assistantChatGuideBody =>
      '• Ассистент опирается на данные вашей машины и настройки.\n• Важное из разговора он может отметить для себя — это помогает в следующих ответах.\n• Очень длинный диалог ухудшает качество: лучше начать новую тему по новому вопросу.\n• Это подсказки нейросети, а не диагноз и не замена сервису — решения за вами.';

  @override
  String get agentEnergyLowTitle => 'AI-токенов осталось мало';

  @override
  String get agentEnergyLowBanner =>
      'Токенов для ответов осталось немного — скоро ответы могут прекратиться. Лучше заранее докупить AI-токены.';

  @override
  String get agentEnergyLowAction => 'Купить токены';

  @override
  String get agentEnergyUnitShort => 'ток.';

  @override
  String get agentUsageTitle => 'Расход AI-токенов';

  @override
  String get agentUsageToday => 'Сегодня';

  @override
  String get agentUsageWeek => '7 дней';

  @override
  String get agentUsageAll => 'Всего';

  @override
  String agentUsageFuel(String liters) {
    return 'Потрачено: $liters AI-токенов';
  }

  @override
  String agentUsageTokens(int count) {
    return 'Токены модели: $count';
  }

  @override
  String get agentUsageEstimate =>
      'Токены модели: оценка (провайдер не вернул usage)';

  @override
  String agentUsageCost(String amount, String currency) {
    return 'Оценка стоимости: $amount $currency';
  }

  @override
  String get agentUsageWeekChart => 'Последние 7 дней';

  @override
  String get agentUsageLegendSpent => 'Потрачено';

  @override
  String get agentUsageLegendRefuel => 'Куплено';

  @override
  String agentUsageCompactSpent(String amount) {
    return '−$amount';
  }

  @override
  String agentUsageCompactRefuel(String amount) {
    return '+$amount';
  }

  @override
  String get agentHowItAnswers => 'Как отвечает';

  @override
  String get agentHowItAnswersHint =>
      'Слайдеры влияют на стиль. Безопасность и ваш уровень знаний важнее.';

  @override
  String get agentSelectOption => 'Выберите вариант';

  @override
  String get agentSliderSimplicity => 'Простота языка';

  @override
  String get agentSliderSimplicityLow => 'Проще';

  @override
  String get agentSliderSimplicityHigh => 'Техничнее';

  @override
  String get agentSliderVerbosity => 'Краткость';

  @override
  String get agentSliderVerbosityLow => 'Коротко';

  @override
  String get agentSliderVerbosityHigh => 'Подробнее';

  @override
  String get agentSliderDirectness => 'Прямота';

  @override
  String get agentSliderDirectnessLow => 'Мягче';

  @override
  String get agentSliderDirectnessHigh => 'Прямее';

  @override
  String get agentSliderInitiative => 'Инициативность';

  @override
  String get agentSliderInitiativeLow => 'Ждёт';

  @override
  String get agentSliderInitiativeHigh => 'Сам уточняет';

  @override
  String get agentCustomInstructions => 'Ваши инструкции агенту';

  @override
  String get agentCustomInstructionsHint =>
      'Например: всегда обращайся по имени, не предлагай СТО сразу…';

  @override
  String get agentNotesTitle => 'Что агент отметил для себя';

  @override
  String get agentNotesHint =>
      'Это не настройки и не анкеты — агент сам подчеркнул важное из разговора с вами. Здесь только то, что он запомнил сверх уже заполненных данных.';

  @override
  String get agentNotesUser => 'О вас — из диалога';

  @override
  String get agentNotesVehicle => 'О машине — из диалога';

  @override
  String get agentNotesEmpty =>
      'Пока ничего не отметил. Появится, когда в разговоре всплывут важные детали.';

  @override
  String get agentRefuelTitle => 'Купить AI-токены';

  @override
  String get agentRefuelHint =>
      'Покупка токенов для ответов ассистента. Оплата скоро — сейчас доступна демо-покупка.';

  @override
  String agentRefuelPackage(String label) {
    return 'Пакет $label';
  }

  @override
  String get agentPaymentSoon => 'оплата скоро';

  @override
  String get agentRefuelStubDone => 'Демо-токены добавлены на баланс';

  @override
  String get agentFuelEmptyTitle => 'AI-токены закончились';

  @override
  String get agentFuelEmptyBody =>
      'Извините за неудобство.\n\nПомощник работает на нейросети: каждый ответ тратит AI-токены, поэтому бесплатно без ограничений мы продолжать не можем.\n\nКупите токены в профиле агента — и сразу продолжим разговор.';

  @override
  String get agentFuelEmptyBanner =>
      'AI-токены закончились — ответы временно недоступны';

  @override
  String get agentFuelEmptyRefuel => 'Купить токены';

  @override
  String get agentFuelEmptyLater => 'Позже';

  @override
  String get agentOwnerSkillTitle => 'Ваш уровень в технике';

  @override
  String get agentOwnerSkillHint =>
      'Так ассистент проще подберёт слова и не будет просить сложные проверки.';

  @override
  String get agentOwnerSkillBand => 'Насколько разбираетесь в машинах';

  @override
  String get agentOwnerSkillHandsOn =>
      'Готовы сами заглянуть под капот / к колёсам';

  @override
  String get agentOwnerSkillBandNeverTools => 'Никогда не держал отвертку';

  @override
  String get agentOwnerSkillBandScared => 'Боюсь что-то трогать';

  @override
  String get agentOwnerSkillBandNovice => 'Почти не разбираюсь';

  @override
  String get agentOwnerSkillBandBasic => 'Знаю основы';

  @override
  String get agentOwnerSkillBandCurious => 'Любитель: читаю и смотрю';

  @override
  String get agentOwnerSkillBandConfident => 'Хорошо разбираюсь';

  @override
  String get agentOwnerSkillBandAdvanced => 'Многое делаю сам';

  @override
  String get agentOwnerSkillBandPro => 'Механик / сотрудник сервиса';

  @override
  String get agentOwnerSkillHandsNever => 'Нет, только сервис';

  @override
  String get agentOwnerSkillHandsOutside => 'Только снаружи (колёса, уровни)';

  @override
  String get agentOwnerSkillHandsSometimes => 'Иногда простое';

  @override
  String get agentOwnerSkillHandsOften => 'Часто сам заглядываю';

  @override
  String get agentOwnerSkillHandsAlways => 'Да, спокойно под капотом';

  @override
  String get agentOwnerSkillHandsYes => 'Да, могу проверить';

  @override
  String get agentPrefsLiveHint =>
      'Слайдеры и инструкции уже влияют на ответы ассистента.';

  @override
  String get assistantFillHistoryManual => 'Заполнить историю вручную';

  @override
  String get assistantTopicsActive => 'Активные';

  @override
  String get assistantTopicsArchive => 'Архив';

  @override
  String get assistantArchiveEmpty => 'В архиве пока пусто.';

  @override
  String get assistantEmptyThread => 'Пустой диалог';

  @override
  String get assistantDeleteTopic => 'Удалить тему';

  @override
  String get assistantDeleteTopicConfirmTitle => 'Удалить чат?';

  @override
  String get assistantDeleteTopicConfirmBody =>
      'Чат исчезнет навсегда. Это нельзя отменить.';

  @override
  String get assistantDeleteTopicConfirmAction => 'Удалить';

  @override
  String get assistantRenameTopic => 'Переименовать';

  @override
  String get assistantRenameHint => 'Название темы';

  @override
  String get assistantTopicResolved => 'Решено';

  @override
  String get assistantMarkResolved => 'Отметить решённым';

  @override
  String get assistantMarkActive => 'Вернуть в активные';

  @override
  String get assistantArchiveTopic => 'В архив';

  @override
  String get assistantRestoreTopic => 'Из архива';

  @override
  String get assistantThreadMissing => 'Этот диалог не найден.';

  @override
  String get assistantKeyMissing =>
      'AI настраивается на сервере. Проверьте админку и ключ в .env.';

  @override
  String get assistantNeedsVehicle =>
      'Для ответа AI выберите или добавьте автомобиль.';

  @override
  String get cancel => 'Отмена';

  @override
  String get odometerPickerTitle => 'Пробег';

  @override
  String get odometerPickerHint => 'Прокрутите каждую цифру, как на одометре.';

  @override
  String get odometerPickerSelected => 'Выбрано';

  @override
  String get odometerPickerConfirm => 'Готово';

  @override
  String get journalLoading => 'Загружаем записи обслуживания…';

  @override
  String get journalLoadError => 'Не удалось загрузить записи обслуживания.';

  @override
  String journalForVehicle(String make, String model) {
    return 'Журнал · $make $model';
  }

  @override
  String analyticsForVehicle(String make, String model) {
    return 'Аналитика · $make $model';
  }

  @override
  String get analyticsPreparing =>
      'Подготавливаем аналитику по подтверждённым записям…';

  @override
  String get analyticsNoData =>
      'Подтверждённых записей для аналитики пока нет.';

  @override
  String get analyticsLoadError => 'Не удалось загрузить данные для аналитики.';

  @override
  String get consumablesRedirecting =>
      'Открываем актуальный план и расходники выбранного автомобиля…';

  @override
  String get analyticsGate =>
      'Аналитика появится после добавления автомобиля и подтверждённых записей.';

  @override
  String get analyticsEmpty =>
      'Здесь будут только подтверждённые данные. Пока суммы, графики и выводы не рассчитываются.';

  @override
  String get confirmedAmounts => 'Подтверждённые суммы';

  @override
  String get currentMonthYear => 'За текущий месяц и год';

  @override
  String get expenseCategories => 'Категории расходов';

  @override
  String get confirmedDistribution => 'Распределение подтверждённых записей';

  @override
  String get confirmedMileage => 'Подтверждённый пробег';

  @override
  String get odometerDynamics => 'Динамика по сохранённым точкам одометра';

  @override
  String get analyticsMileageEmpty =>
      'Пока нет сохранённых точек пробега. Обновите пробег — они появятся на графике.';

  @override
  String get fuelConsumptionFuture =>
      'Расход топлива появится только при достаточном количестве качественных данных.';

  @override
  String get uiKitTitle => 'Компоненты UI';

  @override
  String get uiKitMoreDetail =>
      'Справочник кнопок, полей и панелей для новых экранов';

  @override
  String get uiKitIntro =>
      'Используйте эти компоненты как образец при сборке новых окон — так интерфейс останется единым.';

  @override
  String get uiKitSectionPanels => 'Панели';

  @override
  String get uiKitPanelDefault => 'AutomotivePanel — обычная панель контента';

  @override
  String get uiKitPanelEmphasized =>
      'AutomotivePanel emphasized — акцент слева';

  @override
  String get uiKitSectionHeaders => 'Заголовки';

  @override
  String get uiKitSectionHeaderExample => 'Заголовок секции';

  @override
  String get uiKitSectionButtons => 'Кнопки';

  @override
  String get uiKitPrimaryButton => 'Filled / основная';

  @override
  String get uiKitTonalButton => 'Tonal / вторичная';

  @override
  String get uiKitOutlinedButton => 'Outlined';

  @override
  String get uiKitTextButton => 'Text';

  @override
  String get uiKitDisabledButton => 'Disabled';

  @override
  String get uiKitSectionInputs => 'Поля ввода';

  @override
  String get uiKitInputLabel => 'Подпись поля';

  @override
  String get uiKitInputHint => 'Подсказка';

  @override
  String get uiKitInputErrorLabel => 'Поле с ошибкой';

  @override
  String get uiKitInputError => 'Пример текста ошибки';

  @override
  String get uiKitDropdownLabel => 'Выпадающий список';

  @override
  String get uiKitSwitchLabel => 'Переключатель';

  @override
  String get uiKitSectionStatus => 'Статус и индикаторы';

  @override
  String get uiKitStatusLabel => 'STATUS RAIL';

  @override
  String get uiKitStatusValue => 'В норме';

  @override
  String get uiKitGaugeLabel => 'Индикатор расходника';

  @override
  String get uiKitSectionPreview => 'Превью без авто';

  @override
  String get uiKitPreviewGate => 'Сообщение, когда автомобиль ещё не выбран';

  @override
  String get uiKitPreviewTileTitle => 'Превью-строка';

  @override
  String get uiKitPreviewTileDetail => 'Неактивный пример записи';

  @override
  String get uiKitSectionColors => 'Цвета темы';

  @override
  String structureWithoutData(String title, String detail) {
    return '$title. $detail. Структура без данных';
  }

  @override
  String get allConsumables => 'Все расходники';

  @override
  String get allConsumablesGate =>
      'Полный список строится по проверенному регламенту, плану и истории конкретного автомобиля.';

  @override
  String get oilFilters => 'Масло и фильтры';

  @override
  String get oilFiltersDetail =>
      'Интервальный пункт: прогресс по времени и пробегу показывается раздельно, действует правило «что раньше».';

  @override
  String get technicalFluids => 'Технические жидкости';

  @override
  String get technicalFluidsDetail =>
      'Интервальный пункт появится только при наличии применимого проверенного правила.';

  @override
  String get brakesDetail =>
      'По состоянию: последняя проверка, измерение при наличии и следующая инспекция.';

  @override
  String get tiresDetail =>
      'По состоянию: без выдуманного процента износа или физического остатка жизни.';

  @override
  String get demoConsumableHint =>
      'Демонстрационный расходник, не данные автомобиля';

  @override
  String get demoTechnicalRail => 'Пример · техническая шкала';

  @override
  String get moreGate =>
      'Настройки доступны для просмотра. Функции машины пока отключены.';

  @override
  String get appSettings => 'Настройки приложения';

  @override
  String get unitsThemeLanguage => 'Единицы, тема и язык';

  @override
  String get feedback => 'Обратная связь';

  @override
  String get feedbackDetail => 'Сообщить о проблеме или идее';

  @override
  String get vehicleReminders => 'Напоминания автомобиля';

  @override
  String get controlChannel => 'Канал управления';

  @override
  String get localPreviewFuture =>
      'Локальный предпросмотр. Подключение появится позже.';

  @override
  String get languagePickerTitle => 'Язык';

  @override
  String get selectedLanguage => 'Выбрано';

  @override
  String get garageSetupStep1 => 'Настройка гаража · шаг 01';

  @override
  String get secureInitializing => 'Защищённый канал · инициализация';

  @override
  String get preparingSecureSetup => 'Подготавливаем безопасное добавление…';

  @override
  String get consentProtocol => 'Протокол согласий · шаг 01 / 02';

  @override
  String get consents => 'Согласия';

  @override
  String get consentsIntro =>
      'Для продолжения примите обязательное согласие. Аналитика необязательна и не влияет на основные функции.';

  @override
  String get required => 'Обязательно';

  @override
  String get optional => 'Необязательно';

  @override
  String versionLabel(String version) {
    return 'Версия: $version';
  }

  @override
  String get continueAction => 'Продолжить';

  @override
  String get connectionFault => 'Ошибка соединения';

  @override
  String get bootstrapUnavailable =>
      'Не удалось подготовить добавление автомобиля.';

  @override
  String get networkError =>
      'Не удалось связаться с сервером. Проверьте подключение.';

  @override
  String get unexpectedResponse => 'Сервер вернул неожиданный ответ.';

  @override
  String requestIdLabel(String requestId) {
    return 'ID запроса: $requestId';
  }

  @override
  String get retry => 'Повторить';

  @override
  String get garageSetupStep2 => 'Настройка гаража · шаг 02';

  @override
  String get vinEntry => 'Ввод VIN';

  @override
  String get vinInterfaceOffline => 'Интерфейс VIN · офлайн';

  @override
  String get addStage => 'Этап добавления';

  @override
  String get stepTwoOfTwo => '02 / 02';

  @override
  String get nextStage => 'Следующий этап';

  @override
  String get vinStubDetail => 'Согласия сохранены.';

  @override
  String get vehicleDetailsStep => 'Настройка гаража · данные автомобиля';

  @override
  String get vehicleDetails => 'Данные автомобиля';

  @override
  String get vin => 'VIN';

  @override
  String get vinValidation => 'Введите 17 символов VIN без I, O и Q.';

  @override
  String get vinOptionalHelper =>
      'Без VIN в будущем будут недоступны автоматический сбор данных и точная идентификация комплектации.';

  @override
  String get collectVinData => 'Собрать данные по VIN';

  @override
  String get vinProviderTitle => 'Данные по VIN';

  @override
  String get vinProviderInfo =>
      'Провайдер VIN пока не подключён. Заполните и подтвердите данные вручную — приложение не будет добавлять вымышленные сведения.';

  @override
  String get continueManually => 'Продолжить вручную';

  @override
  String get vehicleMake => 'Марка';

  @override
  String get vehicleMakeOther => 'Введите марку';

  @override
  String get vehicleModel => 'Модель';

  @override
  String get vehicleModelOther => 'Введите модель';

  @override
  String get otherModel => 'Другая модель';

  @override
  String get productionYear => 'Год выпуска';

  @override
  String get mileageKm => 'Пробег, км';

  @override
  String get fuelType => 'Тип топлива';

  @override
  String get engineDisplacement => 'Объём двигателя, см³';

  @override
  String get transmissionType => 'Тип трансмиссии';

  @override
  String get transmissionGears => 'Количество передач';

  @override
  String get moreVehicleDetails => 'Дополнительные данные';

  @override
  String get optionalDetailsAccuracy =>
      'Чем больше данных, тем точнее рекомендации. Для конкретных рекомендаций производителя всё равно потребуется проверенная конфигурация.';

  @override
  String get generation => 'Поколение';

  @override
  String get engineCode => 'Код двигателя';

  @override
  String get powerKw => 'Мощность, кВт';

  @override
  String get drivetrain => 'Привод';

  @override
  String get market => 'Рынок';

  @override
  String get firstUseDate => 'Дата начала эксплуатации';

  @override
  String get notSpecified => 'Не указано';

  @override
  String get reviewVehicle => 'Проверить данные';

  @override
  String get requiredTextValidation =>
      'Обязательное поле, не более 100 символов.';

  @override
  String get max100Validation => 'Не более 100 символов.';

  @override
  String get yearValidation => 'Укажите год от 1886 до 2100.';

  @override
  String get nonNegativeValidation => 'Укажите целое неотрицательное число.';

  @override
  String get displacementValidation => 'Укажите значение от 1 до 20 000.';

  @override
  String get gearsValidation => 'Укажите от 1 до 12 передач.';

  @override
  String get powerValidation => 'Укажите значение больше 0 и не более 2000.';

  @override
  String get selectValueValidation => 'Выберите значение.';

  @override
  String get fuelPetrol => 'Бензин';

  @override
  String get fuelDiesel => 'Дизель';

  @override
  String get fuelHybrid => 'Гибрид';

  @override
  String get fuelElectric => 'Электричество';

  @override
  String get fuelLpg => 'Газ (LPG)';

  @override
  String get other => 'Другое';

  @override
  String get transmissionManual => 'Механическая';

  @override
  String get transmissionAutomatic => 'Автоматическая';

  @override
  String get transmissionCvt => 'Вариатор';

  @override
  String get transmissionRobotized => 'Роботизированная';

  @override
  String get drivetrainFwd => 'Передний';

  @override
  String get drivetrainRwd => 'Задний';

  @override
  String get drivetrainAwd => 'Полный (AWD)';

  @override
  String get drivetrainFourWd => 'Полный (4WD)';

  @override
  String get confirmVehicleStep => 'Настройка гаража · подтверждение';

  @override
  String get confirmVehicleTitle => 'Проверьте автомобиль';

  @override
  String get vehicleIdentitySection => 'Идентификация';

  @override
  String get vehicleTechnicalSection => 'Технические данные';

  @override
  String get vehicleAdditionalSection => 'Дополнительные данные';

  @override
  String get dataSource => 'Источник данных';

  @override
  String get dataSourceUser => 'Введено и подтверждено пользователем';

  @override
  String get vehicleCreateError => 'Не удалось создать профиль автомобиля.';

  @override
  String get vehicleConflictHelp =>
      'Проверьте данные или вернитесь к редактированию. Профиль мог быть создан ранее либо достигнут лимит.';

  @override
  String get editVehicle => 'Изменить данные';

  @override
  String get createVehicle => 'Создать профиль';

  @override
  String get firstPlanStep => 'Профиль автомобиля · готов';

  @override
  String get firstPlanTitle => 'Подготовка плана';

  @override
  String firstPlanPreparing(String make, String model) {
    return '$make $model: профиль создан';
  }

  @override
  String get firstPlanHonestStatus =>
      'План подготавливается. Конкретные регламенты и сроки появятся только после получения применимых данных.';

  @override
  String get openPlan => 'Перейти к плану';

  @override
  String get vehicleStatusActive => 'Активный автомобиль';

  @override
  String get openVehicleProfile => 'Открыть сводку профиля автомобиля';

  @override
  String get vehicleProfileBasicSummary => 'Профиль автомобиля';

  @override
  String vehicleMileageSummary(int mileage, String unit) {
    return 'Пробег: $mileage $unit.';
  }

  @override
  String profileCreatedPlanPreparing(String make, String model) {
    return '$make $model: профиль создан · план подготавливается. Временная шкала ниже — иллюстративный предпросмотр.';
  }

  @override
  String get featurePreparingForVehicle =>
      'Профиль автомобиля создан. Эта функция пока подготавливается.';

  @override
  String loadingRealPlan(String vehicle) {
    return 'Загружаем реальный план для $vehicle';
  }

  @override
  String get planNotReadyYet =>
      'План будет отмечен готовым только после ответа сервера.';

  @override
  String vehicleMaintenancePlan(String vehicle) {
    return 'План обслуживания · $vehicle';
  }

  @override
  String planItemsCount(int count) {
    return 'Пунктов обслуживания: $count';
  }

  @override
  String get editorialNotManufacturer =>
      'Редакционная методика AutoDoctor · не регламент производителя';

  @override
  String get sourceEditorialBaseline => 'Редакционная база, не OEM';

  @override
  String get sourceOfficialOem => 'Официальный источник производителя';

  @override
  String get sourceRegulatory => 'Нормативный источник';

  @override
  String get unknownValue => 'Неизвестное значение';

  @override
  String get warningEditorialBaseline =>
      'План основан на редакционной базе AutoDoctor, а не на регламенте производителя.';

  @override
  String get warningHistoryRequired =>
      'История обслуживания не указана — сроки и просрочка не рассчитаны.';

  @override
  String get warningMileageMissing =>
      'Пробег не указан — пробеговые рекомендации нельзя уточнить.';

  @override
  String get warningUnknown => 'Сервер сообщил дополнительное предупреждение.';

  @override
  String get planPreparingError =>
      'План ещё формируется на сервере. Автомобиль сохранён — повторите запрос.';

  @override
  String get planLoadError => 'Не удалось загрузить план обслуживания.';

  @override
  String get roadmapEmpty =>
      'Для этого автомобиля пока нет применимых пунктов плана или расходников.';

  @override
  String get timelineEmpty => 'Будущие пункты плана пока отсутствуют.';

  @override
  String get nowHistoryUnknown => 'Сейчас · подтверждённый пробег не указан';

  @override
  String nowAtMileage(int mileage, String unit) {
    return 'Сейчас · $mileage $unit';
  }

  @override
  String get statusUnknown => 'Статус: неизвестно';

  @override
  String get statusCurrentReal => 'Статус: актуально';

  @override
  String get statusSoonReal => 'Статус: скоро';

  @override
  String get statusOverdueReal => 'Статус: просрочено';

  @override
  String get statusCompleted => 'Статус: выполнено';

  @override
  String get statusNotApplicable => 'Не применимо';

  @override
  String intervalMileage(int value) {
    return 'Интервал $value км';
  }

  @override
  String intervalDays(int value) {
    return 'Интервал $value дн.';
  }

  @override
  String get intervalNotSpecified => 'Интервал не указан';

  @override
  String get historyNotSpecified => 'История не указана';

  @override
  String get inspectionRequired => 'Требуется осмотр';

  @override
  String get inspectionRequiredNoWear =>
      'Требуется осмотр. Процент износа не рассчитывается.';

  @override
  String intervalUsedFraction(int percent) {
    return 'Использовано $percent% проверенного интервала; это не физический износ.';
  }

  @override
  String get quickAddTechnicalActive => 'Меню команд · активный автомобиль';

  @override
  String get quickAddActiveHint =>
      'Выберите доступное действие для активного автомобиля.';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get specifyServiceHistory => 'Уточнить историю обслуживания';

  @override
  String get refineServiceHistory => 'Уточнить историю обслуживания';

  @override
  String get skipAndOpenPlan => 'Пропустить и открыть план';

  @override
  String get historyWizardLabel => 'История обслуживания';

  @override
  String get historySingleLabel => 'История выбранной работы';

  @override
  String get historyWizardTitle => 'Что уже выполнялось?';

  @override
  String get skipAll => 'Пропустить всё';

  @override
  String get skipItem => 'Пропустить пункт';

  @override
  String get next => 'Далее';

  @override
  String get save => 'Сохранить';

  @override
  String historyProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get historyDoneKnown => 'Выполнено — знаю дату или пробег';

  @override
  String get historyDoneUnknown => 'Выполнено, но не помню когда';

  @override
  String get historyNotDone => 'Не выполнялось';

  @override
  String get historyUnknown => 'Не знаю';

  @override
  String get historyNotApplicable => 'Не применимо';

  @override
  String get historyChooseDate => 'Указать дату';

  @override
  String get historyMileage => 'Пробег при выполнении, км';

  @override
  String get historyKnownHint => 'Укажите хотя бы дату или пробег.';

  @override
  String get historyKnownRequired => 'Укажите дату или корректный пробег.';

  @override
  String historyMileageMax(int mileage) {
    return 'Пробег не может превышать текущий: $mileage км.';
  }

  @override
  String get historySaveError =>
      'Не удалось сохранить историю. Ответы сохранены на экране — повторите попытку.';

  @override
  String get historyUnknownCheckNow =>
      'История неизвестна — рекомендуем проверить/выполнить сейчас';

  @override
  String get specifyHistory => 'Указать историю';

  @override
  String get editHistory => 'Изменить историю';

  @override
  String timeProgress(int percent) {
    return 'По времени использовано $percent% интервала.';
  }

  @override
  String mileageProgress(int percent) {
    return 'По пробегу использовано $percent% интервала.';
  }

  @override
  String dueDate(String date) {
    return 'Следующая дата: $date';
  }

  @override
  String dueMileage(int mileage, String unit) {
    return 'Следующий пробег: $mileage $unit';
  }

  @override
  String lastInspectionDate(String date) {
    return 'Последняя проверка: $date. Процент износа не рассчитывается.';
  }

  @override
  String nextInspectionDue(String due) {
    return 'Следующая проверка: $due';
  }

  @override
  String get refineMileage => 'Уточнить';

  @override
  String get setMileage => 'Указать пробег';

  @override
  String get currentMileage => 'Актуальный пробег';

  @override
  String get mileageDecreaseNotAllowed =>
      'Пробег не может быть меньше текущего значения.';

  @override
  String get mileageUpdateError => 'Не удалось обновить пробег.';

  @override
  String get versionConflict =>
      'Автомобиль изменён на другом устройстве. Обновите данные и повторите.';

  @override
  String get addService => 'Добавить обслуживание';

  @override
  String get addServiceRecord => 'Добавить запись обслуживания';

  @override
  String get serviceRecordFactHint =>
      'Это фактическая запись обслуживания, а не декларация неизвестной истории.';

  @override
  String get serviceDate => 'Дата обслуживания';

  @override
  String get serviceMileage => 'Пробег при обслуживании';

  @override
  String get serviceNote => 'Заметка (необязательно)';

  @override
  String get serviceSaveError =>
      'Не удалось сохранить обслуживание. Проверьте данные и повторите.';

  @override
  String get serviceSaved => 'Обслуживание добавлено';

  @override
  String get lastServiceUnknown => 'Последнее обслуживание: неизвестно';

  @override
  String lastServiceDate(String date) {
    return 'Последнее обслуживание: $date';
  }

  @override
  String lastServiceMileage(int mileage, String unit) {
    return 'при $mileage $unit';
  }

  @override
  String get nowMarker => 'Сейчас';

  @override
  String get nextDue => 'Следующий срок';

  @override
  String get limitingTime => 'Определяющий интервал: время';

  @override
  String get limitingMileage => 'Определяющий интервал: пробег';

  @override
  String get limitingUnknown => 'Определяющий интервал: не определён';

  @override
  String get planLegend => 'Легенда плана';

  @override
  String get legendActionLevel => 'Действие';

  @override
  String get legendBasis => 'Основание';

  @override
  String get actionInfo => 'Информация';

  @override
  String get actionRecommendation => 'Рекомендация';

  @override
  String get actionAttention => 'Внимание';

  @override
  String get actionRequired => 'Требуется действие';

  @override
  String get actionCritical => 'Критично';

  @override
  String get actionInfoExplanation =>
      'Для сведения; сейчас ничего делать не нужно.';

  @override
  String get actionRecommendationExplanation =>
      'Стоит выполнить при удобном случае.';

  @override
  String get actionAttentionExplanation =>
      'Запланируйте это в ближайшее время.';

  @override
  String get actionRequiredExplanation =>
      'Проверьте или выполните без промедления.';

  @override
  String get actionCriticalExplanation =>
      'Действуйте немедленно ради безопасности или надёжности.';

  @override
  String get basisConfirmed => 'Подтверждено';

  @override
  String get basisForecast => 'Прогноз';

  @override
  String get basisMissingData => 'Не хватает данных';

  @override
  String get basisConfirmedExplanation =>
      'Основано на записанных фактах или наблюдениях.';

  @override
  String get basisForecastExplanation =>
      'Явная оценка, а не подтверждённый факт.';

  @override
  String get basisMissingDataExplanation =>
      'Нужна история или фактическая проверка.';

  @override
  String get howSoonLabel => 'Как скоро';

  @override
  String howSoonDays(int days) {
    return '$days дн.';
  }

  @override
  String howSoonKm(int km) {
    return '$km км';
  }

  @override
  String howSoonOverdueDays(int days) {
    return 'просрочено $days дн.';
  }

  @override
  String howSoonOverdueKm(int km) {
    return 'просрочено $km км';
  }

  @override
  String get historyMileageOnly => 'по пробегу';

  @override
  String iconCategorySemantics(String label) {
    return 'Категория: $label';
  }

  @override
  String get serviceTimelineEmpty => 'Записей обслуживания пока нет';

  @override
  String get performed => 'Отметить';

  @override
  String get preliminaryEstimate => 'Предварительная оценка';

  @override
  String forecastAnnualDistance(String label, int distance, String unit) {
    return '$label: $distance $unit/год';
  }

  @override
  String forecastWindow(String from, String to) {
    return 'Ориентировочное окно: $from–$to';
  }

  @override
  String get selectServiceWork => 'Выберите одну работу плана';

  @override
  String get selectServiceWorkHint =>
      'Выберите ровно одну применимую работу плана.';

  @override
  String get wearSpecify => 'Указать износ';

  @override
  String get wearPercent =>
      'Износ, % (0 = нет износа, 100 = полностью изношено)';

  @override
  String wearRemaining(int percent) {
    return 'Остаток: $percent%';
  }

  @override
  String wearMeasured(int percent) {
    return 'Измеренный износ: $percent%';
  }

  @override
  String get wearDate => 'Дата измерения';

  @override
  String get wearSource => 'Источник измерения';

  @override
  String get wearSourceSelf => 'Самостоятельно';

  @override
  String get wearSourceWorkshop => 'Автосервис';

  @override
  String get wearNote => 'Заметка (необязательно)';

  @override
  String get wearValidation => 'Укажите износ от 0 до 100.';

  @override
  String get wearSaveError => 'Не удалось сохранить измерение износа.';

  @override
  String conditionObservationDateSource(String date, String source) {
    return '$date · $source';
  }
}
