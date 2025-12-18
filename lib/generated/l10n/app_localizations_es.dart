// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'Billetera de efectivo';

  @override
  String get accountRoleAssetCC => 'Tarjeta de crédito';

  @override
  String get accountRoleAssetDefault => 'Cuenta de activos por defecto';

  @override
  String get accountRoleAssetSavings => 'Cuenta de ahorros';

  @override
  String get accountRoleAssetShared => 'Cuenta de activos compartida';

  @override
  String get accountsLabelAsset => 'Cuentas de activos';

  @override
  String get accountsLabelExpense => 'Cuentas de gastos';

  @override
  String get accountsLabelLiabilities => 'Pasivos';

  @override
  String get accountsLabelRevenue => 'Cuentas de ingresos';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'semana',
      'monthly': 'mes',
      'quarterly': 'trimestre',
      'halfyear': 'semestre',
      'yearly': 'año',
      'other': 'desconocido',
    });
    return '$interest% de interés por $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'semanalmente',
      'monthly': 'mensualmente',
      'quarterly': 'trimestralmente',
      'halfyear': 'semestralmente',
      'yearly': 'anualmente',
      'other': 'desconocido',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', saltarse $skip',
      zero: '',
    );
    return 'Factura coincide con transacciones entre $minValue y $maxvalue. Se repite $_temp0$_temp1.';
  }

  @override
  String get billsChangeLayoutTooltip => 'Cambiar diseño';

  @override
  String get billsChangeSortOrderTooltip => 'Cambiar orden de clasificación';

  @override
  String get billsErrorLoading => 'Error al cargar facturas.';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'semanalmente',
      'monthly': 'mensualmente',
      'quarterly': 'trimestralmente',
      'halfyear': 'semestralmente',
      'yearly': 'anualmente',
      'other': 'desconocido',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', saltarse $skip',
      zero: '',
    );
    return 'La factura coincide con las transacciones de $value. Se repite $_temp0$_temp1.';
  }

  @override
  String billsExpectedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Esperado $dateString';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Semanal',
      'monthly': 'Mensual',
      'quarterly': 'Trimestral',
      'halfyear': 'Semestral',
      'yearly': 'Anual',
      'other': 'Desconocido',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Semanal',
      'monthly': 'Mensual',
      'quarterly': 'Trimestral',
      'halfyear': 'Semestral',
      'yearly': 'Anual',
      'other': 'Desconocido',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', saltarse $skip',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get billsInactive => 'Inactiva';

  @override
  String get billsIsActive => 'La factura está activa';

  @override
  String get billsLayoutGroupSubtitle =>
      'Facturas mostradas en sus grupos asignados.';

  @override
  String get billsLayoutGroupTitle => 'Grupo';

  @override
  String get billsLayoutListSubtitle =>
      'Facturas mostradas en una lista ordenada por ciertos criterios.';

  @override
  String get billsLayoutListTitle => 'Lista';

  @override
  String get billsListEmpty => 'La lista está actualmente vacía.';

  @override
  String get billsNextExpectedMatch => 'Próxima coincidencia esperada';

  @override
  String get billsNotActive => 'La factura está inactiva';

  @override
  String get billsNotExpected => 'No se esperaba este período';

  @override
  String get billsNoTransactions => 'No se encontraron transacciones.';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Pagado $dateString';
  }

  @override
  String get billsSortAlphabetical => 'Alfabético';

  @override
  String get billsSortByTimePeriod => 'Por período de tiempo';

  @override
  String get billsSortFrequency => 'Frecuencia';

  @override
  String get billsSortName => 'Nombre';

  @override
  String get billsUngrouped => 'Sin agrupar';

  @override
  String get billsSettingsShowOnlyActive => 'Mostrar solo activos';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'Muestra solo las suscripciones activas.';

  @override
  String get billsSettingsShowOnlyExpected => 'Mostrar solo esperados';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'Muestra solo las suscripciones que se esperan (o pagan) este mes.';

  @override
  String get categoryDeleteConfirm =>
      '¿Estás seguro de que deseas eliminar esta categoría? Las transacciones no serán eliminadas, pero ya no tendrán categoría.';

  @override
  String get categoryErrorLoading => 'Error cargando categorías.';

  @override
  String get categoryFormLabelIncludeInSum => 'Incluir en suma mensual';

  @override
  String get categoryFormLabelName => 'Nombre de la categoría';

  @override
  String get categoryMonthNext => 'Próximo Mes';

  @override
  String get categoryMonthPrev => 'Mes anterior';

  @override
  String get categorySumExcluded => 'excluida';

  @override
  String get categoryTitleAdd => 'Agregar categoría';

  @override
  String get categoryTitleDelete => 'Eliminar categoría';

  @override
  String get categoryTitleEdit => 'Editar categoría';

  @override
  String get catNone => '(sin categoría)';

  @override
  String get catOther => 'Otros';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'Respuesta inválida de la API: $message';
  }

  @override
  String get errorAPIUnavailable => 'API no disponible';

  @override
  String get errorFieldRequired => 'Este campo es obligatorio.';

  @override
  String get errorInvalidURL => 'URL inválida';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'Se requiere una versión mínima de la API Firefly -$requiredVersion Por favor, actualice.';
  }

  @override
  String errorStatusCode(int code) {
    return 'Código de estado: $code';
  }

  @override
  String get errorUnknown => 'Error desconocido.';

  @override
  String get formButtonHelp => 'Ayuda';

  @override
  String get formButtonLogin => 'Iniciar Sesión';

  @override
  String get formButtonLogout => 'Cerrar sesión';

  @override
  String get formButtonRemove => 'Eliminar';

  @override
  String get formButtonResetLogin => 'Restablecer inicio de sesión';

  @override
  String get formButtonTransactionAdd => 'Añadir Transacción';

  @override
  String get formButtonTryAgain => 'Inténtalo de nuevo';

  @override
  String get generalAccount => 'Cuenta';

  @override
  String get generalAssets => 'Activos';

  @override
  String get generalBalance => 'Saldo';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Saldo a $dateString';
  }

  @override
  String get generalBill => 'Factura';

  @override
  String get generalBudget => 'Presupuesto';

  @override
  String get generalCategory => 'Categoría';

  @override
  String get generalCurrency => 'Divisa';

  @override
  String get generalDateRangeCurrentMonth => 'Mes actual';

  @override
  String get generalDateRangeLast30Days => 'Últimos 30 días';

  @override
  String get generalDateRangeCurrentYear => 'Año actual';

  @override
  String get generalDateRangeLastYear => 'Año pasado';

  @override
  String get generalDateRangeAll => 'Todos';

  @override
  String get generalDefault => 'por defecto';

  @override
  String get generalDestinationAccount => 'Cuenta de Destino';

  @override
  String get generalDismiss => 'Descartar';

  @override
  String get generalEarned => 'Ingresado';

  @override
  String get generalError => 'Error';

  @override
  String get generalExpenses => 'Gastos';

  @override
  String get generalIncome => 'Ingresos';

  @override
  String get generalLiabilities => 'Pasivos';

  @override
  String get generalMultiple => 'múltiple';

  @override
  String get generalNever => 'nunca';

  @override
  String get generalReconcile => 'Reconciliado';

  @override
  String get generalReset => 'Restablecer';

  @override
  String get generalSourceAccount => 'Cuenta de Origen';

  @override
  String get generalSpent => 'Gastado';

  @override
  String get generalSum => 'Suma';

  @override
  String get generalTarget => 'Objetivo';

  @override
  String get generalUnknown => 'Desconocido';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'semanalmente',
      'monthly': 'mensualmente',
      'quarterly': 'trimestralmente',
      'halfyear': 'semestralmente',
      'yearly': 'anualmente',
      'other': 'desconocido',
    });
    return ' ($_temp0)';
  }

  @override
  String get homeMainBillsTitle => 'Facturas para la próxima semana';

  @override
  String homeMainBudgetInterval(DateTime from, DateTime to, String period) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString hasta $toString, $period)';
  }

  @override
  String homeMainBudgetIntervalSingle(DateTime from, DateTime to) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString hasta $toString)';
  }

  @override
  String homeMainBudgetSum(String current, String status, String available) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'over': 'más de',
      'other': 'restante',
    });
    return '$current $_temp0 $available';
  }

  @override
  String get homeMainBudgetTitle => 'Presupuestos para el mes actual';

  @override
  String get homeMainChartAccountsTitle => 'Resumen de la cuenta';

  @override
  String get homeMainChartCategoriesTitle =>
      'Resumen de categoría para el mes actual';

  @override
  String get homeMainChartDailyAvg => 'promedio de 7 días';

  @override
  String get homeMainChartDailyTitle => 'Resumen diario';

  @override
  String get homeMainChartNetEarningsTitle => 'Beneficio';

  @override
  String get homeMainChartNetWorthTitle => 'Valor neto';

  @override
  String get homeMainChartTagsTitle => 'Resumen de etiquetas del mes actual';

  @override
  String get homePiggyAdjustDialogTitle => 'Ahorrar/Gastar dinero';

  @override
  String homePiggyDateStart(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Fecha de inicio: $dateString';
  }

  @override
  String homePiggyDateTarget(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Fecha objetivo: $dateString';
  }

  @override
  String get homeMainDialogSettingsTitle => 'Personalizar el panel';

  @override
  String homePiggyLinked(String account) {
    return 'Vinculado a $account';
  }

  @override
  String get homePiggyNoAccounts => 'No se han creado huchas.';

  @override
  String get homePiggyNoAccountsSubtitle => '¡Cree alguna en la interfaz web!';

  @override
  String homePiggyRemaining(String amount) {
    return 'Pendiente de ahorrar: $amount';
  }

  @override
  String homePiggySaved(String amount) {
    return 'Ahorrado hasta ahora: $amount';
  }

  @override
  String get homePiggySavedMultiple => 'Ahorrado hasta ahora:';

  @override
  String homePiggyTarget(String amount) {
    return 'Objetivo de ahorro: $amount';
  }

  @override
  String get homePiggyAccountStatus => 'Estado de la cuenta';

  @override
  String get homePiggyAvailableAmounts => 'Cantidades disponibles';

  @override
  String homePiggyAvailable(String amount) {
    return 'Disponible: $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'En huchas: $amount';
  }

  @override
  String get homeTabLabelBalance => 'Hoja de balance';

  @override
  String get homeTabLabelMain => 'Principal';

  @override
  String get homeTabLabelPiggybanks => 'Huchas';

  @override
  String get homeTabLabelTransactions => 'Transacciones';

  @override
  String get homeTransactionsActionFilter => 'Listado de filtros';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<Todas las cuentas>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<Todas las facturas>';

  @override
  String get homeTransactionsDialogFilterBillUnset =>
      '<Factura no establecida>';

  @override
  String get homeTransactionsDialogFilterBudgetsAll =>
      '<Todos los presupuestos>';

  @override
  String get homeTransactionsDialogFilterBudgetUnset =>
      '<Presupuesto no establecido>';

  @override
  String get homeTransactionsDialogFilterCategoriesAll =>
      '<Todas las categorías>';

  @override
  String get homeTransactionsDialogFilterCategoryUnset =>
      '<Categoría no establecida>';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<Todas las divisas>';

  @override
  String get homeTransactionsDialogFilterDateRange => 'Rango de fechas';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'Mostrar transacciones futuras';

  @override
  String get homeTransactionsDialogFilterSearch => 'Término de búsqueda';

  @override
  String get homeTransactionsDialogFilterTitle => 'Seleccionar filtros';

  @override
  String get homeTransactionsEmpty => 'No se encontraron transacciones.';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num categorías';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'Mostrar etiquetas en la lista de transacciones';

  @override
  String get liabilityDirectionCredit => 'Se me debe esta deuda';

  @override
  String get liabilityDirectionDebit => 'Le debo esta deuda a otra persona';

  @override
  String get liabilityTypeDebt => 'Deuda';

  @override
  String get liabilityTypeLoan => 'Préstamo';

  @override
  String get liabilityTypeMortgage => 'Hipoteca';

  @override
  String get loginAbout =>
      'Para usar Waterfly III es necesario disponer de un servidor con una instancia de Firefly III o del add-on de Firefly III para Home Assistant.\n\nPor favor, introduzca la URL completa y el token de acceso personal (Ajustes -> Perfil -> OAuth -> Token de Acceso Personal) debajo.';

  @override
  String get loginFormLabelAPIKey => 'Clave API válida';

  @override
  String get loginFormLabelHost => 'URL del servidor';

  @override
  String get loginWelcome => 'Bienvenido a Waterfly III';

  @override
  String get logoutConfirmation => '¿Estás seguro de que deseas cerrar sesión?';

  @override
  String get navigationAccounts => 'Cuentas';

  @override
  String get navigationBills => 'Facturas';

  @override
  String get navigationCategories => 'Categorías';

  @override
  String get navigationMain => 'Panel principal';

  @override
  String get generalSettings => 'Configuración';

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
      'Puede activar y enviar los registros de depuración desde aquí. Su activación tiene un impacto perjudicial en el rendimiento, así que no los active a no ser que se le haya recomendado. Desactivar los registros elimina los guardados anteriormente.';

  @override
  String get settingsDialogDebugMailCreate => 'Crear email';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      'ATENCIÓN: Se abrirá un borrador de email con los registros de depuración como archivo adjunto (en formato de texto). Los registros pueden contener información sensible, como el nombre del anfitrión de su instancia de Firefly (aunque se ha tratado de no registrar secretos, como la clave API). Por favor, revise los registros cuidadosamente y censure cualquier información que no desea compartir y/o no es relevante para el problema sobre el que quiere informar.';

  @override
  String get settingsDialogDebugSendButton => 'Enviar registros por correo';

  @override
  String get settingsDialogDebugTitle => 'Registros de depuración';

  @override
  String get settingsDialogLanguageTitle => 'Seleccionar idioma';

  @override
  String get settingsDialogThemeTitle => 'Seleccionar tema';

  @override
  String get settingsFAQ => 'FAQ';

  @override
  String get settingsFAQHelp =>
      'Se abre en el navegador. Sólo disponible en inglés.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configurar sincronización sin conexión y uso de datos móviles';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLockscreen => 'Pantalla de bloqueo';

  @override
  String get settingsLockscreenHelp =>
      'Requerir autenticación al iniciar la aplicación';

  @override
  String get settingsLockscreenInitial =>
      'Por favor, autentíquese para activar la pantalla de bloqueo.';

  @override
  String get settingsNLAppAccount => 'Cuenta por defecto';

  @override
  String get settingsNLAppAccountDynamic => '<Dinámico>';

  @override
  String get settingsNLAppAdd => 'Añadir aplicación';

  @override
  String get settingsNLAppAddHelp =>
      'Haga clic para añadir una aplicación para escuchar. Sólo las aplicaciones elegibles aparecerán en la lista.';

  @override
  String get settingsNLAppAddInfo =>
      'Haga algunas transacciones que generen notificaciones en el teléfono para añadir aplicaciones a esta lista. Si la aplicación todavía no aparece, por favor, informe a app@vogt.pw.';

  @override
  String get settingsNLAutoAdd => 'Crear transacción sin interacción';

  @override
  String get settingsNLDescription =>
      'Este servicio permite obtener detalles de la transacción a partir de notificaciones entrantes. Además, puede seleccionar una cuenta por defecto a la que asignar la transacción. Si no se establece ningún valor, trata de extraer la información de la notificación.';

  @override
  String get settingsNLEmptyNote => 'Mantener campo nota vacío';

  @override
  String get settingsNLPermissionGrant => 'Toque para conceder permiso.';

  @override
  String get settingsNLPermissionNotGranted => 'Permiso no concedido.';

  @override
  String get settingsNLPermissionRemove => 'Quitar el permiso?';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'Para desactivar este servicio, haga clic en la aplicación y elimine los permisos en la siguiente pantalla.';

  @override
  String get settingsNLPrefillTXTitle =>
      'Rellenar el título de la transacción con el título de la notificación';

  @override
  String get settingsNLServiceChecking => 'Comprobando estado…';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'Error comprobando estado: $error';
  }

  @override
  String get settingsNLServiceRunning => 'El servicio se está ejecutando.';

  @override
  String get settingsNLServiceStatus => 'Estado del servicio';

  @override
  String get settingsNLServiceStopped => 'El servicio está detenido.';

  @override
  String get settingsNotificationListener =>
      'Servicio de escucha de notificaciones';

  @override
  String get settingsTheme => 'Tema de la aplicación';

  @override
  String get settingsThemeDynamicColors => 'Colores dinámicos';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'Modo Oscuro',
      'light': 'Modo Luz',
      'other': 'Predeterminado del sistema',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone => 'Usar la zona horaria del servidor';

  @override
  String get settingsUseServerTimezoneHelp =>
      'Mostrar todas las horas en la zona horaria del servidor. Esto imita el comportamiento de la interfaz web.';

  @override
  String get settingsVersion => 'Versión de la aplicación';

  @override
  String get settingsVersionChecking => 'comprobando…';

  @override
  String get transactionAttachments => 'Archivos adjuntos';

  @override
  String get transactionDeleteConfirm =>
      '¿Seguro que desea eliminar esta transacción?';

  @override
  String get transactionDialogAttachmentsDelete => 'Eliminar archivo adjunto';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      '¿Está seguro de que desea eliminar el archivo adjunto?';

  @override
  String get transactionDialogAttachmentsErrorDownload =>
      'No se pudo descargar el archivo.';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'No se pudo abrir el archivo: $error';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'No se pudo subir el archivo: $error';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'Archivos adjuntos';

  @override
  String get transactionDialogBillNoBill => 'Sin factura';

  @override
  String get transactionDialogBillTitle => 'Enlace a la factura';

  @override
  String get transactionDialogCurrencyTitle => 'Seleccionar divisa';

  @override
  String get transactionDialogPiggyNoPiggy => 'Sin hucha';

  @override
  String get transactionDialogPiggyTitle => 'Vincular a hucha';

  @override
  String get transactionDialogTagsAdd => 'Añadir etiqueta';

  @override
  String get transactionDialogTagsHint => 'Buscar/Añadir etiqueta';

  @override
  String get transactionDialogTagsTitle => 'Seleccionar etiquetas';

  @override
  String get transactionDuplicate => 'Duplicado';

  @override
  String get transactionErrorInvalidAccount => 'Cuenta inválida';

  @override
  String get transactionErrorInvalidBudget => 'Presupuesto inválido';

  @override
  String get transactionErrorNoAccounts =>
      'Por favor, primero rellene las cuentas.';

  @override
  String get transactionErrorNoAssetAccount =>
      'Por favor, seleccione una cuenta de activo.';

  @override
  String get transactionErrorTitle => 'Por favor, proporcione un título.';

  @override
  String get transactionFormLabelAccountDestination => 'Cuenta de destino';

  @override
  String get transactionFormLabelAccountForeign => 'Cuenta extranjera';

  @override
  String get transactionFormLabelAccountOwn => 'Cuenta propia';

  @override
  String get transactionFormLabelAccountSource => 'Cuenta de origen';

  @override
  String get transactionFormLabelNotes => 'Notas';

  @override
  String get transactionFormLabelTags => 'Etiquetas';

  @override
  String get transactionFormLabelTitle => 'Título de la transacción';

  @override
  String get transactionSplitAdd => 'Añadir transacción dividida';

  @override
  String get transactionSplitChangeCurrency => 'Cambiar moneda dividida';

  @override
  String get transactionSplitChangeDestinationAccount =>
      'Cambiar cuenta de destino dividida';

  @override
  String get transactionSplitChangeSourceAccount =>
      'Cambiar cuenta de origen dividida';

  @override
  String get transactionSplitChangeTarget =>
      'Cambiar cuenta de destina dividida';

  @override
  String get transactionSplitDelete => 'Eliminar división';

  @override
  String get transactionTitleAdd => 'Añadir Transacción';

  @override
  String get transactionTitleDelete => 'Eliminar transacción';

  @override
  String get transactionTitleEdit => 'Editar Transacción';

  @override
  String get transactionTypeDeposit => 'Ingreso';

  @override
  String get transactionTypeTransfer => 'Transferencia';

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
    return 'Sincronizar $entity';
  }

  @override
  String generalSyncComplete(String entity, int count) {
    return 'Sincronizados $count $entity';
  }

  @override
  String generalSyncFailed(String error) {
    return 'Error de sincronización: $error';
  }

  @override
  String get generalOffline => 'Sin conexión';

  @override
  String get generalOfflineMessage =>
      'Estás sin conexión. Conéctate para sincronizar.';

  @override
  String get generalSyncNotAvailable =>
      'Servicio de sincronización no disponible';

  @override
  String get generalBackOnline => 'Conectado nuevamente';

  @override
  String get generalOfflineModeWifiOnly => 'Modo sin conexión (solo WiFi)';

  @override
  String get generalCheckingConnection => 'Verificando conexión...';

  @override
  String get generalNetworkStatus => 'Estado de la Red';

  @override
  String get generalAppStatus => 'Estado de la Aplicación';

  @override
  String get generalOnline => 'En línea';

  @override
  String get generalNetwork => 'Red';

  @override
  String get generalNoConnection => 'Sin conexión';

  @override
  String get generalWifiOnlyModeEnabled =>
      'El modo solo WiFi está habilitado. Los datos móviles están deshabilitados. Conéctese a WiFi para usar las funciones en línea.';

  @override
  String get generalOfflineFeaturesLimited =>
      'Algunas funciones pueden estar limitadas sin conexión. Los datos se sincronizarán automáticamente cuando se restaure la conexión.';

  @override
  String get generalAllFeaturesAvailable =>
      'Todas las funciones están disponibles.';

  @override
  String get generalConnectionRestored => '¡Conexión restaurada!';

  @override
  String get generalStillOffline =>
      'Todavía sin conexión. Por favor, verifique la configuración de su red.';

  @override
  String get generalFailedToCheckConnectivity =>
      'Error al verificar la conectividad';

  @override
  String get generalRetry => 'Reintentar';

  @override
  String get incrementalSyncStatsTitle => 'Estadísticas de Sincronización';

  @override
  String incrementalSyncStatsDescription(int count) {
    return '$count sincronizaciones incrementales realizadas';
  }

  @override
  String get incrementalSyncStatsDescriptionEmpty =>
      'Rastree la eficiencia de sincronización y el ahorro de ancho de banda';

  @override
  String get incrementalSyncStatsRefresh => 'Actualizar estadísticas';

  @override
  String get incrementalSyncStatsNoData =>
      'Aún No Hay Estadísticas de Sincronización';

  @override
  String get incrementalSyncStatsNoDataDesc =>
      'Las estadísticas aparecerán aquí después de su primera sincronización incremental.';

  @override
  String get incrementalSyncStatsNoDataYet =>
      'Aún no hay datos de sincronización incremental';

  @override
  String get incrementalSyncStatsNoDataAvailable =>
      'No hay datos de sincronización disponibles';

  @override
  String get incrementalSyncStatsEfficiencyExcellent => 'Eficiencia Excelente';

  @override
  String get incrementalSyncStatsEfficiencyGood => 'Buena Eficiencia';

  @override
  String get incrementalSyncStatsEfficiencyModerate => 'Eficiencia Moderada';

  @override
  String get incrementalSyncStatsEfficiencyLow => 'Baja Eficiencia';

  @override
  String get incrementalSyncStatsEfficiencyVeryLow => 'Eficiencia Muy Baja';

  @override
  String get incrementalSyncStatsEfficiencyDescExcellent =>
      'La mayoría de los datos sin cambios - ¡la sincronización incremental es muy efectiva!';

  @override
  String get incrementalSyncStatsEfficiencyDescGood =>
      'Buen ahorro - la sincronización incremental funciona bien.';

  @override
  String get incrementalSyncStatsEfficiencyDescModerate =>
      'Cambios moderados detectados - se ahorró algo de ancho de banda.';

  @override
  String get incrementalSyncStatsEfficiencyDescLow =>
      'Muchos cambios - considere ajustar la ventana de sincronización.';

  @override
  String get incrementalSyncStatsEfficiencyDescVeryLow =>
      'La mayoría de los datos cambiaron - la sincronización incremental proporciona un beneficio mínimo.';

  @override
  String get incrementalSyncStatsLabelFetched => 'Obtenidos';

  @override
  String get incrementalSyncStatsLabelUpdated => 'Actualizados';

  @override
  String get incrementalSyncStatsLabelSkipped => 'Omitidos';

  @override
  String get incrementalSyncStatsLabelSaved => 'Ahorrado';

  @override
  String get incrementalSyncStatsLabelSyncs => 'Sincronizaciones';

  @override
  String get incrementalSyncStatsLabelBandwidthSaved =>
      'Ancho de Banda Ahorrado';

  @override
  String get incrementalSyncStatsLabelApiCallsSaved => 'Llamadas API Ahorradas';

  @override
  String get incrementalSyncStatsLabelUpdateRate => 'Tasa de Actualización';

  @override
  String get incrementalSyncStatsCurrentSync => 'Sincronización Actual';

  @override
  String incrementalSyncStatsDuration(String duration) {
    return 'Duración: $duration';
  }

  @override
  String get incrementalSyncStatsStatusSuccess => 'Estado: Exitoso';

  @override
  String get incrementalSyncStatsStatusFailed => 'Estado: Fallido';

  @override
  String incrementalSyncStatsError(String error) {
    return 'Error: $error';
  }

  @override
  String get incrementalSyncStatsByEntityType => 'Por Tipo de Entidad:';

  @override
  String incrementalSyncStatsEfficient(String rate) {
    return '$rate% eficiente';
  }

  @override
  String get offlineBannerTitle => 'Estás sin conexión';

  @override
  String get offlineBannerMessage =>
      'Los cambios se sincronizarán cuando estés en línea.';

  @override
  String get offlineBannerLearnMore => 'Más información';

  @override
  String get offlineBannerDismiss => 'Descartar';

  @override
  String get offlineBannerSemanticLabel =>
      'Estás sin conexión. Los cambios se sincronizarán cuando vuelvas a estar en línea. Desliza para descartar o toca Más información para detalles.';

  @override
  String get transactionOfflineMode => 'Modo Sin Conexión';

  @override
  String get transactionOfflineSaveNew =>
      'La transacción se guardará localmente y se sincronizará cuando estés en línea';

  @override
  String get transactionOfflineSaveEdit =>
      'Los cambios se guardarán localmente y se sincronizarán cuando estés en línea';

  @override
  String get transactionSaveOffline => 'Guardar Sin Conexión';

  @override
  String get transactionSave => 'Guardar';

  @override
  String get transactionSavedSynced => 'Transacción guardada y sincronizada';

  @override
  String get transactionSavedOffline =>
      'Transacción guardada sin conexión. Se sincronizará cuando estés en línea.';

  @override
  String get transactionSaved => 'Transacción guardada';

  @override
  String get syncStatusSynced => 'Sincronizado';

  @override
  String get syncStatusSyncing => 'Sincronizando...';

  @override
  String syncStatusPending(int count) {
    return '$count elementos pendientes';
  }

  @override
  String get syncStatusFailed => 'Sincronización fallida';

  @override
  String get syncStatusOffline => 'Sin conexión';

  @override
  String get syncStatusJustNow => 'Ahora mismo';

  @override
  String syncStatusMinutesAgo(int minutes) {
    return 'hace ${minutes}m';
  }

  @override
  String syncStatusHoursAgo(int hours) {
    return 'hace ${hours}h';
  }

  @override
  String syncStatusDaysAgo(int days) {
    return 'hace ${days}d';
  }

  @override
  String get syncStatusOverWeekAgo => 'Hace más de una semana';

  @override
  String get syncActionSyncNow => 'Sincronizar ahora';

  @override
  String get syncActionForceFullSync => 'Forzar sincronización completa';

  @override
  String get syncActionViewStatus => 'Ver estado de sincronización';

  @override
  String get syncActionSettings => 'Configuración de sincronización';

  @override
  String get syncStarted => 'Sincronización iniciada';

  @override
  String get syncFullStarted => 'Sincronización completa iniciada';

  @override
  String syncFailedToStart(String error) {
    return 'Error al iniciar la sincronización: $error';
  }

  @override
  String syncFailedToStartFull(String error) {
    return 'Error al iniciar la sincronización completa: $error';
  }

  @override
  String get syncServiceNotAvailable =>
      'Servicio de sincronización no disponible. Por favor, reinicie la aplicación.';

  @override
  String get syncProgressProviderNotAvailable =>
      'Proveedor de Estado de Sincronización No Disponible';

  @override
  String get syncProgressProviderNotAvailableDesc =>
      'Por favor, reinicie la aplicación para habilitar el seguimiento del progreso de sincronización.';

  @override
  String get syncProgressServiceUnavailable =>
      'Servicio de Sincronización No Disponible';

  @override
  String get syncProgressServiceUnavailableDesc =>
      'El Proveedor de Estado de Sincronización no está disponible. Por favor, reinicie la aplicación.';

  @override
  String get syncProgressCancel => 'Cancelar';

  @override
  String get syncProgressFailed => 'Sincronización Fallida';

  @override
  String get syncProgressComplete => 'Sincronización Completa';

  @override
  String get syncProgressSyncing => 'Sincronizando...';

  @override
  String incrementalSyncCacheCurrent(String ttl) {
    return 'Actual: $ttl';
  }

  @override
  String syncStatusProgressComplete(String percentage) {
    return '$percentage% completo';
  }

  @override
  String syncProgressSuccessfullySynced(int count) {
    return 'Sincronizadas exitosamente $count operaciones';
  }

  @override
  String syncProgressConflictsDetected(int count) {
    return '$count conflictos detectados';
  }

  @override
  String syncProgressOperationsFailed(int count) {
    return '$count operaciones fallaron';
  }

  @override
  String syncProgressOperationsCount(int completed, int total) {
    return '$completed/$total operaciones';
  }

  @override
  String get syncProgressSyncingOperations => 'Sincronizando operaciones...';

  @override
  String get syncProgressPreparing => 'Preparando...';

  @override
  String get syncProgressDetectingConflicts => 'Detectando conflictos...';

  @override
  String get syncProgressResolvingConflicts => 'Resolviendo conflictos...';

  @override
  String get syncProgressPullingUpdates => 'Obteniendo actualizaciones...';

  @override
  String get syncProgressFinalizing => 'Finalizando...';

  @override
  String get syncProgressCompleted => 'Completado';

  @override
  String syncStatusSyncingCount(int synced, int total) {
    return 'Sincronizando... $synced de $total';
  }

  @override
  String get listViewOfflineFilterPending => 'Pendiente';

  @override
  String listViewOfflineNoDataAvailable(String entityType) {
    return 'No hay $entityType Disponibles';
  }

  @override
  String listViewOfflineNoDataMessage(String entityType) {
    return 'Estás sin conexión. $entityType aparecerán aquí cuando te conectes a internet.';
  }

  @override
  String listViewOfflineLastUpdated(String age) {
    return 'Última actualización: $age';
  }

  @override
  String get dashboardOfflineIncludesUnsynced =>
      'Incluye datos no sincronizados';

  @override
  String dashboardOfflineDataAsOf(String age) {
    return 'Datos desde $age';
  }

  @override
  String get dashboardOfflineUnsynced => 'No sincronizado';

  @override
  String get dashboardOfflineViewingOfflineData =>
      'Viendo datos sin conexión. Algunos datos pueden estar desactualizados.';

  @override
  String dashboardOfflineNoDataAvailable(String dataType) {
    return 'No hay $dataType Disponibles';
  }

  @override
  String dashboardOfflineConnectToLoad(String dataType) {
    return 'Conéctate a internet para cargar $dataType';
  }

  @override
  String dashboardOfflineDataOutdated(String age) {
    return 'Los datos pueden estar desactualizados. Última actualización: $age.';
  }

  @override
  String get generalNetworkTypeWifi => 'WiFi';

  @override
  String get generalNetworkTypeMobile => 'Datos Móviles';

  @override
  String get generalNetworkTypeEthernet => 'Ethernet';

  @override
  String get generalNetworkTypeVpn => 'VPN';

  @override
  String get generalNetworkTypeBluetooth => 'Bluetooth';

  @override
  String get generalNetworkTypeOther => 'Otro';

  @override
  String get generalNetworkTypeNone => 'Ninguno';

  @override
  String get generalNetworkTypeSeparator => '+';

  @override
  String get offlineSettingsTitle => 'Configuración del Modo Sin Conexión';

  @override
  String get offlineSettingsHelp => 'Ayuda';

  @override
  String get offlineSettingsSynchronization => 'Sincronización';

  @override
  String get offlineSettingsAutoSync => 'Sincronización automática';

  @override
  String get offlineSettingsAutoSyncDesc =>
      'Sincronizar automáticamente en segundo plano';

  @override
  String get offlineSettingsAutoSyncEnabled =>
      'Sincronización automática habilitada';

  @override
  String get offlineSettingsAutoSyncDisabled =>
      'Sincronización automática deshabilitada';

  @override
  String get offlineSettingsSyncInterval => 'Intervalo de sincronización';

  @override
  String get offlineSettingsWifiOnly => 'Solo WiFi';

  @override
  String get offlineSettingsWifiOnlyDesc =>
      'Sincronizar solo cuando esté conectado a WiFi';

  @override
  String get offlineSettingsWifiOnlyEnabled =>
      'Sincronización solo WiFi habilitada';

  @override
  String get offlineSettingsWifiOnlyDisabled =>
      'Sincronización solo WiFi deshabilitada';

  @override
  String offlineSettingsLastSync(String time) {
    return 'Última sincronización: $time';
  }

  @override
  String offlineSettingsNextSync(String time) {
    return 'Próxima sincronización: $time';
  }

  @override
  String get offlineSettingsConflictResolution => 'Resolución de Conflictos';

  @override
  String get offlineSettingsResolutionStrategy => 'Estrategia de resolución';

  @override
  String get offlineSettingsStorage => 'Almacenamiento';

  @override
  String get offlineSettingsDatabaseSize => 'Tamaño de la base de datos';

  @override
  String get offlineSettingsClearCache => 'Limpiar caché';

  @override
  String get offlineSettingsClearCacheDesc => 'Eliminar datos temporales';

  @override
  String get offlineSettingsClearAllData => 'Limpiar todos los datos';

  @override
  String get offlineSettingsClearAllDataDesc =>
      'Eliminar todos los datos sin conexión';

  @override
  String get offlineSettingsStatistics => 'Estadísticas';

  @override
  String get offlineSettingsTotalSyncs => 'Sincronizaciones totales';

  @override
  String get offlineSettingsConflicts => 'Conflictos';

  @override
  String get offlineSettingsErrors => 'Errores';

  @override
  String get offlineSettingsSuccessRate => 'Tasa de éxito';

  @override
  String get offlineSettingsActions => 'Acciones';

  @override
  String get offlineSettingsSyncing => 'Sincronizando...';

  @override
  String get offlineSettingsSyncNow => 'Sincronizar ahora';

  @override
  String get offlineSettingsForceFullSync => 'Forzar sincronización completa';

  @override
  String get offlineSettingsCheckConsistency => 'Verificar consistencia';

  @override
  String get offlineSettingsChecking => 'Verificando...';

  @override
  String get offlineSettingsSyncIntervalTitle => 'Intervalo de Sincronización';

  @override
  String offlineSettingsSyncIntervalSet(String interval) {
    return 'Intervalo de sincronización establecido en $interval';
  }

  @override
  String get offlineSettingsConflictStrategyTitle =>
      'Estrategia de Resolución de Conflictos';

  @override
  String offlineSettingsConflictStrategySet(String strategy) {
    return 'Estrategia de conflicto establecida en $strategy';
  }

  @override
  String get offlineSettingsClearCacheTitle => 'Limpiar Caché';

  @override
  String get offlineSettingsClearCacheMessage =>
      'Esto eliminará los datos temporales. Sus datos sin conexión se conservarán.';

  @override
  String get offlineSettingsClearAllDataTitle => 'Limpiar Todos los Datos';

  @override
  String get offlineSettingsClearAllDataMessage =>
      'Esto eliminará TODOS los datos sin conexión. Esta acción no se puede deshacer. Necesitará sincronizar nuevamente para usar el modo sin conexión.';

  @override
  String get offlineSettingsCacheCleared => 'Caché limpiado';

  @override
  String get offlineSettingsAllDataCleared =>
      'Todos los datos sin conexión eliminados';

  @override
  String get offlineSettingsPerformingSync => 'Realizando sincronización...';

  @override
  String get offlineSettingsPerformingIncrementalSync =>
      'Realizando sincronización incremental...';

  @override
  String get offlineSettingsPerformingFullSync =>
      'Realizando sincronización completa...';

  @override
  String get offlineSettingsIncrementalSyncCompleted =>
      'Sincronización incremental completada exitosamente';

  @override
  String offlineSettingsIncrementalSyncIssues(String error) {
    return 'Sincronización incremental completada con problemas: $error';
  }

  @override
  String get offlineSettingsForceFullSyncTitle =>
      'Forzar Sincronización Completa';

  @override
  String get offlineSettingsForceFullSyncMessage =>
      'Esto descargará todos los datos del servidor, reemplazando los datos locales. Esto puede tardar varios minutos.';

  @override
  String get offlineSettingsConsistencyCheckComplete =>
      'Verificación de Consistencia Completada';

  @override
  String get offlineSettingsConsistencyCheckNoIssues =>
      'No se encontraron problemas. Sus datos son consistentes.';

  @override
  String offlineSettingsConsistencyCheckIssuesFound(int count) {
    return 'Se encontraron $count problema(s).';
  }

  @override
  String get offlineSettingsConsistencyCheckIssueBreakdown =>
      'Desglose de problemas:';

  @override
  String offlineSettingsConsistencyCheckMoreIssues(int count) {
    return '... y $count más';
  }

  @override
  String get offlineSettingsRepairInconsistencies => 'Reparar Inconsistencias';

  @override
  String get offlineSettingsRepairInconsistenciesMessage =>
      'Esto intentará corregir automáticamente los problemas detectados. Algunos problemas pueden requerir intervención manual.';

  @override
  String get offlineSettingsRepairComplete => 'Reparación Completada';

  @override
  String offlineSettingsRepairCompleteMessage(int repaired, int failed) {
    return '$repaired problema(s) reparado(s).\n$failed problema(s) no se pudieron reparar.';
  }

  @override
  String get offlineSettingsHelpTitle => 'Ayuda del Modo Sin Conexión';

  @override
  String get offlineSettingsHelpAutoSync => 'Sincronización automática';

  @override
  String get offlineSettingsHelpAutoSyncDesc =>
      'Sincronizar automáticamente los datos en segundo plano en el intervalo especificado.';

  @override
  String get offlineSettingsHelpWifiOnly => 'Solo WiFi';

  @override
  String get offlineSettingsHelpWifiOnlyDesc =>
      'Sincronizar solo cuando esté conectado a WiFi para ahorrar datos móviles.';

  @override
  String get offlineSettingsHelpConflictResolution =>
      'Resolución de Conflictos';

  @override
  String get offlineSettingsHelpConflictResolutionDesc =>
      'Elija cómo manejar los conflictos cuando los mismos datos se modifican tanto localmente como en el servidor.';

  @override
  String get offlineSettingsHelpConsistencyCheck =>
      'Verificación de Consistencia';

  @override
  String get offlineSettingsHelpConsistencyCheckDesc =>
      'Verificar la integridad de los datos y corregir cualquier inconsistencia en la base de datos local.';

  @override
  String get offlineSettingsStrategyLocalWins => 'Ganan los Locales';

  @override
  String get offlineSettingsStrategyRemoteWins => 'Ganan los Remotos';

  @override
  String get offlineSettingsStrategyLastWriteWins => 'Gana la Última Escritura';

  @override
  String get offlineSettingsStrategyManual => 'Resolución Manual';

  @override
  String get offlineSettingsStrategyMerge => 'Combinar Cambios';

  @override
  String get offlineSettingsStrategyLocalWinsDesc =>
      'Siempre mantener los cambios locales';

  @override
  String get offlineSettingsStrategyRemoteWinsDesc =>
      'Siempre mantener los cambios del servidor';

  @override
  String get offlineSettingsStrategyLastWriteWinsDesc =>
      'Mantener la versión modificada más recientemente';

  @override
  String get offlineSettingsStrategyManualDesc =>
      'Resolver manualmente cada conflicto';

  @override
  String get offlineSettingsStrategyMergeDesc =>
      'Combinar automáticamente los cambios no conflictivos';

  @override
  String get offlineSettingsJustNow => 'Ahora mismo';

  @override
  String offlineSettingsMinutesAgo(int minutes) {
    return 'hace $minutes minutos';
  }

  @override
  String offlineSettingsHoursAgo(int hours) {
    return 'hace $hours horas';
  }

  @override
  String offlineSettingsDaysAgo(int days) {
    return 'hace $days días';
  }

  @override
  String get offlineSettingsFailedToUpdateAutoSync =>
      'Error al actualizar la configuración de sincronización automática';

  @override
  String get offlineSettingsFailedToUpdateWifiOnly =>
      'Error al actualizar la configuración de solo WiFi';

  @override
  String get offlineSettingsFailedToUpdateSyncInterval =>
      'Error al actualizar el intervalo de sincronización';

  @override
  String get offlineSettingsFailedToUpdateConflictStrategy =>
      'Error al actualizar la estrategia de conflicto';

  @override
  String offlineSettingsFailedToClearCache(String error) {
    return 'Error al limpiar la caché: $error';
  }

  @override
  String get offlineSettingsFailedToClearData => 'Error al limpiar los datos';

  @override
  String offlineSettingsSyncFailed(String error) {
    return 'Error en la sincronización: $error';
  }

  @override
  String offlineSettingsFullSyncFailed(String error) {
    return 'Error en la sincronización completa: $error';
  }

  @override
  String offlineSettingsConsistencyCheckFailed(String error) {
    return 'Error en la verificación de consistencia: $error';
  }

  @override
  String offlineSettingsRepairFailed(String error) {
    return 'Error en la reparación: $error';
  }

  @override
  String get offlineSettingsIncrementalSyncNotAvailable =>
      'La sincronización incremental no está disponible. Por favor, realice una sincronización completa primero.';

  @override
  String offlineSettingsIncrementalSyncFailed(String error) {
    return 'Error en la sincronización incremental: $error';
  }

  @override
  String get offlineSettingsSyncServiceNotAvailable =>
      'Servicio de sincronización no disponible. Por favor, reinicie la aplicación.';

  @override
  String offlineSettingsFailedToGetSyncService(String error) {
    return 'Error al obtener el servicio de sincronización: $error';
  }

  @override
  String get offlineSettingsIncrementalSyncServiceNotAvailable =>
      'Servicio de sincronización incremental no disponible';

  @override
  String get offlineSettingsDismiss => 'Descartar';

  @override
  String get offlineSettingsSyncIntervalManual => 'Manual';

  @override
  String get offlineSettingsSyncInterval15Minutes => '15 minutos';

  @override
  String get offlineSettingsSyncInterval30Minutes => '30 minutos';

  @override
  String get offlineSettingsSyncInterval1Hour => '1 hora';

  @override
  String get offlineSettingsSyncInterval6Hours => '6 horas';

  @override
  String get offlineSettingsSyncInterval12Hours => '12 horas';

  @override
  String get offlineSettingsSyncInterval24Hours => '24 horas';

  @override
  String get incrementalSyncTitle => 'Sincronización Incremental';

  @override
  String get incrementalSyncDescription =>
      'Optimizar el rendimiento de sincronización obteniendo solo datos modificados';

  @override
  String get incrementalSyncEnable => 'Habilitar Sincronización Incremental';

  @override
  String get incrementalSyncEnabledDesc =>
      'Obtener solo datos modificados desde la última sincronización (70-80% más rápido)';

  @override
  String get incrementalSyncDisabledDesc =>
      'La sincronización completa obtiene todos los datos cada vez';

  @override
  String get incrementalSyncEnabled => 'Sincronización incremental habilitada';

  @override
  String get incrementalSyncDisabled =>
      'Sincronización incremental deshabilitada';

  @override
  String get incrementalSyncFailedToUpdate =>
      'Error al actualizar la configuración';

  @override
  String get incrementalSyncWindow => 'Ventana de Sincronización';

  @override
  String get incrementalSyncWindowDesc => 'Cuánto tiempo atrás buscar cambios';

  @override
  String incrementalSyncWindowSet(String window) {
    return 'Ventana de sincronización establecida en $window';
  }

  @override
  String get incrementalSyncWindowFailed =>
      'Error al actualizar la ventana de sincronización';

  @override
  String get incrementalSyncCacheDuration => 'Duración de la Caché';

  @override
  String get incrementalSyncCacheDurationDesc =>
      'Cuánto tiempo almacenar en caché categorías, facturas y alcancías antes de actualizar. Estas entidades cambian con poca frecuencia, por lo que duraciones de caché más largas reducen las llamadas a la API.';

  @override
  String get incrementalSyncCacheDurationFailed =>
      'Error al actualizar la duración de la caché';

  @override
  String get incrementalSyncLastIncremental =>
      'Última Sincronización Incremental';

  @override
  String get incrementalSyncLastFull => 'Última Sincronización Completa';

  @override
  String get incrementalSyncNever => 'Nunca';

  @override
  String get incrementalSyncToday => 'Hoy';

  @override
  String incrementalSyncDaysAgo(int days) {
    return 'hace ${days}d';
  }

  @override
  String get incrementalSyncFullSyncRecommended =>
      'Sincronización Completa Recomendada';

  @override
  String get incrementalSyncFullSyncRecommendedDesc =>
      'Han pasado más de 7 días desde la última sincronización completa. Se recomienda una sincronización completa para garantizar la integridad de los datos.';

  @override
  String get incrementalSyncIncrementalButton => 'Sincronización Incremental';

  @override
  String get incrementalSyncFullButton => 'Sincronización Completa';

  @override
  String get incrementalSyncResetStatistics => 'Restablecer Estadísticas';

  @override
  String get incrementalSyncResetting => 'Restableciendo...';

  @override
  String get incrementalSyncResetStatisticsTitle => 'Restablecer Estadísticas';

  @override
  String get incrementalSyncResetStatisticsMessage =>
      'Esto eliminará todas las estadísticas de sincronización incremental (elementos obtenidos, ancho de banda ahorrado, etc.).\n\nLa configuración se conservará. Esta acción no se puede deshacer.';

  @override
  String get incrementalSyncResetStatisticsSuccess =>
      'Estadísticas restablecidas exitosamente';

  @override
  String get incrementalSyncResetStatisticsFailed =>
      'Error al restablecer las estadísticas';

  @override
  String get incrementalSyncWindowLabel => 'Ventana de sincronización: ';

  @override
  String get incrementalSyncFullSyncEnabled =>
      'Sincronización completa habilitada';

  @override
  String incrementalSyncWindowDays(int days) {
    return '$days días';
  }

  @override
  String incrementalSyncCacheHours(int hours) {
    return '$hours horas';
  }

  @override
  String get incrementalSyncWindowWord => 'ventana';
}
