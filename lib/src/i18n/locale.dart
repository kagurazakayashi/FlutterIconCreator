enum SupportedLocale { zhCN, zhTW, en, ja }

SupportedLocale localeFromString(String s) {
  final normalized = s.replaceAll('-', '_').toLowerCase();
  if (normalized.startsWith('zh_hant') || normalized.startsWith('zh_tw')) {
    return SupportedLocale.zhTW;
  }
  if (normalized.startsWith('zh')) {
    return SupportedLocale.zhCN;
  }
  if (normalized.startsWith('ja')) {
    return SupportedLocale.ja;
  }
  return SupportedLocale.en;
}

String localeToCode(SupportedLocale locale) {
  switch (locale) {
    case SupportedLocale.zhCN:
      return 'zh_CN';
    case SupportedLocale.zhTW:
      return 'zh_TW';
    case SupportedLocale.en:
      return 'en';
    case SupportedLocale.ja:
      return 'ja';
  }
}
