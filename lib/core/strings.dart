/// Interface labels.
///
/// Only chrome lives here — section headings, button labels, messages. Every
/// question, answer, verse and translation comes from the content database;
/// none of it may ever be written into the code.
abstract final class Strings {
  static const appName = 'Quran Answers';
  static const wordmark = 'QURAN ANSWERS';
  static const tagline = 'প্রতিটি প্রশ্নের উত্তর, কুরআনের আয়াত থেকে';
  static const searchHint = 'প্রশ্ন, শব্দ বা আয়াত (৯:৩৬)';
  static const questionOfTheDay = 'আজকের প্রশ্ন';
  static const answerAndEvidence = 'উত্তর ও প্রমাণ';
  static const lastRead = 'সর্বশেষ পড়া';
  static const topics = 'বিষয়';
  static const allQuestions = 'সব প্রশ্ন';
  static const seeAll = 'সব দেখুন';
  static const startReading = 'পড়ে দেখুন';
  static const allTopics = 'সব বিষয়';
  static const all = 'সব';
  static const nextQuestion = 'পরের প্রশ্ন';
  static const share = 'শেয়ার করুন';
  static const copyAyah = 'আয়াত কপি করুন';
  static const copied = 'কপি হয়েছে';
  static const compiledAnswer = 'সংকলিত উত্তর';
  static const evidence = 'প্রমাণ';
  static const quranEvidence = 'কুরআনের প্রমাণ';
  static const relatedQuestions = 'সম্পর্কিত প্রশ্ন';
  static const back = 'ফিরে যান';
  static const bookmark = 'সংরক্ষণ';
  static const bookmarked = 'প্রশ্ন সংরক্ষিত';
  static const unbookmarked = 'সংরক্ষণ থেকে সরানো হলো';
  static const undo = 'ফিরিয়ে আনুন';
  static const folderAction = 'ফোল্ডার';
  static const notFound = 'প্রশ্নটি পাওয়া যায়নি';
  static const loadFailed = 'তথ্য খোলা যায়নি';

  static const navHome = 'হোম';
  static const navQuestions = 'প্রশ্ন';
  static const navTopics = 'বিষয়';
  static const navSurahs = 'সূরা';
  static const navSaved = 'সংরক্ষিত';

  static const surahsTitle = 'সূরা থেকে প্রশ্ন';
  static const surahsIntro =
      'যে সূরার আয়াত কোনো প্রশ্নের প্রমাণ হিসেবে এসেছে, সেগুলো এখানে।';
  static const surahQuestionsNote = 'এই সূরার আয়াত যেসব প্রশ্নের প্রমাণ';
  static const makki = 'মাক্কী';
  static const madani = 'মাদানী';
  static const sortByNumber = 'সূরার ক্রমে';
  static const sortByCount = 'বেশি প্রশ্ন আগে';
  static const readingHistory = 'পড়ার ইতিহাস';
  static const savedEmpty =
      'প্রশ্নের পাতায় বুকমার্ক চিহ্নে চাপ দিলে এখানে জমা হবে।';
  static const historyEmpty = 'এখনো কোনো প্রশ্ন পড়া হয়নি।';
  static const savedQuestions = 'সংরক্ষিত প্রশ্ন';
  static const savedAyat = 'সংরক্ষিত আয়াত';
  static const savedAyatEmpty =
      'আয়াতের কার্ডে বুকমার্ক চিহ্নে চাপ দিলে এখানে জমা হবে।';
  static const folderEmpty = 'এই ফোল্ডারে এখনো কিছু রাখা হয়নি।';
  static const bookmarkAyah = 'আয়াত সংরক্ষণ';
  static const ayahBookmarked = 'আয়াত সংরক্ষিত';
  static const nothingSaved =
      'এখনো কিছু সংরক্ষণ করা হয়নি। প্রশ্নের পাতায় বা আয়াতের কার্ডে '
      'বুকমার্ক চিহ্নে চাপ দিলে এখানে জমা হবে।';
  static const manageFolders = 'ফোল্ডার সাজান';
  static const allFolders = 'সব';
  static const newFolder = 'নতুন ফোল্ডার';
  static const folderName = 'ফোল্ডারের নাম';
  static const moveToFolder = 'ফোল্ডারে রাখুন';
  static const noFolder = 'কোনো ফোল্ডারে নয়';
  static const renameFolder = 'নাম বদলান';
  static const deleteFolder = 'ফোল্ডার মুছুন';
  static const clearHistory = 'ইতিহাস মুছুন';
  static const clearHistoryConfirm =
      'পড়ার ইতিহাস মুছে ফেলবেন? সংরক্ষিত প্রশ্ন ও আয়াত থাকবে।';
  static const cancel = 'বাতিল';
  static const save = 'রাখুন';
  static const delete = 'মুছুন';

  static const searchPrompt =
      'প্রশ্নের শব্দ, আরবি বা বাংলা শব্দ, অথবা আয়াত নম্বর (৫৪:১৫) লিখুন।';
  static const noResults = 'কিছু পাওয়া যায়নি।';
  static const filterQuestionsHint = 'প্রশ্ন বা উত্তরের শব্দ';
  static const searchWholeQuran = 'পুরো কুরআনে খুঁজুন';
  static const clearSearch = 'মুছুন';
  static const searchQuestions = 'প্রশ্ন';
  static const searchAyat = 'আয়াত';
  static const searchExamplesLabel = 'যেমন';

  /// Tapped into the search field from its empty state. Bengali and a
  /// reference only: Arabic is never written into the code.
  static const searchExamples = ['৫৪:১৫', 'নূহ', 'সালাত', 'মারইয়াম'];
  static const citingThisAyah = 'এই আয়াত যেসব প্রশ্নের প্রমাণ';

  static const previousAyah = 'আগের আয়াত';
  static const nextAyah = 'পরের আয়াত';
  static const notCitedYet = 'এই আয়াত এখনো কোনো প্রশ্নের প্রমাণ হিসেবে আসেনি।';

  static const settings = 'সেটিংস';
  static const appearance = 'থিম';
  static const themeSystem = 'ফোনের মতো';
  static const themeLight = 'হালকা';
  static const themeDark = 'গাঢ়';
  static const arabicSize = 'আরবি লেখার আকার';
  static const bengaliSize = 'বাংলা লেখার আকার';

  /// Shown small and large at the ends of a text-size slider.
  static const sizeSample = 'অ';

  static const about = 'পরিচিতি ও কৃতজ্ঞতা';
  static const licenses = 'লাইসেন্স';
  static const quranTextTitle = 'কুরআনের পাঠ';
  static const quranTextSource =
      'আরবি পাঠ (উসমানী লিপি) ও বাংলা অনুবাদ Quran.com থেকে একবার সংগ্রহ করে '
      'অ্যাপের সাথেই দেওয়া হয়েছে। অ্যাপ ইন্টারনেট ব্যবহার করে না।';
  static const translationTitle = 'বাংলা অনুবাদ';
  static const fontsTitle = 'ফন্ট';
  static const privacyTitle = 'গোপনীয়তা';
  static const privacyNote =
      'কোনো অ্যাকাউন্ট, বিজ্ঞাপন বা ট্র্যাকিং নেই। সংরক্ষিত প্রশ্ন, আয়াত ও '
      'পড়ার ইতিহাস শুধু এই ফোনেই থাকে।';
  static const contentTitle = 'বিষয়বস্তু';

  static const methodology = 'উত্তর কীভাবে সংকলিত';
  static const methodologyPoints = [
    'প্রতিটি উত্তরের ভিত্তি কেবল কুরআনের আয়াত। উত্তরের নিচে যে আয়াতগুলো '
        'প্রমাণ হিসেবে দেওয়া আছে, উত্তর সেগুলো থেকেই সংকলিত।',
    'আয়াতের আরবি পাঠ ও অনুবাদ হাতে লেখা নয়; আয়াত নম্বর ধরে সরাসরি মুসহাফ '
        'থেকে নেওয়া, যাতে কোনো ভুল অক্ষর ঢুকে না পড়ে।',
    'প্রমাণের আয়াত কখনো কেটে ছোট করা হয় না। পুরো আয়াত দেখানো হয়, আর '
        'আয়াতের পাতায় আগে-পরের আয়াতও পড়া যায়।',
    'সংকলিত উত্তর মানুষের লেখা সারসংক্ষেপ, কুরআনের পাঠ নয়। কোথাও অমিল মনে '
        'হলে আয়াতকেই প্রাধান্য দিন।',
    'কোনো কৃত্রিম বুদ্ধিমত্তা (AI) উত্তর তৈরি করে না।',
  ];

  static String questionCount(String n) => '$nটি প্রশ্ন';
  static String ayahCount(String n) => '$nটি আয়াত';
  static String ayatInSurah(String n) => '$n আয়াত';
  static String deleteFolderConfirm(String name) =>
      '“$name” ফোল্ডারটি মুছে ফেলবেন? ভেতরের প্রশ্ন ও আয়াত সংরক্ষিতই থাকবে, '
      'শুধু ফোল্ডারের বাইরে চলে যাবে।';
  static String noSuchAyah(String surah, String ayah) =>
      'সূরা $surah-এ $ayah নম্বর আয়াত নেই।';
  static String contentSummary(String version, String questions, String ayat) =>
      'সংস্করণ $version · $questionsটি প্রশ্ন · $ayatটি আয়াত';
  static String firstOfTotal(String shown, String total) =>
      'মোট $totalটি আয়াতের প্রথম $shownটি দেখানো হলো। আরও নির্দিষ্ট করে লিখুন।';
}
