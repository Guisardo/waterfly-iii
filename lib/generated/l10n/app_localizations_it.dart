// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class SIt extends S {
  SIt([String locale = 'it']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'Portafoglio contanti';

  @override
  String get accountRoleAssetCC => 'Carta di credito';

  @override
  String get accountRoleAssetDefault => 'Conto attività predefinito';

  @override
  String get accountRoleAssetSavings => 'Conto risparmi';

  @override
  String get accountRoleAssetShared => 'Conto attività condiviso';

  @override
  String get accountsLabelAsset => 'Conti attività';

  @override
  String get accountsLabelExpense => 'Conti uscite';

  @override
  String get accountsLabelLiabilities => 'Passività';

  @override
  String get accountsLabelRevenue => 'Conti entrate';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'settimana',
      'monthly': 'mese',
      'quarterly': 'trimestre',
      'halfyear': 'semestre',
      'yearly': 'anno',
      'other': 'sconosciuto',
    });
    return '$interest% di interesse per $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'settimanale',
      'monthly': 'mensile',
      'quarterly': 'trimestrale',
      'halfyear': 'semestrale',
      'yearly': 'annuale',
      'other': 'sconosciuta',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', rimandata il $skip',
      zero: '',
    );
    return 'Il pagamento ricorrente comprende le transazioni con importo tra $minValue e $maxvalue. Si ripete con frequenza $_temp0$_temp1.';
  }

  @override
  String get billsChangeLayoutTooltip => 'Cambia layout';

  @override
  String get billsChangeSortOrderTooltip => 'Modifica ordinamento';

  @override
  String get billsErrorLoading => 'Errore caricando i pagamenti ricorrenti.';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'settimanale',
      'monthly': 'mensile',
      'quarterly': 'trimestrale',
      'halfyear': 'semestrale',
      'yearly': 'annuale',
      'other': 'sconosciuta',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', rimandata il $skip',
      zero: '',
    );
    return 'Il pagamento ricorrente comprende transazioni di valore $value. Si ripete con frequenza $_temp0$_temp1.';
  }

  @override
  String billsExpectedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Attesa per $dateString';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Settimanale',
      'monthly': 'Mensile',
      'quarterly': 'Trimestrale',
      'halfyear': 'Semestrale',
      'yearly': 'Annuale',
      'other': 'Sconosciuta',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Settimanale',
      'monthly': 'Mensile',
      'quarterly': 'Trimestrale',
      'halfyear': 'Semestrale',
      'yearly': 'Annuale',
      'other': 'Sconosciuta',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', rimandata il $skip',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get billsInactive => 'Non attiva';

  @override
  String get billsIsActive => 'Il pagamento ricorrente è attivo';

  @override
  String get billsLayoutGroupSubtitle =>
      'Pagamenti ricorrenti visualizzati nei gruppi assegnati.';

  @override
  String get billsLayoutGroupTitle => 'Gruppo';

  @override
  String get billsLayoutListSubtitle =>
      'Pagamenti ricorrenti visualizzati in un elenco ordinate in base a determinati criteri.';

  @override
  String get billsLayoutListTitle => 'Elenco';

  @override
  String get billsListEmpty => 'Questo elenco è attualmente vuoto.';

  @override
  String get billsNextExpectedMatch => 'Prossima';

  @override
  String get billsNotActive => 'Il pagamento ricorrente è inattivo';

  @override
  String get billsNotExpected => 'Non prevista in questo periodo';

  @override
  String get billsNoTransactions => 'Nessuna transazione trovata.';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Pagata $dateString';
  }

  @override
  String get billsSortAlphabetical => 'Alfabetico';

  @override
  String get billsSortByTimePeriod => 'Per periodo di tempo';

  @override
  String get billsSortFrequency => 'Frequenza';

  @override
  String get billsSortName => 'Nome';

  @override
  String get billsUngrouped => 'Non raggruppate';

  @override
  String get billsSettingsShowOnlyActive => 'Mostra solo attivi';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'Mostra solo gli abbonamenti attivi.';

  @override
  String get billsSettingsShowOnlyExpected => 'Mostra solo previsti';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'Mostra solo gli abbonamenti previsti (o pagati) questo mese.';

  @override
  String get categoryDeleteConfirm =>
      'Sei sicuro di voler eliminare questa categoria? Le transazioni non saranno eliminate, ma non avranno più una categoria.';

  @override
  String get categoryErrorLoading => 'Errore nel caricamento delle categorie.';

  @override
  String get categoryFormLabelIncludeInSum => 'Includi nel totale mensile';

  @override
  String get categoryFormLabelName => 'Nome categoria';

  @override
  String get categoryMonthNext => 'Mese prossimo';

  @override
  String get categoryMonthPrev => 'Mese precedente';

  @override
  String get categorySumExcluded => 'esclusa';

  @override
  String get categoryTitleAdd => 'Aggiungi Categoria';

  @override
  String get categoryTitleDelete => 'Elimina Categoria';

  @override
  String get categoryTitleEdit => 'Modifica Categoria';

  @override
  String get catNone => '(nessuna categoria)';

  @override
  String get catOther => 'Altro';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'Risposta non valida dall\'API: $message';
  }

  @override
  String get errorAPIUnavailable => 'API non raggiungibile';

  @override
  String get errorFieldRequired => 'Questo campo è obbligatorio.';

  @override
  String get errorInvalidURL => 'URL non valido';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'È richiesta almeno la versione API v$requiredVersion su Firefly. Per favore, aggiornare.';
  }

  @override
  String errorStatusCode(int code) {
    return 'Codice di stato: $code';
  }

  @override
  String get errorUnknown => 'Errore sconosciuto.';

  @override
  String get formButtonHelp => 'Aiuto';

  @override
  String get formButtonLogin => 'Accedi';

  @override
  String get formButtonLogout => 'Esci';

  @override
  String get formButtonRemove => 'Rimuovi';

  @override
  String get formButtonResetLogin => 'Reimposta accesso';

  @override
  String get formButtonTransactionAdd => 'Aggiungi transazione';

  @override
  String get formButtonTryAgain => 'Riprova';

  @override
  String get generalAccount => 'Conto';

  @override
  String get generalAssets => 'Attività';

  @override
  String get generalBalance => 'Saldo';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Saldo al $dateString';
  }

  @override
  String get generalBill => 'Bolletta';

  @override
  String get generalBudget => 'Budget';

  @override
  String get generalCategory => 'Categoria';

  @override
  String get generalCurrency => 'Valuta';

  @override
  String get generalDateRangeCurrentMonth => 'Mese Corrente';

  @override
  String get generalDateRangeLast30Days => 'Ultimi 30 giorni';

  @override
  String get generalDateRangeCurrentYear => 'Anno Corrente';

  @override
  String get generalDateRangeLastYear => 'Anno Precedente';

  @override
  String get generalDateRangeAll => 'Tutto';

  @override
  String get generalDefault => 'predefinito';

  @override
  String get generalDestinationAccount => 'Conto di destinazione';

  @override
  String get generalDismiss => 'Ignora';

  @override
  String get generalEarned => 'Guadagnato';

  @override
  String get generalError => 'Errore';

  @override
  String get generalExpenses => 'Spese';

  @override
  String get generalIncome => 'Entrate';

  @override
  String get generalLiabilities => 'Passività';

  @override
  String get generalMultiple => 'molteplice';

  @override
  String get generalNever => 'mai';

  @override
  String get generalReconcile => 'Contabilizzato';

  @override
  String get generalReset => 'Reimposta';

  @override
  String get generalSourceAccount => 'Conto di origine';

  @override
  String get generalSpent => 'Speso';

  @override
  String get generalSum => 'Totale';

  @override
  String get generalTarget => 'Obiettivo';

  @override
  String get generalUnknown => 'Sconosciuto';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'settimanale',
      'monthly': 'mensile',
      'quarterly': 'trimestrale',
      'halfyear': 'semestrale',
      'yearly': 'annuale',
      'other': 'sconosciuto',
    });
    return ' ($_temp0)';
  }

  @override
  String get homeMainBillsTitle => 'Bollette per la prossima settimana';

  @override
  String homeMainBudgetInterval(DateTime from, DateTime to, String period) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' (da $fromString a $toString, $period)';
  }

  @override
  String homeMainBudgetIntervalSingle(DateTime from, DateTime to) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' (da $fromString al $toString)';
  }

  @override
  String homeMainBudgetSum(String current, String status, String available) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'over': 'su',
      'other': 'rimanente da',
    });
    return '$current $_temp0 $available';
  }

  @override
  String get homeMainBudgetTitle => 'Budget per il mese corrente';

  @override
  String get homeMainChartAccountsTitle => 'Riepilogo conti';

  @override
  String get homeMainChartCategoriesTitle =>
      'Riepilogo categorie per il mese corrente';

  @override
  String get homeMainChartDailyAvg => 'Media di 7 giorni';

  @override
  String get homeMainChartDailyTitle => 'Riepilogo giornaliero';

  @override
  String get homeMainChartNetEarningsTitle => 'Guadagni Netti';

  @override
  String get homeMainChartNetWorthTitle => 'Patrimonio';

  @override
  String get homeMainChartTagsTitle =>
      'Riepilogo etichette per il mese corrente';

  @override
  String get homePiggyAdjustDialogTitle => 'Risparmia/Spendi Denaro';

  @override
  String homePiggyDateStart(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Data inizio: $dateString';
  }

  @override
  String homePiggyDateTarget(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Data termine: $dateString';
  }

  @override
  String get homeMainDialogSettingsTitle => 'Personalizza Dashboard';

  @override
  String homePiggyLinked(String account) {
    return 'Collegato a $account';
  }

  @override
  String get homePiggyNoAccounts => 'Nessun salvadanaio impostato.';

  @override
  String get homePiggyNoAccountsSubtitle =>
      'Creane alcuni dall\'interfaccia web!';

  @override
  String homePiggyRemaining(String amount) {
    return 'Da risparmiare: $amount';
  }

  @override
  String homePiggySaved(String amount) {
    return 'Risparmiato finora: $amount';
  }

  @override
  String get homePiggySavedMultiple => 'Risparmiato finora:';

  @override
  String homePiggyTarget(String amount) {
    return 'Importo obiettivo: $amount';
  }

  @override
  String get homePiggyAccountStatus => 'Stato conto';

  @override
  String get homePiggyAvailableAmounts => 'Importi disponibili';

  @override
  String homePiggyAvailable(String amount) {
    return 'Disponibile: $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'Nei salvadanai: $amount';
  }

  @override
  String get homeTabLabelBalance => 'Bilancio';

  @override
  String get homeTabLabelMain => 'Principale';

  @override
  String get homeTabLabelPiggybanks => 'Salvadanai';

  @override
  String get homeTabLabelTransactions => 'Transazioni';

  @override
  String get homeTransactionsActionFilter => 'Elenco Filtri';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<Tutti i conti>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<Tutte le bollette>';

  @override
  String get homeTransactionsDialogFilterBillUnset => '<Nessuna bolletta>';

  @override
  String get homeTransactionsDialogFilterBudgetsAll => '<Tutti i budget>';

  @override
  String get homeTransactionsDialogFilterBudgetUnset => '<Nessun budget>';

  @override
  String get homeTransactionsDialogFilterCategoriesAll =>
      '<Tutte le categorie>';

  @override
  String get homeTransactionsDialogFilterCategoryUnset => '<Nessuna categoria>';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<Tutte le valute>';

  @override
  String get homeTransactionsDialogFilterDateRange => 'Periodo';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'Mostra transazioni future';

  @override
  String get homeTransactionsDialogFilterSearch => 'Termine di ricerca';

  @override
  String get homeTransactionsDialogFilterTitle => 'Seleziona filtri';

  @override
  String get homeTransactionsEmpty => 'Nessuna transazione trovata.';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num categorie';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'Mostra etichette nella lista transazioni';

  @override
  String get liabilityDirectionCredit => 'Questo debito mi è dovuto';

  @override
  String get liabilityDirectionDebit => 'Ho questo debito';

  @override
  String get liabilityTypeDebt => 'Debito';

  @override
  String get liabilityTypeLoan => 'Prestito';

  @override
  String get liabilityTypeMortgage => 'Mutuo';

  @override
  String get loginAbout =>
      'Per utilizzare Waterfly III produttivamente è necessario il proprio server con un\'istanza di Firefly III o l\'add-on di Firefly III per Home Assistant.\n\nInserisci l\'URL completo e un token di accesso personale (Opzioni -> Profilo -> OAuth -> Token di accesso personale) qui sotto.';

  @override
  String get loginFormLabelAPIKey => 'Chiave API valida';

  @override
  String get loginFormLabelHost => 'URL del server';

  @override
  String get loginWelcome => 'Benvenuto su Waterfly III';

  @override
  String get logoutConfirmation => 'Sei sicuro di volerti disconnettere?';

  @override
  String get navigationAccounts => 'Conti';

  @override
  String get navigationBills => 'Pagamenti ricorrenti';

  @override
  String get navigationCategories => 'Categorie';

  @override
  String get navigationMain => 'Dashboard principale';

  @override
  String get generalSettings => 'Impostazioni';

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

    return '$percString di $of';
  }

  @override
  String get settingsDialogDebugInfo =>
      'Qui puoi abilitare il registro di debug e inviarlo. Questo ha un impatto significativo sulle prestazioni, quindi non attivarlo a meno che non venga suggerito di farlo. Disabilitare il registro cancellerà quello memorizzato in precedenza.';

  @override
  String get settingsDialogDebugMailCreate => 'Crea E-mail';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      'ATTENZIONE: Si aprirà una bozza di e-mail con il file di registro allegato (in formato testuale). I registri potrebbero contenere informazioni sensibili, come il nome host della tua istanza di Firefly (anche se cerco di evitare la registrazione di qualsiasi segreto, come la chiave API). Si prega di leggere attentamente il registro e censurare qualsiasi informazione che non si desidera condividere e/o non è rilevante per il problema che si desidera segnalare.\n\nPer favore non inviare il registro senza previo accordo via e-mail/GitHub. Eliminerò tutti i registri inviati senza contesto per motivi di privacy. Non caricare mai il registro senza censura su GitHub o altrove.';

  @override
  String get settingsDialogDebugSendButton => 'Invia registro via e-mail';

  @override
  String get settingsDialogDebugTitle => 'Registro di debug';

  @override
  String get settingsDialogLanguageTitle => 'Seleziona Lingua';

  @override
  String get settingsDialogThemeTitle => 'Seleziona Tema';

  @override
  String get settingsFAQ => 'Domande frequenti';

  @override
  String get settingsFAQHelp => 'Si apre nel browser. Solo in inglese.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configure offline sync and mobile data usage';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLockscreen => 'Schermata di blocco';

  @override
  String get settingsLockscreenHelp =>
      'Richiedi l\'autenticazione all\'avvio dell\'app';

  @override
  String get settingsLockscreenInitial =>
      'Si prega di autenticarsi per abilitare la schermata di blocco.';

  @override
  String get settingsNLAppAccount => 'Conto Predefinito';

  @override
  String get settingsNLAppAccountDynamic => '<Dinamico>';

  @override
  String get settingsNLAppAdd => 'Aggiungi App';

  @override
  String get settingsNLAppAddHelp =>
      'Tocca per aggiungere un\'app di cui leggere le notifiche. Solo le app idonee verranno visualizzate nella lista.';

  @override
  String get settingsNLAppAddInfo =>
      'Effettua alcune transazioni per le quali ricevi notifiche sullo smartphone per aggiungere app a questo elenco. Se l\'app che cerchi non è comunque presente, si prega di segnalarla ad app@vogt.pw.';

  @override
  String get settingsNLAutoAdd => 'Crea transazione automaticamente';

  @override
  String get settingsNLDescription =>
      'Questo servizio consente di recuperare i dettagli delle transazioni dalle notifiche push che ricevi. Inoltre, è possibile selezionare un account predefinito a cui la transazione dovrebbe essere assegnata - se non è impostato alcun valore, il servizio cerca di estrarre un account dal testo della notifica.';

  @override
  String get settingsNLEmptyNote => 'Lascia vuota l\'annotazione';

  @override
  String get settingsNLPermissionGrant => 'Tocca per concedere i permessi.';

  @override
  String get settingsNLPermissionNotGranted => 'Permesso non concesso.';

  @override
  String get settingsNLPermissionRemove => 'Rimuovere il permesso?';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'Per disabilitare questo servizio, fare clic sull\'app e rimuovi i permessi nella schermata successiva.';

  @override
  String get settingsNLPrefillTXTitle =>
      'Compila il titolo della transazione con il titolo della notifica';

  @override
  String get settingsNLServiceChecking => 'Controllo dello stato…';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'Errore nel controllo dello stato: $error';
  }

  @override
  String get settingsNLServiceRunning => 'Servizio in esecuzione.';

  @override
  String get settingsNLServiceStatus => 'Stato del Servizio';

  @override
  String get settingsNLServiceStopped => 'Il servizio è interrotto.';

  @override
  String get settingsNotificationListener => 'Servizio di Lettura Notifiche';

  @override
  String get settingsTheme => 'Tema App';

  @override
  String get settingsThemeDynamicColors => 'Colori Dinamici';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'Modalità Scura',
      'light': 'Modalità Chiara',
      'other': 'Predefinito di sistema',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone => 'Usa fuso orario del server';

  @override
  String get settingsUseServerTimezoneHelp =>
      'Mostra tutti gli orari nel fuso orario del server. Questo simula il comportamento dell\'interfaccia web.';

  @override
  String get settingsVersion => 'Versione App';

  @override
  String get settingsVersionChecking => 'verifica…';

  @override
  String get transactionAttachments => 'Allegati';

  @override
  String get transactionDeleteConfirm =>
      'Confermare l\'eliminazione della transazione?';

  @override
  String get transactionDialogAttachmentsDelete => 'Elimina Allegato';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      'Confermare l\'eliminazione dell\'allegato?';

  @override
  String get transactionDialogAttachmentsErrorDownload =>
      'Impossibile scaricare il file.';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'Impossibile aprire il file: $error';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'Impossibile caricare il file: $error';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'Allegati';

  @override
  String get transactionDialogBillNoBill => 'Nessuna bolletta';

  @override
  String get transactionDialogBillTitle => 'Collega a bolletta';

  @override
  String get transactionDialogCurrencyTitle => 'Seleziona la valuta';

  @override
  String get transactionDialogPiggyNoPiggy => 'Nessun salvadanaio';

  @override
  String get transactionDialogPiggyTitle => 'Collega al salvadanaio';

  @override
  String get transactionDialogTagsAdd => 'Aggiungi Etichetta';

  @override
  String get transactionDialogTagsHint => 'Ricerca/Aggiungi Etichetta';

  @override
  String get transactionDialogTagsTitle => 'Seleziona etichette';

  @override
  String get transactionDuplicate => 'Duplica';

  @override
  String get transactionErrorInvalidAccount => 'Conto non valido';

  @override
  String get transactionErrorInvalidBudget => 'Budget non valido';

  @override
  String get transactionErrorNoAccounts =>
      'Si prega di compilare prima i conti.';

  @override
  String get transactionErrorNoAssetAccount =>
      'Si prega di selezionare un conto attività.';

  @override
  String get transactionErrorTitle => 'Si prega di fornire un titolo.';

  @override
  String get transactionFormLabelAccountDestination => 'Conto di destinazione';

  @override
  String get transactionFormLabelAccountForeign => 'Conto esterno';

  @override
  String get transactionFormLabelAccountOwn => 'Conto personale';

  @override
  String get transactionFormLabelAccountSource => 'Conto di origine';

  @override
  String get transactionFormLabelNotes => 'Note';

  @override
  String get transactionFormLabelTags => 'Etichette';

  @override
  String get transactionFormLabelTitle => 'Titolo Transazione';

  @override
  String get transactionSplitAdd => 'Aggiungi transazione suddivisa';

  @override
  String get transactionSplitChangeCurrency => 'Modifica Valuta Suddivisa';

  @override
  String get transactionSplitChangeDestinationAccount =>
      'Cambia conto di destinazione diviso';

  @override
  String get transactionSplitChangeSourceAccount =>
      'Cambia conto di origine diviso';

  @override
  String get transactionSplitChangeTarget =>
      'Modifica conto destinazione suddivisa';

  @override
  String get transactionSplitDelete => 'Elimina suddivisione';

  @override
  String get transactionTitleAdd => 'Aggiungi transazione';

  @override
  String get transactionTitleDelete => 'Elimina Transazione';

  @override
  String get transactionTitleEdit => 'Modifica Transazione';

  @override
  String get transactionTypeDeposit => 'Deposito';

  @override
  String get transactionTypeTransfer => 'Trasferimento';

  @override
  String get transactionTypeWithdrawal => 'Prelievo';

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
