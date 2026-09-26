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

  static String questionCount(String n) => '$nটি প্রশ্ন';
  static String ayahCount(String n) => '$nটি আয়াত';
  static String ayatInSurah(String n) => '$n আয়াত';
}
