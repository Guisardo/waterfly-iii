// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class SHu extends S {
  SHu([String locale = 'hu']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'Készpénz';

  @override
  String get accountRoleAssetCC => 'Hitelkártya';

  @override
  String get accountRoleAssetDefault => 'Alapértelmezett vagyon számla';

  @override
  String get accountRoleAssetSavings => 'Megtakarítási számla';

  @override
  String get accountRoleAssetShared => 'Megosztott vagyon számla';

  @override
  String get accountsLabelAsset => 'Eszközszámlák';

  @override
  String get accountsLabelExpense => 'Költségszámlák';

  @override
  String get accountsLabelLiabilities => 'Kötelezettségek';

  @override
  String get accountsLabelRevenue => 'Bevételi Számlák';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'hét',
      'monthly': 'hónap',
      'quarterly': 'negyedév',
      'halfyear': 'félév',
      'yearly': 'év',
      'other': 'ismeretlen',
    });
    return '$interest% kamat per $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Heti',
      'monthly': 'Havi',
      'quarterly': 'Negyedéves',
      'halfyear': 'Féléves',
      'yearly': 'Éves',
      'other': 'Ismeretlen',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', $skip ismétlést átugorva',
      zero: '',
    );
    return 'A számla $minValue és $maxvalue közötti értékű tranzakcióknak felel meg. $_temp0 ismétlődésű$_temp1.';
  }

  @override
  String get billsChangeLayoutTooltip => 'Elrendezés módosítása';

  @override
  String get billsChangeSortOrderTooltip => 'Rendezési sorrend módosítása';

  @override
  String get billsErrorLoading => 'Hiba a számla betöltése során.';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Heti',
      'monthly': 'Havi',
      'quarterly': 'Negyedéves',
      'halfyear': 'Féléves',
      'yearly': 'Éves',
      'other': 'Ismeretlen',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', $skip ismétlést átugorva',
      zero: '',
    );
    return 'A számla $value értékű tranzakcióknak felel meg. $_temp0 ismétlődésű$_temp1.';
  }

  @override
  String billsExpectedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Várható dátum $dateString';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Heti',
      'monthly': 'Havi',
      'quarterly': 'Negyedéves',
      'halfyear': 'Féléves',
      'yearly': 'Éves',
      'other': 'Ismeretlen',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Heti',
      'monthly': 'Havi',
      'quarterly': 'Negyedéves',
      'halfyear': 'Féléves',
      'yearly': 'Éves',
      'other': 'Ismeretlen',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', $skip ismétlést átugorva',
      zero: '',
    );
    return '$_temp0 ismétlődésű$_temp1';
  }

  @override
  String get billsInactive => 'Inaktív';

  @override
  String get billsIsActive => 'Aktív számla';

  @override
  String get billsLayoutGroupSubtitle =>
      'Számlák megjelenítése a hozzájuk rendelt csoportokban.';

  @override
  String get billsLayoutGroupTitle => 'Csoport';

  @override
  String get billsLayoutListSubtitle =>
      'Számlák megjelenítése egy listában bizonyos kritériumok szerint rendezve.';

  @override
  String get billsLayoutListTitle => 'Lista';

  @override
  String get billsListEmpty => 'A lista jelenleg üres.';

  @override
  String get billsNextExpectedMatch => 'Következő várható egyezés';

  @override
  String get billsNotActive => 'Inaktív számla';

  @override
  String get billsNotExpected => 'Nem várható ebben az időszakban';

  @override
  String get billsNoTransactions => 'Nem található tranzakció.';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Kifizetés dátuma $dateString';
  }

  @override
  String get billsSortAlphabetical => 'Betűrendi';

  @override
  String get billsSortByTimePeriod => 'Időszak szerint';

  @override
  String get billsSortFrequency => 'Gyakoriság';

  @override
  String get billsSortName => 'Név';

  @override
  String get billsUngrouped => 'Csoportosítatlan';

  @override
  String get billsSettingsShowOnlyActive => 'Csak az aktívak';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'Csak az aktív előfizetéseket mutatja.';

  @override
  String get billsSettingsShowOnlyExpected => 'Csak a várhatók';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'Csak azokat az előfizetéseket mutatja, amelyek várhatóak (vagy kifizetésre kerültek) ebben a hónapban.';

  @override
  String get categoryDeleteConfirm =>
      'Biztosan törli ezt a kategóriát? A tranzakciók nem kerülnek törlésre, ugyanakkor nem lesznek kategóriához rendelve.';

  @override
  String get categoryErrorLoading => 'Hiba a kategóriák betöltése során.';

  @override
  String get categoryFormLabelIncludeInSum => 'Beleszámítani a havi összegbe';

  @override
  String get categoryFormLabelName => 'Kategória neve';

  @override
  String get categoryMonthNext => 'Következő hónap';

  @override
  String get categoryMonthPrev => 'Előző hónap';

  @override
  String get categorySumExcluded => 'nem számított';

  @override
  String get categoryTitleAdd => 'Kategória hozzáadása';

  @override
  String get categoryTitleDelete => 'Kategória törlése';

  @override
  String get categoryTitleEdit => 'Kategória szerkesztése';

  @override
  String get catNone => '<nincs kategória>';

  @override
  String get catOther => 'Egyéb';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'Érvénytelen válasz az API-tól: $message';
  }

  @override
  String get errorAPIUnavailable => 'API nem érhető el';

  @override
  String get errorFieldRequired => 'A mező kitöltése kötelező.';

  @override
  String get errorInvalidURL => 'Érvénytelen URL';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'Minimális támogatott Firefly API-verzió: v$requiredVersion. Kérjük, frissítsen.';
  }

  @override
  String errorStatusCode(int code) {
    return 'Státusz kód: $code';
  }

  @override
  String get errorUnknown => 'Ismeretlen hiba.';

  @override
  String get formButtonHelp => 'Súgó';

  @override
  String get formButtonLogin => 'Bejelentkezés';

  @override
  String get formButtonLogout => 'Kijelentkezés';

  @override
  String get formButtonRemove => 'Eltávolítás';

  @override
  String get formButtonResetLogin => 'A bejelentkezés visszaállítása';

  @override
  String get formButtonTransactionAdd => 'Tranzakció Hozzáadása';

  @override
  String get formButtonTryAgain => 'Próbálja újra';

  @override
  String get generalAccount => 'Számla';

  @override
  String get generalAssets => 'Vagyonok';

  @override
  String get generalBalance => 'Egyenleg';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Egyenleg ekkor: $dateString';
  }

  @override
  String get generalBill => 'Számla';

  @override
  String get generalBudget => 'Költségkeret';

  @override
  String get generalCategory => 'Kategória';

  @override
  String get generalCurrency => 'Pénznem';

  @override
  String get generalDateRangeCurrentMonth => 'Aktuális hónap';

  @override
  String get generalDateRangeLast30Days => 'Utolsó 30 nap';

  @override
  String get generalDateRangeCurrentYear => 'Aktuális év';

  @override
  String get generalDateRangeLastYear => 'Előző év';

  @override
  String get generalDateRangeAll => 'Összes';

  @override
  String get generalDefault => 'alapértelmezett';

  @override
  String get generalDestinationAccount => 'Célszámla';

  @override
  String get generalDismiss => 'Elvetés';

  @override
  String get generalEarned => 'Megkeresett';

  @override
  String get generalError => 'Hiba';

  @override
  String get generalExpenses => 'Kiadások';

  @override
  String get generalIncome => 'Bevétel';

  @override
  String get generalLiabilities => 'Kötelezettségek';

  @override
  String get generalMultiple => 'több';

  @override
  String get generalNever => 'soha';

  @override
  String get generalReconcile => 'Egyeztetve';

  @override
  String get generalReset => 'Visszaállítás';

  @override
  String get generalSourceAccount => 'Forrásszámla';

  @override
  String get generalSpent => 'Elköltött';

  @override
  String get generalSum => 'Összesen';

  @override
  String get generalTarget => 'Cél';

  @override
  String get generalUnknown => 'Ismeretlen';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'heti',
      'monthly': 'havi',
      'quarterly': 'negyedéves',
      'halfyear': 'féléves',
      'yearly': 'éves',
      'other': 'ismeretlen',
    });
    return ' ($_temp0)';
  }

  @override
  String get homeMainBillsTitle => 'Számlák a következő hétre';

  @override
  String homeMainBudgetInterval(DateTime from, DateTime to, String period) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' (Ettől: $fromString eddig: $toString, $period)';
  }

  @override
  String homeMainBudgetIntervalSingle(DateTime from, DateTime to) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' (Ettől: $fromString eddig: $toString)';
  }

  @override
  String homeMainBudgetSum(String current, String status, String available) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'over': 'többletköltség a',
      'other': 'maradt a',
    });
    String _temp1 = intl.Intl.selectLogic(status, {
      'over': 'limithez képest',
      'other': 'limitből',
    });
    return '$current $_temp0 $available $_temp1';
  }

  @override
  String get homeMainBudgetTitle => 'Költségkeretek erre a hónapra';

  @override
  String get homeMainChartAccountsTitle => 'Számla Áttekintése';

  @override
  String get homeMainChartCategoriesTitle =>
      'Kategória összefoglaló az aktuális hónapra';

  @override
  String get homeMainChartDailyAvg => '7 napi átlag';

  @override
  String get homeMainChartDailyTitle => 'Napi Összefoglaló';

  @override
  String get homeMainChartNetEarningsTitle => 'Nettó Kereset';

  @override
  String get homeMainChartNetWorthTitle => 'Nettó Érték';

  @override
  String get homeMainChartTagsTitle => 'Címke összefoglaló az aktuális hónapra';

  @override
  String get homePiggyAdjustDialogTitle => 'Pénz megtakarítása/költése';

  @override
  String homePiggyDateStart(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Kezdés dátuma: $dateString';
  }

  @override
  String homePiggyDateTarget(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Céldátum: $dateString';
  }

  @override
  String get homeMainDialogSettingsTitle => 'Műszerfal testreszabása';

  @override
  String homePiggyLinked(String account) {
    return 'Összekapcsolva a következővel: $account';
  }

  @override
  String get homePiggyNoAccounts => 'Még nincsenek malacperselyek.';

  @override
  String get homePiggyNoAccountsSubtitle =>
      'Hozzon létre néhányat a webes felületen!';

  @override
  String homePiggyRemaining(String amount) {
    return 'Megtakarításra váró összeg: $amount';
  }

  @override
  String homePiggySaved(String amount) {
    return 'Eddig megtakarított összeg: $amount';
  }

  @override
  String get homePiggySavedMultiple => 'Eddig megtakarítva:';

  @override
  String homePiggyTarget(String amount) {
    return 'Célösszeg: $amount';
  }

  @override
  String get homePiggyAccountStatus => 'Számla állapota';

  @override
  String get homePiggyAvailableAmounts => 'Rendelkezésre álló összegek';

  @override
  String homePiggyAvailable(String amount) {
    return 'Rendelkezésre álló: $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'Perselyekben: $amount';
  }

  @override
  String get homeTabLabelBalance => 'Mérleg';

  @override
  String get homeTabLabelMain => 'Kezdőlap';

  @override
  String get homeTabLabelPiggybanks => 'Malacperselyek';

  @override
  String get homeTabLabelTransactions => 'Tranzakciók';

  @override
  String get homeTransactionsActionFilter => 'Szűrő lista';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<Összes Számla>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<Összes Számla>';

  @override
  String get homeTransactionsDialogFilterBillUnset =>
      '<Nincs Számla Kiválasztva>';

  @override
  String get homeTransactionsDialogFilterBudgetsAll => '<Összes Költségkeret>';

  @override
  String get homeTransactionsDialogFilterBudgetUnset =>
      '<Nincs Költségkeret Kiválasztva>';

  @override
  String get homeTransactionsDialogFilterCategoriesAll => '<Összes Kategória>';

  @override
  String get homeTransactionsDialogFilterCategoryUnset =>
      '<Nincs Kategória Kiválasztva>';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<Összes Pénznem>';

  @override
  String get homeTransactionsDialogFilterDateRange => 'Dátumtartomány';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'Jövőbeli tranzakciók megjelenítése';

  @override
  String get homeTransactionsDialogFilterSearch => 'Keresési Kifejezés';

  @override
  String get homeTransactionsDialogFilterTitle => 'Szűrők kiválasztása';

  @override
  String get homeTransactionsEmpty => 'Nem található tranzakció.';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num kategória';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'Címkék megjelenítése a tranzakciós listában';

  @override
  String get liabilityDirectionCredit => 'Tartoznak nekem ezzel az adóssággal';

  @override
  String get liabilityDirectionDebit => 'Tartozom ezzel az adóssággal';

  @override
  String get liabilityTypeDebt => 'Adósság';

  @override
  String get liabilityTypeLoan => 'Kölcsön';

  @override
  String get liabilityTypeMortgage => 'Jelzálog';

  @override
  String get loginAbout =>
      'A Waterfly III hatékony használatához saját szerveren futtatott Firefly III-ra vagy Firefly III kiegészítővel ellátott Home Assistant-re van szükség.\n\nKérjük, adja meg alább a teljes URL-t, valamint egy személyes hozzáférési tokent (Beállítások -> Profil -> OAuth -> Személyes hozzáférési tokenek).';

  @override
  String get loginFormLabelAPIKey => 'Érvényes API kulcs';

  @override
  String get loginFormLabelHost => 'Szerver URL';

  @override
  String get loginWelcome => 'Üdvözöljük a Waterfly III-ban';

  @override
  String get logoutConfirmation => 'Biztos, hogy ki szeretne jelentkezni?';

  @override
  String get navigationAccounts => 'Fiókok';

  @override
  String get navigationBills => 'Számlák';

  @override
  String get navigationCategories => 'Kategóriák';

  @override
  String get navigationMain => 'Főoldal';

  @override
  String get generalSettings => 'Beállítások';

  @override
  String get no => 'Nem';

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

    return '$of $percString-a';
  }

  @override
  String get settingsDialogDebugInfo =>
      'Itt engedélyezheti és küldheti el a hibakeresési naplókat. A naplók gyűjtése rossz hatással van a teljesítményre, ezért kérjük, ne engedélyezze őket, hacsak nem kapott erre javaslatot. A naplózás letiltása törli a tárolt naplót.';

  @override
  String get settingsDialogDebugMailCreate => 'Levél Létrehozása';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      'FIGYELMEZTETÉS: Egy levél piszkozat fog megnyílni a csatolt naplófájllal (szöveg formátumban). A naplók érzékeny információkat tartalmazhatnak, például a Firefly-példány gazdagépnevét (bár igyekszem elkerülni a titkok, például az API-kulcs naplózását). Kérjük, figyelmesen olvassa el a naplót, és cenzúrázzon minden olyan információt, amelyet nem szeretne megosztani, és/vagy nem kapcsolódik a jelenteni kívánt problémához.\n\nKérjük, ne küldjön naplókat előzetes egyeztetés nélkül e-mailben/GitHubon keresztül. Adatvédelmi okokból törlöm a kontextus nélkül küldött naplókat. Soha ne töltse fel a naplót cenzúrázatlanul a GitHub-ra vagy máshová.';

  @override
  String get settingsDialogDebugSendButton => 'Naplók küldése e-mailben';

  @override
  String get settingsDialogDebugTitle => 'Hibakeresési Naplók';

  @override
  String get settingsDialogLanguageTitle => 'Nyelv Kiválasztása';

  @override
  String get settingsDialogThemeTitle => 'Téma Kiválasztása';

  @override
  String get settingsFAQ => 'GYIK';

  @override
  String get settingsFAQHelp =>
      'Megnyitás böngészőben. Csak angol nyelven elérhető.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configure offline sync and mobile data usage';

  @override
  String get settingsLanguage => 'Nyelv';

  @override
  String get settingsLockscreen => 'Zárképernyő';

  @override
  String get settingsLockscreenHelp =>
      'Hitelesítés szükséges az alkalmazás indításakor';

  @override
  String get settingsLockscreenInitial =>
      'A lezárási képernyő engedélyezéséhez hitelesítsen.';

  @override
  String get settingsNLAppAccount => 'Alapértelmezett Számla';

  @override
  String get settingsNLAppAccountDynamic => '<Dinamikus>';

  @override
  String get settingsNLAppAdd => 'Alkalmazás Hozzáadása';

  @override
  String get settingsNLAppAddHelp =>
      'Kattintson a figyelni kívánt alkalmazás hozzáadásához. Csak az erre jogosult alkalmazások jelennek meg a listában.';

  @override
  String get settingsNLAppAddInfo =>
      'Egy alkalmazás ezen listához adásához indítson olyan tranzakciókat amelyek telefonértesítéseket generálnak. Ha az alkalmazás továbbra sem jelenik meg, kérjük, jelentse az app@vogt.pw email címre írva.';

  @override
  String get settingsNLAutoAdd =>
      'Tranzakció létrehozása felhasználói beavatkozás nélkül';

  @override
  String get settingsNLDescription =>
      'Ez a szolgáltatás lehetővé teszi a tranzakció részleteinek lekérését a bejövő értesítésekből. Továbbá kiválaszthat egy alapértelmezett számlát, amelyhez a tranzakciót hozzá kívánja rendelni - amennyiben ez nincs beállítva, akkor a szolgáltatás az értesítés szövegéből kisérli meg annak kinyerését.';

  @override
  String get settingsNLEmptyNote => 'A \"Jegyzetek\" mező maradjon üres';

  @override
  String get settingsNLPermissionGrant => 'Koppintson az engedélyezéshez.';

  @override
  String get settingsNLPermissionNotGranted => 'Hozzáférés megtagadva.';

  @override
  String get settingsNLPermissionRemove => 'Eltávolítja a jogosultságot?';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'A szolgáltatás letiltásához kattintson az alkalmazásra, majd távolítsa el az engedélyeket a következő képernyőn.';

  @override
  String get settingsNLPrefillTXTitle =>
      'A tranzakció leírásának előzetes kitöltése az értesítés címével';

  @override
  String get settingsNLServiceChecking => 'Állapot ellenőrzése…';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'Hibaellenőrzés állapota: $error';
  }

  @override
  String get settingsNLServiceRunning => 'A szolgáltatás fut.';

  @override
  String get settingsNLServiceStatus => 'Szolgáltatás Állapota';

  @override
  String get settingsNLServiceStopped => 'A szolgáltatás leállt.';

  @override
  String get settingsNotificationListener => 'Értesítés Figyelő Szolgáltatás';

  @override
  String get settingsTheme => 'Alkalmazás Téma';

  @override
  String get settingsThemeDynamicColors => 'Dinamikus Színek';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'Sötét',
      'light': 'Világos',
      'other': 'Alapértelmezett',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone => 'Használja a szerver időzónáját';

  @override
  String get settingsUseServerTimezoneHelp =>
      'Minden időpont megjelenítése a szerver időzónájában. Ez a webes felület viselkedését utánozza.';

  @override
  String get settingsVersion => 'Alkalmazás Verzió';

  @override
  String get settingsVersionChecking => 'ellenőrzés…';

  @override
  String get transactionAttachments => 'Mellékletek';

  @override
  String get transactionDeleteConfirm =>
      'Biztos benne, hogy törölni szeretné ezt a tranzakciót?';

  @override
  String get transactionDialogAttachmentsDelete => 'Melléklet Törlése';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      'Biztos benne, hogy törölni szeretné ezt a mellékletet?';

  @override
  String get transactionDialogAttachmentsErrorDownload =>
      'Nem sikerült letölteni a fájlt.';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'Nem sikerült megnyitni a fájlt: $error';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'Nem sikerült feltölteni a fájlt: $error';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'Mellékletek';

  @override
  String get transactionDialogBillNoBill => 'Nincs számla';

  @override
  String get transactionDialogBillTitle => 'Számlához Rendelés';

  @override
  String get transactionDialogCurrencyTitle => 'Pénznem kiválasztása';

  @override
  String get transactionDialogPiggyNoPiggy => 'Nincs malacpersely';

  @override
  String get transactionDialogPiggyTitle => 'Kapcsolás malacperselyhez';

  @override
  String get transactionDialogTagsAdd => 'Címke hozzáadása';

  @override
  String get transactionDialogTagsHint => 'Címke keresése/hozzáadása';

  @override
  String get transactionDialogTagsTitle => 'Címke kiválasztása';

  @override
  String get transactionDuplicate => 'Duplikálás';

  @override
  String get transactionErrorInvalidAccount => 'Érvénytelen Számla';

  @override
  String get transactionErrorInvalidBudget => 'Érvénytelen Költségkeret';

  @override
  String get transactionErrorNoAccounts =>
      'Kérjük, először töltse ki a számlákat.';

  @override
  String get transactionErrorNoAssetAccount =>
      'Kérjük, válasszon ki egy eszközzámlát.';

  @override
  String get transactionErrorTitle => 'Kérjük, adjon meg egy leírást.';

  @override
  String get transactionFormLabelAccountDestination => 'Célszámla';

  @override
  String get transactionFormLabelAccountForeign => 'Külföldi számla';

  @override
  String get transactionFormLabelAccountOwn => 'Saját számla';

  @override
  String get transactionFormLabelAccountSource => 'Forrás számla';

  @override
  String get transactionFormLabelNotes => 'Jegyzetek';

  @override
  String get transactionFormLabelTags => 'Címkék';

  @override
  String get transactionFormLabelTitle => 'Tranzakció Leírása';

  @override
  String get transactionSplitAdd => 'Osztott tranzakció hozzáadása';

  @override
  String get transactionSplitChangeCurrency =>
      'Felosztás Pénznemének Megváltoztatása';

  @override
  String get transactionSplitChangeDestinationAccount =>
      'Részletes felosztás célszámlájának módosítása';

  @override
  String get transactionSplitChangeSourceAccount =>
      'Részletes felosztás forrásszámlájának módosítása';

  @override
  String get transactionSplitChangeTarget =>
      'Felosztás Célszámlájának Megváltoztatása';

  @override
  String get transactionSplitDelete => 'Felosztás törlése';

  @override
  String get transactionTitleAdd => 'Tranzakció Hozzáadása';

  @override
  String get transactionTitleDelete => 'Tranzakció Törlése';

  @override
  String get transactionTitleEdit => 'Tranzakció Szerkesztése';

  @override
  String get transactionTypeDeposit => 'Bevétel';

  @override
  String get transactionTypeTransfer => 'Átvezetés';

  @override
  String get transactionTypeWithdrawal => 'Költség';

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
