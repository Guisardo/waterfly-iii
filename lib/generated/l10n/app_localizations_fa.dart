// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class SFa extends S {
  SFa([String locale = 'fa']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'کیف پول نقد\n';

  @override
  String get accountRoleAssetCC => 'کارت اعتباری';

  @override
  String get accountRoleAssetDefault => 'حساب دارایی پیش فرض\n';

  @override
  String get accountRoleAssetSavings => 'حساب پس انداز';

  @override
  String get accountRoleAssetShared => 'حساب دارایی مشترک\n';

  @override
  String get accountsLabelAsset => 'حساب های دارایی';

  @override
  String get accountsLabelExpense => 'حساب‌های هزینه';

  @override
  String get accountsLabelLiabilities => 'بدهی ها';

  @override
  String get accountsLabelRevenue => 'حساب‌های درآمد';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'هفته',
      'monthly': 'ماه',
      'quarterly': 'سه‌ماهه',
      'halfyear': 'نیم‌ساله',
      'yearly': 'سال',
      'other': 'نامشخص',
    });
    return '$interest% سود به ازای هر $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'هفتگی',
      'monthly': 'ماهیانه',
      'quarterly': 'سه‌ماهه',
      'halfyear': 'نیم‌ساله',
      'yearly': 'سالیانه',
      'other': 'نامشخص',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: '، از $skip گذر می‌کند',
      zero: '',
    );
    return 'قبض مطابق با تراکنش‌ها بین $minValue و $maxvalue است. تکرارها $_temp0$_temp1.';
  }

  @override
  String get billsChangeLayoutTooltip => 'تغییر چیدمان';

  @override
  String get billsChangeSortOrderTooltip => 'تغییر ترتیب مرتب‌سازی\n';

  @override
  String get billsErrorLoading => 'خطا در بارگیری صورتحساب.\n';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'هفتگی',
      'monthly': 'ماهیانه',
      'quarterly': 'سه‌ماهه',
      'halfyear': 'نیم‌ساله',
      'yearly': 'سالیانه',
      'other': 'نامشخص',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: '، از $skip گذر می‌کند',
      zero: '',
    );
    return 'قبض با تراکنش‌های مبلغ $value مطابقت دارد. تکرارها $_temp0$_temp1.';
  }

  @override
  String billsExpectedOn(DateTime date) {
    return 'تاریخ مورد انتظار: :date\n\n\n\n\n\n';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'هفتگی',
      'monthly': 'ماهیانه',
      'quarterly': 'سه‌ماهه',
      'halfyear': 'نیم‌ساله',
      'yearly': 'سالیانه',
      'other': 'نامشخص',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'هفتگی',
      'monthly': 'ماهیانه',
      'quarterly': 'سه‌ماهه',
      'halfyear': 'نیم‌ساله',
      'yearly': 'سالیانه',
      'other': 'نامشخص',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: '، از $skip گذر می‌کند',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get billsInactive => 'غیر فعال';

  @override
  String get billsIsActive => 'قبض فعال است\n\n\n\n\n\n';

  @override
  String get billsLayoutGroupSubtitle =>
      'صورت‌حساب‌ها در گروه‌های اختصاص داده شده نمایش داده می‌شوند.\n';

  @override
  String get billsLayoutGroupTitle => 'گروه';

  @override
  String get billsLayoutListSubtitle =>
      'صورت‌حساب‌ها در فهرستی که بر اساس معیارهای خاصی مرتب شده‌اند نمایش داده می‌شوند.\n';

  @override
  String get billsLayoutListTitle => 'لیست';

  @override
  String get billsListEmpty => 'لیست در حال حاضر خالی است.\n';

  @override
  String get billsNextExpectedMatch => 'مسابقه بعدی مورد انتظار\n';

  @override
  String get billsNotActive => 'قبض غیرفعال است\n\n\n\n\n\n';

  @override
  String get billsNotExpected => 'این دوره انتظار نمی رود\n';

  @override
  String get billsNoTransactions => 'هیچ تراکنشی یافت نشد';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'پرداخت شده $dateString\n';
  }

  @override
  String get billsSortAlphabetical => 'الفبایی';

  @override
  String get billsSortByTimePeriod => 'بر اساس دوره زمانی\n';

  @override
  String get billsSortFrequency => 'فرکانس';

  @override
  String get billsSortName => 'نام';

  @override
  String get billsUngrouped => 'گروه‌بندی نشده';

  @override
  String get billsSettingsShowOnlyActive => 'فقط فعال‌ها را نمایش بده';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'فقط اشتراک‌های فعال را نمایش می‌دهد.';

  @override
  String get billsSettingsShowOnlyExpected => 'فقط مورد انتظارها را نمایش بده';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'فقط آن اشتراک‌هایی را نمایش می‌دهد که در این ماه مورد انتظار (یا پرداخت شده) هستند.';

  @override
  String get categoryDeleteConfirm =>
      'آیا مطمئن هستید که می‌خواهید این دسته را حذف کنید؟ تراکنش ها حذف نمی شوند، اما دیگر دسته بندی نخواهند داشت.\n';

  @override
  String get categoryErrorLoading => 'خطا در بارگیری دسته‌ها.\n';

  @override
  String get categoryFormLabelIncludeInSum => 'در جمع ماهیانه لحاظ شود\n';

  @override
  String get categoryFormLabelName => 'نام دسته';

  @override
  String get categoryMonthNext => 'ماه آینده';

  @override
  String get categoryMonthPrev => 'ماه قبل';

  @override
  String get categorySumExcluded => 'مستثتی شده';

  @override
  String get categoryTitleAdd => 'افزودن دسته';

  @override
  String get categoryTitleDelete => 'حذف دسته';

  @override
  String get categoryTitleEdit => 'ویرایش دسته‌ بندی';

  @override
  String get catNone => '<no category>';

  @override
  String get catOther => 'دیگر';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'پاسخ نامعتبر از API: $message\n';
  }

  @override
  String get errorAPIUnavailable => 'API در دسترس نیست\n';

  @override
  String get errorFieldRequired => 'این فیلد الزامی است.\n';

  @override
  String get errorInvalidURL => 'آدرس نامعتبر';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'حداقل نسخه Firefly API v$requiredVersion مورد نیاز است. لطفا ارتقا دهید.\n';
  }

  @override
  String errorStatusCode(int code) {
    return 'کد وضعیت: $code\n';
  }

  @override
  String get errorUnknown => 'خطای ناشناخته.\n';

  @override
  String get formButtonHelp => 'راهنما';

  @override
  String get formButtonLogin => 'ورود';

  @override
  String get formButtonLogout => 'خروج از سیستم';

  @override
  String get formButtonRemove => 'پاک کردن';

  @override
  String get formButtonResetLogin => 'بازنشانی ورود به سیستم\n';

  @override
  String get formButtonTransactionAdd => 'افزودن تراکنش';

  @override
  String get formButtonTryAgain => 'دوباره سعی کنید';

  @override
  String get generalAccount => 'حساب';

  @override
  String get generalAssets => 'دارایی ها';

  @override
  String get generalBalance => 'مانده حساب';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'موجودی در تاریخ $dateString';
  }

  @override
  String get generalBill => 'صورت حساب';

  @override
  String get generalBudget => 'بودجه';

  @override
  String get generalCategory => 'دسته‌بندی';

  @override
  String get generalCurrency => 'واحدپول';

  @override
  String get generalDateRangeCurrentMonth => 'ماه جاری';

  @override
  String get generalDateRangeLast30Days => '۳۰ روز گذشته';

  @override
  String get generalDateRangeCurrentYear => 'سال جاری';

  @override
  String get generalDateRangeLastYear => 'سال گذشته';

  @override
  String get generalDateRangeAll => 'همه';

  @override
  String get generalDefault => 'پیش فرض';

  @override
  String get generalDestinationAccount => 'حساب مقصد';

  @override
  String get generalDismiss => 'نادیده گرفتن';

  @override
  String get generalEarned => 'به دست آورده';

  @override
  String get generalError => 'خطا';

  @override
  String get generalExpenses => 'هزینه ها';

  @override
  String get generalIncome => 'درآمد';

  @override
  String get generalLiabilities => 'بدهی ها';

  @override
  String get generalMultiple => 'چندتایی';

  @override
  String get generalNever => 'هرگز';

  @override
  String get generalReconcile => 'مغایرت گیری شده';

  @override
  String get generalReset => 'تنظیم مجدد';

  @override
  String get generalSourceAccount => 'حساب مبدأ';

  @override
  String get generalSpent => 'خرج شده';

  @override
  String get generalSum => 'مجموع';

  @override
  String get generalTarget => 'هدف';

  @override
  String get generalUnknown => 'ناشناخته';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'هفتگی',
      'monthly': 'ماهیانه',
      'quarterly': 'سه‌ماهه',
      'halfyear': 'نیم‌ساله',
      'yearly': 'سالیانه',
      'other': 'نامشخص',
    });
    return '($_temp0)';
  }

  @override
  String get homeMainBillsTitle => 'صورت حساب های هفته آینده\n';

  @override
  String homeMainBudgetInterval(DateTime from, DateTime to, String period) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return '($fromString تا $toString، $period)';
  }

  @override
  String homeMainBudgetIntervalSingle(DateTime from, DateTime to) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return '($fromString تا $toString)';
  }

  @override
  String homeMainBudgetSum(String current, String status, String available) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'over': 'از',
      'other': 'باقیمانده از',
    });
    return '$current $_temp0 $available';
  }

  @override
  String get homeMainBudgetTitle => 'بودجه ماه جاری';

  @override
  String get homeMainChartAccountsTitle => 'خلاصه حساب\n';

  @override
  String get homeMainChartCategoriesTitle => 'خلاصه دسته برای ماه جاری\n';

  @override
  String get homeMainChartDailyAvg => 'میانگین 7 روز\n';

  @override
  String get homeMainChartDailyTitle => 'خلاصه روزانه';

  @override
  String get homeMainChartNetEarningsTitle => 'دریافتی خالص';

  @override
  String get homeMainChartNetWorthTitle => 'ارزش خالص\n';

  @override
  String get homeMainChartTagsTitle => 'خلاصه برچسب‌ها برای ماه جاری';

  @override
  String get homePiggyAdjustDialogTitle => 'پس انداز/خرج پول\n';

  @override
  String homePiggyDateStart(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'تاریخ شروع: $dateString\n';
  }

  @override
  String homePiggyDateTarget(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'تاریخ هدف: $dateString\n';
  }

  @override
  String get homeMainDialogSettingsTitle => 'سفارشی‌سازی داشبورد';

  @override
  String homePiggyLinked(String account) {
    return 'لینک به $account\n';
  }

  @override
  String get homePiggyNoAccounts => 'هیچ پس‌اندازی تنظیم نشده است.\n\n';

  @override
  String get homePiggyNoAccountsSubtitle => 'مقداری در رابط وب ایجاد کنید!\n';

  @override
  String homePiggyRemaining(String amount) {
    return 'باقی مانده برای ذخیره: $amount\n';
  }

  @override
  String homePiggySaved(String amount) {
    return 'ذخیره شده تا کنون: $amount\n';
  }

  @override
  String get homePiggySavedMultiple => 'تاکنون ذخیره شده:';

  @override
  String homePiggyTarget(String amount) {
    return 'مقدار هدف: $amount\n';
  }

  @override
  String get homePiggyAccountStatus => 'وضعیت حساب';

  @override
  String get homePiggyAvailableAmounts => 'مبالغ موجود';

  @override
  String homePiggyAvailable(String amount) {
    return 'موجود: $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'در قلک‌ها: $amount';
  }

  @override
  String get homeTabLabelBalance => 'ترازنامه';

  @override
  String get homeTabLabelMain => 'اصلی';

  @override
  String get homeTabLabelPiggybanks => 'صندوق پس‌انداز\n\n\n\n\n\n';

  @override
  String get homeTabLabelTransactions => 'تراکنش‌ها';

  @override
  String get homeTransactionsActionFilter => 'لیست فیلتر';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<همه حساب‌ها>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<همه قبوض>';

  @override
  String get homeTransactionsDialogFilterBillUnset =>
      '<بدون تنظیم صورت حساب>\n';

  @override
  String get homeTransactionsDialogFilterBudgetsAll => '<همه بودجه‌ها>\n';

  @override
  String get homeTransactionsDialogFilterBudgetUnset => '<بدون تنظیم بودجه>\n';

  @override
  String get homeTransactionsDialogFilterCategoriesAll => '<همه دسته‌ها>\n';

  @override
  String get homeTransactionsDialogFilterCategoryUnset => '<بدون دسته بندی>\n';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<همه ارزها>\n';

  @override
  String get homeTransactionsDialogFilterDateRange => 'بازه زمانی';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'نمایش معاملات آتی\n';

  @override
  String get homeTransactionsDialogFilterSearch => 'عبارت جستجو';

  @override
  String get homeTransactionsDialogFilterTitle => 'فیلترها را انتخاب کنید';

  @override
  String get homeTransactionsEmpty => 'هیچ تراکنشی یافت نشد';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num دسته\n';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'نمایش برچسب‌ها در لیست تراکنش‌ها';

  @override
  String get liabilityDirectionCredit => 'این بدهی متعلق به من است';

  @override
  String get liabilityDirectionDebit => 'این بدهی را بدهکارم\n';

  @override
  String get liabilityTypeDebt => 'بدهی';

  @override
  String get liabilityTypeLoan => 'وام';

  @override
  String get liabilityTypeMortgage => 'رهن';

  @override
  String get loginAbout =>
      'برای استفاده مؤثر از Waterfly III به سرور خود با نمونه Firefly III یا افزونه Firefly III برای Home Assistant نیاز دارید.\n\nلطفاً URL کامل و همچنین یک نشانه دسترسی شخصی (تنظیمات -> نمایه -> OAuth -> رمز دسترسی شخصی) را در زیر وارد کنید.\n';

  @override
  String get loginFormLabelAPIKey => 'کلید API معتبر\n';

  @override
  String get loginFormLabelHost => 'URL میزبان\n';

  @override
  String get loginWelcome => 'به Waterfly III خوش آمدید\n';

  @override
  String get logoutConfirmation => 'آیا برای خارج شدن مطمئن هستید؟\n';

  @override
  String get navigationAccounts => 'حساب‌ها';

  @override
  String get navigationBills => 'صورت حساب';

  @override
  String get navigationCategories => 'دسته\n';

  @override
  String get navigationMain => 'داشبورد اصلی\n';

  @override
  String get generalSettings => 'تنظیمات';

  @override
  String get no => 'نه';

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

    return '$percString از $of\n\n\n\n\n\n';
  }

  @override
  String get settingsDialogDebugInfo =>
      'می‌توانید گزارش‌های اشکال‌زدایی را در اینجا فعال و ارسال کنید. اینها تأثیر بدی بر عملکرد دارند، بنابراین لطفاً آنها را فعال نکنید مگر اینکه به شما توصیه شده باشد. غیرفعال کردن گزارش، گزارش ذخیره شده را حذف می کند.\n';

  @override
  String get settingsDialogDebugMailCreate => 'ایجاد ایمیل\n';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      '\nهشدار: یک پیش‌نویس ایمیل با پیوست فایل گزارش (به فرمت متنی) باز می‌شود. گزارش‌ها ممکن است اطلاعات حساسی را مانند نام میزبان نمونه Firefly شما (هرچند که سعی در ثبت اطلاعات محرمانه مانند کلید API نداریم) شامل شوند. لطفاً با دقت گزارش را مطالعه کرده و هرگونه اطلاعاتی که نمی‌خواهید به اشتراک بگذارید و/یا با موضوع گزارش مرتبط نیست را سانسور کنید.\n\nلطفاً قبل از ارسال هرگونه گزارش، توافق قبلی را از طریق ایمیل/گیت‌هاب برای انجام این کار داشته باشید. هرگونه گزارشی که بدون در نظر گرفتن متن مناسبی برای حریم خصوصی ارسال شود، توسط من به دلایل حفظ حریم خصوصی حذف خواهد شد.هرگز گزارش را بدون سانسور مطلق به گیت‌هاب یا جای دیگری آپلود نکنید.\n\n\n\n\n';

  @override
  String get settingsDialogDebugSendButton => 'ارسال گزارش از طریق ایمیل\n';

  @override
  String get settingsDialogDebugTitle => 'گزارش اشکالات';

  @override
  String get settingsDialogLanguageTitle => 'انتخاب زبان';

  @override
  String get settingsDialogThemeTitle => 'انتخاب تم';

  @override
  String get settingsFAQ => 'سوالات متداول';

  @override
  String get settingsFAQHelp =>
      'در مرورگر باز می‌شود. فقط به زبان انگلیسی موجود است.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configure offline sync and mobile data usage';

  @override
  String get settingsLanguage => 'زبان';

  @override
  String get settingsLockscreen => 'صفحه قفل';

  @override
  String get settingsLockscreenHelp =>
      'نیاز به احراز هویت در راه اندازی برنامه\n';

  @override
  String get settingsLockscreenInitial =>
      'لطفاً برای فعال کردن صفحه قفل، احراز هویت کنید.\n';

  @override
  String get settingsNLAppAccount => 'حساب پیش فرض';

  @override
  String get settingsNLAppAccountDynamic => '<Dynamic>';

  @override
  String get settingsNLAppAdd => 'افزودن برنامه\n';

  @override
  String get settingsNLAppAddHelp =>
      'برای افزودن یک برنامه برای گوش دادن کلیک کنید. فقط برنامه های واجد شرایط در لیست نمایش داده می شوند.\n';

  @override
  String get settingsNLAppAddInfo =>
      'برخی از تراکنش‌ها را در جایی که اعلان‌های تلفن دریافت می‌کنید انجام دهید تا برنامه‌ها را به این فهرست اضافه کنید. اگر برنامه همچنان نمایش داده نشد، لطفاً آن را به app@vogt.pw گزارش دهید.\n';

  @override
  String get settingsNLAutoAdd => 'ایجاد تراکنش بدون تعامل';

  @override
  String get settingsNLDescription =>
      'این سرویس به شما امکان می‌دهد جزئیات تراکنش را از اعلان‌های فشار دریافتی دریافت کنید. علاوه بر این، می‌توانید یک حساب پیش فرض را انتخاب کنید که تراکنش باید به آن اختصاص یابد - اگر مقداری تنظیم نشده باشد، سعی می‌کند یک حساب از اعلان استخراج کند.\n';

  @override
  String get settingsNLEmptyNote => 'فیلد یادداشت را خالی بگذار';

  @override
  String get settingsNLPermissionGrant => 'برای اعطای مجوز ضربه بزنید.\n';

  @override
  String get settingsNLPermissionNotGranted => 'مجوز داده نشد';

  @override
  String get settingsNLPermissionRemove => 'مجوز حذف شود؟\n';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'برای غیرفعال کردن این سرویس، روی برنامه کلیک کنید و مجوزها را در صفحه بعدی حذف کنید.\n';

  @override
  String get settingsNLPrefillTXTitle =>
      'عنوان تراکنش را با عنوان اعلان از قبل پر کنید\n';

  @override
  String get settingsNLServiceChecking => 'در حال بررسی وضعیت...';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'خطا در بررسی وضعیت: $error\n';
  }

  @override
  String get settingsNLServiceRunning => 'سرویس در حال اجرا است.\n';

  @override
  String get settingsNLServiceStatus => 'وضعیت سرویس\n';

  @override
  String get settingsNLServiceStopped => 'سرویس متوقف شده است.\n';

  @override
  String get settingsNotificationListener => 'سرویس شنونده اعلان\n';

  @override
  String get settingsTheme => 'تم برنامه\n';

  @override
  String get settingsThemeDynamicColors => 'رنگ‌های پویا';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'حالت تاریک',
      'light': 'حالت روشن',
      'other': 'پیش‌فرض سیستم',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone => 'از منطقه زمانی سرور استفاده کنید\n';

  @override
  String get settingsUseServerTimezoneHelp =>
      'نمایش همه زمان‌ها در منطقه زمانی سرور. این رفتار رابط وب را تقلید می کند.\n';

  @override
  String get settingsVersion => 'نسخه نرم افزاز';

  @override
  String get settingsVersionChecking => 'چک کردن…';

  @override
  String get transactionAttachments => 'پیوست ها';

  @override
  String get transactionDeleteConfirm =>
      'آیا مطمئن هستید که می خواهید این تراکنش را حذف کنید؟\n';

  @override
  String get transactionDialogAttachmentsDelete => 'حذف پیوست\n';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      'آیا مطمئن هستید که می خواهید این پیوست را حذف کنید؟\n';

  @override
  String get transactionDialogAttachmentsErrorDownload => 'فایل دانلود نشد\n';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'فایل باز نشد: $error\n';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'فایل آپلود نشد: $error\n';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'پیوست ها';

  @override
  String get transactionDialogBillNoBill => 'بدون صورتحساب\n';

  @override
  String get transactionDialogBillTitle => 'پیوند به بیل\n';

  @override
  String get transactionDialogCurrencyTitle => 'واحد پول را انتخاب کنید\n';

  @override
  String get transactionDialogPiggyNoPiggy => 'بدون قلک';

  @override
  String get transactionDialogPiggyTitle => 'اتصال به قلک';

  @override
  String get transactionDialogTagsAdd => 'افزودن برچسب';

  @override
  String get transactionDialogTagsHint => 'جستجو/افزودن برچسب\n';

  @override
  String get transactionDialogTagsTitle => 'برچسب ها را انتخاب کنید';

  @override
  String get transactionDuplicate => 'کپی کردن';

  @override
  String get transactionErrorInvalidAccount => 'حساب نامعتبر';

  @override
  String get transactionErrorInvalidBudget => 'بودجه نامعتبر\n';

  @override
  String get transactionErrorNoAccounts => 'لطفاً ابتدا حساب‌ها را وارد کنید.';

  @override
  String get transactionErrorNoAssetAccount =>
      'لطفاً یک حساب دارایی انتخاب کنید.';

  @override
  String get transactionErrorTitle => 'لطفا عنوان بفرمایید\n';

  @override
  String get transactionFormLabelAccountDestination => 'حساب مقصد\n';

  @override
  String get transactionFormLabelAccountForeign => 'حساب خارجی\n';

  @override
  String get transactionFormLabelAccountOwn => 'حساب شخصی\n';

  @override
  String get transactionFormLabelAccountSource => 'حساب منبع\n';

  @override
  String get transactionFormLabelNotes => 'یادداشت';

  @override
  String get transactionFormLabelTags => 'برچسب ها';

  @override
  String get transactionFormLabelTitle => 'عنوان معامله\n';

  @override
  String get transactionSplitAdd => 'اضافه کردن تراکنش تقسیم\n';

  @override
  String get transactionSplitChangeCurrency => 'ارز تقسیم شده را تغییر دهید\n';

  @override
  String get transactionSplitChangeDestinationAccount =>
      'تغییر حساب مقصد تفکیک';

  @override
  String get transactionSplitChangeSourceAccount => 'تغییر حساب مبدأ تفکیک';

  @override
  String get transactionSplitChangeTarget => 'تغییر حساب هدف تقسیم شده\n';

  @override
  String get transactionSplitDelete => 'حذف تقسیم\n';

  @override
  String get transactionTitleAdd => 'افزودن تراکنش';

  @override
  String get transactionTitleDelete => 'حذف تراکنش\n';

  @override
  String get transactionTitleEdit => 'ویرایش تراکنش\n';

  @override
  String get transactionTypeDeposit => 'سپرده';

  @override
  String get transactionTypeTransfer => 'انتقال';

  @override
  String get transactionTypeWithdrawal => 'درخواست برداشت';

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
