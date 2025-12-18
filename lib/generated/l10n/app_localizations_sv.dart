// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class SSv extends S {
  SSv([String locale = 'sv']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'Plånbok';

  @override
  String get accountRoleAssetCC => 'Kreditkort';

  @override
  String get accountRoleAssetDefault => 'Förvalt tillgångskonto';

  @override
  String get accountRoleAssetSavings => 'Sparkonto';

  @override
  String get accountRoleAssetShared => 'Delat tillgångskonto';

  @override
  String get accountsLabelAsset => 'Tillgångskonton';

  @override
  String get accountsLabelExpense => 'Kostnadskonton';

  @override
  String get accountsLabelLiabilities => 'Skulder';

  @override
  String get accountsLabelRevenue => 'Intäktskonton';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'vecka',
      'monthly': 'månad',
      'quarterly': 'kvartal',
      'halfyear': 'halvår',
      'yearly': 'år',
      'other': 'okänd',
    });
    return '$interest% ränta per $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'veckovis',
      'monthly': 'månadsvis',
      'quarterly': 'kvartalsvis',
      'halfyear': 'halvårsvis',
      'yearly': 'årligen',
      'other': 'okänt',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', hoppar över $skip',
      zero: '',
    );
    return 'Räkningen matchar transaktioner mellan $minValue och $maxvalue. Upprepas $_temp0$_temp1.';
  }

  @override
  String get billsChangeLayoutTooltip => 'Ändra layout';

  @override
  String get billsChangeSortOrderTooltip => 'Ändra sorteringsordning';

  @override
  String get billsErrorLoading => 'Fel vid laddning av räkningar.';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'veckovis',
      'monthly': 'månadsvis',
      'quarterly': 'kvartalsvis',
      'halfyear': 'halvårsvis',
      'yearly': 'årligen',
      'other': 'okänt',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', hoppar över $skip',
      zero: '',
    );
    return 'Räkningen matchar transaktioner på $value. Upprepas $_temp0$_temp1.';
  }

  @override
  String billsExpectedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Förväntad $dateString';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Veckovis',
      'monthly': 'Månadsvis',
      'quarterly': 'Kvartalsvis',
      'halfyear': 'Halvårsvis',
      'yearly': 'Årligen',
      'other': 'Okänt',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Veckovis',
      'monthly': 'Månadsvis',
      'quarterly': 'Kvartalsvis',
      'halfyear': 'Halvårsvis',
      'yearly': 'Årligen',
      'other': 'Okänt',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', hoppar över $skip',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get billsInactive => 'Inaktiv';

  @override
  String get billsIsActive => 'Räkningen aktiv';

  @override
  String get billsLayoutGroupSubtitle =>
      'Räkningar visas i sina tilldelade grupper.';

  @override
  String get billsLayoutGroupTitle => 'Grupp';

  @override
  String get billsLayoutListSubtitle =>
      'Räkningar visas i en lista sorterad efter vissa kriterier.';

  @override
  String get billsLayoutListTitle => 'Lista';

  @override
  String get billsListEmpty => 'Den här listan är för närvarande tom.';

  @override
  String get billsNextExpectedMatch => 'Nästa förväntade träff';

  @override
  String get billsNotActive => 'Räkningen är inaktiv';

  @override
  String get billsNotExpected => 'Ej förväntat denna period';

  @override
  String get billsNoTransactions => 'Inga transaktioner hittade.';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Betald $dateString';
  }

  @override
  String get billsSortAlphabetical => 'Alfabetisk';

  @override
  String get billsSortByTimePeriod => 'Efter tidsperiod';

  @override
  String get billsSortFrequency => 'Frekvens';

  @override
  String get billsSortName => 'Namn';

  @override
  String get billsUngrouped => 'Ogrupperad';

  @override
  String get billsSettingsShowOnlyActive => 'Visa endast aktiva';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'Visar endast aktiva prenumerationer.';

  @override
  String get billsSettingsShowOnlyExpected => 'Visa endast förväntade';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'Visar endast de prenumerationer som är förväntade (eller betalda) denna månad.';

  @override
  String get categoryDeleteConfirm =>
      'Är du säker på att du vill ta bort denna kategori? Transaktionerna kommer inte att tas bort, men kommer inte att ha en kategori längre.';

  @override
  String get categoryErrorLoading => 'Fel vid laddning av kategorier.';

  @override
  String get categoryFormLabelIncludeInSum => 'Inkludera i månadssumman';

  @override
  String get categoryFormLabelName => 'Kategorinamn';

  @override
  String get categoryMonthNext => 'Nästa Månad';

  @override
  String get categoryMonthPrev => 'Föregående månad';

  @override
  String get categorySumExcluded => 'exkluderad';

  @override
  String get categoryTitleAdd => 'Lägg till kategori';

  @override
  String get categoryTitleDelete => 'Ta bort kategori';

  @override
  String get categoryTitleEdit => 'Redigera kategori';

  @override
  String get catNone => '<ingen kategori>';

  @override
  String get catOther => 'Övrigt';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'Ogiltigt svar från API: $message';
  }

  @override
  String get errorAPIUnavailable => 'API inte tillgängligt';

  @override
  String get errorFieldRequired => 'Detta fält är obligatoriskt.';

  @override
  String get errorInvalidURL => 'Ogiltig URL';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'Minsta Firefly API Version v$requiredVersion krävs. Vänligen uppdatera Firefly.';
  }

  @override
  String errorStatusCode(int code) {
    return 'Statuskod: $code';
  }

  @override
  String get errorUnknown => 'Okänt fel.';

  @override
  String get formButtonHelp => 'Hjälp';

  @override
  String get formButtonLogin => 'Logga in';

  @override
  String get formButtonLogout => 'Logga ut';

  @override
  String get formButtonRemove => 'Ta bort';

  @override
  String get formButtonResetLogin => 'Återställ inloggning';

  @override
  String get formButtonTransactionAdd => 'Lägg till transaktion';

  @override
  String get formButtonTryAgain => 'Försök igen';

  @override
  String get generalAccount => 'Konto';

  @override
  String get generalAssets => 'Tillgångar';

  @override
  String get generalBalance => 'Balans';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Saldo för $dateString';
  }

  @override
  String get generalBill => 'Räkning';

  @override
  String get generalBudget => 'Budget';

  @override
  String get generalCategory => 'Kategori';

  @override
  String get generalCurrency => 'Valuta';

  @override
  String get generalDateRangeCurrentMonth => 'Aktuell månad';

  @override
  String get generalDateRangeLast30Days => 'Senaste 30 dagarna';

  @override
  String get generalDateRangeCurrentYear => 'Aktuellt år';

  @override
  String get generalDateRangeLastYear => 'Förra året';

  @override
  String get generalDateRangeAll => 'Alla';

  @override
  String get generalDefault => 'förvald';

  @override
  String get generalDestinationAccount => 'Målkonto';

  @override
  String get generalDismiss => 'Stäng';

  @override
  String get generalEarned => 'Intjänat';

  @override
  String get generalError => 'Fel';

  @override
  String get generalExpenses => 'Utgifter';

  @override
  String get generalIncome => 'Inkomst';

  @override
  String get generalLiabilities => 'Skulder';

  @override
  String get generalMultiple => 'multipla';

  @override
  String get generalNever => 'aldrig';

  @override
  String get generalReconcile => 'Avstämt';

  @override
  String get generalReset => 'Återställ';

  @override
  String get generalSourceAccount => 'Källkonto';

  @override
  String get generalSpent => 'Spenderat';

  @override
  String get generalSum => 'Summa';

  @override
  String get generalTarget => 'Mål';

  @override
  String get generalUnknown => 'Okänt';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'veckovis',
      'monthly': 'månadsvis',
      'quarterly': 'kvartalsvis',
      'halfyear': 'årligen',
      'yearly': '',
      'other': 'okänd',
    });
    return ' ($_temp0)';
  }

  @override
  String get homeMainBillsTitle => 'Räkningar inför nästa vecka';

  @override
  String homeMainBudgetInterval(DateTime from, DateTime to, String period) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString till $toString, $period)';
  }

  @override
  String homeMainBudgetIntervalSingle(DateTime from, DateTime to) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString till $toString)';
  }

  @override
  String homeMainBudgetSum(String current, String status, String available) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'over': 'över',
      'other': 'kvar från',
    });
    return '$current $_temp0 $available';
  }

  @override
  String get homeMainBudgetTitle => 'Budgetar för den aktuella månaden';

  @override
  String get homeMainChartAccountsTitle => 'Kontosammanfattning';

  @override
  String get homeMainChartCategoriesTitle =>
      'Kategorisammanfattning för aktuell månad';

  @override
  String get homeMainChartDailyAvg => '7 dagars genomsnitt';

  @override
  String get homeMainChartDailyTitle => 'Daglig sammanfattning';

  @override
  String get homeMainChartNetEarningsTitle => 'Nettoinkomst';

  @override
  String get homeMainChartNetWorthTitle => 'Nettoförmögenhet';

  @override
  String get homeMainChartTagsTitle => 'Taggsammanfattning för aktuell månad';

  @override
  String get homePiggyAdjustDialogTitle => 'Spara/spendera pengar';

  @override
  String homePiggyDateStart(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Startdatum: $dateString';
  }

  @override
  String homePiggyDateTarget(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Måldatum: $dateString';
  }

  @override
  String get homeMainDialogSettingsTitle => 'Anpassa kontrollpanelen';

  @override
  String homePiggyLinked(String account) {
    return 'Länkad till $account';
  }

  @override
  String get homePiggyNoAccounts => 'Inga spargrisar har inrättats.';

  @override
  String get homePiggyNoAccountsSubtitle => 'Skapa några i webbgränssnittet!';

  @override
  String homePiggyRemaining(String amount) {
    return 'Kvar att spara: $amount';
  }

  @override
  String homePiggySaved(String amount) {
    return 'Sparat hittills: $amount';
  }

  @override
  String get homePiggySavedMultiple => 'Hittills sparat:';

  @override
  String homePiggyTarget(String amount) {
    return 'Målbelopp: $amount';
  }

  @override
  String get homePiggyAccountStatus => 'Kontostatus';

  @override
  String get homePiggyAvailableAmounts => 'Tillgängliga belopp';

  @override
  String homePiggyAvailable(String amount) {
    return 'Tillgängligt: $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'I spargrisar: $amount';
  }

  @override
  String get homeTabLabelBalance => 'Balansräkning';

  @override
  String get homeTabLabelMain => 'Start';

  @override
  String get homeTabLabelPiggybanks => 'Spargris';

  @override
  String get homeTabLabelTransactions => 'Transaktioner';

  @override
  String get homeTransactionsActionFilter => 'Filtrera listan';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<Alla konton>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<Alla räkningar>';

  @override
  String get homeTransactionsDialogFilterBillUnset => '<Utan räkning>';

  @override
  String get homeTransactionsDialogFilterBudgetsAll => '<All budgetar>';

  @override
  String get homeTransactionsDialogFilterBudgetUnset => '<Utan budget>';

  @override
  String get homeTransactionsDialogFilterCategoriesAll => '<All kategorier>';

  @override
  String get homeTransactionsDialogFilterCategoryUnset => '<Utan kategori>';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<Alla valutor>';

  @override
  String get homeTransactionsDialogFilterDateRange => 'Datumintervall';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'Visa framtida transaktioner';

  @override
  String get homeTransactionsDialogFilterSearch => 'Sökord';

  @override
  String get homeTransactionsDialogFilterTitle => 'Välj filter';

  @override
  String get homeTransactionsEmpty => 'Inga transaktioner hittade.';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num kategorier';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'Visa taggar i transaktionslista';

  @override
  String get liabilityDirectionCredit => 'Jag är skyldig denna skuld';

  @override
  String get liabilityDirectionDebit => 'Jag har denna skuld';

  @override
  String get liabilityTypeDebt => 'Skuld';

  @override
  String get liabilityTypeLoan => 'Lån';

  @override
  String get liabilityTypeMortgage => 'Bolån';

  @override
  String get loginAbout =>
      'För att använda Waterfly III på ett produktivt sätt behöver du din egen server med en Firefly III instans eller Firefly III-tillägget för Home Assistant.\n\nAnge hela URL: en samt en personlig åtkomst-token (inställningar -> Profil -> OAuth -> Personlig åtkomst-token) nedan.';

  @override
  String get loginFormLabelAPIKey => 'Giltig API-nyckel';

  @override
  String get loginFormLabelHost => 'Värd URL';

  @override
  String get loginWelcome => 'Välkommen till Waterfly III';

  @override
  String get logoutConfirmation => 'Är du säker på att du vill logga ut?';

  @override
  String get navigationAccounts => 'Konton';

  @override
  String get navigationBills => 'Räkningar';

  @override
  String get navigationCategories => 'Kategorier';

  @override
  String get navigationMain => 'Kontrollpanel';

  @override
  String get generalSettings => 'Inställningar';

  @override
  String get no => 'Nej';

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

    return '$percString av $of';
  }

  @override
  String get settingsDialogDebugInfo =>
      'Du kan aktivera och skicka felsökningsloggar här. Dessa har en dålig inverkan på prestandan, så var snäll och aktivera dem inte om du inte rekommenderas att göra det. Inaktivering av loggning kommer att ta bort den lagrade loggen.';

  @override
  String get settingsDialogDebugMailCreate => 'Skapa e-post';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      'VARNING: Ett e-postutkast öppnas med loggfilen bifogad (i textformat). Loggarna kan innehålla känslig information, såsom värdnamnet för din Firefly instans (även om jag försöker undvika loggning av några hemligheter, såsom api nyckel). Läs igenom loggen noga och censurera all information som du inte vill dela och/eller inte är relevant för det problem du vill rapportera.\n\nSkicka inte in loggar utan föregående överenskommelse via mail/GitHub. Jag kommer att ta bort alla loggar som skickas utan kontext av sekretessskäl. Ladda aldrig upp loggen ocensurerad till GitHub eller någon annanstans.';

  @override
  String get settingsDialogDebugSendButton => 'Skicka loggar via e-post';

  @override
  String get settingsDialogDebugTitle => 'Felsökningsloggar';

  @override
  String get settingsDialogLanguageTitle => 'Välj språk';

  @override
  String get settingsDialogThemeTitle => 'Välj tema';

  @override
  String get settingsFAQ => 'Vanliga frågor';

  @override
  String get settingsFAQHelp =>
      'Öppnas i webbläsaren. Endast tillgänglig på engelska.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configure offline sync and mobile data usage';

  @override
  String get settingsLanguage => 'Språk';

  @override
  String get settingsLockscreen => 'Låsskärm';

  @override
  String get settingsLockscreenHelp => 'Kräv autentisering vid appstart';

  @override
  String get settingsLockscreenInitial =>
      'Vänligen autentisera för att aktivera låsskärmen.';

  @override
  String get settingsNLAppAccount => 'Förvalt konto';

  @override
  String get settingsNLAppAccountDynamic => '<Dynamiskt>';

  @override
  String get settingsNLAppAdd => 'Lägg till app';

  @override
  String get settingsNLAppAddHelp =>
      'Klicka för att lägga till en app att lyssna efter. Endast kvalificerade appar visas i listan.';

  @override
  String get settingsNLAppAddInfo =>
      'Gör några transaktioner där du får telefonaviseringar för att lägga till appar i den här listan. Om appen fortfarande inte dyker upp, vänligen rapportera det till app@vogt.pw.';

  @override
  String get settingsNLAutoAdd => 'Skapa transaktion utan interaktion';

  @override
  String get settingsNLDescription =>
      'Den här tjänsten låter dig hämta transaktionsdetaljer från inkommande pushnotifikationer. Du kan även välja ett förvalt konto som transaktionen ska göras på - om inget värde ges försöker den extrahera kontot från notifikationen.';

  @override
  String get settingsNLEmptyNote => 'Håll anteckningsfältet tomt';

  @override
  String get settingsNLPermissionGrant => 'Tryck för att bevilja tillstånd.';

  @override
  String get settingsNLPermissionNotGranted => 'Behörighet inte beviljad.';

  @override
  String get settingsNLPermissionRemove => 'Ta bort behörigheten?';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'För att avaktivera den här tjänsten, tryck på appen och ta bort behörigheterna på den nästa skärmen.';

  @override
  String get settingsNLPrefillTXTitle =>
      'Fyll i transaktionstiteln med nofikationstiteln i förväg';

  @override
  String get settingsNLServiceChecking => 'Kontrollerar status…';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'Fel vid kontroll av status: $error';
  }

  @override
  String get settingsNLServiceRunning => 'Tjänsten körs.';

  @override
  String get settingsNLServiceStatus => 'Tjänstestatus';

  @override
  String get settingsNLServiceStopped => 'Tjänsten är stoppad.';

  @override
  String get settingsNotificationListener => 'Notifikationslyssningstjänst';

  @override
  String get settingsTheme => 'Apptema';

  @override
  String get settingsThemeDynamicColors => 'Dynamiska färger';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'Mörkt läge',
      'light': 'Ljust läge',
      'other': 'Systemstandard',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone => 'Använd serverns tidszon';

  @override
  String get settingsUseServerTimezoneHelp =>
      'Visa alla tider i serverns tidszon. Detta härmar beteendet hos webbgränssnittet.';

  @override
  String get settingsVersion => 'Appversion';

  @override
  String get settingsVersionChecking => 'kontrollerar…';

  @override
  String get transactionAttachments => 'Bilagor';

  @override
  String get transactionDeleteConfirm =>
      'Är du säker att du vill radera denna transaktion?';

  @override
  String get transactionDialogAttachmentsDelete => 'Ta bort bifogad fil';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      'Är du säker på att du vill radera bilagan?';

  @override
  String get transactionDialogAttachmentsErrorDownload =>
      'Kunde inte ladda ner filen.';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'Kunde inte öppna filen: $error';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'Kunde inte ladda upp filen: $error';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'Bilagor';

  @override
  String get transactionDialogBillNoBill => 'Ingen faktura';

  @override
  String get transactionDialogBillTitle => 'Länk till faktura';

  @override
  String get transactionDialogCurrencyTitle => 'Välj valuta';

  @override
  String get transactionDialogPiggyNoPiggy => 'Ingen spargris';

  @override
  String get transactionDialogPiggyTitle => 'Koppla till spargris';

  @override
  String get transactionDialogTagsAdd => 'Lägg till Tagg';

  @override
  String get transactionDialogTagsHint => 'Sök/Lägg till tagg';

  @override
  String get transactionDialogTagsTitle => 'Välj taggar';

  @override
  String get transactionDuplicate => 'Dubblett';

  @override
  String get transactionErrorInvalidAccount => 'Ogiltigt konto';

  @override
  String get transactionErrorInvalidBudget => 'Ogiltig budget';

  @override
  String get transactionErrorNoAccounts => 'Fyll i kontona först.';

  @override
  String get transactionErrorNoAssetAccount =>
      'Vänligen välj ett tillgångskonto.';

  @override
  String get transactionErrorTitle => 'Vänligen ange en titel.';

  @override
  String get transactionFormLabelAccountDestination => 'Till konto';

  @override
  String get transactionFormLabelAccountForeign => 'Mottagarkonto';

  @override
  String get transactionFormLabelAccountOwn => 'Källkonto';

  @override
  String get transactionFormLabelAccountSource => 'Källkonto';

  @override
  String get transactionFormLabelNotes => 'Anteckningar';

  @override
  String get transactionFormLabelTags => 'Taggar';

  @override
  String get transactionFormLabelTitle => 'Transaktionstitel';

  @override
  String get transactionSplitAdd => 'Lägg till delad transaktion';

  @override
  String get transactionSplitChangeCurrency => 'Ändra delad valuta';

  @override
  String get transactionSplitChangeDestinationAccount =>
      'Ändra mottagarkonto för delad transaktion';

  @override
  String get transactionSplitChangeSourceAccount =>
      'Ändra avsändarkonto för delad transaktion';

  @override
  String get transactionSplitChangeTarget => 'Ändra delat målkonto';

  @override
  String get transactionSplitDelete => 'Ta bort delning';

  @override
  String get transactionTitleAdd => 'Lägg till transaktion';

  @override
  String get transactionTitleDelete => 'Ta bort transaktion';

  @override
  String get transactionTitleEdit => 'Ändra transaktion';

  @override
  String get transactionTypeDeposit => 'Insättning';

  @override
  String get transactionTypeTransfer => 'Överföring';

  @override
  String get transactionTypeWithdrawal => 'Uttag';

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
