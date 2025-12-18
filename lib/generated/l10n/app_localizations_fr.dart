// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class SFr extends S {
  SFr([String locale = 'fr']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'Porte-monnaie';

  @override
  String get accountRoleAssetCC => 'Carte de crédit';

  @override
  String get accountRoleAssetDefault => 'Compte d\'actif par défaut';

  @override
  String get accountRoleAssetSavings => 'Compte d\'épargne';

  @override
  String get accountRoleAssetShared => 'Compte d\'actif partagé';

  @override
  String get accountsLabelAsset => 'Comptes d\'actifs';

  @override
  String get accountsLabelExpense => 'Comptes de dépenses';

  @override
  String get accountsLabelLiabilities => 'Passifs';

  @override
  String get accountsLabelRevenue => 'Comptes de recettes';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'semaine',
      'monthly': 'mois',
      'quarterly': 'trimestre',
      'halfyear': 'semestre',
      'yearly': 'année',
      'other': 'inconnue',
    });
    return '$interest% d\'intérêts par $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'toutes les semaines',
      'monthly': 'tous les mois',
      'quarterly': 'tous les trimestres',
      'halfyear': 'tous les six mois',
      'yearly': 'tous les ans',
      'other': 'autre',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', ignorer $skip répétitions',
      zero: '',
      one: '',
    );
    return 'La facture correspond aux transactions entre $minValue et $maxvalue. Se répète $_temp0$_temp1.';
  }

  @override
  String get billsChangeLayoutTooltip => 'Modifier la mise en page';

  @override
  String get billsChangeSortOrderTooltip => 'Changer l\'ordre de tri';

  @override
  String get billsErrorLoading => 'Erreur lors du chargement des factures.';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'toutes les semaines',
      'monthly': 'tous les mois',
      'quarterly': 'tous les trimestres',
      'halfyear': 'tous les six mois',
      'yearly': 'tous les ans',
      'other': 'autre',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', ignorer $skip répétitions',
      zero: '',
      one: '',
    );
    return 'La facture correspond à des transactions de $value. Se répète $_temp0$_temp1.';
  }

  @override
  String billsExpectedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Prévu le $dateString';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Hebdomadaire',
      'monthly': 'Mensuelle',
      'quarterly': 'Trimestrielle',
      'halfyear': 'Semestrielle',
      'yearly': 'Annuelle',
      'other': 'Autre',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Hebdomadaire',
      'monthly': 'Mensuelle',
      'quarterly': 'Trimestrielle',
      'halfyear': 'Semestrielle',
      'yearly': 'Annuelle',
      'other': 'Autre',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', ignorer $skip répétitions',
      zero: '',
      one: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get billsInactive => 'Inactive';

  @override
  String get billsIsActive => 'Facture active';

  @override
  String get billsLayoutGroupSubtitle =>
      'Factures affichées par groupe assigné.';

  @override
  String get billsLayoutGroupTitle => 'Groupe';

  @override
  String get billsLayoutListSubtitle =>
      'Factures affichées dans une liste triée selon certains critères.';

  @override
  String get billsLayoutListTitle => 'Liste';

  @override
  String get billsListEmpty => 'La liste est actuellement vide.';

  @override
  String get billsNextExpectedMatch => 'Prochaine association attendue';

  @override
  String get billsNotActive => 'Facture inactive';

  @override
  String get billsNotExpected => 'Non attendu cette période';

  @override
  String get billsNoTransactions => 'Aucune transaction trouvée.';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Payée le $dateString';
  }

  @override
  String get billsSortAlphabetical => 'Alphabétique';

  @override
  String get billsSortByTimePeriod => 'Par période';

  @override
  String get billsSortFrequency => 'Fréquence';

  @override
  String get billsSortName => 'Nom';

  @override
  String get billsUngrouped => 'Sans groupe';

  @override
  String get billsSettingsShowOnlyActive => 'Afficher seulement les actifs';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'Affiche uniquement les abonnements actifs.';

  @override
  String get billsSettingsShowOnlyExpected => 'Afficher seulement les prévus';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'Affiche uniquement les abonnements prévus (ou payés) ce mois-ci.';

  @override
  String get categoryDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette catégorie ? Les transactions ne seront pas supprimées, mais n\'auront plus de catégorie.';

  @override
  String get categoryErrorLoading => 'Erreur de chargement des catégories.';

  @override
  String get categoryFormLabelIncludeInSum => 'Inclure dans le montant mensuel';

  @override
  String get categoryFormLabelName => 'Nom de catégorie';

  @override
  String get categoryMonthNext => 'Le mois prochain';

  @override
  String get categoryMonthPrev => 'Le mois précédent';

  @override
  String get categorySumExcluded => 'exclue';

  @override
  String get categoryTitleAdd => 'Ajouter une catégorie';

  @override
  String get categoryTitleDelete => 'Supprimer la catégorie';

  @override
  String get categoryTitleEdit => 'Modifier la catégorie';

  @override
  String get catNone => '<aucune catégorie>';

  @override
  String get catOther => 'Autre';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'Réponse invalide de l\'API : $message';
  }

  @override
  String get errorAPIUnavailable => 'API indisponible';

  @override
  String get errorFieldRequired => 'Ce champ est obligatoire.';

  @override
  String get errorInvalidURL => 'URL invalide';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'Version minimale de l\'API Firefly v$requiredVersion requise. Veuillez mettre à niveau.';
  }

  @override
  String errorStatusCode(int code) {
    return 'Code d\'état : $code';
  }

  @override
  String get errorUnknown => 'Erreur inconnue.';

  @override
  String get formButtonHelp => 'Aide';

  @override
  String get formButtonLogin => 'Se connecter';

  @override
  String get formButtonLogout => 'Se déconnecter';

  @override
  String get formButtonRemove => 'Retirer';

  @override
  String get formButtonResetLogin => 'Réinitialiser l\'authentification';

  @override
  String get formButtonTransactionAdd => 'Ajouter une opération';

  @override
  String get formButtonTryAgain => 'Réessayer';

  @override
  String get generalAccount => 'Compte';

  @override
  String get generalAssets => 'Actifs';

  @override
  String get generalBalance => 'Solde';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Solde au $dateString';
  }

  @override
  String get generalBill => 'Facture';

  @override
  String get generalBudget => 'Budget';

  @override
  String get generalCategory => 'Catégorie';

  @override
  String get generalCurrency => 'Devise';

  @override
  String get generalDateRangeCurrentMonth => 'Mois actuel';

  @override
  String get generalDateRangeLast30Days => '30 derniers jours';

  @override
  String get generalDateRangeCurrentYear => 'Année actuelle';

  @override
  String get generalDateRangeLastYear => 'Année dernière';

  @override
  String get generalDateRangeAll => 'Tout';

  @override
  String get generalDefault => 'par défaut';

  @override
  String get generalDestinationAccount => 'Compte de destination';

  @override
  String get generalDismiss => 'Annuler';

  @override
  String get generalEarned => 'Gagné';

  @override
  String get generalError => 'Erreur';

  @override
  String get generalExpenses => 'Dépenses';

  @override
  String get generalIncome => 'Revenus';

  @override
  String get generalLiabilities => 'Passifs';

  @override
  String get generalMultiple => 'plusieurs';

  @override
  String get generalNever => 'jamais';

  @override
  String get generalReconcile => 'Rapproché';

  @override
  String get generalReset => 'Réinitialiser';

  @override
  String get generalSourceAccount => 'Compte source';

  @override
  String get generalSpent => 'Dépensé';

  @override
  String get generalSum => 'Total';

  @override
  String get generalTarget => 'Objectif';

  @override
  String get generalUnknown => 'Inconnu';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'hebdomadaire',
      'monthly': 'mensuel',
      'quarterly': 'trimestriel',
      'halfyear': 'semestriel',
      'yearly': 'annuel',
      'other': 'inconnu',
    });
    return ' ($_temp0)';
  }

  @override
  String get homeMainBillsTitle => 'Factures pour la semaine prochaine';

  @override
  String homeMainBudgetInterval(DateTime from, DateTime to, String period) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString au $toString, $period)';
  }

  @override
  String homeMainBudgetIntervalSingle(DateTime from, DateTime to) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString au $toString)';
  }

  @override
  String homeMainBudgetSum(String current, String status, String available) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'over': 'au-dessus de',
      'other': 'restant sur',
    });
    return '$current $_temp0 $available';
  }

  @override
  String get homeMainBudgetTitle => 'Budgets du mois en cours';

  @override
  String get homeMainChartAccountsTitle => 'Résumé des comptes';

  @override
  String get homeMainChartCategoriesTitle =>
      'Résumé des catégories pour le mois en cours';

  @override
  String get homeMainChartDailyAvg => 'Moyenne sur 7 jours';

  @override
  String get homeMainChartDailyTitle => 'Résumé quotidien';

  @override
  String get homeMainChartNetEarningsTitle => 'Revenus nets';

  @override
  String get homeMainChartNetWorthTitle => 'Avoir net';

  @override
  String get homeMainChartTagsTitle =>
      'Résumé des étiquettes pour le mois actuel';

  @override
  String get homePiggyAdjustDialogTitle => 'Économiser/Dépenser de l\'argent';

  @override
  String homePiggyDateStart(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Date de début : $dateString';
  }

  @override
  String homePiggyDateTarget(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Date cible : $dateString';
  }

  @override
  String get homeMainDialogSettingsTitle => 'Personnaliser le tableau de bord';

  @override
  String homePiggyLinked(String account) {
    return 'Liée à $account';
  }

  @override
  String get homePiggyNoAccounts => 'Aucune tirelire n\'a été créée.';

  @override
  String get homePiggyNoAccountsSubtitle =>
      'Créez-en une depuis l\'interface Web !';

  @override
  String homePiggyRemaining(String amount) {
    return 'Reste à économiser : $amount';
  }

  @override
  String homePiggySaved(String amount) {
    return 'Économisé jusqu\'à présent : $amount';
  }

  @override
  String get homePiggySavedMultiple => 'Économisé jusqu\'à présent :';

  @override
  String homePiggyTarget(String amount) {
    return 'Montant cible : $amount';
  }

  @override
  String get homePiggyAccountStatus => 'Statut du compte';

  @override
  String get homePiggyAvailableAmounts => 'Montants disponibles';

  @override
  String homePiggyAvailable(String amount) {
    return 'Disponible : $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'Dans les tirelires : $amount';
  }

  @override
  String get homeTabLabelBalance => 'Bilan';

  @override
  String get homeTabLabelMain => 'Accueil';

  @override
  String get homeTabLabelPiggybanks => 'Tirelires';

  @override
  String get homeTabLabelTransactions => 'Opérations';

  @override
  String get homeTransactionsActionFilter => 'Liste de filtres';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<Tous les comptes>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<Toutes les factures>';

  @override
  String get homeTransactionsDialogFilterBillUnset =>
      '<Aucune facture établie>';

  @override
  String get homeTransactionsDialogFilterBudgetsAll => '<Tous les budgets>';

  @override
  String get homeTransactionsDialogFilterBudgetUnset => '<Aucun budget défini>';

  @override
  String get homeTransactionsDialogFilterCategoriesAll =>
      '<Toutes les catégories>';

  @override
  String get homeTransactionsDialogFilterCategoryUnset =>
      '<Aucune catégorie définie>';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<Toutes le devises>';

  @override
  String get homeTransactionsDialogFilterDateRange => 'Plage de dates';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'Afficher les futures transactions';

  @override
  String get homeTransactionsDialogFilterSearch => 'Terme de recherche';

  @override
  String get homeTransactionsDialogFilterTitle => 'Sélectionnez les filtres';

  @override
  String get homeTransactionsEmpty => 'Aucune transaction trouvée.';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num catégories';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'Afficher les étiquettes dans la liste des transactions';

  @override
  String get liabilityDirectionCredit => 'On me doit cette dette';

  @override
  String get liabilityDirectionDebit => 'Je dois cette dette';

  @override
  String get liabilityTypeDebt => 'Dette';

  @override
  String get liabilityTypeLoan => 'Prêt';

  @override
  String get liabilityTypeMortgage => 'Emprunts';

  @override
  String get loginAbout =>
      'Pour utiliser Waterfly III, vous avez besoin de votre propre serveur avec une instance Firefly III ou le module complémentaire Firefly III pour Home Assistant.\n\nVeuillez renseigner l\'URL complète ainsi qu\'un jeton d\'accès personnel (Options -> Profil -> OAuth -> Jetons d\'accès personnel) ci-dessous.';

  @override
  String get loginFormLabelAPIKey => 'Clé API valide';

  @override
  String get loginFormLabelHost => 'URL du serveur';

  @override
  String get loginWelcome => 'Bienvenue sur Waterfly III';

  @override
  String get logoutConfirmation =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get navigationAccounts => 'Comptes';

  @override
  String get navigationBills => 'Factures';

  @override
  String get navigationCategories => 'Catégories';

  @override
  String get navigationMain => 'Tableau de bord';

  @override
  String get generalSettings => 'Paramètres';

  @override
  String get no => 'Non';

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

    return '$percString sur $of';
  }

  @override
  String get settingsDialogDebugInfo =>
      'Vous pouvez activer et envoyer les journaux de débogage ici. Ces derniers ont un impact négatif sur les performances, veuillez ne pas les activer à moins que cela ne vous soit demandé. La désactivation de la journalisation supprimera le journal stocké.';

  @override
  String get settingsDialogDebugMailCreate => 'Créer un e-mail';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      'AVERTISSEMENT : Un brouillon d\'e-mail s\'ouvrira avec le fichier journal en pièce jointe (au format texte). Les journaux peuvent contenir des informations sensibles, telles que le nom d\'hôte de votre instance Firefly (bien que j\'essaie d\'éviter de consigner des éléments confidentiels, tels que la clé API). Veuillez lire attentivement le journal et censurer toute information que vous ne souhaitez pas partager et/ou qui n\'est pas pertinente par rapport au problème que vous souhaitez signaler.\n\nVeuillez ne pas envoyer de journaux sans accord préalable via e-mail/GitHub. Je supprimerai tous les journaux envoyés sans contexte pour des raisons de confidentialité. N\'envoyez jamais de journal non censuré sur GitHub ou ailleurs.';

  @override
  String get settingsDialogDebugSendButton => 'Envoyer les journaux par e-mail';

  @override
  String get settingsDialogDebugTitle => 'Journaux de débogage';

  @override
  String get settingsDialogLanguageTitle => 'Choisir la langue';

  @override
  String get settingsDialogThemeTitle => 'Choisir un thème';

  @override
  String get settingsFAQ => 'FAQ';

  @override
  String get settingsFAQHelp =>
      'S\'ouvre dans le navigateur. Disponible uniquement en anglais.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configure offline sync and mobile data usage';

  @override
  String get settingsLanguage => 'Langage';

  @override
  String get settingsLockscreen => 'Écran de verrouillage';

  @override
  String get settingsLockscreenHelp =>
      'Exiger une authentification au démarrage de l\'application';

  @override
  String get settingsLockscreenInitial =>
      'Veuillez vous authentifier pour activer l\'écran de verrouillage.';

  @override
  String get settingsNLAppAccount => 'Compte par défaut';

  @override
  String get settingsNLAppAccountDynamic => '<Dynamique>';

  @override
  String get settingsNLAppAdd => 'Ajouter appli';

  @override
  String get settingsNLAppAddHelp =>
      'Cliquez pour ajouter une application à écouter. Seules les applications éligibles apparaîtront dans la liste.';

  @override
  String get settingsNLAppAddInfo =>
      'Effectuez des opérations pour lesquelles vous recevez des notifications sur votre téléphone afin d\'ajouter des applications à cette liste. Si l\'application ne s\'affiche toujours pas, veuillez le signaler à app@vogt.pw.';

  @override
  String get settingsNLAutoAdd => 'Créer une transaction sans interaction';

  @override
  String get settingsNLDescription =>
      'Ce service vous permet de récupérer les détails des opérations à partir des notifications push entrantes. De plus, vous pouvez sélectionner un compte par défaut auquel l\'opération doit être affectée - si aucune valeur n\'est définie, il essaie d\'extraire un compte de la notification.';

  @override
  String get settingsNLEmptyNote => 'Conserver le champ de note vide';

  @override
  String get settingsNLPermissionGrant =>
      'Appuyez pour accorder la permission.';

  @override
  String get settingsNLPermissionNotGranted => 'Permission non accordée.';

  @override
  String get settingsNLPermissionRemove => 'Supprimer la permission ?';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'Pour désactiver ce service, cliquez sur l\'application et supprimez les autorisations dans l\'écran suivant.';

  @override
  String get settingsNLPrefillTXTitle =>
      'Pré-remplir le titre de la transaction avec le titre de la notification';

  @override
  String get settingsNLServiceChecking => 'Vérification de l\'état…';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'Erreur lors de la vérification de l\'état : $error';
  }

  @override
  String get settingsNLServiceRunning => 'Service en cours d\'exécution.';

  @override
  String get settingsNLServiceStatus => 'État du service';

  @override
  String get settingsNLServiceStopped => 'Le service est arrêté.';

  @override
  String get settingsNotificationListener =>
      'Service d\'écoute des notifications';

  @override
  String get settingsTheme => 'Thème de l\'appli';

  @override
  String get settingsThemeDynamicColors => 'Couleurs dyn.';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'Sombre',
      'light': 'Clair',
      'other': 'Système',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone =>
      'Utiliser le fuseau horaire du serveur';

  @override
  String get settingsUseServerTimezoneHelp =>
      'Afficher tous les horaires dans le fuseau horaire du serveur. Cela reproduit le comportement de l\'interface web.';

  @override
  String get settingsVersion => 'Version de l’appli';

  @override
  String get settingsVersionChecking => 'vérification…';

  @override
  String get transactionAttachments => 'Pièces jointes';

  @override
  String get transactionDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette opération ?';

  @override
  String get transactionDialogAttachmentsDelete => 'Supprimer la pièce jointe';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette pièce jointe ?';

  @override
  String get transactionDialogAttachmentsErrorDownload =>
      'Impossible de télécharger le fichier.';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'Impossible d\'ouvrir le fichier : $error';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'Impossible d\'envoyer le fichier : $error';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'Pièces jointes';

  @override
  String get transactionDialogBillNoBill => 'Aucune facture';

  @override
  String get transactionDialogBillTitle => 'Lien vers la facture';

  @override
  String get transactionDialogCurrencyTitle => 'Sélectionnez la devise';

  @override
  String get transactionDialogPiggyNoPiggy => 'Aucune tirelire';

  @override
  String get transactionDialogPiggyTitle => 'Lier à une tirelire';

  @override
  String get transactionDialogTagsAdd => 'Ajouter une étiquette';

  @override
  String get transactionDialogTagsHint => 'Rechercher/Ajouter une étiquette';

  @override
  String get transactionDialogTagsTitle => 'Sélectionnez des étiquettes';

  @override
  String get transactionDuplicate => 'Dupliquer';

  @override
  String get transactionErrorInvalidAccount => 'Compte non valide';

  @override
  String get transactionErrorInvalidBudget => 'Budget non valide';

  @override
  String get transactionErrorNoAccounts =>
      'Veuillez d\'abord renseigner les comptes.';

  @override
  String get transactionErrorNoAssetAccount =>
      'Veuillez sélectionner un compte d\'actif.';

  @override
  String get transactionErrorTitle => 'Veuillez indiquer un titre.';

  @override
  String get transactionFormLabelAccountDestination => 'Compte destinataire';

  @override
  String get transactionFormLabelAccountForeign => 'Compte externe';

  @override
  String get transactionFormLabelAccountOwn => 'Compte personnel';

  @override
  String get transactionFormLabelAccountSource => 'Compte source';

  @override
  String get transactionFormLabelNotes => 'Notes';

  @override
  String get transactionFormLabelTags => 'Étiquettes';

  @override
  String get transactionFormLabelTitle => 'Titre de l\'opération';

  @override
  String get transactionSplitAdd => 'Ajouter une opération fractionnée';

  @override
  String get transactionSplitChangeCurrency => 'Changer de devise';

  @override
  String get transactionSplitChangeDestinationAccount =>
      'Modifier le compte de destination du split';

  @override
  String get transactionSplitChangeSourceAccount =>
      'Modifier le compte source du split';

  @override
  String get transactionSplitChangeTarget => 'Changer de compte cible';

  @override
  String get transactionSplitDelete => 'Supprimer l\'opération fractionnée';

  @override
  String get transactionTitleAdd => 'Ajouter une opération';

  @override
  String get transactionTitleDelete => 'Supprimer l\'opération';

  @override
  String get transactionTitleEdit => 'Modifier l\'opération';

  @override
  String get transactionTypeDeposit => 'Dépôt';

  @override
  String get transactionTypeTransfer => 'Transfert';

  @override
  String get transactionTypeWithdrawal => 'Dépense';

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
