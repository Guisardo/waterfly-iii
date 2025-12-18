// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class SCs extends S {
  SCs([String locale = 'cs']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'Peněženka';

  @override
  String get accountRoleAssetCC => 'Kreditní karta';

  @override
  String get accountRoleAssetDefault => 'Výchozí účet majetku';

  @override
  String get accountRoleAssetSavings => 'Spořicí účet';

  @override
  String get accountRoleAssetShared => 'Sdílený účet aktiv';

  @override
  String get accountsLabelAsset => 'Účty majetku';

  @override
  String get accountsLabelExpense => 'Výdajové účty';

  @override
  String get accountsLabelLiabilities => 'Závazky';

  @override
  String get accountsLabelRevenue => 'Příjmové účty';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'týden',
      'monthly': 'měsíc',
      'quarterly': 'čtvrtletí',
      'halfyear': 'půlrok',
      'yearly': 'rok',
      'other': 'neznámé',
    });
    return '$interest% úrok za $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'týdně',
      'monthly': 'měsíčně',
      'quarterly': 'čtvrtletně',
      'halfyear': 'pololetně',
      'yearly': 'ročně',
      'other': 'neznámé',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', přeskočí $skip',
      zero: '',
    );
    return 'Předplatné odpovídá transakcím mezi $minValue a $maxvalue. Opakuje se $_temp0$_temp1.';
  }

  @override
  String get billsChangeLayoutTooltip => 'Změnit rozložení';

  @override
  String get billsChangeSortOrderTooltip => 'Změnit pořadí řazení';

  @override
  String get billsErrorLoading => 'Chyba při načítání předplatných.';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'týdně',
      'monthly': 'měsíčně',
      'quarterly': 'čtvrtletně',
      'halfyear': 'pololetně',
      'yearly': 'ročně',
      'other': 'neznámé',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', přeskočí $skip',
      zero: '',
    );
    return 'Předplatné odpovídá transakcím v hodnotě $value. Opakuje se $_temp0$_temp1.';
  }

  @override
  String billsExpectedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Očekáváno $dateString';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Týdně',
      'monthly': 'Měsíčně',
      'quarterly': 'Čtvrtletně',
      'halfyear': 'Pololetně',
      'yearly': 'Ročně',
      'other': 'Neznámé',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Týdně',
      'monthly': 'Měsíčně',
      'quarterly': 'Čtvrtletně',
      'halfyear': 'Pololetně',
      'yearly': 'Ročně',
      'other': 'Neznámé',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', přeskočí $skip',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get billsInactive => 'Neaktivní';

  @override
  String get billsIsActive => 'Předplatné je aktivní';

  @override
  String get billsLayoutGroupSubtitle =>
      'Předplatná zobrazená v přiřazených skupinách.';

  @override
  String get billsLayoutGroupTitle => 'Skupina';

  @override
  String get billsLayoutListSubtitle =>
      'Předplatná zobrazená v seznamu seřazeném podle určitých kritérií.';

  @override
  String get billsLayoutListTitle => 'Seznam';

  @override
  String get billsListEmpty => 'Seznam je aktuálně prázdný.';

  @override
  String get billsNextExpectedMatch => 'Další očekávaná shoda';

  @override
  String get billsNotActive => 'Předplatné je neaktivní';

  @override
  String get billsNotExpected => 'V tomto období neočekáváno';

  @override
  String get billsNoTransactions => 'Nebyly nalezeny žádné transakce.';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Zaplaceno $dateString';
  }

  @override
  String get billsSortAlphabetical => 'Abecedně';

  @override
  String get billsSortByTimePeriod => 'Podle časového období';

  @override
  String get billsSortFrequency => 'Frekvence';

  @override
  String get billsSortName => 'Název';

  @override
  String get billsUngrouped => 'Neseskupené';

  @override
  String get billsSettingsShowOnlyActive => 'Zobrazit pouze aktivní';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'Zobrazuje pouze aktivní předplatná.';

  @override
  String get billsSettingsShowOnlyExpected => 'Zobrazit pouze očekávané';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'Zobrazuje pouze ta předplatná, která jsou očekávána (nebo zaplacena) tento měsíc.';

  @override
  String get categoryDeleteConfirm =>
      'Opravdu chcete smazat tuto kategorii? Transakce nebudou smazány, ale již nebudou mít přiřazenou kategorii.';

  @override
  String get categoryErrorLoading => 'Chyba při načítání kategorií.';

  @override
  String get categoryFormLabelIncludeInSum => 'Zahrnout do měsíčního součtu';

  @override
  String get categoryFormLabelName => 'Název kategorie';

  @override
  String get categoryMonthNext => 'Příští měsíc';

  @override
  String get categoryMonthPrev => 'Předchozí měsíc';

  @override
  String get categorySumExcluded => 'vyloučeno';

  @override
  String get categoryTitleAdd => 'Přidat kategorii';

  @override
  String get categoryTitleDelete => 'Smazat kategorii';

  @override
  String get categoryTitleEdit => 'Upravit kategorii';

  @override
  String get catNone => '<bez kategorie>';

  @override
  String get catOther => 'Ostatní';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'Neplatná odpověď z API: $message';
  }

  @override
  String get errorAPIUnavailable => 'API není dostupné';

  @override
  String get errorFieldRequired => 'Toto pole je povinné.';

  @override
  String get errorInvalidURL => 'Neplatná URL adresa';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'Je vyžadováno minimálně Firefly API verze $requiredVersion. Prosíme proveďte aktualizaci.';
  }

  @override
  String errorStatusCode(int code) {
    return 'Stavový kód: $code';
  }

  @override
  String get errorUnknown => 'Neznámá chyba.';

  @override
  String get formButtonHelp => 'Nápověda';

  @override
  String get formButtonLogin => 'Přihlásit se';

  @override
  String get formButtonLogout => 'Odhlásit se';

  @override
  String get formButtonRemove => 'Odstranit';

  @override
  String get formButtonResetLogin => 'Resetovat přihlášení';

  @override
  String get formButtonTransactionAdd => 'Přidat transakci';

  @override
  String get formButtonTryAgain => 'Zkusit znovu';

  @override
  String get generalAccount => 'Účet';

  @override
  String get generalAssets => 'Aktiva';

  @override
  String get generalBalance => 'Zůstatek';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Zůstatek k $dateString';
  }

  @override
  String get generalBill => 'Účtenka';

  @override
  String get generalBudget => 'Rozpočet';

  @override
  String get generalCategory => 'Kategorie';

  @override
  String get generalCurrency => 'Měna';

  @override
  String get generalDateRangeCurrentMonth => 'Aktuální měsíc';

  @override
  String get generalDateRangeLast30Days => 'Posledních 30 dní';

  @override
  String get generalDateRangeCurrentYear => 'Aktuální rok';

  @override
  String get generalDateRangeLastYear => 'Minulý rok';

  @override
  String get generalDateRangeAll => 'Vše';

  @override
  String get generalDefault => 'výchozí';

  @override
  String get generalDestinationAccount => 'Cílový účet';

  @override
  String get generalDismiss => 'Zrušit';

  @override
  String get generalEarned => 'Získané';

  @override
  String get generalError => 'Chyba';

  @override
  String get generalExpenses => 'Výdaje';

  @override
  String get generalIncome => 'Příjmy';

  @override
  String get generalLiabilities => 'Závazky';

  @override
  String get generalMultiple => 'několik';

  @override
  String get generalNever => 'nikdy';

  @override
  String get generalReconcile => 'Ověřeno';

  @override
  String get generalReset => 'Resetovat';

  @override
  String get generalSourceAccount => 'Zdrojový účet';

  @override
  String get generalSpent => 'Utracené';

  @override
  String get generalSum => 'Součet';

  @override
  String get generalTarget => 'Cíl';

  @override
  String get generalUnknown => 'Neznámý';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'týdně',
      'monthly': 'měsíčně',
      'quarterly': 'čtvrtletně',
      'halfyear': 'půlročně',
      'yearly': 'ročně',
      'other': 'neznámé',
    });
    return ' ($_temp0)';
  }

  @override
  String get homeMainBillsTitle => 'Účty na příští týden';

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
      'over': 'přes',
      'other': 'zbývá z',
    });
    return '$current $_temp0 $available';
  }

  @override
  String get homeMainBudgetTitle => 'Rozpočty na aktuální měsíc';

  @override
  String get homeMainChartAccountsTitle => 'Souhrn účtů';

  @override
  String get homeMainChartCategoriesTitle =>
      'Souhrn kategorie pro aktuální měsíc';

  @override
  String get homeMainChartDailyAvg => 'Průměr za 7 dní';

  @override
  String get homeMainChartDailyTitle => 'Denní souhrn';

  @override
  String get homeMainChartNetEarningsTitle => 'Čisté příjmy';

  @override
  String get homeMainChartNetWorthTitle => 'Čisté jmění';

  @override
  String get homeMainChartTagsTitle => 'Souhrn štítků za aktuální měsíc';

  @override
  String get homePiggyAdjustDialogTitle => 'Uložit/utratit peníze';

  @override
  String homePiggyDateStart(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Datum začátku: $dateString';
  }

  @override
  String homePiggyDateTarget(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Datum cíle: $dateString';
  }

  @override
  String get homeMainDialogSettingsTitle => 'Přizpůsobit nástěnku';

  @override
  String homePiggyLinked(String account) {
    return 'Připojeno k $account';
  }

  @override
  String get homePiggyNoAccounts => 'Nebyly vytvořeny žádné pokladničky.';

  @override
  String get homePiggyNoAccountsSubtitle =>
      'Vytvořte si nějaké pokladničky ve webovém rozhraní!';

  @override
  String homePiggyRemaining(String amount) {
    return 'Zbývá našetřit: $amount';
  }

  @override
  String homePiggySaved(String amount) {
    return 'Dosud našetřeno: $amount';
  }

  @override
  String get homePiggySavedMultiple => 'Dosud ušetřeno:';

  @override
  String homePiggyTarget(String amount) {
    return 'Cílová částka: $amount';
  }

  @override
  String get homePiggyAccountStatus => 'Stav účtu';

  @override
  String get homePiggyAvailableAmounts => 'Dostupné částky';

  @override
  String homePiggyAvailable(String amount) {
    return 'K dispozici: $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'V prasátkách: $amount';
  }

  @override
  String get homeTabLabelBalance => 'Zůstatek';

  @override
  String get homeTabLabelMain => 'Hlavní';

  @override
  String get homeTabLabelPiggybanks => 'Pokladničky';

  @override
  String get homeTabLabelTransactions => 'Transakce';

  @override
  String get homeTransactionsActionFilter => 'Seznam filtrů';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<Všechny účty>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<Všechny účty>';

  @override
  String get homeTransactionsDialogFilterBillUnset =>
      '<Žádný účet není nastaven>';

  @override
  String get homeTransactionsDialogFilterBudgetsAll => '<Všechny rozpočty>';

  @override
  String get homeTransactionsDialogFilterBudgetUnset =>
      '<Nebyl vybrán žádný rozpočeet>';

  @override
  String get homeTransactionsDialogFilterCategoriesAll => '<Všechny kategorie>';

  @override
  String get homeTransactionsDialogFilterCategoryUnset =>
      '<Žádná kategorie není nastavena>';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<Všechny měny>';

  @override
  String get homeTransactionsDialogFilterDateRange => 'Rozsah dat';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'Zobrazit budoucí transakce';

  @override
  String get homeTransactionsDialogFilterSearch => 'Hledaný výraz';

  @override
  String get homeTransactionsDialogFilterTitle => 'Vybrat filtry';

  @override
  String get homeTransactionsEmpty => 'Nebyly nalezeny žádné transakce.';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num kategorií';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'Zobrazit štítky v seznamu transakcí';

  @override
  String get liabilityDirectionCredit => 'Je mi dlužen tento dluh';

  @override
  String get liabilityDirectionDebit => 'Já dlužím tento dluh';

  @override
  String get liabilityTypeDebt => 'Dluh';

  @override
  String get liabilityTypeLoan => 'Půjčka';

  @override
  String get liabilityTypeMortgage => 'Hypotéka';

  @override
  String get loginAbout =>
      'Pro používání Waterfly III potřebujete vlastní server s instancí Firefly III nebo doplněk Firefly III v rámci služby Home Assistant.\n\nZadejte celou adresu URL spolu s vaším osobním přístupovým tokenem (Možnosti -> Profil -> OAuth -> Osobní přístupový token) níže.';

  @override
  String get loginFormLabelAPIKey => 'Platný klíč API';

  @override
  String get loginFormLabelHost => 'URL serveru';

  @override
  String get loginWelcome => 'Vítejte ve Waterfly III';

  @override
  String get logoutConfirmation => 'Opravdu se chcete odhlásit?';

  @override
  String get navigationAccounts => 'Účty';

  @override
  String get navigationBills => 'Předplatné';

  @override
  String get navigationCategories => 'Kategorie';

  @override
  String get navigationMain => 'Přehled';

  @override
  String get generalSettings => 'Nastavení';

  @override
  String get no => 'Ne';

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
      'Zde můžete povolit a odeslat protokoly ladění. Toto nastavení má negativní dopad na výkon aplikace, proto je prosím nepovolujte pokud to není nutné. Zakázáním logování bude odstraněn uložený protokol.';

  @override
  String get settingsDialogDebugMailCreate => 'Vytvořit e-mail';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      'VAROVÁNÍ: Bude otevřen koncept e-mailu s přiloženým log souborem (v textovém formátu). Protokoly mohou obsahovat citlivé informace, například název a doménu Vaší instance Firefly (přestože se snažím zabránit logování jakýchkoliv citlivých informací, jako je API klíč). Prosím přečtěte si pečlivě přiložený log a odeberte jakékoliv informace, které nechcete sdílet a/nebo nejsou relevantní pro problém, který chcete nahlásit.\n\nNeposílejte prosím žádné logy bez předchozí domluvy prostřednictvím e-mailu nebo GitHub. Z důvodů ochrany osobních údajů smažu všechny protokoly odeslané bez kontextu. Nikdy nenahrávejte necenzurovaný log na GitHub nebo kamkoliv jinam.';

  @override
  String get settingsDialogDebugSendButton => 'Poslat protokoly přes e-mail';

  @override
  String get settingsDialogDebugTitle => 'Protokoly ladění';

  @override
  String get settingsDialogLanguageTitle => 'Vyberte jazyk';

  @override
  String get settingsDialogThemeTitle => 'Vyberte motiv';

  @override
  String get settingsFAQ => 'Často kladené dotazy';

  @override
  String get settingsFAQHelp =>
      'Otevře se v prohlížeči. Dostupné pouze v angličtině.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configure offline sync and mobile data usage';

  @override
  String get settingsLanguage => 'Jazyk';

  @override
  String get settingsLockscreen => 'Obrazovka uzamčení';

  @override
  String get settingsLockscreenHelp =>
      'Při spuštění aplikace požadovat ověření';

  @override
  String get settingsLockscreenInitial =>
      'Pro povolení zamykací obrazovky se prosím ověřte.';

  @override
  String get settingsNLAppAccount => 'Výchozí účet';

  @override
  String get settingsNLAppAccountDynamic => '<Dynamický>';

  @override
  String get settingsNLAppAdd => 'Přidat aplikaci';

  @override
  String get settingsNLAppAddHelp =>
      'Kliknutím přidáte aplikaci, které má aplikace poslouchat. V seznamu se zobrazí pouze podporované aplikace.';

  @override
  String get settingsNLAppAddInfo =>
      'Pro přidání aplikací do tohoto seznamu proveďte transakce, při kterých obdržíte oznámení v telefonu. Pokud se aplikace přesto nezobrazí, nahlaste to prosím na app@vogt.pw.';

  @override
  String get settingsNLAutoAdd => 'Vytvořit transakci bez interakce';

  @override
  String get settingsNLDescription =>
      'Tato služba umožňuje načíst podrobnosti o transakcích z příchozích oznámení. Kromě toho si můžete vybrat výchozí účet, ke kterému by měla být transakce přiřazena — pokud není nastavena žádná hodnota, služba se pokusí získat účet z textu oznámení.';

  @override
  String get settingsNLEmptyNote => 'Ponechat pole poznámky prázdné';

  @override
  String get settingsNLPermissionGrant => 'Klepnutím udělte oprávnění.';

  @override
  String get settingsNLPermissionNotGranted => 'Oprávnění nebylo uděleno.';

  @override
  String get settingsNLPermissionRemove => 'Odstranit oprávnění?';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'Chcete-li zakázat tuto službu, klikněte na aplikaci a odeberte oprávnění na další obrazovce.';

  @override
  String get settingsNLPrefillTXTitle =>
      'Doplnit název transakce pomocí nadpisu nofikace';

  @override
  String get settingsNLServiceChecking => 'Kontroluji stav…';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'Chyba při kontrole stavu: $error';
  }

  @override
  String get settingsNLServiceRunning => 'Služba je spuštěna.';

  @override
  String get settingsNLServiceStatus => 'Stav služby';

  @override
  String get settingsNLServiceStopped => 'Služba je zastavena.';

  @override
  String get settingsNotificationListener => 'Služba pro čtení oznámení';

  @override
  String get settingsTheme => 'Motiv aplikace';

  @override
  String get settingsThemeDynamicColors => 'Dynamické barvy';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'Tmavý motiv',
      'light': 'Světlý motiv',
      'other': 'Výchozí systému',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone => 'Použít časové pásmo serveru';

  @override
  String get settingsUseServerTimezoneHelp =>
      'Zobrazit všechny časy v časovém pásmu serveru. Toto napodobuje chování webového rozhraní.';

  @override
  String get settingsVersion => 'Verze aplikace';

  @override
  String get settingsVersionChecking => 'kontroluji…';

  @override
  String get transactionAttachments => 'Přílohy';

  @override
  String get transactionDeleteConfirm =>
      'Opravdu chcete tuto transakci smazat?';

  @override
  String get transactionDialogAttachmentsDelete => 'Smazat přílohu';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      'Opravdu chcete tuto přílohu smazat?';

  @override
  String get transactionDialogAttachmentsErrorDownload =>
      'Soubor se nepodařilo stáhnout.';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'Nepodařilo se otevřít soubor: $error';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'Nepodařilo se nahrát soubor: $error';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'Přílohy';

  @override
  String get transactionDialogBillNoBill => 'Žádný účet';

  @override
  String get transactionDialogBillTitle => 'Odkaz na účet';

  @override
  String get transactionDialogCurrencyTitle => 'Vybrat měnu';

  @override
  String get transactionDialogPiggyNoPiggy => 'No Piggy Bank';

  @override
  String get transactionDialogPiggyTitle => 'Link to Piggy Bank';

  @override
  String get transactionDialogTagsAdd => 'Přidat štítek';

  @override
  String get transactionDialogTagsHint => 'Hledat/Přidat štítek';

  @override
  String get transactionDialogTagsTitle => 'Vybrat štítky';

  @override
  String get transactionDuplicate => 'Duplikovat';

  @override
  String get transactionErrorInvalidAccount => 'Neplatný účet';

  @override
  String get transactionErrorInvalidBudget => 'Neplatný rozpočet';

  @override
  String get transactionErrorNoAccounts => 'Prosím, nejprve vyplňte účty.';

  @override
  String get transactionErrorNoAssetAccount =>
      'Prosím, vyberte majetkový účet.';

  @override
  String get transactionErrorTitle => 'Zadejte prosím název.';

  @override
  String get transactionFormLabelAccountDestination => 'Cílový účet';

  @override
  String get transactionFormLabelAccountForeign => 'Zahraniční účet';

  @override
  String get transactionFormLabelAccountOwn => 'Vlastní účet';

  @override
  String get transactionFormLabelAccountSource => 'Zdrojový účet';

  @override
  String get transactionFormLabelNotes => 'Poznámky';

  @override
  String get transactionFormLabelTags => 'Štítky';

  @override
  String get transactionFormLabelTitle => 'Název transakce';

  @override
  String get transactionSplitAdd => 'Přidat rozdělenou transakci';

  @override
  String get transactionSplitChangeCurrency => 'Změnit rozdělenou měnu';

  @override
  String get transactionSplitChangeDestinationAccount =>
      'Změnit cílový účet rozdělené transakce';

  @override
  String get transactionSplitChangeSourceAccount =>
      'Změnit zdrojový účet rozdělené transakce';

  @override
  String get transactionSplitChangeTarget => 'Změnit cílový účet rozdělení';

  @override
  String get transactionSplitDelete => 'Odstranit rozdělení';

  @override
  String get transactionTitleAdd => 'Přidat transakci';

  @override
  String get transactionTitleDelete => 'Smazat transakci';

  @override
  String get transactionTitleEdit => 'Upravit transakci';

  @override
  String get transactionTypeDeposit => 'Vklad';

  @override
  String get transactionTypeTransfer => 'Převod';

  @override
  String get transactionTypeWithdrawal => 'Výběr';

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
