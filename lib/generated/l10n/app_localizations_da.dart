// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class SDa extends S {
  SDa([String locale = 'da']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'Kontantstegnebog';

  @override
  String get accountRoleAssetCC => 'Kreditkort';

  @override
  String get accountRoleAssetDefault => 'Standard aktivkonto';

  @override
  String get accountRoleAssetSavings => 'Opsparingskonto';

  @override
  String get accountRoleAssetShared => 'Delt aktivkonto';

  @override
  String get accountsLabelAsset => 'Aktivkonti';

  @override
  String get accountsLabelExpense => 'Udgiftskonti';

  @override
  String get accountsLabelLiabilities => 'Gældsforpligtelser';

  @override
  String get accountsLabelRevenue => 'Indtægtskonti';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'uge',
      'monthly': 'måned',
      'quarterly': 'kvartal',
      'halfyear': 'halvår',
      'yearly': 'år',
      'other': 'ukendt',
    });
    return '$interest% renter per $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'ugentligt',
      'monthly': 'månedligt',
      'quarterly': 'kvartalsvis',
      'halfyear': 'halvårligt',
      'yearly': 'årligt',
      'other': 'ukendt',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', springer over $skip',
      zero: '',
    );
    return 'Abonnement matcher transaktioner mellem $minValue og $maxvalue. Gentages $_temp0$_temp1.';
  }

  @override
  String get billsChangeLayoutTooltip => 'Skift layout';

  @override
  String get billsChangeSortOrderTooltip => 'Skift sorteringsrækkefølge';

  @override
  String get billsErrorLoading => 'Fejl ved indlæsning af abonnementer.';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'ugentligt',
      'monthly': 'månedligt',
      'quarterly': 'kvartalsvis',
      'halfyear': 'halvårligt',
      'yearly': 'årligt',
      'other': 'ukendt',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', springer over $skip',
      zero: '',
    );
    return 'Abonnement matcher transaktioner af $value. Gentages $_temp0$_temp1.';
  }

  @override
  String billsExpectedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Forventet $dateString';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Ugentlig',
      'monthly': 'Månedlig',
      'quarterly': 'Kvartalsvis',
      'halfyear': 'Halvårlig',
      'yearly': 'Årlig',
      'other': 'Ukendt',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Ugentlig',
      'monthly': 'Månedlig',
      'quarterly': 'Kvartalsvis',
      'halfyear': 'Halvårlig',
      'yearly': 'Årlig',
      'other': 'Ukendt',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', springer over $skip',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get billsInactive => 'Inaktiv';

  @override
  String get billsIsActive => 'Abonnementet er aktivt';

  @override
  String get billsLayoutGroupSubtitle =>
      'Abonnementer vises i deres tildelte grupper.';

  @override
  String get billsLayoutGroupTitle => 'Gruppe';

  @override
  String get billsLayoutListSubtitle =>
      'Abonnementer vises på en liste sorteret efter bestemte kriterier.';

  @override
  String get billsLayoutListTitle => 'Liste';

  @override
  String get billsListEmpty => 'Listen er i øjeblikket tom.';

  @override
  String get billsNextExpectedMatch => 'Næste forventede match';

  @override
  String get billsNotActive => 'Abonnementet er inaktivt';

  @override
  String get billsNotExpected => 'Ikke forventet i denne periode';

  @override
  String get billsNoTransactions => 'Ingen transaktioner fundet.';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Betalt $dateString';
  }

  @override
  String get billsSortAlphabetical => 'Alfabetisk';

  @override
  String get billsSortByTimePeriod => 'Efter tidsperiode';

  @override
  String get billsSortFrequency => 'Frekvens';

  @override
  String get billsSortName => 'Navn';

  @override
  String get billsUngrouped => 'Ugrupperede';

  @override
  String get billsSettingsShowOnlyActive => 'Vis kun aktive';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'Viser kun aktive abonnementer.';

  @override
  String get billsSettingsShowOnlyExpected => 'Vis kun forventede';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'Viser kun de abonnementer, der forventes (eller er betalt) denne måned.';

  @override
  String get categoryDeleteConfirm =>
      'Er du sikker på, at du vil slette denne kategori? Transaktionerne vil ikke blive slettet, men vil ikke længere have en kategori.';

  @override
  String get categoryErrorLoading => 'Fejl ved indlæsning af kategorier.';

  @override
  String get categoryFormLabelIncludeInSum => 'Medregn i månedlig sum';

  @override
  String get categoryFormLabelName => 'Kategorinavn';

  @override
  String get categoryMonthNext => 'Næste måned';

  @override
  String get categoryMonthPrev => 'Sidste måned';

  @override
  String get categorySumExcluded => 'udelukket';

  @override
  String get categoryTitleAdd => 'Tilføj kategori';

  @override
  String get categoryTitleDelete => 'Slet kategori';

  @override
  String get categoryTitleEdit => 'Redigér kategori';

  @override
  String get catNone => '<ingen kategori>';

  @override
  String get catOther => 'Andet';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'Ugyldigt svar fra API: $message';
  }

  @override
  String get errorAPIUnavailable => 'API utilgængelig';

  @override
  String get errorFieldRequired => 'Dette felt er påkrævet.';

  @override
  String get errorInvalidURL => 'Ugyldig URL';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'Minimum Firefly API-version v$requiredVersion påkrævet. Opgradér venligst.';
  }

  @override
  String errorStatusCode(int code) {
    return 'Statuskode: $code';
  }

  @override
  String get errorUnknown => 'Ukendt fejl.';

  @override
  String get formButtonHelp => 'Hjælp';

  @override
  String get formButtonLogin => 'Log ind';

  @override
  String get formButtonLogout => 'Log ud';

  @override
  String get formButtonRemove => 'Fjern';

  @override
  String get formButtonResetLogin => 'Nulstil login';

  @override
  String get formButtonTransactionAdd => 'Tilføj transaktion';

  @override
  String get formButtonTryAgain => 'Prøv igen';

  @override
  String get generalAccount => 'Konto';

  @override
  String get generalAssets => 'Aktiver';

  @override
  String get generalBalance => 'Saldo';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Saldo på $dateString';
  }

  @override
  String get generalBill => 'Regning';

  @override
  String get generalBudget => 'Budgetter';

  @override
  String get generalCategory => 'Kategori';

  @override
  String get generalCurrency => 'Valuta';

  @override
  String get generalDateRangeCurrentMonth => 'Nuværende måned';

  @override
  String get generalDateRangeLast30Days => 'Sidste 30 dage';

  @override
  String get generalDateRangeCurrentYear => 'Nuværende år';

  @override
  String get generalDateRangeLastYear => 'Sidste år';

  @override
  String get generalDateRangeAll => 'Alle';

  @override
  String get generalDefault => 'standard';

  @override
  String get generalDestinationAccount => 'Destinationskonto';

  @override
  String get generalDismiss => 'Afvis';

  @override
  String get generalEarned => 'Optjent';

  @override
  String get generalError => 'Fejl';

  @override
  String get generalExpenses => 'Udgifter';

  @override
  String get generalIncome => 'Indtægter';

  @override
  String get generalLiabilities => 'Gældsforpligtelser';

  @override
  String get generalMultiple => 'flere';

  @override
  String get generalNever => 'aldrig';

  @override
  String get generalReconcile => 'Afstemt';

  @override
  String get generalReset => 'Nulstil';

  @override
  String get generalSourceAccount => 'Kildekonto';

  @override
  String get generalSpent => 'Brugt';

  @override
  String get generalSum => 'I alt';

  @override
  String get generalTarget => 'Mål';

  @override
  String get generalUnknown => 'Ukendt';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'ugentligt',
      'monthly': 'månedligt',
      'quarterly': 'kvartalsvis',
      'halfyear': 'halvårligt',
      'yearly': 'årligt',
      'other': 'ukendt',
    });
    return '($_temp0)';
  }

  @override
  String get homeMainBillsTitle => 'Regninger for næste uge';

  @override
  String homeMainBudgetInterval(DateTime from, DateTime to, String period) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return '($fromString til $toString, $period)';
  }

  @override
  String homeMainBudgetIntervalSingle(DateTime from, DateTime to) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return '($fromString til $toString)';
  }

  @override
  String homeMainBudgetSum(String current, String status, String available) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'over': 'over',
      'other': 'tilbage af',
    });
    return '$current$_temp0 $available';
  }

  @override
  String get homeMainBudgetTitle => 'Budgetter for denne måned';

  @override
  String get homeMainChartAccountsTitle => 'Kontooversigt';

  @override
  String get homeMainChartCategoriesTitle => 'Kategorioversigt for denne måned';

  @override
  String get homeMainChartDailyAvg => '7 dages-gennemsnit';

  @override
  String get homeMainChartDailyTitle => 'Dagsoversigt';

  @override
  String get homeMainChartNetEarningsTitle => 'Nettoindtjening';

  @override
  String get homeMainChartNetWorthTitle => 'Nettoværdi';

  @override
  String get homeMainChartTagsTitle => 'Tag-oversigt for nuværende måned';

  @override
  String get homePiggyAdjustDialogTitle => 'Gem/brug penge';

  @override
  String homePiggyDateStart(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Startdato: $dateString';
  }

  @override
  String homePiggyDateTarget(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Måldato: $dateString';
  }

  @override
  String get homeMainDialogSettingsTitle => 'Tilpas Dashboard';

  @override
  String homePiggyLinked(String account) {
    return 'Knyttet til $account';
  }

  @override
  String get homePiggyNoAccounts => 'Ingen sparegris er sat op.';

  @override
  String get homePiggyNoAccountsSubtitle => 'Opret nogle i webgrænsefladen!';

  @override
  String homePiggyRemaining(String amount) {
    return 'Mangler at spare: $amount';
  }

  @override
  String homePiggySaved(String amount) {
    return 'Gemt indtil videre: $amount';
  }

  @override
  String get homePiggySavedMultiple => 'Opsparet indtil videre:';

  @override
  String homePiggyTarget(String amount) {
    return 'Målbeløb: $amount';
  }

  @override
  String get homePiggyAccountStatus => 'Kontostatus';

  @override
  String get homePiggyAvailableAmounts => 'Tilgængelige beløb';

  @override
  String homePiggyAvailable(String amount) {
    return 'Tilgængelig: $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'I sparegrise: $amount';
  }

  @override
  String get homeTabLabelBalance => 'Balance';

  @override
  String get homeTabLabelMain => 'Primær';

  @override
  String get homeTabLabelPiggybanks => 'Sparegrise';

  @override
  String get homeTabLabelTransactions => 'Transaktioner';

  @override
  String get homeTransactionsActionFilter => 'Filterliste';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<Alle konti>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<All Bills>';

  @override
  String get homeTransactionsDialogFilterBillUnset => '<No Bill set>';

  @override
  String get homeTransactionsDialogFilterBudgetsAll => '<Alle budgetter>';

  @override
  String get homeTransactionsDialogFilterBudgetUnset =>
      '<Intet budget tildelt>';

  @override
  String get homeTransactionsDialogFilterCategoriesAll => '<Alle kategorier>';

  @override
  String get homeTransactionsDialogFilterCategoryUnset =>
      '<Ingen kategori tildelt>';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<Alle valutaer>';

  @override
  String get homeTransactionsDialogFilterDateRange => 'Datointerval';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'Vis fremtidige transaktioner';

  @override
  String get homeTransactionsDialogFilterSearch => 'Søgeord';

  @override
  String get homeTransactionsDialogFilterTitle => 'Vælg filtre';

  @override
  String get homeTransactionsEmpty => 'Ingen transaktioner fundet.';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num kategorier';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'Vis tags på transaktionslisten';

  @override
  String get liabilityDirectionCredit => 'Jeg er skyldt denne gæld';

  @override
  String get liabilityDirectionDebit => 'Jeg skylder denne gæld';

  @override
  String get liabilityTypeDebt => 'Gæld';

  @override
  String get liabilityTypeLoan => 'Lån';

  @override
  String get liabilityTypeMortgage => 'Boliglån';

  @override
  String get loginAbout =>
      'For at bruge Waterfly III produktivt har du brug for din egen server med en Firefly III-instans eller Firefly II-add-on til Home Assistant.\n\nIndtast venligst det fulde URL samt en personlig adgangstoken (Indstillinger -> Profil -> OAuth -> Personlig adgangstoken) nedenfor.';

  @override
  String get loginFormLabelAPIKey => 'Gyldig API-nøgle';

  @override
  String get loginFormLabelHost => 'Værts-URL';

  @override
  String get loginWelcome => 'Velkommen til Waterfly III';

  @override
  String get logoutConfirmation => 'Er du sikker på, at du vil logge ud?';

  @override
  String get navigationAccounts => 'Konti';

  @override
  String get navigationBills => 'Abonnementer';

  @override
  String get navigationCategories => 'Kategorier';

  @override
  String get navigationMain => 'Hoveddashboard';

  @override
  String get generalSettings => 'Indstillinger';

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

    return '$percString af $of';
  }

  @override
  String get settingsDialogDebugInfo =>
      'Du kan aktivere og sende fejfindingslogs her. Disse har en dårlig indvirkning på ydeevnen, så du skal venligst ikke aktivere dem, medmindre du rådes til at gøre det. Deaktivering af logning vil slette den gemte log.';

  @override
  String get settingsDialogDebugMailCreate => 'Opret mail';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      'ADVARSEL: En mailkladde åbnes med logfilen vedhæftet (i tekstformat). Logfilerne kan indeholdet følsomme oplysninger, såsom værtsnavnet på din Firefly instans (selvom jeg forsøger at undgå logning af eventuelle hemmeligheder, såsom api-nøgle). Læs venligst loggen grundigt og censurér alle oplysninger, du ikke ønsker at dele og/eller ikke er relevante for det problem, du ønsker at rapportere.';

  @override
  String get settingsDialogDebugSendButton => 'Send logfiler via e-mail';

  @override
  String get settingsDialogDebugTitle => 'Fejlfindingslogs';

  @override
  String get settingsDialogLanguageTitle => 'Vælg sprog';

  @override
  String get settingsDialogThemeTitle => 'Vælg tema';

  @override
  String get settingsFAQ => 'Ofte stillede spørgsmål';

  @override
  String get settingsFAQHelp =>
      'Åbnes i browseren. Kun tilgængelig på engelsk.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configure offline sync and mobile data usage';

  @override
  String get settingsLanguage => 'Sprog';

  @override
  String get settingsLockscreen => 'Låst skærm';

  @override
  String get settingsLockscreenHelp => 'Kræv godkendelse ved opstart af app';

  @override
  String get settingsLockscreenInitial =>
      'Godkend venligst for at aktivere skærmlåsning.';

  @override
  String get settingsNLAppAccount => 'Standard konto';

  @override
  String get settingsNLAppAccountDynamic => '<Dynamisk>';

  @override
  String get settingsNLAppAdd => 'Tilføj app';

  @override
  String get settingsNLAppAddHelp =>
      'Klik for at tilføje en app til at lytte til. Kun kvalificerede apps vil dukke op på listen.';

  @override
  String get settingsNLAppAddInfo =>
      'Foretag nogle transaktioner, hvor du modtager telefonmeddelelser for at tilføje apps til denne liste. Hvis appen stadig ikke dukker op, bedes du rapportere den til app@vogt.pw.';

  @override
  String get settingsNLAutoAdd => 'Opret transaktion uden interaktion';

  @override
  String get settingsNLDescription =>
      'Denne tjeneste giver dig mulighed for at hente transaktionsoplysninger fra indgående push-notifikationer. Derudover kan du vælge en standardkonto, som transaktionen skal tildeles til - hvis ingen værdi er angivet, vil den prøve at udtrække en konto fra notifikationen.';

  @override
  String get settingsNLEmptyNote => 'Lad notatfeltet være tomt';

  @override
  String get settingsNLPermissionGrant => 'Tryk for at give tilladelse.';

  @override
  String get settingsNLPermissionNotGranted => 'Tilladelse ikke givet.';

  @override
  String get settingsNLPermissionRemove => 'Fjern tilladelse?';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'Klik på appen for at deaktivere denne tjeneste og fjern tilladelserne på den næste skærm.';

  @override
  String get settingsNLPrefillTXTitle =>
      'Forudfyld transaktionstitel med nofikationstitel';

  @override
  String get settingsNLServiceChecking => 'Tjekker status…';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'Fejl under kontrol af status: $error';
  }

  @override
  String get settingsNLServiceRunning => 'Tjenesten kører.';

  @override
  String get settingsNLServiceStatus => 'Tjenestestatus';

  @override
  String get settingsNLServiceStopped => 'Tjenesten er stoppet.';

  @override
  String get settingsNotificationListener => 'Notifikationslytter-service';

  @override
  String get settingsTheme => 'App tema';

  @override
  String get settingsThemeDynamicColors => 'Dynamisk farve';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'Mørk tilstand',
      'light': 'Lys tilstand',
      'other': 'Systemstandard',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone => 'Brug serverens tidszone';

  @override
  String get settingsUseServerTimezoneHelp =>
      'Vis alle gange i serverens tidszone. Dette efterligner webgrænsefladens opførsel.';

  @override
  String get settingsVersion => 'Appversion';

  @override
  String get settingsVersionChecking => 'tjekker…';

  @override
  String get transactionAttachments => 'Bilag';

  @override
  String get transactionDeleteConfirm =>
      'Er du sikker på, at du vil slette denne transaktion?';

  @override
  String get transactionDialogAttachmentsDelete => 'Slet bilag';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      'Er du sikker på, at du vil slette dette bilag?';

  @override
  String get transactionDialogAttachmentsErrorDownload =>
      'Kunne ikke downloade fil.';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'Kunne ikke åbne fil: $error';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'Kunne ikke uploade fil: $error';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'Bilag';

  @override
  String get transactionDialogBillNoBill => 'Ingen regning';

  @override
  String get transactionDialogBillTitle => 'Link til regning';

  @override
  String get transactionDialogCurrencyTitle => 'Vælg valuta';

  @override
  String get transactionDialogPiggyNoPiggy => 'Ingen opsparingsmål';

  @override
  String get transactionDialogPiggyTitle => 'Knyt til opsparingsmål';

  @override
  String get transactionDialogTagsAdd => 'Tilføj etiket';

  @override
  String get transactionDialogTagsHint => 'Søg/Tilføj Tag';

  @override
  String get transactionDialogTagsTitle => 'Vælg etiketter';

  @override
  String get transactionDuplicate => 'Duplikér';

  @override
  String get transactionErrorInvalidAccount => 'Ugyldig konto';

  @override
  String get transactionErrorInvalidBudget => 'Ugyldigt Budget';

  @override
  String get transactionErrorNoAccounts => 'Udfyld venligst konti først.';

  @override
  String get transactionErrorNoAssetAccount => 'Vælg venligst en aktivkonto.';

  @override
  String get transactionErrorTitle => 'Angiv venligst en titel.';

  @override
  String get transactionFormLabelAccountDestination => 'Destinationskonto';

  @override
  String get transactionFormLabelAccountForeign => 'Fremmed konto';

  @override
  String get transactionFormLabelAccountOwn => 'Egen konto';

  @override
  String get transactionFormLabelAccountSource => 'Fra konto';

  @override
  String get transactionFormLabelNotes => 'Noter';

  @override
  String get transactionFormLabelTags => 'Etiketter';

  @override
  String get transactionFormLabelTitle => 'Transaktionstitel';

  @override
  String get transactionSplitAdd => 'Tilføj delt transaktion';

  @override
  String get transactionSplitChangeCurrency => 'Ændr delt valuta';

  @override
  String get transactionSplitChangeDestinationAccount =>
      'Skift destinationkonto for opdeling';

  @override
  String get transactionSplitChangeSourceAccount =>
      'Skift kildekonto for opdeling';

  @override
  String get transactionSplitChangeTarget => 'Ændr delt målkonto';

  @override
  String get transactionSplitDelete => 'Slet split';

  @override
  String get transactionTitleAdd => 'Tilføj transaktion';

  @override
  String get transactionTitleDelete => 'Slet transaktion';

  @override
  String get transactionTitleEdit => 'Redigér transaktion';

  @override
  String get transactionTypeDeposit => 'Indbetal';

  @override
  String get transactionTypeTransfer => 'Overfør';

  @override
  String get transactionTypeWithdrawal => 'Hævning';

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
