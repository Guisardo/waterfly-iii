// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class SSl extends S {
  SSl([String locale = 'sl']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'Gotovina';

  @override
  String get accountRoleAssetCC => 'Kreditna kartica';

  @override
  String get accountRoleAssetDefault => 'Privzeti premoženjski račun';

  @override
  String get accountRoleAssetSavings => 'Varčevalni račun';

  @override
  String get accountRoleAssetShared => 'Skupni račun sredstev';

  @override
  String get accountsLabelAsset => 'Računi sredstev';

  @override
  String get accountsLabelExpense => 'Računi stroškov';

  @override
  String get accountsLabelLiabilities => 'Obveznosti';

  @override
  String get accountsLabelRevenue => 'Računi prihodkov';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'tedensko',
      'monthly': 'mesečno',
      'quarterly': 'četrtletno',
      'halfyear': 'polletno',
      'yearly': 'letno',
      'other': 'neznano',
    });
    return '$interest% obresti $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'tedensko',
      'monthly': 'mesečno',
      'quarterly': 'četrtletno',
      'halfyear': 'polletno',
      'yearly': 'letno',
      'other': 'neznano',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', preskoči čez $skip',
      zero: '',
    );
    return 'Račun se ujema s transakcijami med $minValue in $maxvalue. Ponavlja se $_temp0$_temp1.';
  }

  @override
  String get billsChangeLayoutTooltip => 'Spremeni postavitev';

  @override
  String get billsChangeSortOrderTooltip => 'Spremeni vrstni red';

  @override
  String get billsErrorLoading => 'Napaka pri nalaganju transakcij.';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'tedensko',
      'monthly': 'mesečno',
      'quarterly': 'četrtletno',
      'halfyear': 'polletno',
      'yearly': 'letno',
      'other': 'neznano',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', preskoči čez $skip',
      zero: '',
    );
    return 'Račun se ujema s transakcijami v vrednosti $value. Ponavlja se $_temp0$_temp1.';
  }

  @override
  String billsExpectedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Predvideno $dateString';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Tedensko',
      'monthly': 'Mesečno',
      'quarterly': 'Četrtletno',
      'halfyear': 'Polletno',
      'yearly': 'Letno',
      'other': 'Neznano',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Tedensko',
      'monthly': 'Mesečno',
      'quarterly': 'Četrtletno',
      'halfyear': 'Polletno',
      'yearly': 'Letno',
      'other': 'Neznano',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', preskoči čez $skip',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get billsInactive => 'Neaktiven';

  @override
  String get billsIsActive => 'Transakcija je aktivna';

  @override
  String get billsLayoutGroupSubtitle =>
      'Transakcije, prikazane v dodeljenih skupinah.';

  @override
  String get billsLayoutGroupTitle => 'Skupina';

  @override
  String get billsLayoutListSubtitle =>
      'Transakcije prikazane na seznamu, razvrščenem po določenih kriterijih.';

  @override
  String get billsLayoutListTitle => 'Seznam';

  @override
  String get billsListEmpty => 'Seznam je trenutno prazen.';

  @override
  String get billsNextExpectedMatch => 'Naslednje pričakovano ujemanje';

  @override
  String get billsNotActive => 'Transakcija ni aktivna';

  @override
  String get billsNotExpected => 'Ni pričakovano v tem obdobju';

  @override
  String get billsNoTransactions => 'Ni najdenih transakcij.';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Plačano dne $dateString';
  }

  @override
  String get billsSortAlphabetical => 'Po abecedi';

  @override
  String get billsSortByTimePeriod => 'Po časovnem obdobju';

  @override
  String get billsSortFrequency => 'Pogostost';

  @override
  String get billsSortName => 'Naziv';

  @override
  String get billsUngrouped => 'Nezdruženo';

  @override
  String get billsSettingsShowOnlyActive => 'Prikaži samo aktivne';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'Prikazuje samo aktivne naročnine.';

  @override
  String get billsSettingsShowOnlyExpected => 'Prikaži samo pričakovano';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'Prikazuje samo tiste naročnine, ki so pričakovane (ali plačane) ta mesec.';

  @override
  String get categoryDeleteConfirm =>
      'Ali ste prepričani, da želite izbrisati to kategorijo? Transakcije ne bodo izbrisane, vendar ne bodo imele več kategorije.';

  @override
  String get categoryErrorLoading => 'Napaka pri nalaganju kategorij.';

  @override
  String get categoryFormLabelIncludeInSum => 'Vključi v mesečni znesek';

  @override
  String get categoryFormLabelName => 'Ime kategorije';

  @override
  String get categoryMonthNext => 'Naslednji mesec';

  @override
  String get categoryMonthPrev => 'Prejšnji mesec';

  @override
  String get categorySumExcluded => 'izvzeto';

  @override
  String get categoryTitleAdd => 'Dodaj kategorijo';

  @override
  String get categoryTitleDelete => 'Izbriši kategorijo';

  @override
  String get categoryTitleEdit => 'Uredi kategorijo';

  @override
  String get catNone => '<brez kategorije>';

  @override
  String get catOther => 'Ostalo';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'Neveljaven odgovor API-ja: $message';
  }

  @override
  String get errorAPIUnavailable => 'API ni na voljo';

  @override
  String get errorFieldRequired => 'To polje je obvezno.';

  @override
  String get errorInvalidURL => 'Neveljaven URL';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'Zahtevana najmanjša različica Firefly API je v$requiredVersion. Prosimo nadgradite.';
  }

  @override
  String errorStatusCode(int code) {
    return 'Statusna koda: $code';
  }

  @override
  String get errorUnknown => 'Neznana napaka.';

  @override
  String get formButtonHelp => 'Pomoč';

  @override
  String get formButtonLogin => 'Prijava';

  @override
  String get formButtonLogout => 'Odjava';

  @override
  String get formButtonRemove => 'Odstrani';

  @override
  String get formButtonResetLogin => 'Ponastavi prijavo';

  @override
  String get formButtonTransactionAdd => 'Dodaj transakcijo';

  @override
  String get formButtonTryAgain => 'Poskusite znova';

  @override
  String get generalAccount => 'Račun';

  @override
  String get generalAssets => 'Sredstva';

  @override
  String get generalBalance => 'Stanje';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Stanje na $dateString';
  }

  @override
  String get generalBill => 'Račun';

  @override
  String get generalBudget => 'Proračun';

  @override
  String get generalCategory => 'Kategorija';

  @override
  String get generalCurrency => 'Valuta';

  @override
  String get generalDateRangeCurrentMonth => 'Trenutni mesec';

  @override
  String get generalDateRangeLast30Days => 'Zadnjih 30 dni';

  @override
  String get generalDateRangeCurrentYear => 'Trenutno leto';

  @override
  String get generalDateRangeLastYear => 'Prejšnje leto';

  @override
  String get generalDateRangeAll => 'Vse';

  @override
  String get generalDefault => 'privzeto';

  @override
  String get generalDestinationAccount => 'Ciljni račun';

  @override
  String get generalDismiss => 'Opusti';

  @override
  String get generalEarned => 'Prisluženo';

  @override
  String get generalError => 'Napaka';

  @override
  String get generalExpenses => 'Stroški';

  @override
  String get generalIncome => 'Prihodek';

  @override
  String get generalLiabilities => 'Obveznosti';

  @override
  String get generalMultiple => 'več';

  @override
  String get generalNever => 'nikoli';

  @override
  String get generalReconcile => 'Usklajeno';

  @override
  String get generalReset => 'Ponastavi';

  @override
  String get generalSourceAccount => 'Izvorni račun';

  @override
  String get generalSpent => 'Porabljeno';

  @override
  String get generalSum => 'Vsota';

  @override
  String get generalTarget => 'Ciljni';

  @override
  String get generalUnknown => 'Neznano';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'tedensko',
      'monthly': 'mesečno',
      'quarterly': 'četrtletno',
      'halfyear': 'polletno',
      'yearly': 'letno',
      'other': 'neznano',
    });
    return ' ($_temp0)';
  }

  @override
  String get homeMainBillsTitle => 'Računi za naslednji teden';

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
      'over': 'čez',
      'other': 'ostane še',
    });
    return '$current $_temp0 $available';
  }

  @override
  String get homeMainBudgetTitle => 'Proračuni za tekoči mesec';

  @override
  String get homeMainChartAccountsTitle => 'Povzetek računa';

  @override
  String get homeMainChartCategoriesTitle =>
      'Povzetek kategorij za tekoči mesec';

  @override
  String get homeMainChartDailyAvg => 'Povprečno 7 dni';

  @override
  String get homeMainChartDailyTitle => 'Dnevno povprečje';

  @override
  String get homeMainChartNetEarningsTitle => 'Neto zaslužek';

  @override
  String get homeMainChartNetWorthTitle => 'Neto vrednost';

  @override
  String get homeMainChartTagsTitle => 'Povzetek oznak za trenutni mesec';

  @override
  String get homePiggyAdjustDialogTitle => 'Prihranek/poraba denarja';

  @override
  String homePiggyDateStart(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Začetni datum: $dateString';
  }

  @override
  String homePiggyDateTarget(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Ciljni datum: $dateString';
  }

  @override
  String get homeMainDialogSettingsTitle => 'Prilagodi nadzorno ploščo';

  @override
  String homePiggyLinked(String account) {
    return 'Povezano z $account';
  }

  @override
  String get homePiggyNoAccounts => 'Nimate še hranilnikov.';

  @override
  String get homePiggyNoAccountsSubtitle =>
      'Ustvarite jih v spletnem vmesniku!';

  @override
  String homePiggyRemaining(String amount) {
    return 'Preostalo za varčevanje: $amount';
  }

  @override
  String homePiggySaved(String amount) {
    return 'Privarčevano do sedaj: $amount';
  }

  @override
  String get homePiggySavedMultiple => 'Privarčevano do sedaj:';

  @override
  String homePiggyTarget(String amount) {
    return 'Ciljni znesek: $amount';
  }

  @override
  String get homePiggyAccountStatus => 'Status računa';

  @override
  String get homePiggyAvailableAmounts => 'Razpoložljivi zneski';

  @override
  String homePiggyAvailable(String amount) {
    return 'Razpoložljivo: $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'V hranilnikih: $amount';
  }

  @override
  String get homeTabLabelBalance => 'Bilanca stanja';

  @override
  String get homeTabLabelMain => 'Glavna';

  @override
  String get homeTabLabelPiggybanks => 'Hranilniki';

  @override
  String get homeTabLabelTransactions => 'Transakcije';

  @override
  String get homeTransactionsActionFilter => 'Seznam filtrov';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<Vsi računi>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<Vsi računi>';

  @override
  String get homeTransactionsDialogFilterBillUnset => '<Ni računov>';

  @override
  String get homeTransactionsDialogFilterBudgetsAll => '<Vsi proračuni>';

  @override
  String get homeTransactionsDialogFilterBudgetUnset =>
      '<Proračuni niso nastavljeni>';

  @override
  String get homeTransactionsDialogFilterCategoriesAll => '<Vse kategorije>';

  @override
  String get homeTransactionsDialogFilterCategoryUnset =>
      '<Kategorije niso nastavljene>';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<Vse valute>';

  @override
  String get homeTransactionsDialogFilterDateRange => 'Časovno območje';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'Prikaži bodoče transakcije';

  @override
  String get homeTransactionsDialogFilterSearch => 'Iskalni pojem';

  @override
  String get homeTransactionsDialogFilterTitle => 'Izberi filter';

  @override
  String get homeTransactionsEmpty => 'Ni najdenih transakcij.';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num kategorij';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'Pokaži oznake na seznamu transakcij';

  @override
  String get liabilityDirectionCredit => 'Dolžan sem ta dolg';

  @override
  String get liabilityDirectionDebit => 'To dolgujem';

  @override
  String get liabilityTypeDebt => 'Dolg';

  @override
  String get liabilityTypeLoan => 'Posojilo';

  @override
  String get liabilityTypeMortgage => 'Hipoteka';

  @override
  String get loginAbout =>
      'Za funkcijsko uporabo Waterfly III potrebujete lasten strežnik z namestitvijo Firefly III ali dodatek Firefly III za Home Assistant.\n\nSpodaj vnesite poln URL in osebni žeton dostopa (Možnosti-> Profil -> OAuth -> Osebni dostopni žetoni).';

  @override
  String get loginFormLabelAPIKey => 'Veljaven API ključ';

  @override
  String get loginFormLabelHost => 'URL gostitelja';

  @override
  String get loginWelcome => 'Dobrodošli v Waterfly III';

  @override
  String get logoutConfirmation => 'Ali ste prepričani, da se želite odjaviti?';

  @override
  String get navigationAccounts => 'Računi';

  @override
  String get navigationBills => 'Transakcije';

  @override
  String get navigationCategories => 'Kategorije';

  @override
  String get navigationMain => 'Glavna nadzorna plošča';

  @override
  String get generalSettings => 'Nastavitve';

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

    return '$percString od $of';
  }

  @override
  String get settingsDialogDebugInfo =>
      'Tukaj lahko omogočite in pošljete dnevnike odpravljanja napak. Vklop slabo vpliva na delovanje aplikacije, zato jih ne omogočite, razen če so vam tako svetovali. Če onemogočite beleženje, boste izbrisali shranjeni dnevnik.';

  @override
  String get settingsDialogDebugMailCreate => 'Ustvari e-pošto';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      'OPOZORILO: Odpre se osnutek pošte s priloženo dnevniško datoteko (v besedilni obliki). Dnevniki lahko vsebujejo občutljive podatke, kot je ime gostitelja vašega primerka Firefly (čeprav se poskušam izogniti zapisovanju kakršnih koli skrivnosti, kot je API ključ). Pozorno preberite dnevnik in cenzurirajte vse informacije, ki jih ne želite deliti in/ali niso pomembne za težavo, ki jo želite prijaviti.\n\nProsimo, ne pošiljajte dnevnikov brez predhodnega dogovora po pošti/GitHubu. Izbrisal bom vse dnevnike, poslane brez konteksta, zaradi zasebnosti. Dnevnika nikoli ne nalagajte necenzuriranega na GitHub ali drugam.';

  @override
  String get settingsDialogDebugSendButton => 'Pošlji dnevnike po e-pošti';

  @override
  String get settingsDialogDebugTitle => 'Debug dnevniki';

  @override
  String get settingsDialogLanguageTitle => 'Izberite jezik';

  @override
  String get settingsDialogThemeTitle => 'Izberite temo';

  @override
  String get settingsFAQ => 'FAQ';

  @override
  String get settingsFAQHelp =>
      'Odpre se v brskalniku. Na voljo samo v angleščini.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configure offline sync and mobile data usage';

  @override
  String get settingsLanguage => 'Jezik';

  @override
  String get settingsLockscreen => 'Zaklenjen zaslon';

  @override
  String get settingsLockscreenHelp =>
      'Zahtevaj preverjanje pristnosti ob zagonu aplikacije';

  @override
  String get settingsLockscreenInitial =>
      'Preverite pristnost, da omogočite zaklenjeni zaslon.';

  @override
  String get settingsNLAppAccount => 'Privzeti račun';

  @override
  String get settingsNLAppAccountDynamic => '<Dinamično>';

  @override
  String get settingsNLAppAdd => 'Dodaj aplikacijo';

  @override
  String get settingsNLAppAddHelp =>
      'Kliknite, če želite dodati aplikacijo za poslušanje. Na seznamu bodo prikazane samo primerne aplikacije.';

  @override
  String get settingsNLAppAddInfo =>
      'Izvedite nekaj transakcij, pri katerih prejmete telefonska obvestila za dodajanje aplikacij na ta seznam. Če se aplikacija še vedno ne prikaže, mi prijavite na app@vogt.pw.';

  @override
  String get settingsNLAutoAdd => 'Ustvari transakcijo brez interakcije';

  @override
  String get settingsNLDescription =>
      'Ta storitev vam omogoča pridobivanje podrobnosti transakcije iz dohodnih potisnih obvestil. Poleg tega lahko izberete privzeti račun, ki naj mu bo dodeljena transakcija - če vrednost ni nastavljena, poskuša iz obvestila izvleči račun.';

  @override
  String get settingsNLEmptyNote => 'Polje za opombo naj bo prazno';

  @override
  String get settingsNLPermissionGrant => 'Pritisnite za odobritev dovoljenja.';

  @override
  String get settingsNLPermissionNotGranted => 'Dovoljenje ni odobreno.';

  @override
  String get settingsNLPermissionRemove => 'Odstrani dovoljenje?';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'Če želite onemogočiti to storitev, kliknite aplikacijo in na naslednjem zaslonu odstranite dovoljenja.';

  @override
  String get settingsNLPrefillTXTitle =>
      'Vnaprej izpolnite naslov transakcije z naslovom obvestila';

  @override
  String get settingsNLServiceChecking => 'Preverjanje stanja…';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'Napaka pri preverjanju stanja: $error';
  }

  @override
  String get settingsNLServiceRunning => 'Storitev je zagnana.';

  @override
  String get settingsNLServiceStatus => 'Stanje storitve';

  @override
  String get settingsNLServiceStopped => 'Storitev je ustavljena.';

  @override
  String get settingsNotificationListener => 'Storitev poslušanja obvestil';

  @override
  String get settingsTheme => 'Tema aplikacije';

  @override
  String get settingsThemeDynamicColors => 'Dinamične barve';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'Temen način',
      'light': 'Svetel način',
      'other': 'Sistemsko privzeto',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone => 'Uporabite časovni pas strežnika';

  @override
  String get settingsUseServerTimezoneHelp =>
      'Prikaži vse čase v časovnem pasu strežnika. To posnema vedenje spletnega vmesnika.';

  @override
  String get settingsVersion => 'Verzija aplikacije';

  @override
  String get settingsVersionChecking => 'preverjam…';

  @override
  String get transactionAttachments => 'Priponke';

  @override
  String get transactionDeleteConfirm =>
      'Ali ste prepričani, da želite izbrisati to transakcijo?';

  @override
  String get transactionDialogAttachmentsDelete => 'Izbriši priponko';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      'Ali ste prepričani, da želite izbrisati to priponko?';

  @override
  String get transactionDialogAttachmentsErrorDownload =>
      'Datoteke ni bilo mogoče prenesti.';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'Ni bilo mogoče odpreti datoteke: $error';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'Ni bilo mogoče naložiti datoteke: $error';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'Priponke';

  @override
  String get transactionDialogBillNoBill => 'Ni računa';

  @override
  String get transactionDialogBillTitle => 'Poveži z računom';

  @override
  String get transactionDialogCurrencyTitle => 'Izberi valuto';

  @override
  String get transactionDialogPiggyNoPiggy => 'Brez hranilnika';

  @override
  String get transactionDialogPiggyTitle => 'Poveži s hranilnikom';

  @override
  String get transactionDialogTagsAdd => 'Dodaj oznako';

  @override
  String get transactionDialogTagsHint => 'Išči/dodaj oznako';

  @override
  String get transactionDialogTagsTitle => 'Izberi oznake';

  @override
  String get transactionDuplicate => 'Podvoji';

  @override
  String get transactionErrorInvalidAccount => 'Neveljaven račun';

  @override
  String get transactionErrorInvalidBudget => 'Neveljaven proračun';

  @override
  String get transactionErrorNoAccounts => 'Najprej izpolni račune.';

  @override
  String get transactionErrorNoAssetAccount => 'Izberi račun sredstev.';

  @override
  String get transactionErrorTitle => 'Prosim navedite naslov.';

  @override
  String get transactionFormLabelAccountDestination => 'Ciljni račun';

  @override
  String get transactionFormLabelAccountForeign => 'Tuji račun';

  @override
  String get transactionFormLabelAccountOwn => 'Lastni račun';

  @override
  String get transactionFormLabelAccountSource => 'Izvorni račun';

  @override
  String get transactionFormLabelNotes => 'Zapiski';

  @override
  String get transactionFormLabelTags => 'Oznake';

  @override
  String get transactionFormLabelTitle => 'Naslov transakcije';

  @override
  String get transactionSplitAdd => 'Dodaj razdeljeno transakcijo';

  @override
  String get transactionSplitChangeCurrency => 'Spremeni valuto razdelitve';

  @override
  String get transactionSplitChangeDestinationAccount =>
      'Spremeni razdeljeni ciljni račun';

  @override
  String get transactionSplitChangeSourceAccount =>
      'Spremeni izvirni račun razdeljenega vira';

  @override
  String get transactionSplitChangeTarget => 'Spremeni ciljni račun razdelitve';

  @override
  String get transactionSplitDelete => 'Izbriši razdelitev';

  @override
  String get transactionTitleAdd => 'Dodaj transakcijo';

  @override
  String get transactionTitleDelete => 'Izbriši transakcijo';

  @override
  String get transactionTitleEdit => 'Uredi transakcijo';

  @override
  String get transactionTypeDeposit => 'Priliv';

  @override
  String get transactionTypeTransfer => 'Prenos';

  @override
  String get transactionTypeWithdrawal => 'Dvig';

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
