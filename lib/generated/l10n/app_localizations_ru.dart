// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SRu extends S {
  SRu([String locale = 'ru']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'Денежный кошелек';

  @override
  String get accountRoleAssetCC => 'Кредитная карта';

  @override
  String get accountRoleAssetDefault => 'Счёт по умолчанию';

  @override
  String get accountRoleAssetSavings => 'Сберегательный счет';

  @override
  String get accountRoleAssetShared => 'Общий основной счёт';

  @override
  String get accountsLabelAsset => 'Счета активов';

  @override
  String get accountsLabelExpense => 'Счета расходов';

  @override
  String get accountsLabelLiabilities => 'Обязательства';

  @override
  String get accountsLabelRevenue => 'Счета учета доходов';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'неделя',
      'monthly': 'месяц',
      'quarterly': 'квартал',
      'halfyear': 'полугодие',
      'yearly': 'год',
      'other': 'неизвестно',
    });
    return '$interest% за $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'еженедельно',
      'monthly': 'ежемесячно',
      'quarterly': 'ежеквартально',
      'halfyear': 'раз в полгода',
      'yearly': 'ежегодно',
      'other': 'неизвестно',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', пропускает $skip раз',
      many: ', пропускает $skip раз',
      few: ', пропускает $skip раза',
      one: ', пропускает $skip раз',
      zero: '',
    );
    return 'Подписка соответствует транзакциям между $minValue и $maxvalue. Повторяется $_temp0$_temp1.';
  }

  @override
  String get billsChangeLayoutTooltip => 'Изменить вид';

  @override
  String get billsChangeSortOrderTooltip => 'Изменить порядок сортировки';

  @override
  String get billsErrorLoading => 'Ошибка при загрузке подписок.';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'еженедельно',
      'monthly': 'ежемесячно',
      'quarterly': 'ежеквартально',
      'halfyear': 'раз в полгода',
      'yearly': 'ежегодно',
      'other': 'неизвестно',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', пропускает $skip раз',
      many: ', пропускает $skip раз',
      few: ', пропускает $skip раза',
      one: ', пропускает $skip раз',
      zero: '',
    );
    return 'Подписка соответствует транзакциям на сумму $value. Повторяется $_temp0$_temp1.';
  }

  @override
  String billsExpectedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Ожидается $dateString';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Еженедельно',
      'monthly': 'Ежемесячно',
      'quarterly': 'Ежеквартально',
      'halfyear': 'Раз в полгода',
      'yearly': 'Ежегодно',
      'other': 'Неизвестно',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Еженедельно',
      'monthly': 'Ежемесячно',
      'quarterly': 'Ежеквартально',
      'halfyear': 'Раз в полгода',
      'yearly': 'Ежегодно',
      'other': 'Неизвестно',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', пропускает $skip раз',
      many: ', пропускает $skip раз',
      few: ', пропускает $skip раза',
      one: ', пропускает $skip раз',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get billsInactive => 'Неактивна';

  @override
  String get billsIsActive => 'Подписка активна';

  @override
  String get billsLayoutGroupSubtitle =>
      'Подписки отображаются в назначенных им группах.';

  @override
  String get billsLayoutGroupTitle => 'Группа';

  @override
  String get billsLayoutListSubtitle =>
      'Подписки отображаются в виде списка, отсортированного по определённым критериям.';

  @override
  String get billsLayoutListTitle => 'Список';

  @override
  String get billsListEmpty => 'Список в настоящее время пуст.';

  @override
  String get billsNextExpectedMatch => 'Следующее ожидаемое совпадение';

  @override
  String get billsNotActive => 'Подписка неактивна';

  @override
  String get billsNotExpected => 'Не ожидается в этот период';

  @override
  String get billsNoTransactions => 'Транзакции не найдены.';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Оплачено $dateString';
  }

  @override
  String get billsSortAlphabetical => 'По алфавиту';

  @override
  String get billsSortByTimePeriod => 'По периоду';

  @override
  String get billsSortFrequency => 'По частоте';

  @override
  String get billsSortName => 'По имени';

  @override
  String get billsUngrouped => 'Без группы';

  @override
  String get billsSettingsShowOnlyActive => 'Показывать только активные';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'Показывает только активные подписки.';

  @override
  String get billsSettingsShowOnlyExpected => 'Показывать только ожидаемые';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'Показывает только те подписки, которые ожидаются (или оплачены) в этом месяце.';

  @override
  String get categoryDeleteConfirm =>
      'Вы уверены, что хотите удалить категорию? Транзакции, входящие в нее, удалены не будут, они просто останутся без категории.';

  @override
  String get categoryErrorLoading => 'Ошибка загрузки категорий.';

  @override
  String get categoryFormLabelIncludeInSum => 'Включить в месячную сумму';

  @override
  String get categoryFormLabelName => 'Название категории';

  @override
  String get categoryMonthNext => 'След. месяц';

  @override
  String get categoryMonthPrev => 'Пред. месяц';

  @override
  String get categorySumExcluded => 'исключено';

  @override
  String get categoryTitleAdd => 'Добавить категорию';

  @override
  String get categoryTitleDelete => 'Удалить категорию';

  @override
  String get categoryTitleEdit => 'Изменить категорию';

  @override
  String get catNone => '<без категории>';

  @override
  String get catOther => 'Прочее';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'Неверный ответ API: $message';
  }

  @override
  String get errorAPIUnavailable => 'API недоступен';

  @override
  String get errorFieldRequired => 'Обязательное поле.';

  @override
  String get errorInvalidURL => 'Неверный URL-адрес';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'Минимально требуемая версия Firefly API $requiredVersion. Пожалуйста, выполните обновление.';
  }

  @override
  String errorStatusCode(int code) {
    return 'Код ошибки: $code';
  }

  @override
  String get errorUnknown => 'Неизвестная ошибка.';

  @override
  String get formButtonHelp => 'Помощь';

  @override
  String get formButtonLogin => 'Вход';

  @override
  String get formButtonLogout => 'Выход';

  @override
  String get formButtonRemove => 'Убрать';

  @override
  String get formButtonResetLogin => 'Сбросить логин';

  @override
  String get formButtonTransactionAdd => 'Добавить транзакцию';

  @override
  String get formButtonTryAgain => 'Попробовать снова';

  @override
  String get generalAccount => 'Аккаунт';

  @override
  String get generalAssets => 'Активы';

  @override
  String get generalBalance => 'Баланс';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Баланс на $dateString';
  }

  @override
  String get generalBill => 'Счет';

  @override
  String get generalBudget => 'Бюджет';

  @override
  String get generalCategory => 'Категория';

  @override
  String get generalCurrency => 'Валюта';

  @override
  String get generalDateRangeCurrentMonth => 'Текущий месяц';

  @override
  String get generalDateRangeLast30Days => 'Последние 30 дней';

  @override
  String get generalDateRangeCurrentYear => 'Текущий год';

  @override
  String get generalDateRangeLastYear => 'Прошлый год';

  @override
  String get generalDateRangeAll => 'Все';

  @override
  String get generalDefault => 'по умолчанию';

  @override
  String get generalDestinationAccount => 'Счет назначения';

  @override
  String get generalDismiss => 'Отмена';

  @override
  String get generalEarned => 'Заработано';

  @override
  String get generalError => 'Ошибка';

  @override
  String get generalExpenses => 'Расходы';

  @override
  String get generalIncome => 'Доходы';

  @override
  String get generalLiabilities => 'Обязательства';

  @override
  String get generalMultiple => 'множественные';

  @override
  String get generalNever => 'никогда';

  @override
  String get generalReconcile => 'Согласованный';

  @override
  String get generalReset => 'Сбросить';

  @override
  String get generalSourceAccount => 'Счет отправителя';

  @override
  String get generalSpent => 'Потрачено';

  @override
  String get generalSum => 'Сумма';

  @override
  String get generalTarget => 'Цель';

  @override
  String get generalUnknown => 'Неизвестно';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'еженедельно',
      'monthly': 'ежемесячно',
      'quarterly': 'ежеквартально',
      'halfyear': 'каждые полгода',
      'yearly': 'ежегодно',
      'other': 'неизвестно',
    });
    return ' ($_temp0)';
  }

  @override
  String get homeMainBillsTitle => 'Счета на следующую неделю';

  @override
  String homeMainBudgetInterval(DateTime from, DateTime to, String period) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString до $toString, $period)';
  }

  @override
  String homeMainBudgetIntervalSingle(DateTime from, DateTime to) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return 'С $fromString до $toString';
  }

  @override
  String homeMainBudgetSum(String current, String status, String available) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'over': 'over',
      'other': 'left from',
    });
    return '$current $_temp0 $available';
  }

  @override
  String get homeMainBudgetTitle => 'Бюджеты за текущий месяц';

  @override
  String get homeMainChartAccountsTitle => 'Сведения об аккаунте';

  @override
  String get homeMainChartCategoriesTitle =>
      'Сводка по категории за текущий месяц';

  @override
  String get homeMainChartDailyAvg => 'Среднее за 7 дней';

  @override
  String get homeMainChartDailyTitle => 'Ежедневная сводка';

  @override
  String get homeMainChartNetEarningsTitle => 'Чистый доход';

  @override
  String get homeMainChartNetWorthTitle => 'Общая средства';

  @override
  String get homeMainChartTagsTitle => 'Сводка по тегам за текущий месяц';

  @override
  String get homePiggyAdjustDialogTitle => 'Сохранить/потратить деньги';

  @override
  String homePiggyDateStart(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Начальная дата: $dateString';
  }

  @override
  String homePiggyDateTarget(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Целевая дата: $dateString';
  }

  @override
  String get homeMainDialogSettingsTitle => 'Настроить панель управления';

  @override
  String homePiggyLinked(String account) {
    return 'Привязано к $account';
  }

  @override
  String get homePiggyNoAccounts => 'Копилки не созданы.';

  @override
  String get homePiggyNoAccountsSubtitle => 'Создайте в веб-интерфейсе!';

  @override
  String homePiggyRemaining(String amount) {
    return 'Осталось накопить: $amount';
  }

  @override
  String homePiggySaved(String amount) {
    return 'Накоплено: $amount';
  }

  @override
  String get homePiggySavedMultiple => 'Накоплено:';

  @override
  String homePiggyTarget(String amount) {
    return 'Целевая сумма: $amount';
  }

  @override
  String get homePiggyAccountStatus => 'Статус счета';

  @override
  String get homePiggyAvailableAmounts => 'Доступные средства';

  @override
  String homePiggyAvailable(String amount) {
    return 'Доступно: $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'В копилках: $amount';
  }

  @override
  String get homeTabLabelBalance => 'Балансовая ведомость';

  @override
  String get homeTabLabelMain => 'Главная';

  @override
  String get homeTabLabelPiggybanks => 'Копилки';

  @override
  String get homeTabLabelTransactions => 'Транзакции';

  @override
  String get homeTransactionsActionFilter => 'Фильтровать список';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<All Accounts>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<All Bills>';

  @override
  String get homeTransactionsDialogFilterBillUnset => '<No Bill set>';

  @override
  String get homeTransactionsDialogFilterBudgetsAll => '<All Budgets>';

  @override
  String get homeTransactionsDialogFilterBudgetUnset => '<No Budget set>';

  @override
  String get homeTransactionsDialogFilterCategoriesAll => '<All Categories>';

  @override
  String get homeTransactionsDialogFilterCategoryUnset => '<No Category set>';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<All Currencies>';

  @override
  String get homeTransactionsDialogFilterDateRange => 'Диапазон дат';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'Показать предстоящие транзакции';

  @override
  String get homeTransactionsDialogFilterSearch => 'Искать термин';

  @override
  String get homeTransactionsDialogFilterTitle => 'Выбрать фильтры';

  @override
  String get homeTransactionsEmpty => 'Транзакции не найдены.';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num категории';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'Показывать теги в списке транзакций';

  @override
  String get liabilityDirectionCredit => 'Мне причитается этот долг';

  @override
  String get liabilityDirectionDebit => 'Я в долгу';

  @override
  String get liabilityTypeDebt => 'Долг';

  @override
  String get liabilityTypeLoan => 'Заём';

  @override
  String get liabilityTypeMortgage => 'Ипотека';

  @override
  String get loginAbout =>
      'Для эффективного использования Waterfly III Вам необходим собственный сервер с установленным Firefly III или аддоном Firefly III для Home Assistant.\n\nПожалуйста, введите полный URL-адрес и персональный ключ доступа (Настройки -> Профиль -> OAuth -> Персональный ключ доступа).';

  @override
  String get loginFormLabelAPIKey => 'Действительный ключ API';

  @override
  String get loginFormLabelHost => 'URL-адрес хоста';

  @override
  String get loginWelcome => 'Добро пожаловать в Waterfly III';

  @override
  String get logoutConfirmation => 'Вы уверены, что хотите выйти?';

  @override
  String get navigationAccounts => 'Аккаунты';

  @override
  String get navigationBills => 'Подписки';

  @override
  String get navigationCategories => 'Категории';

  @override
  String get navigationMain => 'Главное табло';

  @override
  String get generalSettings => 'Настройки';

  @override
  String get no => 'Нет';

  @override
  String numPercent(double num) {
    final intl.NumberFormat numNumberFormat = intl
        .NumberFormat.decimalPercentPattern(
      locale: localeName,
      decimalDigits: 0,
    );
    final String numString = numNumberFormat.format(num);

    return '$numString';
  }

  @override
  String numPercentOf(double perc, String of) {
    final intl.NumberFormat percNumberFormat = intl
        .NumberFormat.decimalPercentPattern(
      locale: localeName,
      decimalDigits: 0,
    );
    final String percString = percNumberFormat.format(perc);

    return '$percString из $of';
  }

  @override
  String get settingsDialogDebugInfo =>
      'Здесь можно включить и отправить журналы отладки. Они плохо влияют на производительность, поэтому не включайте их, если вам не рекомендовано это делать. Отключение регистрации приведет к удалению сохраненного журнала.';

  @override
  String get settingsDialogDebugMailCreate => 'Создать почту';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      'ВНИМАНИЕ: Будет открыт почтовый проект с прикрепленным файлом журнала (в текстовом формате). В журнале может содержаться конфиденциальная информация, например, имя хоста вашего экземпляра Firefly (хотя я стараюсь избегать записи в журнал каких-либо секретов, например, api ключ). Пожалуйста, внимательно прочитайте журнал и вычеркните из него ту информацию, которой вы не хотите делиться и/или которая не имеет отношения к проблеме, о которой вы хотите сообщить.\n\nПожалуйста, не присылайте логи без предварительного согласия на это по почте/GitHub. Я буду удалять любые журналы, присланные без контекста, из соображений конфиденциальности. Никогда не загружайте журнал без цензуры на GitHub или куда-либо еще.';

  @override
  String get settingsDialogDebugSendButton => 'Отправлять логи по почте';

  @override
  String get settingsDialogDebugTitle => 'Отладочные логи';

  @override
  String get settingsDialogLanguageTitle => 'Выберите язык';

  @override
  String get settingsDialogThemeTitle => 'Выберите тему';

  @override
  String get settingsFAQ => 'Часто задаваемые вопросы';

  @override
  String get settingsFAQHelp =>
      'Открывается в браузере. Доступно только на английском языке.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configure offline sync and mobile data usage';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLockscreen => 'Экран блокировки';

  @override
  String get settingsLockscreenHelp =>
      'Требовать аутентификацию при запуске приложения';

  @override
  String get settingsLockscreenInitial =>
      'Пожалуйста, авторизуйтесь, чтобы включить экран блокировки.';

  @override
  String get settingsNLAppAccount => 'Аккаунт по умолчанию';

  @override
  String get settingsNLAppAccountDynamic => '<Dynamic>';

  @override
  String get settingsNLAppAdd => 'Добавить приложение';

  @override
  String get settingsNLAppAddHelp =>
      'Нажмите, чтобы добавить приложение для прослушивания. В списке будут отображаться только подходящие приложения.';

  @override
  String get settingsNLAppAddInfo =>
      'Сделайте несколько транзакций, в которых Вы должны получить уведомление на телефон, для добавления приложения в этот лист. Если приложение до сих пор не отображается, пожалуйста, сообщите нам на app@vogt.pw.';

  @override
  String get settingsNLAutoAdd => 'Создавать транзакцию без подтверждения';

  @override
  String get settingsNLDescription =>
      'Данный сервис позволяет получать данные о транзакциях из входящих push-уведомлений. Кроме того, можно выбрать счет по умолчанию, к которому должна быть отнесена транзакция, - если значение не задано, он пытается извлечь счет из уведомления.';

  @override
  String get settingsNLEmptyNote => 'Оставлять поле заметки пустым';

  @override
  String get settingsNLPermissionGrant => 'Нажмите для подтверждения.';

  @override
  String get settingsNLPermissionNotGranted => 'Разрешение не было получено.';

  @override
  String get settingsNLPermissionRemove => 'Удалить разрешение?';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'Чтобы отключить эту службу, кликните на приложение и удалите разрешения на следующем экране.';

  @override
  String get settingsNLPrefillTXTitle =>
      'Заполнить заголовок транзакции, используя заголовок уведомления';

  @override
  String get settingsNLServiceChecking => 'Проверка статуса…';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'Ошибка проверки статуса: $error';
  }

  @override
  String get settingsNLServiceRunning => 'Сервис запущен.';

  @override
  String get settingsNLServiceStatus => 'Статус сервиса';

  @override
  String get settingsNLServiceStopped => 'Сервис остановлен.';

  @override
  String get settingsNotificationListener => 'Сервис прослушивания уведомлений';

  @override
  String get settingsTheme => 'Тема приложения';

  @override
  String get settingsThemeDynamicColors => 'Динамические цвета';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'Темная',
      'light': 'Светлая',
      'other': 'Системная',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone => 'Использовать часовой пояс сервера';

  @override
  String get settingsUseServerTimezoneHelp =>
      'Показывать время по часовому поясу сервера. Имитирует веб-интерфейс.';

  @override
  String get settingsVersion => 'Версия приложения';

  @override
  String get settingsVersionChecking => 'проверка…';

  @override
  String get transactionAttachments => 'Вложения';

  @override
  String get transactionDeleteConfirm =>
      'Вы уверены, что хотите удалить эту транзакцию?';

  @override
  String get transactionDialogAttachmentsDelete => 'Удалить вложение';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      'Вы уверены что хотите удалить это вложение?';

  @override
  String get transactionDialogAttachmentsErrorDownload =>
      'Не удалось скачать файл.';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'Не удалось открыть файл: $error';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'Не удалось загрузить файл: $error';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'Вложения';

  @override
  String get transactionDialogBillNoBill => 'Нет счета';

  @override
  String get transactionDialogBillTitle => 'Ссылка на счет';

  @override
  String get transactionDialogCurrencyTitle => 'Выбор валюты';

  @override
  String get transactionDialogPiggyNoPiggy => 'Нет копилки';

  @override
  String get transactionDialogPiggyTitle => 'Привязать к копилке';

  @override
  String get transactionDialogTagsAdd => 'Добавить тег';

  @override
  String get transactionDialogTagsHint => 'Искать/Добавить тег';

  @override
  String get transactionDialogTagsTitle => 'Выбрать теги';

  @override
  String get transactionDuplicate => 'Дубликат';

  @override
  String get transactionErrorInvalidAccount => 'Недействительный аккаунт';

  @override
  String get transactionErrorInvalidBudget => 'Неверный бюджет';

  @override
  String get transactionErrorNoAccounts => 'Пожалуйста, сначала укажите счета.';

  @override
  String get transactionErrorNoAssetAccount =>
      'Пожалуйста, выберите счёт актива.';

  @override
  String get transactionErrorTitle => 'Пожалуйста, укажите заголовок.';

  @override
  String get transactionFormLabelAccountDestination => 'Счет назначения';

  @override
  String get transactionFormLabelAccountForeign => 'Внешний счет';

  @override
  String get transactionFormLabelAccountOwn => 'Собственный аккаунт';

  @override
  String get transactionFormLabelAccountSource => 'Исходный аккаунт';

  @override
  String get transactionFormLabelNotes => 'Примечания';

  @override
  String get transactionFormLabelTags => 'Теги';

  @override
  String get transactionFormLabelTitle => 'Название транзакции';

  @override
  String get transactionSplitAdd => 'Добавить разделенную транзакцию';

  @override
  String get transactionSplitChangeCurrency => 'Изменить раздельную валюту';

  @override
  String get transactionSplitChangeDestinationAccount =>
      'Изменить счёт назначения для разделения';

  @override
  String get transactionSplitChangeSourceAccount =>
      'Изменить исходный счёт для разделения';

  @override
  String get transactionSplitChangeTarget =>
      'Изменение раздельного целевого счета';

  @override
  String get transactionSplitDelete => 'Удалить разделение';

  @override
  String get transactionTitleAdd => 'Добавить транзакцию';

  @override
  String get transactionTitleDelete => 'Удалить транзакцию';

  @override
  String get transactionTitleEdit => 'Редактировать транзакцию';

  @override
  String get transactionTypeDeposit => 'Депозит';

  @override
  String get transactionTypeTransfer => 'Перемещение';

  @override
  String get transactionTypeWithdrawal => 'Вывод средств';

  @override
  String get notificationCreateTransactionTitle => 'Create Transaction?';

  @override
  String notificationCreateTransactionBody(String source) {
    return 'Click to create a transaction based on the notification from $source';
  }

  @override
  String get notificationExtractTransactionChannelName =>
      'Create Transaction from Notification';

  @override
  String get notificationExtractTransactionChannelDescription =>
      'Notification asking to create a transaction from another notification.';

  @override
  String generalSyncEntity(String entity) {
    return 'Sync $entity';
  }

  @override
  String generalSyncComplete(String entity, int count) {
    return 'Synced $count $entity';
  }

  @override
  String generalSyncFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get generalOffline => 'Offline';

  @override
  String get generalOfflineMessage => 'You are offline. Connect to sync.';

  @override
  String get generalSyncNotAvailable => 'Sync service not available';

  @override
  String get generalBackOnline => 'Back online';

  @override
  String get generalOfflineModeWifiOnly => 'Offline mode (WiFi only)';

  @override
  String get generalCheckingConnection => 'Checking connection...';

  @override
  String get generalNetworkStatus => 'Network Status';

  @override
  String get generalAppStatus => 'App Status';

  @override
  String get generalOnline => 'Online';

  @override
  String get generalNetwork => 'Network';

  @override
  String get generalNoConnection => 'No connection';

  @override
  String get generalWifiOnlyModeEnabled =>
      'WiFi-only mode is enabled. Mobile data is disabled. Connect to WiFi to use online features.';

  @override
  String get generalOfflineFeaturesLimited =>
      'Some features may be limited while offline. Data will sync automatically when connection is restored.';

  @override
  String get generalAllFeaturesAvailable => 'All features are available.';

  @override
  String get generalConnectionRestored => 'Connection restored!';

  @override
  String get generalStillOffline =>
      'Still offline. Please check your network settings.';

  @override
  String get generalFailedToCheckConnectivity => 'Failed to check connectivity';

  @override
  String get generalRetry => 'Retry';

  @override
  String get incrementalSyncStatsTitle => 'Sync Statistics';

  @override
  String incrementalSyncStatsDescription(int count) {
    return '$count incremental syncs performed';
  }

  @override
  String get incrementalSyncStatsDescriptionEmpty =>
      'Track sync efficiency and bandwidth savings';

  @override
  String get incrementalSyncStatsRefresh => 'Refresh statistics';

  @override
  String get incrementalSyncStatsNoData => 'No Sync Statistics Yet';

  @override
  String get incrementalSyncStatsNoDataDesc =>
      'Statistics will appear here after your first incremental sync.';

  @override
  String get incrementalSyncStatsNoDataYet => 'No incremental sync data yet';

  @override
  String get incrementalSyncStatsNoDataAvailable => 'No sync data available';

  @override
  String get incrementalSyncStatsEfficiencyExcellent => 'Excellent Efficiency';

  @override
  String get incrementalSyncStatsEfficiencyGood => 'Good Efficiency';

  @override
  String get incrementalSyncStatsEfficiencyModerate => 'Moderate Efficiency';

  @override
  String get incrementalSyncStatsEfficiencyLow => 'Low Efficiency';

  @override
  String get incrementalSyncStatsEfficiencyVeryLow => 'Very Low Efficiency';

  @override
  String get incrementalSyncStatsEfficiencyDescExcellent =>
      'Most data unchanged - incremental sync is very effective!';

  @override
  String get incrementalSyncStatsEfficiencyDescGood =>
      'Good savings - incremental sync is working well.';

  @override
  String get incrementalSyncStatsEfficiencyDescModerate =>
      'Moderate changes detected - some bandwidth saved.';

  @override
  String get incrementalSyncStatsEfficiencyDescLow =>
      'Many changes - consider adjusting sync window.';

  @override
  String get incrementalSyncStatsEfficiencyDescVeryLow =>
      'Most data changed - incremental sync provides minimal benefit.';

  @override
  String get incrementalSyncStatsLabelFetched => 'Fetched';

  @override
  String get incrementalSyncStatsLabelUpdated => 'Updated';

  @override
  String get incrementalSyncStatsLabelSkipped => 'Skipped';

  @override
  String get incrementalSyncStatsLabelSaved => 'Saved';

  @override
  String get incrementalSyncStatsLabelSyncs => 'Syncs';

  @override
  String get incrementalSyncStatsLabelBandwidthSaved => 'Bandwidth Saved';

  @override
  String get incrementalSyncStatsLabelApiCallsSaved => 'API Calls Saved';

  @override
  String get incrementalSyncStatsLabelUpdateRate => 'Update Rate';

  @override
  String get incrementalSyncStatsCurrentSync => 'Current Sync';

  @override
  String incrementalSyncStatsDuration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get incrementalSyncStatsStatusSuccess => 'Status: Success';

  @override
  String get incrementalSyncStatsStatusFailed => 'Status: Failed';

  @override
  String incrementalSyncStatsError(String error) {
    return 'Error: $error';
  }

  @override
  String get incrementalSyncStatsByEntityType => 'By Entity Type:';

  @override
  String incrementalSyncStatsEfficient(String rate) {
    return '$rate% efficient';
  }

  @override
  String get offlineBannerTitle => 'You\'re offline';

  @override
  String get offlineBannerMessage => 'Changes will sync when online.';

  @override
  String get offlineBannerLearnMore => 'Learn More';

  @override
  String get offlineBannerDismiss => 'Dismiss';

  @override
  String get offlineBannerSemanticLabel =>
      'You are offline. Changes will sync when you are back online. Swipe to dismiss or tap Learn More for details.';

  @override
  String get transactionOfflineMode => 'Offline Mode';

  @override
  String get transactionOfflineSaveNew =>
      'Transaction will be saved locally and synced when online';

  @override
  String get transactionOfflineSaveEdit =>
      'Changes will be saved locally and synced when online';

  @override
  String get transactionSaveOffline => 'Save Offline';

  @override
  String get transactionSave => 'Save';

  @override
  String get transactionSavedSynced => 'Transaction saved and synced';

  @override
  String get transactionSavedOffline =>
      'Transaction saved offline. Will sync when online.';

  @override
  String get transactionSaved => 'Transaction saved';

  @override
  String get syncStatusSynced => 'Synced';

  @override
  String get syncStatusSyncing => 'Syncing...';

  @override
  String syncStatusPending(int count) {
    return '$count items pending';
  }

  @override
  String get syncStatusFailed => 'Sync failed';

  @override
  String get syncStatusOffline => 'Offline';

  @override
  String get syncStatusJustNow => 'Just now';

  @override
  String syncStatusMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String syncStatusHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String syncStatusDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get syncStatusOverWeekAgo => 'Over a week ago';

  @override
  String get syncActionSyncNow => 'Sync now';

  @override
  String get syncActionForceFullSync => 'Force full sync';

  @override
  String get syncActionViewStatus => 'View sync status';

  @override
  String get syncActionSettings => 'Sync settings';

  @override
  String get syncStarted => 'Sync started';

  @override
  String get syncFullStarted => 'Full sync started';

  @override
  String syncFailedToStart(String error) {
    return 'Failed to start sync: $error';
  }

  @override
  String syncFailedToStartFull(String error) {
    return 'Failed to start full sync: $error';
  }

  @override
  String get syncServiceNotAvailable =>
      'Sync service not available. Please restart the app.';

  @override
  String get syncProgressProviderNotAvailable =>
      'Sync Status Provider Not Available';

  @override
  String get syncProgressProviderNotAvailableDesc =>
      'Please restart the app to enable sync progress tracking.';

  @override
  String get syncProgressServiceUnavailable => 'Sync Service Unavailable';

  @override
  String get syncProgressServiceUnavailableDesc =>
      'Sync Status Provider is not available. Please restart the app.';

  @override
  String get syncProgressCancel => 'Cancel';

  @override
  String get syncProgressFailed => 'Sync Failed';

  @override
  String get syncProgressComplete => 'Sync Complete';

  @override
  String get syncProgressSyncing => 'Syncing...';

  @override
  String incrementalSyncCacheCurrent(String ttl) {
    return 'Current: $ttl';
  }

  @override
  String syncStatusProgressComplete(String percentage) {
    return '$percentage% complete';
  }

  @override
  String syncProgressSuccessfullySynced(int count) {
    return 'Successfully synced $count operations';
  }

  @override
  String syncProgressConflictsDetected(int count) {
    return '$count conflicts detected';
  }

  @override
  String syncProgressOperationsFailed(int count) {
    return '$count operations failed';
  }

  @override
  String syncProgressOperationsCount(int completed, int total) {
    return '$completed/$total operations';
  }

  @override
  String get syncProgressSyncingOperations => 'Syncing operations...';

  @override
  String get syncProgressPreparing => 'Preparing...';

  @override
  String get syncProgressDetectingConflicts => 'Detecting conflicts...';

  @override
  String get syncProgressResolvingConflicts => 'Resolving conflicts...';

  @override
  String get syncProgressPullingUpdates => 'Pulling updates...';

  @override
  String get syncProgressFinalizing => 'Finalizing...';

  @override
  String get syncProgressCompleted => 'Completed';

  @override
  String syncStatusSyncingCount(int synced, int total) {
    return 'Syncing... $synced of $total';
  }

  @override
  String get listViewOfflineFilterPending => 'Pending';

  @override
  String listViewOfflineNoDataAvailable(String entityType) {
    return 'No $entityType Available';
  }

  @override
  String listViewOfflineNoDataMessage(String entityType) {
    return 'You are offline. $entityType will appear here when you connect to the internet.';
  }

  @override
  String listViewOfflineLastUpdated(String age) {
    return 'Last updated $age';
  }

  @override
  String get dashboardOfflineIncludesUnsynced => 'Includes unsynced data';

  @override
  String dashboardOfflineDataAsOf(String age) {
    return 'Data as of $age';
  }

  @override
  String get dashboardOfflineUnsynced => 'Unsynced';

  @override
  String get dashboardOfflineViewingOfflineData =>
      'Viewing offline data. Some information may be outdated.';

  @override
  String dashboardOfflineNoDataAvailable(String dataType) {
    return 'No $dataType Available';
  }

  @override
  String dashboardOfflineConnectToLoad(String dataType) {
    return 'Connect to the internet to load $dataType';
  }

  @override
  String dashboardOfflineDataOutdated(String age) {
    return 'Data may be outdated. Last updated $age.';
  }

  @override
  String get generalNetworkTypeWifi => 'WiFi';

  @override
  String get generalNetworkTypeMobile => 'Mobile Data';

  @override
  String get generalNetworkTypeEthernet => 'Ethernet';

  @override
  String get generalNetworkTypeVpn => 'VPN';

  @override
  String get generalNetworkTypeBluetooth => 'Bluetooth';

  @override
  String get generalNetworkTypeOther => 'Other';

  @override
  String get generalNetworkTypeNone => 'None';

  @override
  String get generalNetworkTypeSeparator => '+';

  @override
  String get offlineSettingsTitle => 'Offline Mode Settings';

  @override
  String get offlineSettingsHelp => 'Help';

  @override
  String get offlineSettingsSynchronization => 'Synchronization';

  @override
  String get offlineSettingsAutoSync => 'Auto-sync';

  @override
  String get offlineSettingsAutoSyncDesc => 'Automatically sync in background';

  @override
  String get offlineSettingsAutoSyncEnabled => 'Auto-sync enabled';

  @override
  String get offlineSettingsAutoSyncDisabled => 'Auto-sync disabled';

  @override
  String get offlineSettingsSyncInterval => 'Sync interval';

  @override
  String get offlineSettingsWifiOnly => 'WiFi only';

  @override
  String get offlineSettingsWifiOnlyDesc => 'Sync only when connected to WiFi';

  @override
  String get offlineSettingsWifiOnlyEnabled => 'WiFi-only sync enabled';

  @override
  String get offlineSettingsWifiOnlyDisabled => 'WiFi-only sync disabled';

  @override
  String offlineSettingsLastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String offlineSettingsNextSync(String time) {
    return 'Next sync: $time';
  }

  @override
  String get offlineSettingsConflictResolution => 'Conflict Resolution';

  @override
  String get offlineSettingsResolutionStrategy => 'Resolution strategy';

  @override
  String get offlineSettingsStorage => 'Storage';

  @override
  String get offlineSettingsDatabaseSize => 'Database size';

  @override
  String get offlineSettingsClearCache => 'Clear cache';

  @override
  String get offlineSettingsClearCacheDesc => 'Remove temporary data';

  @override
  String get offlineSettingsClearAllData => 'Clear all data';

  @override
  String get offlineSettingsClearAllDataDesc => 'Remove all offline data';

  @override
  String get offlineSettingsStatistics => 'Statistics';

  @override
  String get offlineSettingsTotalSyncs => 'Total syncs';

  @override
  String get offlineSettingsConflicts => 'Conflicts';

  @override
  String get offlineSettingsErrors => 'Errors';

  @override
  String get offlineSettingsSuccessRate => 'Success rate';

  @override
  String get offlineSettingsActions => 'Actions';

  @override
  String get offlineSettingsSyncing => 'Syncing...';

  @override
  String get offlineSettingsSyncNow => 'Sync now';

  @override
  String get offlineSettingsForceFullSync => 'Force full sync';

  @override
  String get offlineSettingsCheckConsistency => 'Check consistency';

  @override
  String get offlineSettingsChecking => 'Checking...';

  @override
  String get offlineSettingsSyncIntervalTitle => 'Sync Interval';

  @override
  String offlineSettingsSyncIntervalSet(String interval) {
    return 'Sync interval set to $interval';
  }

  @override
  String get offlineSettingsConflictStrategyTitle =>
      'Conflict Resolution Strategy';

  @override
  String offlineSettingsConflictStrategySet(String strategy) {
    return 'Conflict strategy set to $strategy';
  }

  @override
  String get offlineSettingsClearCacheTitle => 'Clear Cache';

  @override
  String get offlineSettingsClearCacheMessage =>
      'This will remove temporary data. Your offline data will be preserved.';

  @override
  String get offlineSettingsClearAllDataTitle => 'Clear All Data';

  @override
  String get offlineSettingsClearAllDataMessage =>
      'This will remove ALL offline data. This action cannot be undone. You will need to sync again to use offline mode.';

  @override
  String get offlineSettingsCacheCleared => 'Cache cleared';

  @override
  String get offlineSettingsAllDataCleared => 'All offline data cleared';

  @override
  String get offlineSettingsPerformingSync => 'Performing sync...';

  @override
  String get offlineSettingsPerformingIncrementalSync =>
      'Performing incremental sync...';

  @override
  String get offlineSettingsPerformingFullSync => 'Performing full sync...';

  @override
  String get offlineSettingsIncrementalSyncCompleted =>
      'Incremental sync completed successfully';

  @override
  String offlineSettingsIncrementalSyncIssues(String error) {
    return 'Incremental sync completed with issues: $error';
  }

  @override
  String get offlineSettingsForceFullSyncTitle => 'Force Full Sync';

  @override
  String get offlineSettingsForceFullSyncMessage =>
      'This will download all data from the server, replacing local data. This may take several minutes.';

  @override
  String get offlineSettingsConsistencyCheckComplete =>
      'Consistency Check Complete';

  @override
  String get offlineSettingsConsistencyCheckNoIssues =>
      'No issues found. Your data is consistent.';

  @override
  String offlineSettingsConsistencyCheckIssuesFound(int count) {
    return '$count issue(s) found.';
  }

  @override
  String get offlineSettingsConsistencyCheckIssueBreakdown =>
      'Issue breakdown:';

  @override
  String offlineSettingsConsistencyCheckMoreIssues(int count) {
    return '... and $count more';
  }

  @override
  String get offlineSettingsRepairInconsistencies => 'Repair Inconsistencies';

  @override
  String get offlineSettingsRepairInconsistenciesMessage =>
      'This will attempt to automatically fix detected issues. Some issues may require manual intervention.';

  @override
  String get offlineSettingsRepairComplete => 'Repair Complete';

  @override
  String offlineSettingsRepairCompleteMessage(int repaired, int failed) {
    return '$repaired issue(s) repaired.\n$failed issue(s) could not be repaired.';
  }

  @override
  String get offlineSettingsHelpTitle => 'Offline Mode Help';

  @override
  String get offlineSettingsHelpAutoSync => 'Auto-sync';

  @override
  String get offlineSettingsHelpAutoSyncDesc =>
      'Automatically synchronize data in the background at the specified interval.';

  @override
  String get offlineSettingsHelpWifiOnly => 'WiFi Only';

  @override
  String get offlineSettingsHelpWifiOnlyDesc =>
      'Only sync when connected to WiFi to save mobile data.';

  @override
  String get offlineSettingsHelpConflictResolution => 'Conflict Resolution';

  @override
  String get offlineSettingsHelpConflictResolutionDesc =>
      'Choose how to handle conflicts when the same data is modified both locally and on the server.';

  @override
  String get offlineSettingsHelpConsistencyCheck => 'Consistency Check';

  @override
  String get offlineSettingsHelpConsistencyCheckDesc =>
      'Verify data integrity and fix any inconsistencies in the local database.';

  @override
  String get offlineSettingsStrategyLocalWins => 'Local Wins';

  @override
  String get offlineSettingsStrategyRemoteWins => 'Remote Wins';

  @override
  String get offlineSettingsStrategyLastWriteWins => 'Last Write Wins';

  @override
  String get offlineSettingsStrategyManual => 'Manual Resolution';

  @override
  String get offlineSettingsStrategyMerge => 'Merge Changes';

  @override
  String get offlineSettingsStrategyLocalWinsDesc =>
      'Always keep local changes';

  @override
  String get offlineSettingsStrategyRemoteWinsDesc =>
      'Always keep server changes';

  @override
  String get offlineSettingsStrategyLastWriteWinsDesc =>
      'Keep most recently modified version';

  @override
  String get offlineSettingsStrategyManualDesc =>
      'Manually resolve each conflict';

  @override
  String get offlineSettingsStrategyMergeDesc =>
      'Automatically merge non-conflicting changes';

  @override
  String get offlineSettingsJustNow => 'Just now';

  @override
  String offlineSettingsMinutesAgo(int minutes) {
    return '$minutes minutes ago';
  }

  @override
  String offlineSettingsHoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String offlineSettingsDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get offlineSettingsFailedToUpdateAutoSync =>
      'Failed to update auto-sync setting';

  @override
  String get offlineSettingsFailedToUpdateWifiOnly =>
      'Failed to update WiFi-only setting';

  @override
  String get offlineSettingsFailedToUpdateSyncInterval =>
      'Failed to update sync interval';

  @override
  String get offlineSettingsFailedToUpdateConflictStrategy =>
      'Failed to update conflict strategy';

  @override
  String offlineSettingsFailedToClearCache(String error) {
    return 'Failed to clear cache: $error';
  }

  @override
  String get offlineSettingsFailedToClearData => 'Failed to clear data';

  @override
  String offlineSettingsSyncFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String offlineSettingsFullSyncFailed(String error) {
    return 'Full sync failed: $error';
  }

  @override
  String offlineSettingsConsistencyCheckFailed(String error) {
    return 'Consistency check failed: $error';
  }

  @override
  String offlineSettingsRepairFailed(String error) {
    return 'Repair failed: $error';
  }

  @override
  String get offlineSettingsIncrementalSyncNotAvailable =>
      'Incremental sync not available. Please perform a full sync first.';

  @override
  String offlineSettingsIncrementalSyncFailed(String error) {
    return 'Incremental sync failed: $error';
  }

  @override
  String get offlineSettingsSyncServiceNotAvailable =>
      'Sync service not available. Please restart the app.';

  @override
  String offlineSettingsFailedToGetSyncService(String error) {
    return 'Failed to get sync service: $error';
  }

  @override
  String get offlineSettingsIncrementalSyncServiceNotAvailable =>
      'Incremental sync service not available';

  @override
  String get offlineSettingsDismiss => 'Dismiss';

  @override
  String get offlineSettingsSyncIntervalManual => 'Manual';

  @override
  String get offlineSettingsSyncInterval15Minutes => '15 minutes';

  @override
  String get offlineSettingsSyncInterval30Minutes => '30 minutes';

  @override
  String get offlineSettingsSyncInterval1Hour => '1 hour';

  @override
  String get offlineSettingsSyncInterval6Hours => '6 hours';

  @override
  String get offlineSettingsSyncInterval12Hours => '12 hours';

  @override
  String get offlineSettingsSyncInterval24Hours => '24 hours';

  @override
  String get incrementalSyncTitle => 'Incremental Sync';

  @override
  String get incrementalSyncDescription =>
      'Optimize sync performance by fetching only changed data';

  @override
  String get incrementalSyncEnable => 'Enable Incremental Sync';

  @override
  String get incrementalSyncEnabledDesc =>
      'Fetch only changed data since last sync (70-80% faster)';

  @override
  String get incrementalSyncDisabledDesc =>
      'Full sync fetches all data each time';

  @override
  String get incrementalSyncEnabled => 'Incremental sync enabled';

  @override
  String get incrementalSyncDisabled => 'Incremental sync disabled';

  @override
  String get incrementalSyncFailedToUpdate => 'Failed to update setting';

  @override
  String get incrementalSyncWindow => 'Sync Window';

  @override
  String get incrementalSyncWindowDesc => 'How far back to look for changes';

  @override
  String incrementalSyncWindowSet(String window) {
    return 'Sync window set to $window';
  }

  @override
  String get incrementalSyncWindowFailed => 'Failed to update sync window';

  @override
  String get incrementalSyncCacheDuration => 'Cache Duration';

  @override
  String get incrementalSyncCacheDurationDesc =>
      'How long to cache categories, bills, and piggy banks before refreshing. These entities change infrequently, so longer cache durations reduce API calls.';

  @override
  String get incrementalSyncCacheDurationFailed =>
      'Failed to update cache duration';

  @override
  String get incrementalSyncLastIncremental => 'Last Incremental Sync';

  @override
  String get incrementalSyncLastFull => 'Last Full Sync';

  @override
  String get incrementalSyncNever => 'Never';

  @override
  String get incrementalSyncToday => 'Today';

  @override
  String incrementalSyncDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get incrementalSyncFullSyncRecommended => 'Full Sync Recommended';

  @override
  String get incrementalSyncFullSyncRecommendedDesc =>
      'It\'s been more than 7 days since the last full sync. A full sync is recommended to ensure data integrity.';

  @override
  String get incrementalSyncIncrementalButton => 'Incremental Sync';

  @override
  String get incrementalSyncFullButton => 'Full Sync';

  @override
  String get incrementalSyncResetStatistics => 'Reset Statistics';

  @override
  String get incrementalSyncResetting => 'Resetting...';

  @override
  String get incrementalSyncResetStatisticsTitle => 'Reset Statistics';

  @override
  String get incrementalSyncResetStatisticsMessage =>
      'This will clear all incremental sync statistics (items fetched, bandwidth saved, etc.).\n\nSettings will be preserved. This action cannot be undone.';

  @override
  String get incrementalSyncResetStatisticsSuccess =>
      'Statistics reset successfully';

  @override
  String get incrementalSyncResetStatisticsFailed =>
      'Failed to reset statistics';

  @override
  String get incrementalSyncWindowLabel => 'Sync window: ';

  @override
  String get incrementalSyncFullSyncEnabled => 'Full sync enabled';

  @override
  String incrementalSyncWindowDays(int days) {
    return '$days days';
  }

  @override
  String incrementalSyncCacheHours(int hours) {
    return '$hours hours';
  }

  @override
  String get incrementalSyncWindowWord => 'window';
}
