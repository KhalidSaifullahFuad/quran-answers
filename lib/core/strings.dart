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
  static const compiledAnswer = 'সংকলিত উত্তর';
  static const evidence = 'প্রমাণ';
  static const quranEvidence = 'কুরআনের প্রমাণ';
  static const citedPositions = 'উদ্ধৃত আয়াতের অবস্থান';
  static const relatedQuestions = 'সম্পর্কিত প্রশ্ন';
  static const back = 'ফিরে যান';
  static const bookmark = 'সংরক্ষণ';
  static const bookmarked = 'প্রশ্নটি সংরক্ষিত হয়েছে';
  static const unbookmarked = 'সংরক্ষিত তালিকা থেকে সরানো হয়েছে';
  static const notFound = 'প্রশ্নটি পাওয়া যায়নি';
  static const loadFailed = 'তথ্য খোলা যায়নি';

  static const navHome = 'হোম';
  static const navTopics = 'বিষয়';
  static const navSurahs = 'সূরা';
  static const navSaved = 'সংরক্ষিত';

  static const surahsTitle = 'সূরা থেকে প্রশ্ন';
  static const surahsIntro =
      'যে সূরার আয়াত কোনো প্রশ্নের প্রমাণ হিসেবে এসেছে, সেগুলো এখানে।';
  static const surahQuestionsNote = 'এই সূরার আয়াত যেসব প্রশ্নের প্রমাণ';
  static const makki = 'মাক্কী';
  static const madani = 'মাদানী';
  static const readingHistory = 'পড়ার ইতিহাস';
  static const savedEmpty =
      'প্রশ্নের পাতায় বুকমার্ক চিহ্নে চাপ দিলে এখানে জমা হবে।';
  static const historyEmpty = 'এখনো কোনো প্রশ্ন পড়া হয়নি।';

  static const searchPrompt =
      'প্রশ্নের শব্দ, আরবি বা বাংলা শব্দ, অথবা আয়াত নম্বর (৫৪:১৫) লিখুন।';
  static const noResults = 'কিছু পাওয়া যায়নি।';
  static const clearSearch = 'মুছুন';
  static const searchQuestions = 'প্রশ্ন';
  static const searchAyat = 'আয়াত';
  static const citingThisAyah = 'এই আয়াত যেসব প্রশ্নের প্রমাণ';

  static String questionCount(String n) => '$nটি প্রশ্ন';
  static String ayahCount(String n) => '$nটি আয়াত';
  static String ayatInSurah(String n) => '$n আয়াত';
  static String noSuchAyah(String surah, String ayah) =>
      'সূরা $surah-এ $ayah নম্বর আয়াত নেই।';
  static String firstOfTotal(String shown, String total) =>
      'মোট $totalটি আয়াতের প্রথম $shownটি দেখানো হলো। আরও নির্দিষ্ট করে লিখুন।';
}
