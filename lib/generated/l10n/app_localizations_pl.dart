// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class SPl extends S {
  SPl([String locale = 'pl']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'Portfel gotówkowy';

  @override
  String get accountRoleAssetCC => 'Karta kredytowa';

  @override
  String get accountRoleAssetDefault => 'Domyślne konto aktywów';

  @override
  String get accountRoleAssetSavings => 'Konto oszczędnościowe';

  @override
  String get accountRoleAssetShared => 'Współdzielone konto aktywów';

  @override
  String get accountsLabelAsset => 'Konta aktywów';

  @override
  String get accountsLabelExpense => 'Konta wydatków';

  @override
  String get accountsLabelLiabilities => 'Zobowiązania';

  @override
  String get accountsLabelRevenue => 'Konta przychodów';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'tydzień',
      'monthly': 'miesiąc',
      'quarterly': 'kwartał',
      'halfyear': 'pół roku',
      'yearly': 'rok',
      'other': 'nieznany',
    });
    return '$interest% odsetek za $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Tygodniowo',
      'monthly': 'Miesięcznie',
      'quarterly': 'Kwartalnie',
      'halfyear': 'Półrocznie',
      'yearly': 'Rocznie',
      'other': 'Nieznany',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', pomiń $skip',
      zero: '',
    );
    return 'Subskrypcja odpowiada transakcjom pomiędzy $minValue, a $maxvalue. Powtarza się $_temp0$_temp1';
  }

  @override
  String get billsChangeLayoutTooltip => 'Zmień układ';

  @override
  String get billsChangeSortOrderTooltip => 'Zmień kolejność sortowania';

  @override
  String get billsErrorLoading => 'Błąd podczas ładowania subskrypcji.';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Tygodniowo',
      'monthly': 'Miesięcznie',
      'quarterly': 'Kwartalnie',
      'halfyear': 'Półrocznie',
      'yearly': 'Rocznie',
      'other': 'Nieznany',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', pomiń $skip',
      zero: '',
    );
    return 'Subskrypcja odpowiada transakcjom z $value. Powtarza się $_temp0$_temp1';
  }

  @override
  String billsExpectedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Oczekiwany $dateString';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Tygodniowo',
      'monthly': 'miesięcznie',
      'quarterly': 'Kwartalnie',
      'halfyear': 'Półrocznie',
      'yearly': 'rocznie',
      'other': 'Nieznany',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Tygodniowo',
      'monthly': 'Miesięcznie',
      'quarterly': 'Kwartalnie',
      'halfyear': 'Półrocznie',
      'yearly': 'Rocznie',
      'other': 'Nieznany',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', pomiń $skip',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get billsInactive => 'Nieaktywny';

  @override
  String get billsIsActive => 'Subskrypcja aktywna';

  @override
  String get billsLayoutGroupSubtitle =>
      'Subskrypcje wyświetlane w przypisanych im grupach.';

  @override
  String get billsLayoutGroupTitle => 'Grupa';

  @override
  String get billsLayoutListSubtitle =>
      'Subskrypcje wyświetlane na liście posortowanej według określonych kryteriów.';

  @override
  String get billsLayoutListTitle => 'Lista';

  @override
  String get billsListEmpty => 'Lista jest obecnie pusta.';

  @override
  String get billsNextExpectedMatch => 'Następne oczekiwane dopasowanie';

  @override
  String get billsNotActive => 'Subskrypcja nieaktywna';

  @override
  String get billsNotExpected => 'Nie oczekiwany w tym okresie';

  @override
  String get billsNoTransactions => 'Nie znaleziono transakcji.';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Zapłacone $dateString';
  }

  @override
  String get billsSortAlphabetical => 'Alfabetycznie';

  @override
  String get billsSortByTimePeriod => 'Według okresu';

  @override
  String get billsSortFrequency => 'Częstotliwość';

  @override
  String get billsSortName => 'Nazwa';

  @override
  String get billsUngrouped => 'Niezgrupowane';

  @override
  String get billsSettingsShowOnlyActive => 'Pokaż tylko aktywne';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'Pokazuje tylko aktywne subskrypcje.';

  @override
  String get billsSettingsShowOnlyExpected => 'Pokaż tylko oczekiwane';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'Pokazuje tylko te subskrypcje, które są oczekiwane (lub opłacone) w tym miesiącu.';

  @override
  String get categoryDeleteConfirm =>
      'Czy na pewno chcesz usunąć tę kategorię? Transakcje nie zostaną usunięte, ale nie będą już posiadały kategorii.';

  @override
  String get categoryErrorLoading => 'Błąd podczas ładowania kategorii.';

  @override
  String get categoryFormLabelIncludeInSum => 'Uwzględnij w sumie miesięcznej';

  @override
  String get categoryFormLabelName => 'Nazwa Kategorii';

  @override
  String get categoryMonthNext => 'Następny Miesiąc';

  @override
  String get categoryMonthPrev => 'Poprzedni Miesiąc';

  @override
  String get categorySumExcluded => 'wykluczone';

  @override
  String get categoryTitleAdd => 'Dodaj Kategorię';

  @override
  String get categoryTitleDelete => 'Usuń kategorię';

  @override
  String get categoryTitleEdit => 'Edytuj Kategorię';

  @override
  String get catNone => '<Bez kategorii><no category>';

  @override
  String get catOther => 'Inne';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'Nieprawidłowa odpowiedź od API: $message';
  }

  @override
  String get errorAPIUnavailable => 'API niedostępne';

  @override
  String get errorFieldRequired => 'To pole jest wymagane.';

  @override
  String get errorInvalidURL => 'Nieprawidłowy adres URL';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'Wymagana minimalna wersja API Firefly v$requiredVersion. Proszę zaktualizować.';
  }

  @override
  String errorStatusCode(int code) {
    return 'Kod statusu: $code';
  }

  @override
  String get errorUnknown => 'Nieznany błąd.';

  @override
  String get formButtonHelp => 'Pomoc';

  @override
  String get formButtonLogin => 'Zaloguj się';

  @override
  String get formButtonLogout => 'Wyloguj się';

  @override
  String get formButtonRemove => 'Usuń';

  @override
  String get formButtonResetLogin => 'Resetuj logowanie';

  @override
  String get formButtonTransactionAdd => 'Dodaj transakcję';

  @override
  String get formButtonTryAgain => 'Spróbuj ponownie';

  @override
  String get generalAccount => 'Konto';

  @override
  String get generalAssets => 'Aktywa';

  @override
  String get generalBalance => 'Saldo';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Saldo na $dateString';
  }

  @override
  String get generalBill => 'Rachunek';

  @override
  String get generalBudget => 'Budżet';

  @override
  String get generalCategory => 'Kategoria';

  @override
  String get generalCurrency => 'Waluta';

  @override
  String get generalDateRangeCurrentMonth => 'Bieżący miesiąc';

  @override
  String get generalDateRangeLast30Days => 'Ostatnie 30 dni';

  @override
  String get generalDateRangeCurrentYear => 'Bieżący rok';

  @override
  String get generalDateRangeLastYear => 'Poprzedni rok';

  @override
  String get generalDateRangeAll => 'Wszystko';

  @override
  String get generalDefault => 'domyślnie';

  @override
  String get generalDestinationAccount => 'Konto docelowe';

  @override
  String get generalDismiss => 'Anuluj';

  @override
  String get generalEarned => 'Zarobiono';

  @override
  String get generalError => 'Błąd';

  @override
  String get generalExpenses => 'Wydatki';

  @override
  String get generalIncome => 'Przychód';

  @override
  String get generalLiabilities => 'Zobowiązania';

  @override
  String get generalMultiple => 'wiele';

  @override
  String get generalNever => 'nigdy';

  @override
  String get generalReconcile => 'Zatwierdzone';

  @override
  String get generalReset => 'Resetuj';

  @override
  String get generalSourceAccount => 'Konto źródłowe';

  @override
  String get generalSpent => 'Wydano';

  @override
  String get generalSum => 'Suma';

  @override
  String get generalTarget => 'Cel';

  @override
  String get generalUnknown => 'Nieznany';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'tydzień',
      'monthly': 'miesiąc',
      'quarterly': 'kwartał',
      'halfyear': 'pół roku',
      'yearly': 'rok',
      'other': 'nieznany',
    });
    return '$_temp0';
  }

  @override
  String get homeMainBillsTitle => 'Subskrypcje w następnym tygodniu';

  @override
  String homeMainBudgetInterval(DateTime from, DateTime to, String period) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString do $toString, $period)';
  }

  @override
  String homeMainBudgetIntervalSingle(DateTime from, DateTime to) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString do $toString)';
  }

  @override
  String homeMainBudgetSum(String current, String status, String available) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'over': 'ponad',
      'other': 'zostało z',
    });
    return '$current $_temp0 $available';
  }

  @override
  String get homeMainBudgetTitle => 'Budżety na bieżący miesiąc';

  @override
  String get homeMainChartAccountsTitle => 'Podsumowanie konta';

  @override
  String get homeMainChartCategoriesTitle =>
      'Podsumowanie kategorii dla bieżącego miesiąca';

  @override
  String get homeMainChartDailyAvg => 'Średnia z 7 dni';

  @override
  String get homeMainChartDailyTitle => 'Podsumowanie dnia';

  @override
  String get homeMainChartNetEarningsTitle => 'Przychody netto';

  @override
  String get homeMainChartNetWorthTitle => 'Wartość netto';

  @override
  String get homeMainChartTagsTitle =>
      'Podsumowanie tagów dla bieżącego miesiąca';

  @override
  String get homePiggyAdjustDialogTitle => 'Wrzuć/Wyjmij Pieniądze';

  @override
  String homePiggyDateStart(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Data rozpoczęcia: $dateString';
  }

  @override
  String homePiggyDateTarget(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Data docelowa: $dateString';
  }

  @override
  String get homeMainDialogSettingsTitle => 'Dostosuj pulpit';

  @override
  String homePiggyLinked(String account) {
    return 'Powiązane z $account';
  }

  @override
  String get homePiggyNoAccounts => 'Żadne skarbonki nie zostały utworzone.';

  @override
  String get homePiggyNoAccountsSubtitle =>
      'Utwórz jakieś w interfejsie internetowym!';

  @override
  String homePiggyRemaining(String amount) {
    return 'Pozostało do zaoszczędzenia: $amount';
  }

  @override
  String homePiggySaved(String amount) {
    return 'Zaoszczędzono dotychczas: $amount';
  }

  @override
  String get homePiggySavedMultiple => 'Zaoszczędzono do tej pory:';

  @override
  String homePiggyTarget(String amount) {
    return 'Docelowa kwota: $amount';
  }

  @override
  String get homePiggyAccountStatus => 'Status konta';

  @override
  String get homePiggyAvailableAmounts => 'Dostępne kwoty';

  @override
  String homePiggyAvailable(String amount) {
    return 'Dostępne: $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'W skarbonkach: $amount';
  }

  @override
  String get homeTabLabelBalance => 'Zestawienie Bilansowe';

  @override
  String get homeTabLabelMain => 'Główna';

  @override
  String get homeTabLabelPiggybanks => 'Skarbonki';

  @override
  String get homeTabLabelTransactions => 'Transakcje';

  @override
  String get homeTransactionsActionFilter => 'Lista filtrów';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<Wszystkie konta>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<Wszystkie rachunki>';

  @override
  String get homeTransactionsDialogFilterBillUnset =>
      '<Brak wybranego rachunku>';

  @override
  String get homeTransactionsDialogFilterBudgetsAll => '<Wszystkie budżety>';

  @override
  String get homeTransactionsDialogFilterBudgetUnset =>
      '<Brak wybranego budżetu>';

  @override
  String get homeTransactionsDialogFilterCategoriesAll =>
      '<Wszystkie kategorie>';

  @override
  String get homeTransactionsDialogFilterCategoryUnset =>
      '<Brak wybranej kategorii>';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<Wszystkie waluty>';

  @override
  String get homeTransactionsDialogFilterDateRange => 'Zakres dat';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'Pokaż przyszłe transakcje';

  @override
  String get homeTransactionsDialogFilterSearch => 'Szukana fraza';

  @override
  String get homeTransactionsDialogFilterTitle => 'Wybierz filtry';

  @override
  String get homeTransactionsEmpty => 'Nie znaleziono transakcji.';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num kategorie';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'Pokaż tagi na liście transakcji';

  @override
  String get liabilityDirectionCredit => 'Zadłużenie wobec mnie';

  @override
  String get liabilityDirectionDebit => 'Jestem dłużny';

  @override
  String get liabilityTypeDebt => 'Dług';

  @override
  String get liabilityTypeLoan => 'Pożyczka';

  @override
  String get liabilityTypeMortgage => 'Hipoteka';

  @override
  String get loginAbout =>
      'Aby wydajnie korzystać z Waterfly III, potrzebujesz własnego serwera z instancją Firefly III lub dodatkiem Firefly III dla asystenta domowego.\n\nWprowadź pełny adres URL oraz osobisty token dostępu (Ustawienia -> Profil -> OAuth -> Osobisty token dostępu) poniżej.';

  @override
  String get loginFormLabelAPIKey => 'Prawidłowy klucz API';

  @override
  String get loginFormLabelHost => 'Adres URL hosta';

  @override
  String get loginWelcome => 'Witaj w Waterfly III';

  @override
  String get logoutConfirmation =>
      'Czy jesteś pewien, że chcesz się wylogować?';

  @override
  String get navigationAccounts => 'Konta';

  @override
  String get navigationBills => 'Subskrypcje';

  @override
  String get navigationCategories => 'Kategorie';

  @override
  String get navigationMain => 'Panel główny';

  @override
  String get generalSettings => 'Ustawienia';

  @override
  String get no => 'Nie';

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

    return '$percString z $of';
  }

  @override
  String get settingsDialogDebugInfo =>
      'Możesz tutaj włączyć i wysłać logi debugowania. Mają one zły wpływ na wydajność, więc nie włączaj ich, chyba że ktoś ci to zalecił. Wyłączenie logowania spowoduje usunięcie zapisanych logów.';

  @override
  String get settingsDialogDebugMailCreate => 'Stwórz email';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      'OSTRZEŻENIE: Szkic wiadomości zostanie otwarty wraz z załączonym plikiem logów (w formacie tekstowym). Logi mogą zawierać poufne informacje, takie jak nazwa hosta twojej instancji Firefly (chociaż staram się unikać logowania wszelkich sekretów, takich jak klucz api). Przeczytaj uważnie logi i ocenzuruj informacje, których nie chcesz udostępniać i/lub które nie są istotne dla problemu, który chcesz zgłosić.\n\nProszę nie wysyłaj logów bez uprzedniego dogadania się poprzez mail/GitHub. Usunę wszystkie wpisy wysłane bez kontekstu ze względu na prywatność. Nigdy nie wysyłaj nieocenzurowanych logów na GitHub lub gdzieś indziej.';

  @override
  String get settingsDialogDebugSendButton => 'Wyślij logi poprzez e-mail';

  @override
  String get settingsDialogDebugTitle => 'Logi Debugowania';

  @override
  String get settingsDialogLanguageTitle => 'Wybierz język';

  @override
  String get settingsDialogThemeTitle => 'Wybierz motyw';

  @override
  String get settingsFAQ => 'FAQ';

  @override
  String get settingsFAQHelp =>
      'Otwórz w przeglądarce. Dostępne tylko w języku angielskim.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configure offline sync and mobile data usage';

  @override
  String get settingsLanguage => 'Język';

  @override
  String get settingsLockscreen => 'Ekran blokady';

  @override
  String get settingsLockscreenHelp =>
      'Wymagaj uwierzytelnienia przy starcie aplikacji';

  @override
  String get settingsLockscreenInitial =>
      'Proszę uwierzytelnić się, aby włączyć ekran blokady.';

  @override
  String get settingsNLAppAccount => 'Konto domyślne';

  @override
  String get settingsNLAppAccountDynamic => '<Dynamicznie>';

  @override
  String get settingsNLAppAdd => 'Dodaj aplikację';

  @override
  String get settingsNLAppAddHelp =>
      'Kliknij, aby dodać aplikację do nasłuchiwania. Tylko kwalifikujące się aplikacje pojawią się na liście.';

  @override
  String get settingsNLAppAddInfo =>
      'Wykonaj transakcje, w których otrzymujesz powiadomienia telefoniczne, aby dodać aplikacje do tej listy. Jeśli aplikacja nadal się nie pojawia, zgłoś to do app@vogt.pw.';

  @override
  String get settingsNLAutoAdd => 'Utwórz transakcję bez interakcji';

  @override
  String get settingsNLDescription =>
      'Ta usługa pozwala na pobranie szczegółów transakcji z przychodzących powiadomień. Dodatkowo możesz wybrać domyślne konto, do którego transakcja powinna być przypisana — jeśli wartość nie jest ustawiona, spróbuje dopisać konto z powiadomienia.';

  @override
  String get settingsNLEmptyNote => 'Pozostaw pole notatki puste';

  @override
  String get settingsNLPermissionGrant => 'Dotknij, aby udzielić uprawnień.';

  @override
  String get settingsNLPermissionNotGranted => 'Nie przyznano uprawnień.';

  @override
  String get settingsNLPermissionRemove => 'Usunąć uprawnienia?';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'Aby wyłączyć tę usługę, kliknij w aplikację i usuń uprawnienia na następnym ekranie.';

  @override
  String get settingsNLPrefillTXTitle =>
      'Uzupełnij tytuł transakcji tytułem powiadomienia';

  @override
  String get settingsNLServiceChecking => 'Sprawdzam stan…';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'Błąd podczas sprawdzania statusu: $error';
  }

  @override
  String get settingsNLServiceRunning => 'Usługa jest uruchomiona.';

  @override
  String get settingsNLServiceStatus => 'Status usługi';

  @override
  String get settingsNLServiceStopped => 'Usługa jest zatrzymana.';

  @override
  String get settingsNotificationListener => 'Usługa nasłuchiwania powiadomień';

  @override
  String get settingsTheme => 'Motyw aplikacji';

  @override
  String get settingsThemeDynamicColors => 'Dynamiczne kolory';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'Tryb ciemny',
      'light': 'Tryb lekki',
      'other': 'Domyślny systemu',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone => 'Użyj strefy czasowej serwera';

  @override
  String get settingsUseServerTimezoneHelp =>
      'Pokaż wszystkie czasy w strefie czasowej serwera. To naśladuje zachowanie interfejsu web.';

  @override
  String get settingsVersion => 'Wersja Aplikacji';

  @override
  String get settingsVersionChecking => 'sprawdzenie…';

  @override
  String get transactionAttachments => 'Załączniki';

  @override
  String get transactionDeleteConfirm =>
      'Czy na pewno chcesz usunąć tę transakcję?';

  @override
  String get transactionDialogAttachmentsDelete => 'Usuń załącznik';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      'Jesteś pewien, że chcesz usunąć ten załącznik?';

  @override
  String get transactionDialogAttachmentsErrorDownload =>
      'Nie można pobrać pliku.';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'Nie można otworzyć pliku: $error';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'Nie można przesłać pliku: $error';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'Załączniki';

  @override
  String get transactionDialogBillNoBill => 'Brak rachunku';

  @override
  String get transactionDialogBillTitle => 'Połącz z rachunkiem';

  @override
  String get transactionDialogCurrencyTitle => 'Wybierz walutę';

  @override
  String get transactionDialogPiggyNoPiggy => 'Brak skarbonki';

  @override
  String get transactionDialogPiggyTitle => 'Połącz ze skarbonką';

  @override
  String get transactionDialogTagsAdd => 'Dodaj Tag';

  @override
  String get transactionDialogTagsHint => 'Szukaj/Dodaj Tag';

  @override
  String get transactionDialogTagsTitle => 'Wybierz tagi';

  @override
  String get transactionDuplicate => 'Duplikat';

  @override
  String get transactionErrorInvalidAccount => 'Błędne konto';

  @override
  String get transactionErrorInvalidBudget => 'Błędny budżet';

  @override
  String get transactionErrorNoAccounts => 'Proszę najpierw wypełnić konta.';

  @override
  String get transactionErrorNoAssetAccount => 'Proszę wybrać konto aktywów.';

  @override
  String get transactionErrorTitle => 'Proszę podać tytuł.';

  @override
  String get transactionFormLabelAccountDestination => 'Konto docelowe';

  @override
  String get transactionFormLabelAccountForeign => 'Konto zagraniczne';

  @override
  String get transactionFormLabelAccountOwn => 'Własne konto';

  @override
  String get transactionFormLabelAccountSource => 'Konto źródłowe';

  @override
  String get transactionFormLabelNotes => 'Notatki';

  @override
  String get transactionFormLabelTags => 'Tagi';

  @override
  String get transactionFormLabelTitle => 'Tytuł transakcji';

  @override
  String get transactionSplitAdd => 'Dodaj podzieloną transakcję';

  @override
  String get transactionSplitChangeCurrency => 'Zmień walutę podziału';

  @override
  String get transactionSplitChangeDestinationAccount => 'Zmień konto docelowe';

  @override
  String get transactionSplitChangeSourceAccount => 'Zmień konto źródłowe';

  @override
  String get transactionSplitChangeTarget => 'Zmień docelowe konto dzielenia';

  @override
  String get transactionSplitDelete => 'Usuń podział';

  @override
  String get transactionTitleAdd => 'Dodaj transakcję';

  @override
  String get transactionTitleDelete => 'Usuń transakcję';

  @override
  String get transactionTitleEdit => 'Edytuj transakcję';

  @override
  String get transactionTypeDeposit => 'Wpłata';

  @override
  String get transactionTypeTransfer => 'Przelew';

  @override
  String get transactionTypeWithdrawal => 'Wypłata';

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
