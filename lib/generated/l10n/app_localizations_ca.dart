// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class SCa extends S {
  SCa([String locale = 'ca']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'Cartera d\'Efectiu';

  @override
  String get accountRoleAssetCC => 'Targeta de crèdit';

  @override
  String get accountRoleAssetDefault => 'Compte d\'actius per defecte';

  @override
  String get accountRoleAssetSavings => 'Compte d\'estalvis';

  @override
  String get accountRoleAssetShared => 'Compte d\'actius compartit';

  @override
  String get accountsLabelAsset => 'Comptes d\'Actius';

  @override
  String get accountsLabelExpense => 'Comptes de Despeses';

  @override
  String get accountsLabelLiabilities => 'Passius';

  @override
  String get accountsLabelRevenue => 'Comptes d\'Ingressos';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'setmana',
      'monthly': 'mes',
      'quarterly': 'quadrimestre',
      'halfyear': 'mig any',
      'yearly': 'any',
      'other': 'desconegut',
    });
    return '$interest% d\'interès per $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'setmanalment',
      'monthly': 'mensualment',
      'quarterly': 'quadrimestralment',
      'halfyear': 'bianualment',
      'yearly': 'anualment',
      'other': 'en altres freqüències',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', salta a partir de $skip',
      zero: '',
      one: '',
    );
    return 'Factures de transaccions entre $minValue i $maxvalue. Es repeteixen $_temp0$_temp1.';
  }

  @override
  String get billsChangeLayoutTooltip => 'Canvia la disposició';

  @override
  String get billsChangeSortOrderTooltip => 'Canvia l\'ordenació';

  @override
  String get billsErrorLoading => 'Error carregant les factures.';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'setmanalment',
      'monthly': 'mensualment',
      'quarterly': 'quadrimestralment',
      'halfyear': 'bianualment',
      'yearly': 'anualment',
      'other': 'en altres freqüències',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', salta a partir de $skip',
      zero: '',
      one: '',
    );
    return 'Factures de transaccions $value. Es repeteixen $_temp0$_temp1.';
  }

  @override
  String billsExpectedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Data estimada $dateString';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Setmanal',
      'monthly': 'Mensual',
      'quarterly': 'Quadrimestral',
      'halfyear': 'Bianual',
      'yearly': 'Anual',
      'other': 'Altres',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Setmanal',
      'monthly': 'Mensual',
      'quarterly': 'Qaudrimestral',
      'halfyear': 'Bianual',
      'yearly': 'Anual',
      'other': 'Altres',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', salta a partir de $skip',
      zero: '',
      one: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get billsInactive => 'Inactiva';

  @override
  String get billsIsActive => 'Factura activa';

  @override
  String get billsLayoutGroupSubtitle =>
      'Factures mostrades als seus grups assignats.';

  @override
  String get billsLayoutGroupTitle => 'Grup';

  @override
  String get billsLayoutListSubtitle =>
      'Factures ordenades segons algun criteri.';

  @override
  String get billsLayoutListTitle => 'Llista';

  @override
  String get billsListEmpty => 'La llista es troba actualment buida.';

  @override
  String get billsNextExpectedMatch => 'Pròxima coincidència esperada';

  @override
  String get billsNotActive => 'Factura inactiva';

  @override
  String get billsNotExpected => 'No s\'espera aquest periode';

  @override
  String get billsNoTransactions => 'No s\'ha trobat cap transacció.';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Pagada a $dateString';
  }

  @override
  String get billsSortAlphabetical => 'Alfabètic';

  @override
  String get billsSortByTimePeriod => 'Per període de temps';

  @override
  String get billsSortFrequency => 'Freqüència';

  @override
  String get billsSortName => 'Nom';

  @override
  String get billsUngrouped => 'Sense grup';

  @override
  String get billsSettingsShowOnlyActive => 'Mostra només actius';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'Mostra només les subscripcions actives.';

  @override
  String get billsSettingsShowOnlyExpected => 'Mostra només esperats';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'Mostra només les subscripcions que s\'esperen (o s\'han pagat) aquest mes.';

  @override
  String get categoryDeleteConfirm =>
      'N\'estàs segur que vols esborrar aquesta categoria? Les transaccions no s\'esborraran, però ja no tindran cap categoria assignada.';

  @override
  String get categoryErrorLoading => 'Error al carregar les categories.';

  @override
  String get categoryFormLabelIncludeInSum => 'Inclou a la suma mensual';

  @override
  String get categoryFormLabelName => 'Nom de la categoria';

  @override
  String get categoryMonthNext => 'Mes següent';

  @override
  String get categoryMonthPrev => 'Mes anterior';

  @override
  String get categorySumExcluded => 'exclosa';

  @override
  String get categoryTitleAdd => 'Afegeix Categoria';

  @override
  String get categoryTitleDelete => 'Esborra la categoria';

  @override
  String get categoryTitleEdit => 'Edita la categoria';

  @override
  String get catNone => '<sense categoria>';

  @override
  String get catOther => 'Altres';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'Resposta de l\'API invàlida: $message';
  }

  @override
  String get errorAPIUnavailable => 'API no disponible';

  @override
  String get errorFieldRequired => 'Aquest camp és obligatori.';

  @override
  String get errorInvalidURL => 'URL invàlida';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'Cal disposar com a mínim de la versió v$requiredVersion de Firefly. Per favor, actualitza.';
  }

  @override
  String errorStatusCode(int code) {
    return 'Codi d\'Estat: $code';
  }

  @override
  String get errorUnknown => 'Error desconegut.';

  @override
  String get formButtonHelp => 'Ajuda';

  @override
  String get formButtonLogin => 'Accedir';

  @override
  String get formButtonLogout => 'Tanca la Sessió';

  @override
  String get formButtonRemove => 'Elimina';

  @override
  String get formButtonResetLogin => 'Reinicia l\'inici de sessió';

  @override
  String get formButtonTransactionAdd => 'Afegir Transacció';

  @override
  String get formButtonTryAgain => 'Torna a provar';

  @override
  String get generalAccount => 'Compte';

  @override
  String get generalAssets => 'Actius';

  @override
  String get generalBalance => 'Balanç';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Balanç el $dateString';
  }

  @override
  String get generalBill => 'Factura';

  @override
  String get generalBudget => 'Pressupost';

  @override
  String get generalCategory => 'Categoria';

  @override
  String get generalCurrency => 'Moneda';

  @override
  String get generalDateRangeCurrentMonth => 'Mes actual';

  @override
  String get generalDateRangeLast30Days => 'Últims 30 dies';

  @override
  String get generalDateRangeCurrentYear => 'Any actual';

  @override
  String get generalDateRangeLastYear => 'Any passat';

  @override
  String get generalDateRangeAll => 'Tots';

  @override
  String get generalDefault => 'per defecte';

  @override
  String get generalDestinationAccount => 'Compte de destí';

  @override
  String get generalDismiss => 'Ignora';

  @override
  String get generalEarned => 'Guanyat';

  @override
  String get generalError => 'Error';

  @override
  String get generalExpenses => 'Despeses';

  @override
  String get generalIncome => 'Ingressos';

  @override
  String get generalLiabilities => 'Passius';

  @override
  String get generalMultiple => 'múltiples';

  @override
  String get generalNever => 'mai';

  @override
  String get generalReconcile => 'Consolidat';

  @override
  String get generalReset => 'Restableix';

  @override
  String get generalSourceAccount => 'Compte d\'origen';

  @override
  String get generalSpent => 'Gastat';

  @override
  String get generalSum => 'Suma';

  @override
  String get generalTarget => 'Destí';

  @override
  String get generalUnknown => 'Desconegut';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'setmanalment',
      'monthly': 'mensualment',
      'quarterly': 'quatrimestralment',
      'halfyear': 'semestralment',
      'yearly': 'anualment',
      'other': 'desconegut',
    });
    return ' ($_temp0)';
  }

  @override
  String get homeMainBillsTitle => 'Factures per a la pròxima setmana';

  @override
  String homeMainBudgetInterval(DateTime from, DateTime to, String period) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString fins a $toString, $period)';
  }

  @override
  String homeMainBudgetIntervalSingle(DateTime from, DateTime to) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString fins a $toString)';
  }

  @override
  String homeMainBudgetSum(String current, String status, String available) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'over': 'per damunt de',
      'other': 'queden de',
    });
    return '$current $_temp0 $available';
  }

  @override
  String get homeMainBudgetTitle => 'Pressupostos per al mes actual';

  @override
  String get homeMainChartAccountsTitle => 'Resum del Compte';

  @override
  String get homeMainChartCategoriesTitle =>
      'Resum de la Categoria per a aquest mes';

  @override
  String get homeMainChartDailyAvg => 'Mitjana de 7 dies';

  @override
  String get homeMainChartDailyTitle => 'Resum Diari';

  @override
  String get homeMainChartNetEarningsTitle => 'Ingressos Nets';

  @override
  String get homeMainChartNetWorthTitle => 'Valor Net';

  @override
  String get homeMainChartTagsTitle => 'Resum d\'etiquetes del mes actual';

  @override
  String get homePiggyAdjustDialogTitle => 'Estalvia/Gasta Diners';

  @override
  String homePiggyDateStart(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Data d\'inici: $dateString';
  }

  @override
  String homePiggyDateTarget(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Data objectiu: $dateString';
  }

  @override
  String get homeMainDialogSettingsTitle => 'Personalitza el tauler';

  @override
  String homePiggyLinked(String account) {
    return 'Enllaçada a $account';
  }

  @override
  String get homePiggyNoAccounts => 'No s\'ha configurat cap guardiola.';

  @override
  String get homePiggyNoAccountsSubtitle => 'Crea\'n una a la interfície web!';

  @override
  String homePiggyRemaining(String amount) {
    return 'Queda per estalviar: $amount';
  }

  @override
  String homePiggySaved(String amount) {
    return 'Has estalviat: $amount';
  }

  @override
  String get homePiggySavedMultiple => 'Estalviat fins ara:';

  @override
  String homePiggyTarget(String amount) {
    return 'Quantitat objectiu: $amount';
  }

  @override
  String get homePiggyAccountStatus => 'Estat del compte';

  @override
  String get homePiggyAvailableAmounts => 'Quantitats disponibles';

  @override
  String homePiggyAvailable(String amount) {
    return 'Disponible: $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'En guardioles: $amount';
  }

  @override
  String get homeTabLabelBalance => 'Fulla de Balanços';

  @override
  String get homeTabLabelMain => 'Principal';

  @override
  String get homeTabLabelPiggybanks => 'Guardioles';

  @override
  String get homeTabLabelTransactions => 'Transaccions';

  @override
  String get homeTransactionsActionFilter => 'Llista de filtres';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<Tots els Comptes>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<Totes les Factures>';

  @override
  String get homeTransactionsDialogFilterBillUnset =>
      '<Cap Factura establerta>';

  @override
  String get homeTransactionsDialogFilterBudgetsAll =>
      '<Tots els Pressupostos>';

  @override
  String get homeTransactionsDialogFilterBudgetUnset =>
      '<Cap Pressupost establert>';

  @override
  String get homeTransactionsDialogFilterCategoriesAll =>
      '<Totes les Categories>';

  @override
  String get homeTransactionsDialogFilterCategoryUnset =>
      '<Cap Categoria establerta>';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<Totes les Monedes>';

  @override
  String get homeTransactionsDialogFilterDateRange => 'Interval de dates';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'Mostra transaccions futures';

  @override
  String get homeTransactionsDialogFilterSearch => 'Cerca un terme';

  @override
  String get homeTransactionsDialogFilterTitle => 'Selecciona filtres';

  @override
  String get homeTransactionsEmpty => 'No s\'ha trobat cap transacció.';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num categories';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'Mostra les etiquetes a la llista de transaccions';

  @override
  String get liabilityDirectionCredit => 'Se\'m deu aquest deute';

  @override
  String get liabilityDirectionDebit => 'Dec aquest deute';

  @override
  String get liabilityTypeDebt => 'Deute';

  @override
  String get liabilityTypeLoan => 'Préstec';

  @override
  String get liabilityTypeMortgage => 'Hipoteca';

  @override
  String get loginAbout =>
      'Per a fer servir Waterfly III adequadament cal que tingues el teu propi servidor de Firefly III o l\'add-on de Firefly III a Home Assistant.\n\nPer favor, introdueix la URL completa a més del token d\'accés (Configuració -> Perfil -> OAuth -> Token d\'Accés Personal) a sota.';

  @override
  String get loginFormLabelAPIKey => 'Clau d\'API vàlida';

  @override
  String get loginFormLabelHost => 'URL d\'allotjament';

  @override
  String get loginWelcome => 'Benvingut/da a Waterfly III';

  @override
  String get logoutConfirmation => 'Segur que vols tancar la sessió?';

  @override
  String get navigationAccounts => 'Comptes';

  @override
  String get navigationBills => 'Factures';

  @override
  String get navigationCategories => 'Categories';

  @override
  String get navigationMain => 'Tauler de control Principal';

  @override
  String get generalSettings => 'Configuració';

  @override
  String get no => 'No';

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

    return '$percString de $of';
  }

  @override
  String get settingsDialogDebugInfo =>
      'Pots habilitar i enviar registres des d\'ací. Aquests poden tenir un impacte sobre el rendiment de l\'aplicació, així que no ho actives si no se t\'ha demanat. Deshabilitar els registres eliminarà els que hi puguin haver desats.';

  @override
  String get settingsDialogDebugMailCreate => 'Crear correu electrònic';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      'ADVERTIMENT: s\'obrirà un esborrany de correu amb el fitxer de registre adjunt (en format de text). Els registres poden contenir informació sensible, com ara el nom d\'amfitrió de la vostra instància de Firefly (tot i que intento evitar el registre de qualsevol secret, com ara la clau API). Si us plau, llegiu atentament el registre i censureu qualsevol informació que no vulgueu compartir i/o que no sigui rellevant per al problema que voleu informar.\n\nSi us plau, no envieu registres sense un acord previ per correu electrònic/GitHub per fer-ho. Suprimiré tots els registres enviats sense context per motius de privadesa. No carregueu mai el registre sense censura a GitHub ni a cap altre lloc.';

  @override
  String get settingsDialogDebugSendButton =>
      'Envia registres per Correu Electrònic';

  @override
  String get settingsDialogDebugTitle => 'Registres de depuració';

  @override
  String get settingsDialogLanguageTitle => 'Selecciona un idioma';

  @override
  String get settingsDialogThemeTitle => 'Selecciona un Tema';

  @override
  String get settingsFAQ => 'Preguntes Freqüents';

  @override
  String get settingsFAQHelp =>
      'S\'obre al navegador. Només disponible en anglès.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configure offline sync and mobile data usage';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLockscreen => 'Pantalla de Bloqueig';

  @override
  String get settingsLockscreenHelp =>
      'Requereix autenticació en iniciar l\'aplicació';

  @override
  String get settingsLockscreenInitial =>
      'Per favor, autentica\'t per habilitar la pantalla de bloqueig.';

  @override
  String get settingsNLAppAccount => 'Compte per Defecte';

  @override
  String get settingsNLAppAccountDynamic => '<Dinàmic>';

  @override
  String get settingsNLAppAdd => 'Afegir Aplicació';

  @override
  String get settingsNLAppAddHelp =>
      'Toca per afegir una aplicació a la qual escoltar. Només es mostraran les aplicacions compatibles.';

  @override
  String get settingsNLAppAddInfo =>
      'Fes algunes transaccions de les aplicacions on rebis notificacions per afegir-les a la llista. Si encara no es mostren, per favor informa app@vogt.pw.';

  @override
  String get settingsNLAutoAdd => 'Crea una transacció sense interacció';

  @override
  String get settingsNLDescription =>
      'Aquest servei et permet obtenir detalls de transaccions a partir de notificacions. Addicionalment, pots seleccionar un compte per defecte al qual assignar les transaccions - si no s\'estableix cap valor, s\'intenta extreure el compte de la notificació.';

  @override
  String get settingsNLEmptyNote => 'Mantén el camp de nota buit';

  @override
  String get settingsNLPermissionGrant => 'Toca per a donar permís.';

  @override
  String get settingsNLPermissionNotGranted => 'Permís no concedit.';

  @override
  String get settingsNLPermissionRemove => 'Eliminar permís?';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'Per a deshabilitar aquest servei, toca en l\'app i elimina els permisos a la pantalla següent.';

  @override
  String get settingsNLPrefillTXTitle =>
      'Emplena automàticament el títol de la transacció amb el títol de la notificació';

  @override
  String get settingsNLServiceChecking => 'Comprovant l\'estat…';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'No s\'ha pogut comprovar l\'estat: $error';
  }

  @override
  String get settingsNLServiceRunning => 'El servei s\'està executant.';

  @override
  String get settingsNLServiceStatus => 'Estat del Servei';

  @override
  String get settingsNLServiceStopped => 'El servei s\'ha detingut.';

  @override
  String get settingsNotificationListener =>
      'Servei d\'escolta de notificacions';

  @override
  String get settingsTheme => 'Tema de l\'aplicació';

  @override
  String get settingsThemeDynamicColors => 'Colors Dinàmics';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'Tema Obscur',
      'light': 'Tema Clar',
      'other': 'Per defecte',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone =>
      'Utilitza la zona horària del servidor';

  @override
  String get settingsUseServerTimezoneHelp =>
      'Mostra totes les hores a la zona horària del servidor. Això mimetitza el comportament de la interfície web.';

  @override
  String get settingsVersion => 'Versió de l\'aplicació';

  @override
  String get settingsVersionChecking => 'comprovant…';

  @override
  String get transactionAttachments => 'Adjunts';

  @override
  String get transactionDeleteConfirm =>
      'Segur que vols eliminar aquesta transacció?';

  @override
  String get transactionDialogAttachmentsDelete => 'Elimina l\'adjunt';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      'Segur que vols eliminar aquest adjunt?';

  @override
  String get transactionDialogAttachmentsErrorDownload =>
      'No s\'ha pogut baixar el fitxer.';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'No s\'ha pogut obrir el fitxer: $error';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'No s\'ha pogut penjar el fitxer: $error';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'Adjunts';

  @override
  String get transactionDialogBillNoBill => 'Cap factura';

  @override
  String get transactionDialogBillTitle => 'Enllaça a una factura';

  @override
  String get transactionDialogCurrencyTitle => 'Tria una Moneda';

  @override
  String get transactionDialogPiggyNoPiggy => 'Sense guardiola';

  @override
  String get transactionDialogPiggyTitle => 'Enllaça amb la guardiola';

  @override
  String get transactionDialogTagsAdd => 'Afegir Etiqueta';

  @override
  String get transactionDialogTagsHint => 'Cerca/Afegeix una Etiqueta';

  @override
  String get transactionDialogTagsTitle => 'Selecciona Etiquetes';

  @override
  String get transactionDuplicate => 'Duplicada';

  @override
  String get transactionErrorInvalidAccount => 'Compte Invàlid';

  @override
  String get transactionErrorInvalidBudget => 'Pressupost Invàlid';

  @override
  String get transactionErrorNoAccounts =>
      'Si us plau, omple els comptes primer.';

  @override
  String get transactionErrorNoAssetAccount =>
      'Si us plau, selecciona un compte d\'actiu.';

  @override
  String get transactionErrorTitle => 'Per favor, introdueix un títol.';

  @override
  String get transactionFormLabelAccountDestination => 'Compte de destí';

  @override
  String get transactionFormLabelAccountForeign => 'Compte estranger';

  @override
  String get transactionFormLabelAccountOwn => 'Compte propi';

  @override
  String get transactionFormLabelAccountSource => 'Compte d\'origen';

  @override
  String get transactionFormLabelNotes => 'Notes';

  @override
  String get transactionFormLabelTags => 'Etiquetes';

  @override
  String get transactionFormLabelTitle => 'Títol de la Transacció';

  @override
  String get transactionSplitAdd => 'Afegeix una transacció dividida';

  @override
  String get transactionSplitChangeCurrency => 'Canvia la moneda de la divisió';

  @override
  String get transactionSplitChangeDestinationAccount =>
      'Canvia el compte de destinació de la divisió';

  @override
  String get transactionSplitChangeSourceAccount =>
      'Canvia el compte d\'origen de la divisió';

  @override
  String get transactionSplitChangeTarget =>
      'Canvia el compte destí de la divisió';

  @override
  String get transactionSplitDelete => 'Elimina la divisió';

  @override
  String get transactionTitleAdd => 'Afegir Transacció';

  @override
  String get transactionTitleDelete => 'Elimina la Transacció';

  @override
  String get transactionTitleEdit => 'Edita la Transacció';

  @override
  String get transactionTypeDeposit => 'Ingrés';

  @override
  String get transactionTypeTransfer => 'Transferència';

  @override
  String get transactionTypeWithdrawal => 'Retirada';

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
