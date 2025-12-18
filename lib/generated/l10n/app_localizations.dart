import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sl.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ca'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('hu'),
    Locale('id'),
    Locale('it'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt', 'BR'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sl'),
    Locale('sv'),
    Locale('tr'),
    Locale('uk'),
    Locale('zh', 'TW'),
    Locale('zh'),
  ];

  /// Firefly Translation String: account_role_cashWalletAsset
  ///
  /// In en, this message translates to:
  /// **'Cash Wallet'**
  String get accountRoleAssetCashWallet;

  /// Firefly Translation String: account_role_ccAsset
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get accountRoleAssetCC;

  /// Firefly Translation String: account_role_defaultAsset
  ///
  /// In en, this message translates to:
  /// **'Default asset account'**
  String get accountRoleAssetDefault;

  /// Firefly Translation String: account_role_savingAsset
  ///
  /// In en, this message translates to:
  /// **'Savings account'**
  String get accountRoleAssetSavings;

  /// Firefly Translation String: account_role_sharedAsset
  ///
  /// In en, this message translates to:
  /// **'Shared asset account'**
  String get accountRoleAssetShared;

  /// Firefly Translation String: asset_accounts
  ///
  /// In en, this message translates to:
  /// **'Asset Accounts'**
  String get accountsLabelAsset;

  /// Firefly Translation String: expense_accounts
  ///
  /// In en, this message translates to:
  /// **'Expense Accounts'**
  String get accountsLabelExpense;

  /// Firefly Translation String: liabilities_accounts
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get accountsLabelLiabilities;

  /// Firefly Translation String: revenue_accounts
  ///
  /// In en, this message translates to:
  /// **'Revenue Accounts'**
  String get accountsLabelRevenue;

  /// Interest in a certain period
  ///
  /// In en, this message translates to:
  /// **'{interest}% interest per {period, select, weekly{week} monthly{month} quarterly{quarter} halfyear{half-year} yearly{year} other{unknown}}'**
  String accountsLiabilitiesInterest(double interest, String period);

  /// Subscription match for min and max amounts, and frequency
  ///
  /// In en, this message translates to:
  /// **'Subscription matches transactions between {minValue} and {maxvalue}. Repeats {frequency, select, weekly{weekly} monthly{monthly} quarterly{quarterly} halfyear{half-yearly} yearly{yearly} other{unknown}}{skip, plural, =0{} other{, skips over {skip}}}.'**
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  );

  /// Text for layout change button tooltip
  ///
  /// In en, this message translates to:
  /// **'Change layout'**
  String get billsChangeLayoutTooltip;

  /// Text for sort order change button tooltip
  ///
  /// In en, this message translates to:
  /// **'Change sort order'**
  String get billsChangeSortOrderTooltip;

  /// Generic error message when subscriptions can't be loaded (shouldn't occur)
  ///
  /// In en, this message translates to:
  /// **'Error loading subscriptions.'**
  String get billsErrorLoading;

  /// Subscription match for exact amount and frequency
  ///
  /// In en, this message translates to:
  /// **'Subscription matches transactions of {value}. Repeats {frequency, select, weekly{weekly} monthly{monthly} quarterly{quarterly} halfyear{half-yearly} yearly{yearly} other{unknown}}{skip, plural, =0{} other{, skips over {skip}}}.'**
  String billsExactAmountAndFrequency(String value, String frequency, num skip);

  /// Describes what date the subscription is expected
  ///
  /// In en, this message translates to:
  /// **'Expected {date}'**
  String billsExpectedOn(DateTime date);

  /// Subscription frequency
  ///
  /// In en, this message translates to:
  /// **'{frequency, select, weekly{Weekly} monthly{Monthly} quarterly{Quarterly} halfyear{Half-yearly} yearly{Yearly} other{Unknown}}'**
  String billsFrequency(String frequency);

  /// Subscription frequency
  ///
  /// In en, this message translates to:
  /// **'{frequency, select, weekly{Weekly} monthly{Monthly} quarterly{Quarterly} halfyear{Half-yearly} yearly{Yearly} other{Unknown}}{skip, plural, =0{} other{, skips over {skip}}}'**
  String billsFrequencySkip(String frequency, num skip);

  /// Text: when the subscription is inactive
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get billsInactive;

  /// Text: the subscription is active
  ///
  /// In en, this message translates to:
  /// **'Subscription is active'**
  String get billsIsActive;

  /// Subtitle text for group layout option
  ///
  /// In en, this message translates to:
  /// **'Subscriptions displayed in their assigned groups.'**
  String get billsLayoutGroupSubtitle;

  /// Title text for group layout option
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get billsLayoutGroupTitle;

  /// Subtitle text for list layout option
  ///
  /// In en, this message translates to:
  /// **'Subscriptions displayed in a list sorted by certain criteria.'**
  String get billsLayoutListSubtitle;

  /// Title text for list layout option
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get billsLayoutListTitle;

  /// Describes that the list is empty
  ///
  /// In en, this message translates to:
  /// **'The list is currently empty.'**
  String get billsListEmpty;

  /// Text: next expected match for subscription
  ///
  /// In en, this message translates to:
  /// **'Next expected match'**
  String get billsNextExpectedMatch;

  /// Text: the subscription is inactive
  ///
  /// In en, this message translates to:
  /// **'Subscription is inactive'**
  String get billsNotActive;

  /// Describes that the subscription is not expected this period
  ///
  /// In en, this message translates to:
  /// **'Not expected this period'**
  String get billsNotExpected;

  /// Describes that there are no transactions connected to the subscription
  ///
  /// In en, this message translates to:
  /// **'No transactions found.'**
  String get billsNoTransactions;

  /// Describes what date the subscription was paid
  ///
  /// In en, this message translates to:
  /// **'Paid {date}'**
  String billsPaidOn(DateTime date);

  /// Text for alphabetical sort types
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get billsSortAlphabetical;

  /// Text for frequency sort type
  ///
  /// In en, this message translates to:
  /// **'By time period'**
  String get billsSortByTimePeriod;

  /// Text for sort by frequency
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get billsSortFrequency;

  /// Text for sort by name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get billsSortName;

  /// Title for ungrouped subscriptions
  ///
  /// In en, this message translates to:
  /// **'Ungrouped'**
  String get billsUngrouped;

  /// Text for show only active subscriptions settings item
  ///
  /// In en, this message translates to:
  /// **'Show only active'**
  String get billsSettingsShowOnlyActive;

  /// Text for show only active subscriptions settings item description
  ///
  /// In en, this message translates to:
  /// **'Shows only active subscriptions.'**
  String get billsSettingsShowOnlyActiveDesc;

  /// Text for show only expected subscriptions settings item
  ///
  /// In en, this message translates to:
  /// **'Show only expected'**
  String get billsSettingsShowOnlyExpected;

  /// Text for show only expected subscriptions settings item description
  ///
  /// In en, this message translates to:
  /// **'Shows only those subscriptions that are expected (or paid) this month.'**
  String get billsSettingsShowOnlyExpectedDesc;

  /// Confirmation text to delete category
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category? The transactions will not be deleted, but will not have a category anymore.'**
  String get categoryDeleteConfirm;

  /// Generic error message when categories can't be loaded (shouldn't occur)
  ///
  /// In en, this message translates to:
  /// **'Error loading categories.'**
  String get categoryErrorLoading;

  /// Category Add/Edit Form: Label for toggle field to include value in monthly sum
  ///
  /// In en, this message translates to:
  /// **'Include in monthly sum'**
  String get categoryFormLabelIncludeInSum;

  /// Category Add/Edit Form: Label for name field
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryFormLabelName;

  /// Button title to view overview for next month
  ///
  /// In en, this message translates to:
  /// **'Next Month'**
  String get categoryMonthNext;

  /// Button title to view overview for previous month
  ///
  /// In en, this message translates to:
  /// **'Previous Month'**
  String get categoryMonthPrev;

  /// Label that the category is excluded from the monthly sum. The label will be shown in the place where usually the monthly percentage share is shown. Should be a single word if possible.
  ///
  /// In en, this message translates to:
  /// **'excluded'**
  String get categorySumExcluded;

  /// Title for Dialog: Add Category
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get categoryTitleAdd;

  /// Title for Dialog: Delete Category
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get categoryTitleDelete;

  /// Title for Dialog: Edit Category
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get categoryTitleEdit;

  /// Placeholder when no category has been set.
  ///
  /// In en, this message translates to:
  /// **'<no category>'**
  String get catNone;

  /// Category description for summary category 'Other'
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// Invalid API response error
  ///
  /// In en, this message translates to:
  /// **'Invalid Response from API: {message}'**
  String errorAPIInvalidResponse(String message);

  /// Error thrown when API is unavailable.
  ///
  /// In en, this message translates to:
  /// **'API unavailable'**
  String get errorAPIUnavailable;

  /// Error: Required field was left empty.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get errorFieldRequired;

  /// Error: URL is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get errorInvalidURL;

  /// Error: Required API version not met.
  ///
  /// In en, this message translates to:
  /// **'Minimum Firefly API Version v{requiredVersion} required. Please upgrade.'**
  String errorMinAPIVersion(String requiredVersion);

  /// HTTP status code information on error
  ///
  /// In en, this message translates to:
  /// **'Status Code: {code}'**
  String errorStatusCode(int code);

  /// Error without further information occurred.
  ///
  /// In en, this message translates to:
  /// **'Unknown error.'**
  String get errorUnknown;

  /// Button Label: Help
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get formButtonHelp;

  /// Button Label: Login
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get formButtonLogin;

  /// Button Label: Logout
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get formButtonLogout;

  /// Button Label: Remove
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get formButtonRemove;

  /// Button Label: Reset login form (when error is shown)
  ///
  /// In en, this message translates to:
  /// **'Reset login'**
  String get formButtonResetLogin;

  /// Button Label: Add Transaction
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get formButtonTransactionAdd;

  /// Button Label: Try that thing again (login etc)
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get formButtonTryAgain;

  /// Asset/Debt (Bank) Account
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get generalAccount;

  /// (Monetary) Assets
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get generalAssets;

  /// (Account) Balance
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get generalBalance;

  /// No description provided for @generalBalanceOn.
  ///
  /// In en, this message translates to:
  /// **'Balance on {date}'**
  String generalBalanceOn(DateTime date);

  /// Subscription (caution: was named Bill until Firefly version 6.2.0)
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get generalBill;

  /// (Monetary) Budget
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get generalBudget;

  /// Category (of transaction etc.).
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get generalCategory;

  /// (Money) Currency
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get generalCurrency;

  /// Date Range: Current Month
  ///
  /// In en, this message translates to:
  /// **'Current Month'**
  String get generalDateRangeCurrentMonth;

  /// Date Range: Last 30 days
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get generalDateRangeLast30Days;

  /// Date Range: Current Year
  ///
  /// In en, this message translates to:
  /// **'Current Year'**
  String get generalDateRangeCurrentYear;

  /// Date Range: Last year
  ///
  /// In en, this message translates to:
  /// **'Last year'**
  String get generalDateRangeLastYear;

  /// Date Range: All
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get generalDateRangeAll;

  /// Indicates that something is the default choice
  ///
  /// In en, this message translates to:
  /// **'default'**
  String get generalDefault;

  /// Destination Account (for transaction)
  ///
  /// In en, this message translates to:
  /// **'Destination Account'**
  String get generalDestinationAccount;

  /// Dismiss window/dialog without action
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get generalDismiss;

  /// (Amount) Earned
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get generalEarned;

  /// Error (title in dialogs etc.)
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get generalError;

  /// (Account) Expenses
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get generalExpenses;

  /// (Account) Info
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get generalIncome;

  /// Firefly Translation String: liabilities
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get generalLiabilities;

  /// Multiples of a single thing (e.g. source accounts) are existing
  ///
  /// In en, this message translates to:
  /// **'multiple'**
  String get generalMultiple;

  /// Has never happened, no update etc.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get generalNever;

  /// Booking has been confirmed/reconciled
  ///
  /// In en, this message translates to:
  /// **'Reconciled'**
  String get generalReconcile;

  /// Reset something (i.e. set filters)
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get generalReset;

  /// Source Account (of transaction)
  ///
  /// In en, this message translates to:
  /// **'Source Account'**
  String get generalSourceAccount;

  /// (Amount) Spent
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get generalSpent;

  /// (Mathematical) Sum
  ///
  /// In en, this message translates to:
  /// **'Sum'**
  String get generalSum;

  /// Target value (i.e. a sum to save)
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get generalTarget;

  /// Something is unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get generalUnknown;

  /// subscription interval type
  ///
  /// In en, this message translates to:
  /// **' ({period, select, weekly{weekly} monthly{monthly} quarterly{quarterly} halfyear{half-year} yearly{yearly} other{unknown}})'**
  String homeMainBillsInterval(String period);

  /// Title: Subscriptions for the next week
  ///
  /// In en, this message translates to:
  /// **'Subscriptions for the next week'**
  String get homeMainBillsTitle;

  /// Budget interval ranging from 'from' to 'to', over an interval of 'period'. 'period' is localized by Firefly.
  ///
  /// In en, this message translates to:
  /// **' ({from} to {to}, {period})'**
  String homeMainBudgetInterval(DateTime from, DateTime to, String period);

  /// Budget interval ranging from 'from' to 'to', without a specified period.
  ///
  /// In en, this message translates to:
  /// **' ({from} to {to})'**
  String homeMainBudgetIntervalSingle(DateTime from, DateTime to);

  /// Budget has 'current' money over/left from ('status') of total budget 'available' money.
  ///
  /// In en, this message translates to:
  /// **'{current} {status, select, over{over} other{left from}} {available}'**
  String homeMainBudgetSum(String current, String status, String available);

  /// Title: Budgets for current month
  ///
  /// In en, this message translates to:
  /// **'Budgets for current month'**
  String get homeMainBudgetTitle;

  /// Chart Label: Account Summary
  ///
  /// In en, this message translates to:
  /// **'Account Summary'**
  String get homeMainChartAccountsTitle;

  /// Chart Label: Category Summary
  ///
  /// In en, this message translates to:
  /// **'Category Summary for current month'**
  String get homeMainChartCategoriesTitle;

  /// Text for last week average spent
  ///
  /// In en, this message translates to:
  /// **'7 days average'**
  String get homeMainChartDailyAvg;

  /// Chart Label: Daily Summary
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get homeMainChartDailyTitle;

  /// Chart Label: Net Earnings
  ///
  /// In en, this message translates to:
  /// **'Net Earnings'**
  String get homeMainChartNetEarningsTitle;

  /// Chart Label: Net Worth
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get homeMainChartNetWorthTitle;

  /// Chart Label: Tags Summary
  ///
  /// In en, this message translates to:
  /// **'Tag Summary for current month'**
  String get homeMainChartTagsTitle;

  /// Title of the dialog where money can be added/removed to a piggy bank.
  ///
  /// In en, this message translates to:
  /// **'Save/Spend Money'**
  String get homePiggyAdjustDialogTitle;

  /// Start of the piggy bank
  ///
  /// In en, this message translates to:
  /// **'Start date: {date}'**
  String homePiggyDateStart(DateTime date);

  /// Set target date of the piggy bank (when saving should be finished)
  ///
  /// In en, this message translates to:
  /// **'Target date: {date}'**
  String homePiggyDateTarget(DateTime date);

  /// Dialog title for dashboard settings (card order & visibility)
  ///
  /// In en, this message translates to:
  /// **'Customize Dashboard'**
  String get homeMainDialogSettingsTitle;

  /// Piggy bank is linked to asset account {account}.
  ///
  /// In en, this message translates to:
  /// **'Linked to {account}'**
  String homePiggyLinked(String account);

  /// Information that no piggy banks are existing
  ///
  /// In en, this message translates to:
  /// **'No piggy banks set up.'**
  String get homePiggyNoAccounts;

  /// Subtitle if no piggy banks are existing, hinting to use the webinterface to create some.
  ///
  /// In en, this message translates to:
  /// **'Create some in the webinterface!'**
  String get homePiggyNoAccountsSubtitle;

  /// How much money is left to save
  ///
  /// In en, this message translates to:
  /// **'Left to save: {amount}'**
  String homePiggyRemaining(String amount);

  /// How much money already was saved
  ///
  /// In en, this message translates to:
  /// **'Saved so far: {amount}'**
  String homePiggySaved(String amount);

  /// Title for a list of multiple accounts with the amount of money saved so far
  ///
  /// In en, this message translates to:
  /// **'Saved so far:'**
  String get homePiggySavedMultiple;

  /// How much money should be saved
  ///
  /// In en, this message translates to:
  /// **'Target amount: {amount}'**
  String homePiggyTarget(String amount);

  /// Title for the account status section showing balances and piggy bank totals
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get homePiggyAccountStatus;

  /// Title for the available amounts section showing money not in piggy banks
  ///
  /// In en, this message translates to:
  /// **'Available Amounts'**
  String get homePiggyAvailableAmounts;

  /// Available balance after subtracting piggy bank amounts
  ///
  /// In en, this message translates to:
  /// **'Available: {amount}'**
  String homePiggyAvailable(String amount);

  /// Amount currently in piggy banks for this account
  ///
  /// In en, this message translates to:
  /// **'In piggy banks: {amount}'**
  String homePiggyInPiggyBanks(String amount);

  /// Tab Label: Balance Sheet page
  ///
  /// In en, this message translates to:
  /// **'Balance Sheet'**
  String get homeTabLabelBalance;

  /// Tab Label: Start page ("main")
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get homeTabLabelMain;

  /// Tab Label: Piggy Banks page
  ///
  /// In en, this message translates to:
  /// **'Piggy Banks'**
  String get homeTabLabelPiggybanks;

  /// Tab Label: Transactions page
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get homeTabLabelTransactions;

  /// Action Button Label: Filter list.
  ///
  /// In en, this message translates to:
  /// **'Filter List'**
  String get homeTransactionsActionFilter;

  /// Don't filter for a specific account (default entry)
  ///
  /// In en, this message translates to:
  /// **'<All Accounts>'**
  String get homeTransactionsDialogFilterAccountsAll;

  /// Don't filter for a specific subscription (default entry)
  ///
  /// In en, this message translates to:
  /// **'<All Subscriptions>'**
  String get homeTransactionsDialogFilterBillsAll;

  /// Filter for unset subscription
  ///
  /// In en, this message translates to:
  /// **'<No Subscription set>'**
  String get homeTransactionsDialogFilterBillUnset;

  /// Don't filter for a specific budget (default entry)
  ///
  /// In en, this message translates to:
  /// **'<All Budgets>'**
  String get homeTransactionsDialogFilterBudgetsAll;

  /// Filter for unset budgets
  ///
  /// In en, this message translates to:
  /// **'<No Budget set>'**
  String get homeTransactionsDialogFilterBudgetUnset;

  /// Don't filter for a specific category (default entry)
  ///
  /// In en, this message translates to:
  /// **'<All Categories>'**
  String get homeTransactionsDialogFilterCategoriesAll;

  /// Filter for unset categories
  ///
  /// In en, this message translates to:
  /// **'<No Category set>'**
  String get homeTransactionsDialogFilterCategoryUnset;

  /// Don't filter for a specific currency (default entry)
  ///
  /// In en, this message translates to:
  /// **'<All Currencies>'**
  String get homeTransactionsDialogFilterCurrenciesAll;

  /// Label for the date range dropdown (all, last year, last month, last 30 days etc)
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get homeTransactionsDialogFilterDateRange;

  /// Setting to show future transactions
  ///
  /// In en, this message translates to:
  /// **'Show future transactions'**
  String get homeTransactionsDialogFilterFutureTransactions;

  /// Search term for filter
  ///
  /// In en, this message translates to:
  /// **'Search Term'**
  String get homeTransactionsDialogFilterSearch;

  /// Title of Filter Dialog
  ///
  /// In en, this message translates to:
  /// **'Select filters'**
  String get homeTransactionsDialogFilterTitle;

  /// Message when no transactions are found.
  ///
  /// In en, this message translates to:
  /// **'No transactions found.'**
  String get homeTransactionsEmpty;

  /// $num categories for the transaction.
  ///
  /// In en, this message translates to:
  /// **'{num} categories'**
  String homeTransactionsMultipleCategories(int num);

  /// Setting label to show tags in transactioon list.
  ///
  /// In en, this message translates to:
  /// **'Show tags in transaction list'**
  String get homeTransactionsSettingsShowTags;

  /// Firefly Translation String: liability_direction_credit
  ///
  /// In en, this message translates to:
  /// **'I am owed this debt'**
  String get liabilityDirectionCredit;

  /// Firefly Translation String: liability_direction_debit
  ///
  /// In en, this message translates to:
  /// **'I owe this debt'**
  String get liabilityDirectionDebit;

  /// Firefly Translation String: account_type_debt
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get liabilityTypeDebt;

  /// Firefly Translation String: account_type_loan
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get liabilityTypeLoan;

  /// Firefly Translation String: account_type_mortgage
  ///
  /// In en, this message translates to:
  /// **'Mortgage'**
  String get liabilityTypeMortgage;

  /// Login screen welcome description
  ///
  /// In en, this message translates to:
  /// **'To use Waterfly III productively you need your own server with a Firefly III instance or the Firefly III add-on for Home Assistant.\n\nPlease enter the full URL as well as a personal access token (Settings -> Profile -> OAuth -> Personal Access Token) below.'**
  String get loginAbout;

  /// Login Form: Label for API Key field
  ///
  /// In en, this message translates to:
  /// **'Valid API Key'**
  String get loginFormLabelAPIKey;

  /// Login Form: Label for Host field
  ///
  /// In en, this message translates to:
  /// **'Host URL'**
  String get loginFormLabelHost;

  /// Login screen welcome banner
  ///
  /// In en, this message translates to:
  /// **'Welcome to Waterfly III'**
  String get loginWelcome;

  /// Get user confirmation if he really wants to log out
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmation;

  /// Navigation Label: Accounts Page
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navigationAccounts;

  /// Navigation Label: Subscriptions
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get navigationBills;

  /// Navigation Label: Categories
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navigationCategories;

  /// Navigation Label: Main Dashboard
  ///
  /// In en, this message translates to:
  /// **'Main Dashboard'**
  String get navigationMain;

  /// Label: Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get generalSettings;

  /// The word no
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Number formatted as percentage
  ///
  /// In en, this message translates to:
  /// **'{num}'**
  String numPercent(double num);

  /// Number formatted as percentage, with total amount provided
  ///
  /// In en, this message translates to:
  /// **'{perc} of {of}'**
  String numPercentOf(double perc, String of);

  /// Information about debug logs and their impact.
  ///
  /// In en, this message translates to:
  /// **'You can enable & send debug logs here. These have a bad impact on performance, so please don\'t enable them unless you\'re advised to do so. Disabling logging will delete the stored log.'**
  String get settingsDialogDebugInfo;

  /// Button to confirm mail creation after privacy disclaimer is shown.
  ///
  /// In en, this message translates to:
  /// **'Create Mail'**
  String get settingsDialogDebugMailCreate;

  /// Privacy disclaimer shown before sending logs
  ///
  /// In en, this message translates to:
  /// **'WARNING: A mail draft will open with the log file attached (in text format). The logs might contain sensitive information, such as the host name of your Firefly instance (though I try to avoid logging of any secrets, such as the api key). Please read through the log carefully and censor out any information you don\'t want to share and/or is not relevant to the problem you want to report.\n\nPlease do not send in logs without prior agreement via mail/GitHub to do so. I will delete any logs sent without context for privacy reasons. Never upload the log uncensored to GitHub or elsewhere.'**
  String get settingsDialogDebugMailDisclaimer;

  /// Button to send logs via E-Mail
  ///
  /// In en, this message translates to:
  /// **'Send Logs via Mail'**
  String get settingsDialogDebugSendButton;

  /// Dialog title: Debug Logs
  ///
  /// In en, this message translates to:
  /// **'Debug Logs'**
  String get settingsDialogDebugTitle;

  /// Dialog title: Select Language
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsDialogLanguageTitle;

  /// Dialog title: Select theme
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get settingsDialogThemeTitle;

  /// FAQ title
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get settingsFAQ;

  /// FAQ help text that explains that it opens up in a browser and is only available in English
  ///
  /// In en, this message translates to:
  /// **'Opens in Browser. Only available in English.'**
  String get settingsFAQHelp;

  /// Subtitle for offline mode settings in main settings page
  ///
  /// In en, this message translates to:
  /// **'Configure offline sync and mobile data usage'**
  String get settingsOfflineModeSubtitle;

  /// Currently selected language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Setting if a lockscreen is shown (authentication is required on startup)
  ///
  /// In en, this message translates to:
  /// **'Lockscreen'**
  String get settingsLockscreen;

  /// Description for lockscreen setting
  ///
  /// In en, this message translates to:
  /// **'Require authenticiation on app startup'**
  String get settingsLockscreenHelp;

  /// Prompt to authenticate once to set up the lockscreen
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to enable the lock screen.'**
  String get settingsLockscreenInitial;

  /// Default account which will be used for the transaction.
  ///
  /// In en, this message translates to:
  /// **'Default Account'**
  String get settingsNLAppAccount;

  /// Account will be selected dynamically by the content of the notification.
  ///
  /// In en, this message translates to:
  /// **'<Dynamic>'**
  String get settingsNLAppAccountDynamic;

  /// Button title to add a new app.
  ///
  /// In en, this message translates to:
  /// **'Add App'**
  String get settingsNLAppAdd;

  /// Help text below adding the new app button.
  ///
  /// In en, this message translates to:
  /// **'Click to add an app to listen to. Only eligible apps will show up in the list.'**
  String get settingsNLAppAddHelp;

  /// Help text when no more app is available to add.
  ///
  /// In en, this message translates to:
  /// **'Make some transactions where you receive phone notifications to add apps to this list. If the app still doesn\'t show up, please report it to app@vogt.pw.'**
  String get settingsNLAppAddInfo;

  /// With this setting enabled, the transaction will be added automatically without further user interaction.
  ///
  /// In en, this message translates to:
  /// **'Create transaction without interaction'**
  String get settingsNLAutoAdd;

  /// Description text for the notification listener service.
  ///
  /// In en, this message translates to:
  /// **'This service allows you to fetch transaction details from incoming push notifications. Additionally, you can select a default account which the transaction should be assigned to - if no value is set, it tries to extract an account from the notification.'**
  String get settingsNLDescription;

  /// Usually the note field will be pre-filled with the notification details. With this setting enabled, it will be empty instead.
  ///
  /// In en, this message translates to:
  /// **'Keep note field empty'**
  String get settingsNLEmptyNote;

  /// Indicates user should tap the text to grant certain permissions (notification access).
  ///
  /// In en, this message translates to:
  /// **'Tap to grant permission.'**
  String get settingsNLPermissionGrant;

  /// A requested permission was not granted.
  ///
  /// In en, this message translates to:
  /// **'Permission not granted.'**
  String get settingsNLPermissionNotGranted;

  /// Dialog title asking if permission should be removed.
  ///
  /// In en, this message translates to:
  /// **'Remove permission?'**
  String get settingsNLPermissionRemove;

  /// Dialog text giving hint how to remove the permission.
  ///
  /// In en, this message translates to:
  /// **'To disable this service, click on the app and remove the permissions in the next screen.'**
  String get settingsNLPermissionRemoveHelp;

  /// Setting pre-fill transaction title with notification title.
  ///
  /// In en, this message translates to:
  /// **'Prefill transaction title with notification title'**
  String get settingsNLPrefillTXTitle;

  /// Checking the status of the background service
  ///
  /// In en, this message translates to:
  /// **'Checking status…'**
  String get settingsNLServiceChecking;

  /// An error occurred while checking the service status
  ///
  /// In en, this message translates to:
  /// **'Error checking status: {error}'**
  String settingsNLServiceCheckingError(String error);

  /// A background service is running normally.
  ///
  /// In en, this message translates to:
  /// **'Service is running.'**
  String get settingsNLServiceRunning;

  /// Status of a background service.
  ///
  /// In en, this message translates to:
  /// **'Service Status'**
  String get settingsNLServiceStatus;

  /// A background service is stopped.
  ///
  /// In en, this message translates to:
  /// **'Service is stopped.'**
  String get settingsNLServiceStopped;

  /// Setting for the notification listener service.
  ///
  /// In en, this message translates to:
  /// **'Notification Listener Service'**
  String get settingsNotificationListener;

  /// App theme (dark or light)
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get settingsTheme;

  /// Material You Dynamic Colors feature
  ///
  /// In en, this message translates to:
  /// **'Dynamic Colors'**
  String get settingsThemeDynamicColors;

  /// Currently selected theme (either dark, light or system)
  ///
  /// In en, this message translates to:
  /// **'{theme, select, dark{Dark Mode} light{Light Mode} other{System Default}}'**
  String settingsThemeValue(String theme);

  /// Setting label to use server timezone.
  ///
  /// In en, this message translates to:
  /// **'Use server timezone'**
  String get settingsUseServerTimezone;

  /// Help text for the server timezone setting. Basically, if enabled, all times shown in the app match the time shown in the webinterface (which is always in the 'home' timezone). Please try to keep the translation short (max 3 lines).
  ///
  /// In en, this message translates to:
  /// **'Show all times in the server timezone. This mimics the behavior of the webinterface.'**
  String get settingsUseServerTimezoneHelp;

  /// Current App Version
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get settingsVersion;

  /// Shown while checking for app version
  ///
  /// In en, this message translates to:
  /// **'checking…'**
  String get settingsVersionChecking;

  /// Button Label: Attachments
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get transactionAttachments;

  /// Confirmation text to delete transaction
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get transactionDeleteConfirm;

  /// Button Label: Delete Attachment
  ///
  /// In en, this message translates to:
  /// **'Delete Attachment'**
  String get transactionDialogAttachmentsDelete;

  /// Confirmation text to delete attachment
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this attachment?'**
  String get transactionDialogAttachmentsDeleteConfirm;

  /// Snackbar Text: File download failed.
  ///
  /// In en, this message translates to:
  /// **'Could not download file.'**
  String get transactionDialogAttachmentsErrorDownload;

  /// Snackbar Text: File could not be opened, with reason.
  ///
  /// In en, this message translates to:
  /// **'Could not open file: {error}'**
  String transactionDialogAttachmentsErrorOpen(String error);

  /// Snackbar Text: File could not be uploaded, with reason.
  ///
  /// In en, this message translates to:
  /// **'Could not upload file: {error}'**
  String transactionDialogAttachmentsErrorUpload(String error);

  /// Dialog Title: Attachments Dialog
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get transactionDialogAttachmentsTitle;

  /// Button Label: no subscription to be used
  ///
  /// In en, this message translates to:
  /// **'No subscription'**
  String get transactionDialogBillNoBill;

  /// Dialog Title: Link Subscription to transaction
  ///
  /// In en, this message translates to:
  /// **'Link to Subscription'**
  String get transactionDialogBillTitle;

  /// Dialog Title: Currency Selection
  ///
  /// In en, this message translates to:
  /// **'Select currency'**
  String get transactionDialogCurrencyTitle;

  /// Button Label: no piggy bank to be used
  ///
  /// In en, this message translates to:
  /// **'No Piggy Bank'**
  String get transactionDialogPiggyNoPiggy;

  /// Dialog Title: Link transaction to piggy bank
  ///
  /// In en, this message translates to:
  /// **'Link to Piggy Bank'**
  String get transactionDialogPiggyTitle;

  /// Button Label: Add Tag
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get transactionDialogTagsAdd;

  /// Hint Text for search tag field
  ///
  /// In en, this message translates to:
  /// **'Search/Add Tag'**
  String get transactionDialogTagsHint;

  /// Dialog Title: Select Tags
  ///
  /// In en, this message translates to:
  /// **'Select tags'**
  String get transactionDialogTagsTitle;

  /// Menu Label: Duplicate item
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get transactionDuplicate;

  /// Transaction Save Error: Invalid account
  ///
  /// In en, this message translates to:
  /// **'Invalid Account'**
  String get transactionErrorInvalidAccount;

  /// Transaction Save Error: Invalid budget
  ///
  /// In en, this message translates to:
  /// **'Invalid Budget'**
  String get transactionErrorInvalidBudget;

  /// Transaction Save Error: No accounts have been entered
  ///
  /// In en, this message translates to:
  /// **'Please fill in the accounts first.'**
  String get transactionErrorNoAccounts;

  /// Transaction Save Error: No account is an asset (own) account
  ///
  /// In en, this message translates to:
  /// **'Please select an asset account.'**
  String get transactionErrorNoAssetAccount;

  /// Transaction Save Error: No title provided
  ///
  /// In en, this message translates to:
  /// **'Please provide a title.'**
  String get transactionErrorTitle;

  /// Transaction Form: Label for destination account for transfer transaction
  ///
  /// In en, this message translates to:
  /// **'Destination account'**
  String get transactionFormLabelAccountDestination;

  /// Transaction Form: Label for foreign (other) account
  ///
  /// In en, this message translates to:
  /// **'Foreign account'**
  String get transactionFormLabelAccountForeign;

  /// Transaction Form: Label for own account
  ///
  /// In en, this message translates to:
  /// **'Own account'**
  String get transactionFormLabelAccountOwn;

  /// Transaction Form: Label for source account for transfer transaction
  ///
  /// In en, this message translates to:
  /// **'Source account'**
  String get transactionFormLabelAccountSource;

  /// Transaction Form: Label for notes field
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get transactionFormLabelNotes;

  /// Transaction Form: Label for tags field
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get transactionFormLabelTags;

  /// Transaction Form: Label for title field
  ///
  /// In en, this message translates to:
  /// **'Transaction Title'**
  String get transactionFormLabelTitle;

  /// Button Label: Add a split
  ///
  /// In en, this message translates to:
  /// **'Add split transaction'**
  String get transactionSplitAdd;

  /// Hint Text: Change currency for a single split
  ///
  /// In en, this message translates to:
  /// **'Change Split Currency'**
  String get transactionSplitChangeCurrency;

  /// Hint Text: Change destination account for a single split
  ///
  /// In en, this message translates to:
  /// **'Change Split Destination Account'**
  String get transactionSplitChangeDestinationAccount;

  /// Hint Text: Change source account for a single split
  ///
  /// In en, this message translates to:
  /// **'Change Split Source Account'**
  String get transactionSplitChangeSourceAccount;

  /// Hint Text: Change target account for single split
  ///
  /// In en, this message translates to:
  /// **'Change Split Target Account'**
  String get transactionSplitChangeTarget;

  /// Hint Text: Delete single split
  ///
  /// In en, this message translates to:
  /// **'Delete split'**
  String get transactionSplitDelete;

  /// Title: Add a new transaction
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get transactionTitleAdd;

  /// Title: Delete existing transaction
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get transactionTitleDelete;

  /// Title: Edit existing transaction
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get transactionTitleEdit;

  /// Deposit transaction type
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get transactionTypeDeposit;

  /// Transfer transaction type
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactionTypeTransfer;

  /// Withdrawal transaction type
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get transactionTypeWithdrawal;

  /// Notification title prompting user to create transaction from detected notification
  ///
  /// In en, this message translates to:
  /// **'Create Transaction?'**
  String get notificationCreateTransactionTitle;

  /// Notification body with source app name
  ///
  /// In en, this message translates to:
  /// **'Click to create a transaction based on the notification from {source}'**
  String notificationCreateTransactionBody(String source);

  /// Android notification channel name for transaction extraction
  ///
  /// In en, this message translates to:
  /// **'Create Transaction from Notification'**
  String get notificationExtractTransactionChannelName;

  /// Android notification channel description for transaction extraction
  ///
  /// In en, this message translates to:
  /// **'Notification asking to create a transaction from another notification.'**
  String get notificationExtractTransactionChannelDescription;

  /// Button tooltip to sync a specific entity type from the server
  ///
  /// In en, this message translates to:
  /// **'Sync {entity}'**
  String generalSyncEntity(String entity);

  /// Message shown after successful sync of an entity type
  ///
  /// In en, this message translates to:
  /// **'Synced {count} {entity}'**
  String generalSyncComplete(String entity, int count);

  /// Error message when sync fails
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String generalSyncFailed(String error);

  /// Label indicating the device is offline
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get generalOffline;

  /// Message shown when trying to sync while offline
  ///
  /// In en, this message translates to:
  /// **'You are offline. Connect to sync.'**
  String get generalOfflineMessage;

  /// Message shown when sync service is not initialized
  ///
  /// In en, this message translates to:
  /// **'Sync service not available'**
  String get generalSyncNotAvailable;

  /// Message shown when connection is restored
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get generalBackOnline;

  /// Message shown when offline mode is enabled with WiFi-only restriction
  ///
  /// In en, this message translates to:
  /// **'Offline mode (WiFi only)'**
  String get generalOfflineModeWifiOnly;

  /// Message shown when checking network connection
  ///
  /// In en, this message translates to:
  /// **'Checking connection...'**
  String get generalCheckingConnection;

  /// Network status dialog title
  ///
  /// In en, this message translates to:
  /// **'Network Status'**
  String get generalNetworkStatus;

  /// App status label in network dialog
  ///
  /// In en, this message translates to:
  /// **'App Status'**
  String get generalAppStatus;

  /// Online status label
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get generalOnline;

  /// Network label in network dialog
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get generalNetwork;

  /// Message shown when there is no network connection
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get generalNoConnection;

  /// Message explaining WiFi-only mode restriction
  ///
  /// In en, this message translates to:
  /// **'WiFi-only mode is enabled. Mobile data is disabled. Connect to WiFi to use online features.'**
  String get generalWifiOnlyModeEnabled;

  /// Message explaining offline mode limitations
  ///
  /// In en, this message translates to:
  /// **'Some features may be limited while offline. Data will sync automatically when connection is restored.'**
  String get generalOfflineFeaturesLimited;

  /// Message shown when all features are available
  ///
  /// In en, this message translates to:
  /// **'All features are available.'**
  String get generalAllFeaturesAvailable;

  /// Message shown when connection is successfully restored
  ///
  /// In en, this message translates to:
  /// **'Connection restored!'**
  String get generalConnectionRestored;

  /// Message shown when still offline after connectivity check
  ///
  /// In en, this message translates to:
  /// **'Still offline. Please check your network settings.'**
  String get generalStillOffline;

  /// Error message when connectivity check fails
  ///
  /// In en, this message translates to:
  /// **'Failed to check connectivity'**
  String get generalFailedToCheckConnectivity;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get generalRetry;

  /// Sync statistics section title
  ///
  /// In en, this message translates to:
  /// **'Sync Statistics'**
  String get incrementalSyncStatsTitle;

  /// Sync statistics description with count
  ///
  /// In en, this message translates to:
  /// **'{count} incremental syncs performed'**
  String incrementalSyncStatsDescription(int count);

  /// Sync statistics description when no syncs performed
  ///
  /// In en, this message translates to:
  /// **'Track sync efficiency and bandwidth savings'**
  String get incrementalSyncStatsDescriptionEmpty;

  /// Refresh statistics button tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh statistics'**
  String get incrementalSyncStatsRefresh;

  /// Title when no sync statistics are available
  ///
  /// In en, this message translates to:
  /// **'No Sync Statistics Yet'**
  String get incrementalSyncStatsNoData;

  /// Description when no sync statistics are available
  ///
  /// In en, this message translates to:
  /// **'Statistics will appear here after your first incremental sync.'**
  String get incrementalSyncStatsNoDataDesc;

  /// Message when no incremental sync data is available (compact mode)
  ///
  /// In en, this message translates to:
  /// **'No incremental sync data yet'**
  String get incrementalSyncStatsNoDataYet;

  /// Message when no sync data is available (summary mode)
  ///
  /// In en, this message translates to:
  /// **'No sync data available'**
  String get incrementalSyncStatsNoDataAvailable;

  /// Efficiency label for excellent (>=80%)
  ///
  /// In en, this message translates to:
  /// **'Excellent Efficiency'**
  String get incrementalSyncStatsEfficiencyExcellent;

  /// Efficiency label for good (>=60%)
  ///
  /// In en, this message translates to:
  /// **'Good Efficiency'**
  String get incrementalSyncStatsEfficiencyGood;

  /// Efficiency label for moderate (>=40%)
  ///
  /// In en, this message translates to:
  /// **'Moderate Efficiency'**
  String get incrementalSyncStatsEfficiencyModerate;

  /// Efficiency label for low (>=20%)
  ///
  /// In en, this message translates to:
  /// **'Low Efficiency'**
  String get incrementalSyncStatsEfficiencyLow;

  /// Efficiency label for very low (<20%)
  ///
  /// In en, this message translates to:
  /// **'Very Low Efficiency'**
  String get incrementalSyncStatsEfficiencyVeryLow;

  /// Efficiency description for excellent
  ///
  /// In en, this message translates to:
  /// **'Most data unchanged - incremental sync is very effective!'**
  String get incrementalSyncStatsEfficiencyDescExcellent;

  /// Efficiency description for good
  ///
  /// In en, this message translates to:
  /// **'Good savings - incremental sync is working well.'**
  String get incrementalSyncStatsEfficiencyDescGood;

  /// Efficiency description for moderate
  ///
  /// In en, this message translates to:
  /// **'Moderate changes detected - some bandwidth saved.'**
  String get incrementalSyncStatsEfficiencyDescModerate;

  /// Efficiency description for low
  ///
  /// In en, this message translates to:
  /// **'Many changes - consider adjusting sync window.'**
  String get incrementalSyncStatsEfficiencyDescLow;

  /// Efficiency description for very low
  ///
  /// In en, this message translates to:
  /// **'Most data changed - incremental sync provides minimal benefit.'**
  String get incrementalSyncStatsEfficiencyDescVeryLow;

  /// Label for fetched items count
  ///
  /// In en, this message translates to:
  /// **'Fetched'**
  String get incrementalSyncStatsLabelFetched;

  /// Label for updated items count
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get incrementalSyncStatsLabelUpdated;

  /// Label for skipped items count
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get incrementalSyncStatsLabelSkipped;

  /// Label for saved bandwidth
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get incrementalSyncStatsLabelSaved;

  /// Label for sync count
  ///
  /// In en, this message translates to:
  /// **'Syncs'**
  String get incrementalSyncStatsLabelSyncs;

  /// Label for bandwidth saved
  ///
  /// In en, this message translates to:
  /// **'Bandwidth Saved'**
  String get incrementalSyncStatsLabelBandwidthSaved;

  /// Label for API calls saved
  ///
  /// In en, this message translates to:
  /// **'API Calls Saved'**
  String get incrementalSyncStatsLabelApiCallsSaved;

  /// Label for update rate
  ///
  /// In en, this message translates to:
  /// **'Update Rate'**
  String get incrementalSyncStatsLabelUpdateRate;

  /// Current sync section title
  ///
  /// In en, this message translates to:
  /// **'Current Sync'**
  String get incrementalSyncStatsCurrentSync;

  /// Sync duration label
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String incrementalSyncStatsDuration(String duration);

  /// Status label for successful sync
  ///
  /// In en, this message translates to:
  /// **'Status: Success'**
  String get incrementalSyncStatsStatusSuccess;

  /// Status label for failed sync
  ///
  /// In en, this message translates to:
  /// **'Status: Failed'**
  String get incrementalSyncStatsStatusFailed;

  /// Error label in sync details
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String incrementalSyncStatsError(String error);

  /// Label for entity type breakdown section
  ///
  /// In en, this message translates to:
  /// **'By Entity Type:'**
  String get incrementalSyncStatsByEntityType;

  /// Efficiency summary text
  ///
  /// In en, this message translates to:
  /// **'{rate}% efficient'**
  String incrementalSyncStatsEfficient(String rate);

  /// Offline banner title
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineBannerTitle;

  /// Offline banner message
  ///
  /// In en, this message translates to:
  /// **'Changes will sync when online.'**
  String get offlineBannerMessage;

  /// Learn More button label
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get offlineBannerLearnMore;

  /// Dismiss button tooltip
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get offlineBannerDismiss;

  /// Accessibility label for offline banner
  ///
  /// In en, this message translates to:
  /// **'You are offline. Changes will sync when you are back online. Swipe to dismiss or tap Learn More for details.'**
  String get offlineBannerSemanticLabel;

  /// Offline mode indicator title
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get transactionOfflineMode;

  /// Message for new transaction saved offline
  ///
  /// In en, this message translates to:
  /// **'Transaction will be saved locally and synced when online'**
  String get transactionOfflineSaveNew;

  /// Message for edited transaction saved offline
  ///
  /// In en, this message translates to:
  /// **'Changes will be saved locally and synced when online'**
  String get transactionOfflineSaveEdit;

  /// Save button label when offline
  ///
  /// In en, this message translates to:
  /// **'Save Offline'**
  String get transactionSaveOffline;

  /// Save button label when online
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get transactionSave;

  /// Message when transaction is saved and synced
  ///
  /// In en, this message translates to:
  /// **'Transaction saved and synced'**
  String get transactionSavedSynced;

  /// Message when transaction is saved offline
  ///
  /// In en, this message translates to:
  /// **'Transaction saved offline. Will sync when online.'**
  String get transactionSavedOffline;

  /// Message when transaction is saved online
  ///
  /// In en, this message translates to:
  /// **'Transaction saved'**
  String get transactionSaved;

  /// Sync status: synced
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStatusSynced;

  /// Sync status: syncing
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncStatusSyncing;

  /// Sync status: pending items
  ///
  /// In en, this message translates to:
  /// **'{count} items pending'**
  String syncStatusPending(int count);

  /// Sync status: failed
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncStatusFailed;

  /// Sync status: offline
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncStatusOffline;

  /// Last sync time: just now
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get syncStatusJustNow;

  /// Last sync time: minutes ago
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String syncStatusMinutesAgo(int minutes);

  /// Last sync time: hours ago
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String syncStatusHoursAgo(int hours);

  /// Last sync time: days ago
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String syncStatusDaysAgo(int days);

  /// Last sync time: over a week ago
  ///
  /// In en, this message translates to:
  /// **'Over a week ago'**
  String get syncStatusOverWeekAgo;

  /// Sync now action label
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncActionSyncNow;

  /// Force full sync action label
  ///
  /// In en, this message translates to:
  /// **'Force full sync'**
  String get syncActionForceFullSync;

  /// View sync status action label
  ///
  /// In en, this message translates to:
  /// **'View sync status'**
  String get syncActionViewStatus;

  /// Sync settings action label
  ///
  /// In en, this message translates to:
  /// **'Sync settings'**
  String get syncActionSettings;

  /// Message when sync is started
  ///
  /// In en, this message translates to:
  /// **'Sync started'**
  String get syncStarted;

  /// Message when full sync is started
  ///
  /// In en, this message translates to:
  /// **'Full sync started'**
  String get syncFullStarted;

  /// Error message when sync fails to start
  ///
  /// In en, this message translates to:
  /// **'Failed to start sync: {error}'**
  String syncFailedToStart(String error);

  /// Error message when full sync fails to start
  ///
  /// In en, this message translates to:
  /// **'Failed to start full sync: {error}'**
  String syncFailedToStartFull(String error);

  /// Message when sync service is not available
  ///
  /// In en, this message translates to:
  /// **'Sync service not available. Please restart the app.'**
  String get syncServiceNotAvailable;

  /// Error title when sync status provider is not available
  ///
  /// In en, this message translates to:
  /// **'Sync Status Provider Not Available'**
  String get syncProgressProviderNotAvailable;

  /// Error description when sync status provider is not available
  ///
  /// In en, this message translates to:
  /// **'Please restart the app to enable sync progress tracking.'**
  String get syncProgressProviderNotAvailableDesc;

  /// Dialog title when sync service is unavailable
  ///
  /// In en, this message translates to:
  /// **'Sync Service Unavailable'**
  String get syncProgressServiceUnavailable;

  /// Dialog message when sync service is unavailable
  ///
  /// In en, this message translates to:
  /// **'Sync Status Provider is not available. Please restart the app.'**
  String get syncProgressServiceUnavailableDesc;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get syncProgressCancel;

  /// Sync failed title
  ///
  /// In en, this message translates to:
  /// **'Sync Failed'**
  String get syncProgressFailed;

  /// Sync complete title
  ///
  /// In en, this message translates to:
  /// **'Sync Complete'**
  String get syncProgressComplete;

  /// Syncing title
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncProgressSyncing;

  /// Current cache TTL label
  ///
  /// In en, this message translates to:
  /// **'Current: {ttl}'**
  String incrementalSyncCacheCurrent(String ttl);

  /// Sync progress percentage complete
  ///
  /// In en, this message translates to:
  /// **'{percentage}% complete'**
  String syncStatusProgressComplete(String percentage);

  /// Message when sync completes successfully
  ///
  /// In en, this message translates to:
  /// **'Successfully synced {count} operations'**
  String syncProgressSuccessfullySynced(int count);

  /// Message when conflicts are detected
  ///
  /// In en, this message translates to:
  /// **'{count} conflicts detected'**
  String syncProgressConflictsDetected(int count);

  /// Message when operations fail
  ///
  /// In en, this message translates to:
  /// **'{count} operations failed'**
  String syncProgressOperationsFailed(int count);

  /// Operations count display
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} operations'**
  String syncProgressOperationsCount(int completed, int total);

  /// Message when syncing operations
  ///
  /// In en, this message translates to:
  /// **'Syncing operations...'**
  String get syncProgressSyncingOperations;

  /// Sync phase: preparing
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get syncProgressPreparing;

  /// Sync phase: detecting conflicts
  ///
  /// In en, this message translates to:
  /// **'Detecting conflicts...'**
  String get syncProgressDetectingConflicts;

  /// Sync phase: resolving conflicts
  ///
  /// In en, this message translates to:
  /// **'Resolving conflicts...'**
  String get syncProgressResolvingConflicts;

  /// Sync phase: pulling updates
  ///
  /// In en, this message translates to:
  /// **'Pulling updates...'**
  String get syncProgressPullingUpdates;

  /// Sync phase: finalizing
  ///
  /// In en, this message translates to:
  /// **'Finalizing...'**
  String get syncProgressFinalizing;

  /// Sync phase: completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get syncProgressCompleted;

  /// Syncing progress with count
  ///
  /// In en, this message translates to:
  /// **'Syncing... {synced} of {total}'**
  String syncStatusSyncingCount(int synced, int total);

  /// Pending filter label
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get listViewOfflineFilterPending;

  /// No data available message
  ///
  /// In en, this message translates to:
  /// **'No {entityType} Available'**
  String listViewOfflineNoDataAvailable(String entityType);

  /// Offline no data message
  ///
  /// In en, this message translates to:
  /// **'You are offline. {entityType} will appear here when you connect to the internet.'**
  String listViewOfflineNoDataMessage(String entityType);

  /// Last updated label
  ///
  /// In en, this message translates to:
  /// **'Last updated {age}'**
  String listViewOfflineLastUpdated(String age);

  /// Message when data includes unsynced items
  ///
  /// In en, this message translates to:
  /// **'Includes unsynced data'**
  String get dashboardOfflineIncludesUnsynced;

  /// Data timestamp label
  ///
  /// In en, this message translates to:
  /// **'Data as of {age}'**
  String dashboardOfflineDataAsOf(String age);

  /// Unsynced label
  ///
  /// In en, this message translates to:
  /// **'Unsynced'**
  String get dashboardOfflineUnsynced;

  /// Offline data viewing message
  ///
  /// In en, this message translates to:
  /// **'Viewing offline data. Some information may be outdated.'**
  String get dashboardOfflineViewingOfflineData;

  /// No data available message
  ///
  /// In en, this message translates to:
  /// **'No {dataType} Available'**
  String dashboardOfflineNoDataAvailable(String dataType);

  /// Connect to load data message
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to load {dataType}'**
  String dashboardOfflineConnectToLoad(String dataType);

  /// Data outdated warning
  ///
  /// In en, this message translates to:
  /// **'Data may be outdated. Last updated {age}.'**
  String dashboardOfflineDataOutdated(String age);

  /// Network type: WiFi
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get generalNetworkTypeWifi;

  /// Network type: Mobile Data
  ///
  /// In en, this message translates to:
  /// **'Mobile Data'**
  String get generalNetworkTypeMobile;

  /// Network type: Ethernet
  ///
  /// In en, this message translates to:
  /// **'Ethernet'**
  String get generalNetworkTypeEthernet;

  /// Network type: VPN
  ///
  /// In en, this message translates to:
  /// **'VPN'**
  String get generalNetworkTypeVpn;

  /// Network type: Bluetooth
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get generalNetworkTypeBluetooth;

  /// Network type: Other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get generalNetworkTypeOther;

  /// Network type: None
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get generalNetworkTypeNone;

  /// Separator for multiple network types (e.g., WiFi + VPN)
  ///
  /// In en, this message translates to:
  /// **'+'**
  String get generalNetworkTypeSeparator;

  /// Title for the offline mode settings screen
  ///
  /// In en, this message translates to:
  /// **'Offline Mode Settings'**
  String get offlineSettingsTitle;

  /// Help button tooltip in offline settings
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get offlineSettingsHelp;

  /// Synchronization section title
  ///
  /// In en, this message translates to:
  /// **'Synchronization'**
  String get offlineSettingsSynchronization;

  /// Auto-sync toggle label
  ///
  /// In en, this message translates to:
  /// **'Auto-sync'**
  String get offlineSettingsAutoSync;

  /// Auto-sync description
  ///
  /// In en, this message translates to:
  /// **'Automatically sync in background'**
  String get offlineSettingsAutoSyncDesc;

  /// Message when auto-sync is enabled
  ///
  /// In en, this message translates to:
  /// **'Auto-sync enabled'**
  String get offlineSettingsAutoSyncEnabled;

  /// Message when auto-sync is disabled
  ///
  /// In en, this message translates to:
  /// **'Auto-sync disabled'**
  String get offlineSettingsAutoSyncDisabled;

  /// Sync interval label
  ///
  /// In en, this message translates to:
  /// **'Sync interval'**
  String get offlineSettingsSyncInterval;

  /// WiFi-only sync toggle label
  ///
  /// In en, this message translates to:
  /// **'WiFi only'**
  String get offlineSettingsWifiOnly;

  /// WiFi-only sync description
  ///
  /// In en, this message translates to:
  /// **'Sync only when connected to WiFi'**
  String get offlineSettingsWifiOnlyDesc;

  /// Message when WiFi-only sync is enabled
  ///
  /// In en, this message translates to:
  /// **'WiFi-only sync enabled'**
  String get offlineSettingsWifiOnlyEnabled;

  /// Message when WiFi-only sync is disabled
  ///
  /// In en, this message translates to:
  /// **'WiFi-only sync disabled'**
  String get offlineSettingsWifiOnlyDisabled;

  /// Last sync time label
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String offlineSettingsLastSync(String time);

  /// Next sync time label
  ///
  /// In en, this message translates to:
  /// **'Next sync: {time}'**
  String offlineSettingsNextSync(String time);

  /// Conflict resolution section title
  ///
  /// In en, this message translates to:
  /// **'Conflict Resolution'**
  String get offlineSettingsConflictResolution;

  /// Resolution strategy label
  ///
  /// In en, this message translates to:
  /// **'Resolution strategy'**
  String get offlineSettingsResolutionStrategy;

  /// Storage section title
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get offlineSettingsStorage;

  /// Database size label
  ///
  /// In en, this message translates to:
  /// **'Database size'**
  String get offlineSettingsDatabaseSize;

  /// Clear cache button label
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get offlineSettingsClearCache;

  /// Clear cache description
  ///
  /// In en, this message translates to:
  /// **'Remove temporary data'**
  String get offlineSettingsClearCacheDesc;

  /// Clear all data button label
  ///
  /// In en, this message translates to:
  /// **'Clear all data'**
  String get offlineSettingsClearAllData;

  /// Clear all data description
  ///
  /// In en, this message translates to:
  /// **'Remove all offline data'**
  String get offlineSettingsClearAllDataDesc;

  /// Statistics section title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get offlineSettingsStatistics;

  /// Total syncs label
  ///
  /// In en, this message translates to:
  /// **'Total syncs'**
  String get offlineSettingsTotalSyncs;

  /// Conflicts label
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get offlineSettingsConflicts;

  /// Errors label
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get offlineSettingsErrors;

  /// Success rate label
  ///
  /// In en, this message translates to:
  /// **'Success rate'**
  String get offlineSettingsSuccessRate;

  /// Actions section title
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get offlineSettingsActions;

  /// Syncing in progress message
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get offlineSettingsSyncing;

  /// Sync now button label
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get offlineSettingsSyncNow;

  /// Force full sync button label
  ///
  /// In en, this message translates to:
  /// **'Force full sync'**
  String get offlineSettingsForceFullSync;

  /// Check consistency button label
  ///
  /// In en, this message translates to:
  /// **'Check consistency'**
  String get offlineSettingsCheckConsistency;

  /// Checking in progress message
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get offlineSettingsChecking;

  /// Sync interval dialog title
  ///
  /// In en, this message translates to:
  /// **'Sync Interval'**
  String get offlineSettingsSyncIntervalTitle;

  /// Message when sync interval is set
  ///
  /// In en, this message translates to:
  /// **'Sync interval set to {interval}'**
  String offlineSettingsSyncIntervalSet(String interval);

  /// Conflict resolution strategy dialog title
  ///
  /// In en, this message translates to:
  /// **'Conflict Resolution Strategy'**
  String get offlineSettingsConflictStrategyTitle;

  /// Message when conflict strategy is set
  ///
  /// In en, this message translates to:
  /// **'Conflict strategy set to {strategy}'**
  String offlineSettingsConflictStrategySet(String strategy);

  /// Clear cache dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get offlineSettingsClearCacheTitle;

  /// Clear cache confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will remove temporary data. Your offline data will be preserved.'**
  String get offlineSettingsClearCacheMessage;

  /// Clear all data dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get offlineSettingsClearAllDataTitle;

  /// Clear all data confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will remove ALL offline data. This action cannot be undone. You will need to sync again to use offline mode.'**
  String get offlineSettingsClearAllDataMessage;

  /// Message when cache is cleared
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get offlineSettingsCacheCleared;

  /// Message when all data is cleared
  ///
  /// In en, this message translates to:
  /// **'All offline data cleared'**
  String get offlineSettingsAllDataCleared;

  /// Message shown during sync
  ///
  /// In en, this message translates to:
  /// **'Performing sync...'**
  String get offlineSettingsPerformingSync;

  /// Message shown during incremental sync
  ///
  /// In en, this message translates to:
  /// **'Performing incremental sync...'**
  String get offlineSettingsPerformingIncrementalSync;

  /// Message shown during full sync
  ///
  /// In en, this message translates to:
  /// **'Performing full sync...'**
  String get offlineSettingsPerformingFullSync;

  /// Message when incremental sync completes successfully
  ///
  /// In en, this message translates to:
  /// **'Incremental sync completed successfully'**
  String get offlineSettingsIncrementalSyncCompleted;

  /// Message when incremental sync completes with issues
  ///
  /// In en, this message translates to:
  /// **'Incremental sync completed with issues: {error}'**
  String offlineSettingsIncrementalSyncIssues(String error);

  /// Force full sync dialog title
  ///
  /// In en, this message translates to:
  /// **'Force Full Sync'**
  String get offlineSettingsForceFullSyncTitle;

  /// Force full sync confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will download all data from the server, replacing local data. This may take several minutes.'**
  String get offlineSettingsForceFullSyncMessage;

  /// Consistency check dialog title
  ///
  /// In en, this message translates to:
  /// **'Consistency Check Complete'**
  String get offlineSettingsConsistencyCheckComplete;

  /// Message when no consistency issues are found
  ///
  /// In en, this message translates to:
  /// **'No issues found. Your data is consistent.'**
  String get offlineSettingsConsistencyCheckNoIssues;

  /// Message when consistency issues are found
  ///
  /// In en, this message translates to:
  /// **'{count} issue(s) found.'**
  String offlineSettingsConsistencyCheckIssuesFound(int count);

  /// Label for issue breakdown section
  ///
  /// In en, this message translates to:
  /// **'Issue breakdown:'**
  String get offlineSettingsConsistencyCheckIssueBreakdown;

  /// Message when there are more issues than displayed
  ///
  /// In en, this message translates to:
  /// **'... and {count} more'**
  String offlineSettingsConsistencyCheckMoreIssues(int count);

  /// Repair inconsistencies dialog title
  ///
  /// In en, this message translates to:
  /// **'Repair Inconsistencies'**
  String get offlineSettingsRepairInconsistencies;

  /// Repair inconsistencies confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will attempt to automatically fix detected issues. Some issues may require manual intervention.'**
  String get offlineSettingsRepairInconsistenciesMessage;

  /// Repair complete dialog title
  ///
  /// In en, this message translates to:
  /// **'Repair Complete'**
  String get offlineSettingsRepairComplete;

  /// Repair complete message
  ///
  /// In en, this message translates to:
  /// **'{repaired} issue(s) repaired.\n{failed} issue(s) could not be repaired.'**
  String offlineSettingsRepairCompleteMessage(int repaired, int failed);

  /// Help dialog title
  ///
  /// In en, this message translates to:
  /// **'Offline Mode Help'**
  String get offlineSettingsHelpTitle;

  /// Help section title for auto-sync
  ///
  /// In en, this message translates to:
  /// **'Auto-sync'**
  String get offlineSettingsHelpAutoSync;

  /// Help description for auto-sync
  ///
  /// In en, this message translates to:
  /// **'Automatically synchronize data in the background at the specified interval.'**
  String get offlineSettingsHelpAutoSyncDesc;

  /// Help section title for WiFi only
  ///
  /// In en, this message translates to:
  /// **'WiFi Only'**
  String get offlineSettingsHelpWifiOnly;

  /// Help description for WiFi only
  ///
  /// In en, this message translates to:
  /// **'Only sync when connected to WiFi to save mobile data.'**
  String get offlineSettingsHelpWifiOnlyDesc;

  /// Help section title for conflict resolution
  ///
  /// In en, this message translates to:
  /// **'Conflict Resolution'**
  String get offlineSettingsHelpConflictResolution;

  /// Help description for conflict resolution
  ///
  /// In en, this message translates to:
  /// **'Choose how to handle conflicts when the same data is modified both locally and on the server.'**
  String get offlineSettingsHelpConflictResolutionDesc;

  /// Help section title for consistency check
  ///
  /// In en, this message translates to:
  /// **'Consistency Check'**
  String get offlineSettingsHelpConsistencyCheck;

  /// Help description for consistency check
  ///
  /// In en, this message translates to:
  /// **'Verify data integrity and fix any inconsistencies in the local database.'**
  String get offlineSettingsHelpConsistencyCheckDesc;

  /// Conflict resolution strategy: local wins
  ///
  /// In en, this message translates to:
  /// **'Local Wins'**
  String get offlineSettingsStrategyLocalWins;

  /// Conflict resolution strategy: remote wins
  ///
  /// In en, this message translates to:
  /// **'Remote Wins'**
  String get offlineSettingsStrategyRemoteWins;

  /// Conflict resolution strategy: last write wins
  ///
  /// In en, this message translates to:
  /// **'Last Write Wins'**
  String get offlineSettingsStrategyLastWriteWins;

  /// Conflict resolution strategy: manual resolution
  ///
  /// In en, this message translates to:
  /// **'Manual Resolution'**
  String get offlineSettingsStrategyManual;

  /// Conflict resolution strategy: merge changes
  ///
  /// In en, this message translates to:
  /// **'Merge Changes'**
  String get offlineSettingsStrategyMerge;

  /// Description for local wins strategy
  ///
  /// In en, this message translates to:
  /// **'Always keep local changes'**
  String get offlineSettingsStrategyLocalWinsDesc;

  /// Description for remote wins strategy
  ///
  /// In en, this message translates to:
  /// **'Always keep server changes'**
  String get offlineSettingsStrategyRemoteWinsDesc;

  /// Description for last write wins strategy
  ///
  /// In en, this message translates to:
  /// **'Keep most recently modified version'**
  String get offlineSettingsStrategyLastWriteWinsDesc;

  /// Description for manual resolution strategy
  ///
  /// In en, this message translates to:
  /// **'Manually resolve each conflict'**
  String get offlineSettingsStrategyManualDesc;

  /// Description for merge changes strategy
  ///
  /// In en, this message translates to:
  /// **'Automatically merge non-conflicting changes'**
  String get offlineSettingsStrategyMergeDesc;

  /// Time format for just now
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get offlineSettingsJustNow;

  /// Time format for minutes ago
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String offlineSettingsMinutesAgo(int minutes);

  /// Time format for hours ago
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String offlineSettingsHoursAgo(int hours);

  /// Time format for days ago
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String offlineSettingsDaysAgo(int days);

  /// Error message when auto-sync update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update auto-sync setting'**
  String get offlineSettingsFailedToUpdateAutoSync;

  /// Error message when WiFi-only update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update WiFi-only setting'**
  String get offlineSettingsFailedToUpdateWifiOnly;

  /// Error message when sync interval update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update sync interval'**
  String get offlineSettingsFailedToUpdateSyncInterval;

  /// Error message when conflict strategy update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update conflict strategy'**
  String get offlineSettingsFailedToUpdateConflictStrategy;

  /// Error message when cache clear fails
  ///
  /// In en, this message translates to:
  /// **'Failed to clear cache: {error}'**
  String offlineSettingsFailedToClearCache(String error);

  /// Error message when data clear fails
  ///
  /// In en, this message translates to:
  /// **'Failed to clear data'**
  String get offlineSettingsFailedToClearData;

  /// Error message when sync fails
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String offlineSettingsSyncFailed(String error);

  /// Error message when full sync fails
  ///
  /// In en, this message translates to:
  /// **'Full sync failed: {error}'**
  String offlineSettingsFullSyncFailed(String error);

  /// Error message when consistency check fails
  ///
  /// In en, this message translates to:
  /// **'Consistency check failed: {error}'**
  String offlineSettingsConsistencyCheckFailed(String error);

  /// Error message when repair fails
  ///
  /// In en, this message translates to:
  /// **'Repair failed: {error}'**
  String offlineSettingsRepairFailed(String error);

  /// Message when incremental sync is not available
  ///
  /// In en, this message translates to:
  /// **'Incremental sync not available. Please perform a full sync first.'**
  String get offlineSettingsIncrementalSyncNotAvailable;

  /// Error message when incremental sync fails
  ///
  /// In en, this message translates to:
  /// **'Incremental sync failed: {error}'**
  String offlineSettingsIncrementalSyncFailed(String error);

  /// Error message when sync service is not available
  ///
  /// In en, this message translates to:
  /// **'Sync service not available. Please restart the app.'**
  String get offlineSettingsSyncServiceNotAvailable;

  /// Error message when sync service cannot be retrieved
  ///
  /// In en, this message translates to:
  /// **'Failed to get sync service: {error}'**
  String offlineSettingsFailedToGetSyncService(String error);

  /// Error message when incremental sync service is not available
  ///
  /// In en, this message translates to:
  /// **'Incremental sync service not available'**
  String get offlineSettingsIncrementalSyncServiceNotAvailable;

  /// Dismiss button label
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get offlineSettingsDismiss;

  /// Manual sync interval option
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get offlineSettingsSyncIntervalManual;

  /// 15 minutes sync interval option
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get offlineSettingsSyncInterval15Minutes;

  /// 30 minutes sync interval option
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get offlineSettingsSyncInterval30Minutes;

  /// 1 hour sync interval option
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get offlineSettingsSyncInterval1Hour;

  /// 6 hours sync interval option
  ///
  /// In en, this message translates to:
  /// **'6 hours'**
  String get offlineSettingsSyncInterval6Hours;

  /// 12 hours sync interval option
  ///
  /// In en, this message translates to:
  /// **'12 hours'**
  String get offlineSettingsSyncInterval12Hours;

  /// 24 hours sync interval option
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get offlineSettingsSyncInterval24Hours;

  /// Incremental sync section title
  ///
  /// In en, this message translates to:
  /// **'Incremental Sync'**
  String get incrementalSyncTitle;

  /// Incremental sync section description
  ///
  /// In en, this message translates to:
  /// **'Optimize sync performance by fetching only changed data'**
  String get incrementalSyncDescription;

  /// Enable incremental sync toggle label
  ///
  /// In en, this message translates to:
  /// **'Enable Incremental Sync'**
  String get incrementalSyncEnable;

  /// Description when incremental sync is enabled
  ///
  /// In en, this message translates to:
  /// **'Fetch only changed data since last sync (70-80% faster)'**
  String get incrementalSyncEnabledDesc;

  /// Description when incremental sync is disabled
  ///
  /// In en, this message translates to:
  /// **'Full sync fetches all data each time'**
  String get incrementalSyncDisabledDesc;

  /// Message when incremental sync is enabled
  ///
  /// In en, this message translates to:
  /// **'Incremental sync enabled'**
  String get incrementalSyncEnabled;

  /// Message when incremental sync is disabled
  ///
  /// In en, this message translates to:
  /// **'Incremental sync disabled'**
  String get incrementalSyncDisabled;

  /// Error message when incremental sync setting update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update setting'**
  String get incrementalSyncFailedToUpdate;

  /// Sync window selector label
  ///
  /// In en, this message translates to:
  /// **'Sync Window'**
  String get incrementalSyncWindow;

  /// Sync window description
  ///
  /// In en, this message translates to:
  /// **'How far back to look for changes'**
  String get incrementalSyncWindowDesc;

  /// Message when sync window is set
  ///
  /// In en, this message translates to:
  /// **'Sync window set to {window}'**
  String incrementalSyncWindowSet(String window);

  /// Error message when sync window update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update sync window'**
  String get incrementalSyncWindowFailed;

  /// Cache duration selector label
  ///
  /// In en, this message translates to:
  /// **'Cache Duration'**
  String get incrementalSyncCacheDuration;

  /// Cache duration description
  ///
  /// In en, this message translates to:
  /// **'How long to cache categories, bills, and piggy banks before refreshing. These entities change infrequently, so longer cache durations reduce API calls.'**
  String get incrementalSyncCacheDurationDesc;

  /// Error message when cache duration update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update cache duration'**
  String get incrementalSyncCacheDurationFailed;

  /// Last incremental sync timestamp label
  ///
  /// In en, this message translates to:
  /// **'Last Incremental Sync'**
  String get incrementalSyncLastIncremental;

  /// Last full sync timestamp label
  ///
  /// In en, this message translates to:
  /// **'Last Full Sync'**
  String get incrementalSyncLastFull;

  /// Text shown when sync has never occurred
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get incrementalSyncNever;

  /// Text shown when sync occurred today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get incrementalSyncToday;

  /// Text shown for days since sync
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String incrementalSyncDaysAgo(int days);

  /// Full sync warning title
  ///
  /// In en, this message translates to:
  /// **'Full Sync Recommended'**
  String get incrementalSyncFullSyncRecommended;

  /// Full sync warning description
  ///
  /// In en, this message translates to:
  /// **'It\'s been more than 7 days since the last full sync. A full sync is recommended to ensure data integrity.'**
  String get incrementalSyncFullSyncRecommendedDesc;

  /// Incremental sync button label
  ///
  /// In en, this message translates to:
  /// **'Incremental Sync'**
  String get incrementalSyncIncrementalButton;

  /// Full sync button label
  ///
  /// In en, this message translates to:
  /// **'Full Sync'**
  String get incrementalSyncFullButton;

  /// Reset statistics button label
  ///
  /// In en, this message translates to:
  /// **'Reset Statistics'**
  String get incrementalSyncResetStatistics;

  /// Resetting statistics in progress message
  ///
  /// In en, this message translates to:
  /// **'Resetting...'**
  String get incrementalSyncResetting;

  /// Reset statistics dialog title
  ///
  /// In en, this message translates to:
  /// **'Reset Statistics'**
  String get incrementalSyncResetStatisticsTitle;

  /// Reset statistics confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will clear all incremental sync statistics (items fetched, bandwidth saved, etc.).\n\nSettings will be preserved. This action cannot be undone.'**
  String get incrementalSyncResetStatisticsMessage;

  /// Message when statistics are reset successfully
  ///
  /// In en, this message translates to:
  /// **'Statistics reset successfully'**
  String get incrementalSyncResetStatisticsSuccess;

  /// Error message when reset statistics fails
  ///
  /// In en, this message translates to:
  /// **'Failed to reset statistics'**
  String get incrementalSyncResetStatisticsFailed;

  /// Sync window label in compact view
  ///
  /// In en, this message translates to:
  /// **'Sync window: '**
  String get incrementalSyncWindowLabel;

  /// Text shown when full sync is enabled (incremental disabled)
  ///
  /// In en, this message translates to:
  /// **'Full sync enabled'**
  String get incrementalSyncFullSyncEnabled;

  /// Sync window option with days
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String incrementalSyncWindowDays(int days);

  /// Cache TTL option with hours
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String incrementalSyncCacheHours(int hours);

  /// Word 'window' used in sync window context
  ///
  /// In en, this message translates to:
  /// **'window'**
  String get incrementalSyncWindowWord;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ca',
    'cs',
    'da',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'hu',
    'id',
    'it',
    'ko',
    'nl',
    'pl',
    'pt',
    'ro',
    'ru',
    'sl',
    'sv',
    'tr',
    'uk',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return SPtBr();
        }
        break;
      }
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return SZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return SCa();
    case 'cs':
      return SCs();
    case 'da':
      return SDa();
    case 'de':
      return SDe();
    case 'en':
      return SEn();
    case 'es':
      return SEs();
    case 'fa':
      return SFa();
    case 'fr':
      return SFr();
    case 'hu':
      return SHu();
    case 'id':
      return SId();
    case 'it':
      return SIt();
    case 'ko':
      return SKo();
    case 'nl':
      return SNl();
    case 'pl':
      return SPl();
    case 'pt':
      return SPt();
    case 'ro':
      return SRo();
    case 'ru':
      return SRu();
    case 'sl':
      return SSl();
    case 'sv':
      return SSv();
    case 'tr':
      return STr();
    case 'uk':
      return SUk();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
