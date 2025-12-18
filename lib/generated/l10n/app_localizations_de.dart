// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class SDe extends S {
  SDe([String locale = 'de']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'Geldbörse';

  @override
  String get accountRoleAssetCC => 'Kreditkarte';

  @override
  String get accountRoleAssetDefault => 'Standard-Bestandskonto';

  @override
  String get accountRoleAssetSavings => 'Sparkonto';

  @override
  String get accountRoleAssetShared => 'Gemeinsames Bestandskonto';

  @override
  String get accountsLabelAsset => 'Bestandskonten';

  @override
  String get accountsLabelExpense => 'Ausgabekonten';

  @override
  String get accountsLabelLiabilities => 'Verbindlichkeiten';

  @override
  String get accountsLabelRevenue => 'Einnahmekonten';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'Woche',
      'monthly': 'Monat',
      'quarterly': 'Quartal',
      'halfyear': 'halbes Jahr',
      'yearly': 'Jahr',
      'other': 'Unbekannt',
    });
    return '$interest% Zinsen pro $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'wöchentlich',
      'monthly': 'monatlich',
      'quarterly': 'vierteljährlich',
      'halfyear': 'halbjährlich',
      'yearly': 'jährlich',
      'other': 'unbekannt',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', überspringt $skip',
      zero: '',
    );
    return 'Abonnement passt zu Transaktionen zwischen $minValue und $maxvalue. Wiederholt sich $_temp0$_temp1.';
  }

  @override
  String get billsChangeLayoutTooltip => 'Layout ändern';

  @override
  String get billsChangeSortOrderTooltip => 'Sortierung ändern';

  @override
  String get billsErrorLoading => 'Fehler beim Laden der Abonnements.';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'wöchentlich',
      'monthly': 'monatlich',
      'quarterly': 'vierteljährlich',
      'halfyear': 'halbjährlich',
      'yearly': 'jährlich',
      'other': 'unbekannt',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', überspringt $skip',
      zero: '',
    );
    return 'Abonnement passt zu Transaktionen mit $value. Wiederholt sich $_temp0$_temp1.';
  }

  @override
  String billsExpectedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Voraussichtliches $dateString';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Wöchentlich',
      'monthly': 'Monatlich',
      'quarterly': 'Vierteljährlich',
      'halfyear': 'Halbjährlich',
      'yearly': 'Jährlich',
      'other': 'Unbekannt',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Wöchentlich',
      'monthly': 'Monatlich',
      'quarterly': 'Vierteljährlich',
      'halfyear': 'Halbjährlich',
      'yearly': 'Jährlich',
      'other': 'Unbekannt',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', überspringt $skip',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get billsInactive => 'Inaktiv';

  @override
  String get billsIsActive => 'Abonnement ist aktiv';

  @override
  String get billsLayoutGroupSubtitle =>
      'Abonnements werden in ihrer Gruppe angezeigt.';

  @override
  String get billsLayoutGroupTitle => 'Gruppe';

  @override
  String get billsLayoutListSubtitle =>
      'Abonnements werden sortiert in einer Liste angezeigt.';

  @override
  String get billsLayoutListTitle => 'Liste';

  @override
  String get billsListEmpty => 'Diese Liste ist momentan leer.';

  @override
  String get billsNextExpectedMatch => 'Nächste erwartete Übereinstimmung';

  @override
  String get billsNotActive => 'Abonnement ist inaktiv';

  @override
  String get billsNotExpected => 'In diesem Zeitraum nicht erwartet';

  @override
  String get billsNoTransactions => 'Keine Transaktionen gefunden.';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Bezahlt am $dateString';
  }

  @override
  String get billsSortAlphabetical => 'Alphabetisch';

  @override
  String get billsSortByTimePeriod => 'Nach Zeitraum';

  @override
  String get billsSortFrequency => 'Häufigkeit';

  @override
  String get billsSortName => 'Name';

  @override
  String get billsUngrouped => 'Keine Gruppe';

  @override
  String get billsSettingsShowOnlyActive => 'Nur aktive anzeigen';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'Zeigt nur aktive Abonnements an.';

  @override
  String get billsSettingsShowOnlyExpected => 'Nur erwartete anzeigen';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'Zeigt nur Abonnements an, die diesen Monat erwartet werden (oder bereits bezahlt worden sind).';

  @override
  String get categoryDeleteConfirm =>
      'Möchtest du diese Kategorie wirklich löschen? Die Transaktionen werden nicht gelöscht, werden aber keine Kategorie mehr haben.';

  @override
  String get categoryErrorLoading => 'Fehler beim Laden der Kategorien.';

  @override
  String get categoryFormLabelIncludeInSum => 'In Monatssumme einbeziehen';

  @override
  String get categoryFormLabelName => 'Kategoriename';

  @override
  String get categoryMonthNext => 'Nächster Monat';

  @override
  String get categoryMonthPrev => 'Letzter Monat';

  @override
  String get categorySumExcluded => 'ausgenommen';

  @override
  String get categoryTitleAdd => 'Kategorie hinzufügen';

  @override
  String get categoryTitleDelete => 'Kategorie löschen';

  @override
  String get categoryTitleEdit => 'Kategorie bearbeiten';

  @override
  String get catNone => '<keine Kategorie>';

  @override
  String get catOther => 'Andere';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'Ungültige API-Antwort: $message';
  }

  @override
  String get errorAPIUnavailable => 'API nicht verfügbar';

  @override
  String get errorFieldRequired => 'Dies ist ein Pflichtfeld.';

  @override
  String get errorInvalidURL => 'Ungültige URL';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'Mindestens Firefly API-Version v$requiredVersion benötigt. Bitte updaten.';
  }

  @override
  String errorStatusCode(int code) {
    return 'Status-Code: $code';
  }

  @override
  String get errorUnknown => 'Unbekannter Fehler.';

  @override
  String get formButtonHelp => 'Hilfe';

  @override
  String get formButtonLogin => 'Login';

  @override
  String get formButtonLogout => 'Logout';

  @override
  String get formButtonRemove => 'Entfernen';

  @override
  String get formButtonResetLogin => 'Login zurücksetzen';

  @override
  String get formButtonTransactionAdd => 'Transaktion hinzufügen';

  @override
  String get formButtonTryAgain => 'Nochmals versuchen';

  @override
  String get generalAccount => 'Konten';

  @override
  String get generalAssets => 'Vermögen';

  @override
  String get generalBalance => 'Kontostand';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Kontostand am $dateString';
  }

  @override
  String get generalBill => 'Abonnement';

  @override
  String get generalBudget => 'Budget';

  @override
  String get generalCategory => 'Kategorie';

  @override
  String get generalCurrency => 'Währung';

  @override
  String get generalDateRangeCurrentMonth => 'Aktueller Monat';

  @override
  String get generalDateRangeLast30Days => 'Letzte 30 Tage';

  @override
  String get generalDateRangeCurrentYear => 'Aktuelles Jahr';

  @override
  String get generalDateRangeLastYear => 'Vergangenes Jahr';

  @override
  String get generalDateRangeAll => 'Alle';

  @override
  String get generalDefault => 'Standard';

  @override
  String get generalDestinationAccount => 'Zielkonto';

  @override
  String get generalDismiss => 'Verwerfen';

  @override
  String get generalEarned => 'Verdient';

  @override
  String get generalError => 'Fehler';

  @override
  String get generalExpenses => 'Ausgaben';

  @override
  String get generalIncome => 'Einnahmen';

  @override
  String get generalLiabilities => 'Verbindlichkeiten';

  @override
  String get generalMultiple => 'mehrere';

  @override
  String get generalNever => 'nie';

  @override
  String get generalReconcile => 'Abgeglichen';

  @override
  String get generalReset => 'Zurücksetzen';

  @override
  String get generalSourceAccount => 'Quellkonto';

  @override
  String get generalSpent => 'Ausgegeben';

  @override
  String get generalSum => 'Summe';

  @override
  String get generalTarget => 'Ziel';

  @override
  String get generalUnknown => 'Unbekannt';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'wöchentlich',
      'monthly': 'monatlich',
      'quarterly': 'vierteljährlich',
      'halfyear': 'halbjährlich',
      'yearly': 'jährlich',
      'other': 'unbekannt',
    });
    return ' ($_temp0)';
  }

  @override
  String get homeMainBillsTitle => 'Abonnements für die nächste Woche';

  @override
  String homeMainBudgetInterval(DateTime from, DateTime to, String period) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString bis $toString, $period)';
  }

  @override
  String homeMainBudgetIntervalSingle(DateTime from, DateTime to) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString bis $toString)';
  }

  @override
  String homeMainBudgetSum(String current, String status, String available) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'over': 'über',
      'other': 'bis',
    });
    return '$current $_temp0 $available';
  }

  @override
  String get homeMainBudgetTitle => 'Budgets für diesen Monat';

  @override
  String get homeMainChartAccountsTitle => 'Konten-Übersicht';

  @override
  String get homeMainChartCategoriesTitle =>
      'Kategorie-Übersicht für diesen Monat';

  @override
  String get homeMainChartDailyAvg => '7-Tage-Durchschnitt';

  @override
  String get homeMainChartDailyTitle => 'Tägliche Zusammenfassung';

  @override
  String get homeMainChartNetEarningsTitle => 'Überschuss';

  @override
  String get homeMainChartNetWorthTitle => 'Nettovermögen';

  @override
  String get homeMainChartTagsTitle => 'Schlagwort-Übersicht für diesen Monat';

  @override
  String get homePiggyAdjustDialogTitle => 'Geld sparen/ausgeben';

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

    return 'Zieldatum: $dateString';
  }

  @override
  String get homeMainDialogSettingsTitle => 'Übersicht anpassen';

  @override
  String homePiggyLinked(String account) {
    return 'Verknüpft mit $account';
  }

  @override
  String get homePiggyNoAccounts => 'Keine Sparschweine vorhanden.';

  @override
  String get homePiggyNoAccountsSubtitle => 'Erstelle welche im Webinterface!';

  @override
  String homePiggyRemaining(String amount) {
    return 'Noch zu sparen: $amount';
  }

  @override
  String homePiggySaved(String amount) {
    return 'Bereits gespart: $amount';
  }

  @override
  String get homePiggySavedMultiple => 'Bereits gespart:';

  @override
  String homePiggyTarget(String amount) {
    return 'Sparziel: $amount';
  }

  @override
  String get homePiggyAccountStatus => 'Kontostatus';

  @override
  String get homePiggyAvailableAmounts => 'Verfügbarer Betrag';

  @override
  String homePiggyAvailable(String amount) {
    return 'Verfügbar: $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'In Sparschweinen: $amount';
  }

  @override
  String get homeTabLabelBalance => 'Kontostände';

  @override
  String get homeTabLabelMain => 'Übersicht';

  @override
  String get homeTabLabelPiggybanks => 'Sparschweine';

  @override
  String get homeTabLabelTransactions => 'Transaktionen';

  @override
  String get homeTransactionsActionFilter => 'Liste filtern';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<Alle Konten>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<Alle Abonnements>';

  @override
  String get homeTransactionsDialogFilterBillUnset => '<Ohne Abonnement>';

  @override
  String get homeTransactionsDialogFilterBudgetsAll => '<Alle Budgets>';

  @override
  String get homeTransactionsDialogFilterBudgetUnset => '<Ohne Budget>';

  @override
  String get homeTransactionsDialogFilterCategoriesAll => '<Alle Kategorien>';

  @override
  String get homeTransactionsDialogFilterCategoryUnset => '<Ohne Kategorie>';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<Alle Währungen>';

  @override
  String get homeTransactionsDialogFilterDateRange => 'Zeitraum';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'Zeige zukünftige Transaktionen';

  @override
  String get homeTransactionsDialogFilterSearch => 'Suchbegriff';

  @override
  String get homeTransactionsDialogFilterTitle => 'Filter auswählen';

  @override
  String get homeTransactionsEmpty => 'Keine Transaktionen gefunden.';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num Kategorien';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'Schlagwörter in der Transaktionsliste anzeigen';

  @override
  String get liabilityDirectionCredit => 'Mir wird dies geschuldet';

  @override
  String get liabilityDirectionDebit => 'Ich schulde dies jemandem';

  @override
  String get liabilityTypeDebt => 'Schulden';

  @override
  String get liabilityTypeLoan => 'Darlehen';

  @override
  String get liabilityTypeMortgage => 'Hypothek';

  @override
  String get loginAbout =>
      'Um Waterfly III nutzen zu können, wird ein eigener Server mit Firefly III oder das Firefly III Add-on für Home Assistant benötigt.\n\nBitte gebe den kompletten Link und den persönlichen Zugangs-Token (Einstellungen → Profil → OAuth → Persönliche Zugangs-Tokens) ein.';

  @override
  String get loginFormLabelAPIKey => 'Gültiger API-Schlüssel';

  @override
  String get loginFormLabelHost => 'Server URL';

  @override
  String get loginWelcome => 'Willkommen zu Waterfly III';

  @override
  String get logoutConfirmation => 'Wirklich ausloggen?';

  @override
  String get navigationAccounts => 'Konten';

  @override
  String get navigationBills => 'Abonnements';

  @override
  String get navigationCategories => 'Kategorien';

  @override
  String get navigationMain => 'Übersicht';

  @override
  String get generalSettings => 'Einstellungen';

  @override
  String get no => 'Nein';

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

    return '$percString von $of';
  }

  @override
  String get settingsDialogDebugInfo =>
      'Hier kann die Fehlerprotokollierung aktiviert werden. Die Protokollierung hat einen negativen Einfluss auf die App-Performance, deshalb aktiviere sie bitte nur nach Absprache. Beim Deaktivieren werden die gespeicherten Protokolle gelöscht.';

  @override
  String get settingsDialogDebugMailCreate => 'E-Mail erstellen';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      'ACHTUNG: Ein E-Mail Entwurf wird mit angehängtem Fehlerprotokoll erstellt. Das Fehlerprotokoll kann sensitive Informationen wie zum Beispiel die URL deiner Firefly-Instanz enthalten (auch wenn ich versuche geheime Informationen wie den API-Schlüssel nicht zu protokollieren). Bitte lese vor dem Senden der Mail das Protokoll durch und zensiere alle Informationen, die du nicht teilen möchtest.\n\nBitte sende keine Fehlerprotokolle ohne vorherige Absprache mit mir via Mail/GitHub. Ich werde alle ohne Kontext eingesendete Protokolle aus Datenschutzgründen löschen. Lade die Protokolle nie auf GitHub oder anderswo hoch.';

  @override
  String get settingsDialogDebugSendButton => 'Protokoll via Mail schicken';

  @override
  String get settingsDialogDebugTitle => 'Fehlerprotokolle';

  @override
  String get settingsDialogLanguageTitle => 'Sprache auswählen';

  @override
  String get settingsDialogThemeTitle => 'Erscheinungsbild auswählen';

  @override
  String get settingsFAQ => 'FAQ';

  @override
  String get settingsFAQHelp =>
      'Öffnet im Browser. Nur auf Englisch verfügbar.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configure offline sync and mobile data usage';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLockscreen => 'App-Sperre';

  @override
  String get settingsLockscreenHelp =>
      'Authentifizierung beim Start der App erzwingen';

  @override
  String get settingsLockscreenInitial =>
      'Bitte authentifiziere dich, um die App-Sperre zu aktivieren.';

  @override
  String get settingsNLAppAccount => 'Standard-Konto';

  @override
  String get settingsNLAppAccountDynamic => '<Dynamisch>';

  @override
  String get settingsNLAppAdd => 'App hinzufügen';

  @override
  String get settingsNLAppAddHelp =>
      'Füge eine neue App hinzu. Nur qualifizierte Apps werden gelistet.';

  @override
  String get settingsNLAppAddInfo =>
      'Führe eine Zahlung durch, bei der die gewünschte Benachrichtigung erscheint, um eine App zu dieser Liste hinzuzufügen. Wenn die App trotzdem nicht erscheint, bitte melde dies an app@vogt.pw.';

  @override
  String get settingsNLAutoAdd => 'Transaktion ohne Nachfragen erstellen';

  @override
  String get settingsNLDescription =>
      'Dieser Dienst erlaubt dir, Transaktionen aus Benachrichtigungen zu erstellen. Außerdem kannst du das Standard-Konto auswählen, zu dem die Transaktion zugeordnet wird - ansonsten wird dynamisch versucht, ein Konto zu ermitteln.';

  @override
  String get settingsNLEmptyNote => 'Notizfeld leer lassen';

  @override
  String get settingsNLPermissionGrant =>
      'Klicke, um die Berechtigung zu erteilen.';

  @override
  String get settingsNLPermissionNotGranted => 'Berechtigung nicht erteilt.';

  @override
  String get settingsNLPermissionRemove => 'Berechtigung löschen?';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'Um den Dienst zu deaktivieren, klicke auf die App und entferne die Berechtigungen im nächsten Bildschirm.';

  @override
  String get settingsNLPrefillTXTitle =>
      'Transaktionstitel mit Benachrichtigungstitel befüllen';

  @override
  String get settingsNLServiceChecking => 'Status wird geprüft…';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'Fehler beim Status prüfen: $error';
  }

  @override
  String get settingsNLServiceRunning => 'Dienst läuft.';

  @override
  String get settingsNLServiceStatus => 'Dienst-Status';

  @override
  String get settingsNLServiceStopped => 'Dienst ist gestoppt.';

  @override
  String get settingsNotificationListener =>
      'Dienst zum Auslesen von Benachrichtigungen';

  @override
  String get settingsTheme => 'Erscheinungsbild';

  @override
  String get settingsThemeDynamicColors => 'Dyn. Farben';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'Dunkel',
      'light': 'Hell',
      'other': 'Systemeinstellung',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone => 'Server-Zeitzone benutzen';

  @override
  String get settingsUseServerTimezoneHelp =>
      'Zeigt alle Zeiten in der Server-Zeitzone an. Dies entspricht dem Verhalten des Webinterfaces.';

  @override
  String get settingsVersion => 'App-Version';

  @override
  String get settingsVersionChecking => 'Überprüfe…';

  @override
  String get transactionAttachments => 'Anhänge';

  @override
  String get transactionDeleteConfirm =>
      'Soll diese Transaktion wirklich gelöscht werden?';

  @override
  String get transactionDialogAttachmentsDelete => 'Anhang löschen';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      'Soll dieser Anhang wirklich gelöscht werden?';

  @override
  String get transactionDialogAttachmentsErrorDownload =>
      'Datei konnte nicht geladen werden.';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'Datei konnte nicht geöffnet werden: $error';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'Datei konnte nicht hochgeladen werden: $error';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'Anhänge';

  @override
  String get transactionDialogBillNoBill => 'Kein Abonnement';

  @override
  String get transactionDialogBillTitle => 'Mit Abonnement verknüpfen';

  @override
  String get transactionDialogCurrencyTitle => 'Währung auswählen';

  @override
  String get transactionDialogPiggyNoPiggy => 'Kein Sparschwein';

  @override
  String get transactionDialogPiggyTitle => 'Mit Sparschwein verknüpfen';

  @override
  String get transactionDialogTagsAdd => 'Schlagwort hinzufügen';

  @override
  String get transactionDialogTagsHint => 'Schlagwort suchen/hinzufügen';

  @override
  String get transactionDialogTagsTitle => 'Schlagwörter auswählen';

  @override
  String get transactionDuplicate => 'Duplizieren';

  @override
  String get transactionErrorInvalidAccount => 'Ungültiges Konto';

  @override
  String get transactionErrorInvalidBudget => 'Ungültiges Budget';

  @override
  String get transactionErrorNoAccounts =>
      'Bitte tragen Sie zuerst die Konten ein.';

  @override
  String get transactionErrorNoAssetAccount =>
      'Bitte ein Bestandskonto auswählen.';

  @override
  String get transactionErrorTitle => 'Bitte gebe einen Titel an.';

  @override
  String get transactionFormLabelAccountDestination => 'Ziel-Konto';

  @override
  String get transactionFormLabelAccountForeign => 'Fremdes Konto';

  @override
  String get transactionFormLabelAccountOwn => 'Eigenes Konto';

  @override
  String get transactionFormLabelAccountSource => 'Quell-Konto';

  @override
  String get transactionFormLabelNotes => 'Notizen';

  @override
  String get transactionFormLabelTags => 'Schlagwörter';

  @override
  String get transactionFormLabelTitle => 'Titel der Transaktion';

  @override
  String get transactionSplitAdd => 'Aufteilung hinzufügen';

  @override
  String get transactionSplitChangeCurrency => 'Währung der Aufteilung ändern';

  @override
  String get transactionSplitChangeDestinationAccount =>
      'Zielkonto der Aufteilung ändern';

  @override
  String get transactionSplitChangeSourceAccount =>
      'Quellkonto der Aufteilung ändern';

  @override
  String get transactionSplitChangeTarget => 'Zielkonto der Aufteilung ändern';

  @override
  String get transactionSplitDelete => 'Aufteilung löschen';

  @override
  String get transactionTitleAdd => 'Transaktion hinzufügen';

  @override
  String get transactionTitleDelete => 'Transaktion löschen';

  @override
  String get transactionTitleEdit => 'Transaktion bearbeiten';

  @override
  String get transactionTypeDeposit => 'Einnahme';

  @override
  String get transactionTypeTransfer => 'Umbuchung';

  @override
  String get transactionTypeWithdrawal => 'Ausgabe';

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
