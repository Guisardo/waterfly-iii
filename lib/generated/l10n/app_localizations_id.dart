// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class SId extends S {
  SId([String locale = 'id']) : super(locale);

  @override
  String get accountRoleAssetCashWallet => 'Dompet Kas';

  @override
  String get accountRoleAssetCC => 'Kartu kredit';

  @override
  String get accountRoleAssetDefault => 'Akun aset standar';

  @override
  String get accountRoleAssetSavings => 'Akun tabungan';

  @override
  String get accountRoleAssetShared => 'Akun aset bersama';

  @override
  String get accountsLabelAsset => 'Akun Aset';

  @override
  String get accountsLabelExpense => 'Akun Pengeluaran';

  @override
  String get accountsLabelLiabilities => 'Kewajiban';

  @override
  String get accountsLabelRevenue => 'Akun Pendapatan';

  @override
  String accountsLiabilitiesInterest(double interest, String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'minggu',
      'monthly': 'bulan',
      'quarterly': 'perempat',
      'halfyear': 'setengah-tahun',
      'yearly': 'tahun',
      'other': 'tidak-diketahui',
    });
    return '$interest% bunga per $_temp0';
  }

  @override
  String billsAmountAndFrequency(
    String minValue,
    String maxvalue,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'weekly',
      'monthly': 'monthly',
      'quarterly': 'quarterly',
      'halfyear': 'half-yearly',
      'yearly': 'yearly',
      'other': 'unknown',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', skips over $skip',
      zero: '',
    );
    return 'Subscription matches transactions between $minValue and $maxvalue. Repeats $_temp0$_temp1.';
  }

  @override
  String get billsChangeLayoutTooltip => 'Ubah tata letak';

  @override
  String get billsChangeSortOrderTooltip => 'Ubah urutan penyortiran';

  @override
  String get billsErrorLoading => 'Terjadi kesalahan saat memuat langganan.';

  @override
  String billsExactAmountAndFrequency(
    String value,
    String frequency,
    num skip,
  ) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'weekly',
      'monthly': 'monthly',
      'quarterly': 'quarterly',
      'halfyear': 'half-yearly',
      'yearly': 'yearly',
      'other': 'unknown',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', skips over $skip',
      zero: '',
    );
    return 'Subscription matches transactions of $value. Repeats $_temp0$_temp1.';
  }

  @override
  String billsExpectedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Diharapkan $dateString';
  }

  @override
  String billsFrequency(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Mingguan',
      'monthly': 'Bulanan',
      'quarterly': 'Triwulanan',
      'halfyear': 'Setengah tahunan',
      'yearly': 'Tahunan',
      'other': 'Tidak diketahui',
    });
    return '$_temp0';
  }

  @override
  String billsFrequencySkip(String frequency, num skip) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'quarterly': 'Quarterly',
      'halfyear': 'Half-yearly',
      'yearly': 'Yearly',
      'other': 'Unknown',
    });
    String _temp1 = intl.Intl.pluralLogic(
      skip,
      locale: localeName,
      other: ', skips over $skip',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get billsInactive => 'Tidak aktif';

  @override
  String get billsIsActive => 'Langganan aktif';

  @override
  String get billsLayoutGroupSubtitle =>
      'Langganan ditampilkan dalam grup yang telah ditetapkan.';

  @override
  String get billsLayoutGroupTitle => 'Grup';

  @override
  String get billsLayoutListSubtitle =>
      'Langganan ditampilkan dalam daftar yang diurutkan berdasarkan kriteria tertentu.';

  @override
  String get billsLayoutListTitle => 'Daftar';

  @override
  String get billsListEmpty => 'Daftar saat ini kosong.';

  @override
  String get billsNextExpectedMatch => 'Kecocokan yang diharapkan berikutnya';

  @override
  String get billsNotActive => 'Langganan tidak aktif';

  @override
  String get billsNotExpected => 'Tidak diharapkan dalam periode ini';

  @override
  String get billsNoTransactions => 'Tidak ada transaksi ditemukan.';

  @override
  String billsPaidOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Dibayar $dateString';
  }

  @override
  String get billsSortAlphabetical => 'Menurut Abjad';

  @override
  String get billsSortByTimePeriod => 'Berdasarkan periode waktu';

  @override
  String get billsSortFrequency => 'Frekuensi';

  @override
  String get billsSortName => 'Nama';

  @override
  String get billsUngrouped => 'Tidak Terkelompok';

  @override
  String get billsSettingsShowOnlyActive => 'Tampilkan yang aktif saja';

  @override
  String get billsSettingsShowOnlyActiveDesc =>
      'Menampilkan langganan yang aktif saja.';

  @override
  String get billsSettingsShowOnlyExpected => 'Tampilkan yang diharapkan saja';

  @override
  String get billsSettingsShowOnlyExpectedDesc =>
      'Menampilkan langganan yang diharapkan (atau dibayar) bulan ini saja.';

  @override
  String get categoryDeleteConfirm =>
      'Apakah Anda yakin ingin menghapus kategori ini? Transaksi tidak akan dihapus, tetapi tidak akan memiliki kategori lagi.';

  @override
  String get categoryErrorLoading => 'Gagal memuat kategori.';

  @override
  String get categoryFormLabelIncludeInSum => 'Sertakan dalam jumlah bulanan';

  @override
  String get categoryFormLabelName => 'Nama Kategori';

  @override
  String get categoryMonthNext => 'Bulan Berikutnya';

  @override
  String get categoryMonthPrev => 'Bulan Sebelumnya';

  @override
  String get categorySumExcluded => 'dikecualikan';

  @override
  String get categoryTitleAdd => 'Tambah Kategori';

  @override
  String get categoryTitleDelete => 'Hapus Kategori';

  @override
  String get categoryTitleEdit => 'Edit Kategori';

  @override
  String get catNone => '<tanpa kategori>';

  @override
  String get catOther => 'Lainnya';

  @override
  String errorAPIInvalidResponse(String message) {
    return 'Respons dari API tidak Valid: $message';
  }

  @override
  String get errorAPIUnavailable => 'API tidak tersedia';

  @override
  String get errorFieldRequired => 'Kolom ini diperlukan.';

  @override
  String get errorInvalidURL => 'URL tidak Valid';

  @override
  String errorMinAPIVersion(String requiredVersion) {
    return 'Versi Firefly API Minimum v$requiredVersion diperlukan. Mohon tingkatkan.';
  }

  @override
  String errorStatusCode(int code) {
    return 'Kode Status: $code';
  }

  @override
  String get errorUnknown => 'Kesalahan tidak diketahui.';

  @override
  String get formButtonHelp => 'Bantuan';

  @override
  String get formButtonLogin => 'Masuk';

  @override
  String get formButtonLogout => 'Keluar';

  @override
  String get formButtonRemove => 'Hapus';

  @override
  String get formButtonResetLogin => 'Setel ulang masuk';

  @override
  String get formButtonTransactionAdd => 'Tambah Transaksi';

  @override
  String get formButtonTryAgain => 'Coba lagi';

  @override
  String get generalAccount => 'Akun';

  @override
  String get generalAssets => 'Aset';

  @override
  String get generalBalance => 'Saldo';

  @override
  String generalBalanceOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Saldo pada tanggal $dateString';
  }

  @override
  String get generalBill => 'Tagihan';

  @override
  String get generalBudget => 'Anggaran';

  @override
  String get generalCategory => 'Kategori';

  @override
  String get generalCurrency => 'Mata Uang';

  @override
  String get generalDateRangeCurrentMonth => 'Bulan Ini';

  @override
  String get generalDateRangeLast30Days => '30 hari terakhir';

  @override
  String get generalDateRangeCurrentYear => 'Tahun Ini';

  @override
  String get generalDateRangeLastYear => 'Tahun lalu';

  @override
  String get generalDateRangeAll => 'Semua';

  @override
  String get generalDefault => 'bawaan';

  @override
  String get generalDestinationAccount => 'Akun Tujuan';

  @override
  String get generalDismiss => 'Tutup';

  @override
  String get generalEarned => 'Didapatkan';

  @override
  String get generalError => 'Kesalahan';

  @override
  String get generalExpenses => 'Pengeluaran';

  @override
  String get generalIncome => 'Pendapatan';

  @override
  String get generalLiabilities => 'Kewajiban';

  @override
  String get generalMultiple => 'beberapa';

  @override
  String get generalNever => 'tidak pernah';

  @override
  String get generalReconcile => 'Terekonsiliasi';

  @override
  String get generalReset => 'Setel ulang';

  @override
  String get generalSourceAccount => 'Akun Sumber';

  @override
  String get generalSpent => 'Dihabiskan';

  @override
  String get generalSum => 'Jumlah';

  @override
  String get generalTarget => 'Target';

  @override
  String get generalUnknown => 'Tidak Diketahui';

  @override
  String homeMainBillsInterval(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'weekly': 'mingguan',
      'monthly': 'bulanan',
      'quarterly': 'triwulanan',
      'halfyear': 'setengah tahunan',
      'yearly': 'tahunan',
      'other': 'tidak diketahui',
    });
    return ' ($_temp0)';
  }

  @override
  String get homeMainBillsTitle => 'Langganan untuk minggu depan';

  @override
  String homeMainBudgetInterval(DateTime from, DateTime to, String period) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString ke $toString, $period)';
  }

  @override
  String homeMainBudgetIntervalSingle(DateTime from, DateTime to) {
    final intl.DateFormat fromDateFormat = intl.DateFormat.MMMd(localeName);
    final String fromString = fromDateFormat.format(from);
    final intl.DateFormat toDateFormat = intl.DateFormat.MMMd(localeName);
    final String toString = toDateFormat.format(to);

    return ' ($fromString sampai $toString)';
  }

  @override
  String homeMainBudgetSum(String current, String status, String available) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'over': 'di atas',
      'other': 'sisa dari',
    });
    return '$current$_temp0$available';
  }

  @override
  String get homeMainBudgetTitle => 'Anggaran bulan berjalan';

  @override
  String get homeMainChartAccountsTitle => 'Ringkasan Akun';

  @override
  String get homeMainChartCategoriesTitle =>
      'Ringkasan Kategori bulan berjalan';

  @override
  String get homeMainChartDailyAvg => 'Rata-rata 7 hari';

  @override
  String get homeMainChartDailyTitle => 'Ringkasan Harian';

  @override
  String get homeMainChartNetEarningsTitle => 'Pendapatan Bersih';

  @override
  String get homeMainChartNetWorthTitle => 'Kekayaan Bersih';

  @override
  String get homeMainChartTagsTitle => 'Ringkasan Tag untuk bulan ini';

  @override
  String get homePiggyAdjustDialogTitle => 'Simpan/Belanjakan Uang';

  @override
  String homePiggyDateStart(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Tanggal mulai: $dateString';
  }

  @override
  String homePiggyDateTarget(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Tanggal target: $dateString';
  }

  @override
  String get homeMainDialogSettingsTitle => 'Sesuaikan Dasbor';

  @override
  String homePiggyLinked(String account) {
    return 'Tautkan ke $account';
  }

  @override
  String get homePiggyNoAccounts => 'Tidak ada celengan yang tersiapkan.';

  @override
  String get homePiggyNoAccountsSubtitle => 'Buat beberapa pada antarmuka web!';

  @override
  String homePiggyRemaining(String amount) {
    return 'Tersisa untuk ditabung: $amount';
  }

  @override
  String homePiggySaved(String amount) {
    return 'Tertabung sejauh ini: $amount';
  }

  @override
  String get homePiggySavedMultiple => 'Tersimpan sejauh ini:';

  @override
  String homePiggyTarget(String amount) {
    return 'Jumlah target: $amount';
  }

  @override
  String get homePiggyAccountStatus => 'Status Akun';

  @override
  String get homePiggyAvailableAmounts => 'Jumlah Tersedia';

  @override
  String homePiggyAvailable(String amount) {
    return 'Tersedia: $amount';
  }

  @override
  String homePiggyInPiggyBanks(String amount) {
    return 'Di celengan: $amount';
  }

  @override
  String get homeTabLabelBalance => 'Neraca Keuangan';

  @override
  String get homeTabLabelMain => 'Utama';

  @override
  String get homeTabLabelPiggybanks => 'Celengan';

  @override
  String get homeTabLabelTransactions => 'Transaksi';

  @override
  String get homeTransactionsActionFilter => 'Filter Daftar';

  @override
  String get homeTransactionsDialogFilterAccountsAll => '<Semua Akun>';

  @override
  String get homeTransactionsDialogFilterBillsAll => '<Semua Tagihan>';

  @override
  String get homeTransactionsDialogFilterBillUnset =>
      '<Tidak ada Tagihan tersetel>';

  @override
  String get homeTransactionsDialogFilterBudgetsAll => '<Semua Anggaran>';

  @override
  String get homeTransactionsDialogFilterBudgetUnset =>
      '<Tidak ada Anggaran tersetel>';

  @override
  String get homeTransactionsDialogFilterCategoriesAll => '<Semua Kategori>';

  @override
  String get homeTransactionsDialogFilterCategoryUnset =>
      '<Tidak ada Kategori tersetel>';

  @override
  String get homeTransactionsDialogFilterCurrenciesAll => '<Semua Mata Uang>';

  @override
  String get homeTransactionsDialogFilterDateRange => 'Rentang Tanggal';

  @override
  String get homeTransactionsDialogFilterFutureTransactions =>
      'Tampilkan transaksi mendatang';

  @override
  String get homeTransactionsDialogFilterSearch => 'Istilah Pencarian';

  @override
  String get homeTransactionsDialogFilterTitle => 'Pilih filter';

  @override
  String get homeTransactionsEmpty => 'Tidak ada transaksi ditemukan.';

  @override
  String homeTransactionsMultipleCategories(int num) {
    return '$num kategori';
  }

  @override
  String get homeTransactionsSettingsShowTags =>
      'Tampilkan tag di daftar transaksi';

  @override
  String get liabilityDirectionCredit => 'Saya pemberi hutang ini';

  @override
  String get liabilityDirectionDebit => 'Saya berhutang hutang ini';

  @override
  String get liabilityTypeDebt => 'Hutang';

  @override
  String get liabilityTypeLoan => 'Pinjaman';

  @override
  String get liabilityTypeMortgage => 'Hipotek';

  @override
  String get loginAbout =>
      'Untuk menggunakan Waterfly III secara produktif anda memerlukan server sendiri dengan instansi Firefly III atau tambahan Firefly III untuk Home Assistant.\n\nSilahkan masukkan URL penuh serta token akses pribadi (Pengaturan -> Profil -> OAuth -> Token Akses Pribadi) di bawah.';

  @override
  String get loginFormLabelAPIKey => 'Kunci API Valid';

  @override
  String get loginFormLabelHost => 'URL Host';

  @override
  String get loginWelcome => 'Selamat Datang di Waterfly III';

  @override
  String get logoutConfirmation => 'Yakin ingin keluar?';

  @override
  String get navigationAccounts => 'Akun';

  @override
  String get navigationBills => 'Langganan';

  @override
  String get navigationCategories => 'Kategori';

  @override
  String get navigationMain => 'Dasbor Utama';

  @override
  String get generalSettings => 'Pengaturan';

  @override
  String get no => 'Tidak';

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

    return '$percString dari $of';
  }

  @override
  String get settingsDialogDebugInfo =>
      'Anda dapat mengaktifkan & mengirim log debug di sini. Akan berdampak buruk pada kinerja, mohon jangan diaktifkan kecuali anda disarankan. Menonaktifkan logging akan menghapus log yang tersimpan.';

  @override
  String get settingsDialogDebugMailCreate => 'Buat Surat';

  @override
  String get settingsDialogDebugMailDisclaimer =>
      'PERHATIAN: Draf surat akan terbuka dengan file log terlampir (dalam format teks). Log mungkin berisi informasi sensitif, seperti nama host instansi Firefly anda (walaupun saya mencoba menghindari pencatatan rahasia apapun, seperti kunci API). Harap baca log dengan cermat dan sensor informasi yang tidak ingin anda bagikan dan/atau tidak relevan dengan masalah yang ingin dilaporkan.\n\nMohon jangan mengirimkan log tanpa persetujuan awal via email/GitHub. Saya akan menghapus semua log yang dikirimkan tanpa konteks untuk alasan privasi. Jangan unggah log tanpa sensor ke GitHub atau manapun.';

  @override
  String get settingsDialogDebugSendButton => 'Kirim Log via Surat';

  @override
  String get settingsDialogDebugTitle => 'Log Debug';

  @override
  String get settingsDialogLanguageTitle => 'Pilih Bahasa';

  @override
  String get settingsDialogThemeTitle => 'Pilih Tema';

  @override
  String get settingsFAQ => 'FAQ';

  @override
  String get settingsFAQHelp =>
      'Dibuka di Peramban. Hanya tersedia dalam Bahasa Inggris.';

  @override
  String get settingsOfflineModeSubtitle =>
      'Configure offline sync and mobile data usage';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsLockscreen => 'Layar Kunci';

  @override
  String get settingsLockscreenHelp =>
      'Memerlukan autentikasi saat memulai aplikasi';

  @override
  String get settingsLockscreenInitial =>
      'Mohon autentikasi untuk mengaktifkan layar kunci.';

  @override
  String get settingsNLAppAccount => 'Akun Bawaan';

  @override
  String get settingsNLAppAccountDynamic => '<Dinamik>';

  @override
  String get settingsNLAppAdd => 'Tambahkan Aplikasi';

  @override
  String get settingsNLAppAddHelp =>
      'Klik untuk menambahkan aplikasi untuk didengarkan. Hanya aplikasi memenuhi syarat yang akan ditampilkan di daftar.';

  @override
  String get settingsNLAppAddInfo =>
      'Jadikan beberapa transaksi dimana anda menerima notifikasi untuk menambahkan aplikasi ke daftar ini. Jika aplikasi tidak muncul, silahkan laporkan ke app@vogt.pw.';

  @override
  String get settingsNLAutoAdd => 'Buat transaksi tanpa interaksi';

  @override
  String get settingsNLDescription =>
      'Layanan ini memungkinkan anda untuk mengambil detail transaksi dari notifikasi push yang masuk. Selain itu, anda dapat memilih akun bawaan dimana transaksi harus ditugaskan kepada - jika tidak ada nilai yang ditetapkan, akan mencoba untuk mengekstrak akun dari notifikasi.';

  @override
  String get settingsNLEmptyNote => 'Biarkan kolom catatan kosong';

  @override
  String get settingsNLPermissionGrant => 'Ketuk untuk memberikan izin.';

  @override
  String get settingsNLPermissionNotGranted => 'Izin tidak diberikan.';

  @override
  String get settingsNLPermissionRemove => 'Hapus izin?';

  @override
  String get settingsNLPermissionRemoveHelp =>
      'Untuk menonaktifkan layanan ini, klik pada aplikasi dan hapus izin di layar berikutnya.';

  @override
  String get settingsNLPrefillTXTitle =>
      'Isi otomatis judul transaksi dengan judul notifikasi';

  @override
  String get settingsNLServiceChecking => 'Memeriksa status…';

  @override
  String settingsNLServiceCheckingError(String error) {
    return 'Kesalahan saat memeriksa status: $error';
  }

  @override
  String get settingsNLServiceRunning => 'Layanan sedang berjalan.';

  @override
  String get settingsNLServiceStatus => 'Status Layanan';

  @override
  String get settingsNLServiceStopped => 'Layanan diberhentikan.';

  @override
  String get settingsNotificationListener => 'Layanan Pendengar Notifikasi';

  @override
  String get settingsTheme => 'Tema Aplikasi';

  @override
  String get settingsThemeDynamicColors => 'Warna Dinamis';

  @override
  String settingsThemeValue(String theme) {
    String _temp0 = intl.Intl.selectLogic(theme, {
      'dark': 'Mode Gelap',
      'light': 'Mode Terang',
      'other': 'Bawaan Sistem',
    });
    return '$_temp0';
  }

  @override
  String get settingsUseServerTimezone => 'Gunakan zona waktu server';

  @override
  String get settingsUseServerTimezoneHelp =>
      'Tampilkan semua waktu dalam zona waktu server. Ini meniru perilaku antarmuka web.';

  @override
  String get settingsVersion => 'Versi Aplikasi';

  @override
  String get settingsVersionChecking => 'memeriksa…';

  @override
  String get transactionAttachments => 'Lampiran';

  @override
  String get transactionDeleteConfirm => 'Yakin ingin menghapus transaksi ini?';

  @override
  String get transactionDialogAttachmentsDelete => 'Hapus Lampiran';

  @override
  String get transactionDialogAttachmentsDeleteConfirm =>
      'Yakin ingin menghapus lampiran ini?';

  @override
  String get transactionDialogAttachmentsErrorDownload =>
      'Tidak dapat mengunduh file.';

  @override
  String transactionDialogAttachmentsErrorOpen(String error) {
    return 'Tidak dapat membuka file: $error';
  }

  @override
  String transactionDialogAttachmentsErrorUpload(String error) {
    return 'Tidak dapat mengunggah file: $error';
  }

  @override
  String get transactionDialogAttachmentsTitle => 'Lampiran';

  @override
  String get transactionDialogBillNoBill => 'Tidak ada tagihan';

  @override
  String get transactionDialogBillTitle => 'Tautkan ke Tagihan';

  @override
  String get transactionDialogCurrencyTitle => 'Pilih mata uang';

  @override
  String get transactionDialogPiggyNoPiggy => 'No Piggy Bank';

  @override
  String get transactionDialogPiggyTitle => 'Link to Piggy Bank';

  @override
  String get transactionDialogTagsAdd => 'Tambahkan Label';

  @override
  String get transactionDialogTagsHint => 'Cari/Tambahkan Label';

  @override
  String get transactionDialogTagsTitle => 'Pilih label';

  @override
  String get transactionDuplicate => 'Duplikat';

  @override
  String get transactionErrorInvalidAccount => 'Akun tidak Valid';

  @override
  String get transactionErrorInvalidBudget => 'Anggaran tidak Valid';

  @override
  String get transactionErrorNoAccounts => 'Harap isi akun terlebih dahulu.';

  @override
  String get transactionErrorNoAssetAccount => 'Harap pilih akun aset.';

  @override
  String get transactionErrorTitle => 'Harap berikan judul.';

  @override
  String get transactionFormLabelAccountDestination => 'Akun tujuan';

  @override
  String get transactionFormLabelAccountForeign => 'Akun asing';

  @override
  String get transactionFormLabelAccountOwn => 'Akun sendiri';

  @override
  String get transactionFormLabelAccountSource => 'Akun asal';

  @override
  String get transactionFormLabelNotes => 'Catatan';

  @override
  String get transactionFormLabelTags => 'Label';

  @override
  String get transactionFormLabelTitle => 'Judul Transaksi';

  @override
  String get transactionSplitAdd => 'Tambah transaksi terpisah';

  @override
  String get transactionSplitChangeCurrency => 'Ubah Mata Uang Terpisah';

  @override
  String get transactionSplitChangeDestinationAccount =>
      'Ubah Akun Tujuan Pembagian';

  @override
  String get transactionSplitChangeSourceAccount =>
      'Ubah Akun Sumber Pembagian';

  @override
  String get transactionSplitChangeTarget =>
      'Ubah Akun Target Transaksi Terpisah';

  @override
  String get transactionSplitDelete => 'Hapus transaksi terpisah';

  @override
  String get transactionTitleAdd => 'Tambah Transaksi';

  @override
  String get transactionTitleDelete => 'Hapus Transaksi';

  @override
  String get transactionTitleEdit => 'Ubah Transaksi';

  @override
  String get transactionTypeDeposit => 'Setoran';

  @override
  String get transactionTypeTransfer => 'Transfer';

  @override
  String get transactionTypeWithdrawal => 'Penarikan';

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
