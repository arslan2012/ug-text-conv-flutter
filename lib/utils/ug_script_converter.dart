String ugScriptConverter(String text,
    {String sourceScript = 'ULS', String targetScript = 'UAS'}) {
  Function? conversionMethod = conversionMethods[sourceScript]?[targetScript];

  if (conversionMethod != null) {
    return conversionMethod(text);
  } else if (sourceScript == targetScript) {
    return text;
  } else {
    throw Exception('Target script not supported');
  }
}

String replaceViaTable(String text, List<String> tab1, List<String> tab2) {
  for (int i = 0; i < tab1.length; i++) {
    text = text.replaceAll(tab1[i], tab2[i]);
  }
  return text;
}

String convertUAS2CTS(String text) {
  text = replaceViaTable(text, uasGroup, ctsGroup);
  text = reviseCTS(text);
  return text;
}

String reviseCTS(String text) {
  // Remove a "U+0626" if it is a beginning of a word
  text = text.replaceAllMapped(RegExp(r'(\s|^)(\u0626)(\w+)'),
      (match) => (match.group(1) ?? '') + (match.group(3) ?? ''));

  // Replace a "U+0626" with "'" if "U+0626" is appeared in a word and its previous character is not in
  // [u'a', u'e', u'é', u'i', u'o', u'u', u'ö', u'ü']
  text = text.replaceAllMapped(
      RegExp(r'(([aeéiouöü])\u0626)'), (match) => match.group(1)?[0] ?? '');

  text = text.replaceAll('\u0626', "'");
  return text;
}

String convertUCS2CTS(String text) {
  text = text.toLowerCase();
  text = replaceViaTable(text, ucsGroup, ctsGroup);
  text = text.replaceAll("я", "ya").replaceAll("ю", "y");
  return text;
}

String convertCTS2UAS(String text) {
  // Dart does not support lookbehind in regex directly, so the regex might need adjustments.

  // Add a "U+0626" before a vowel if it is the beginning of a word or after a vowel
  // for example
  // "ait" -> "U+0626aU+0626it" ئائىت
  // There is a special case cuñxua which should not be converted to cuñxu'a as it is written in UAS as جۇڭخۇا
  // We ignore this special case.
  text = text.replaceAllMapped(
      RegExp(r'(?<=[^bptcçxdrzjsşfñlmhvyqkgnğ]|^)[aeéiouöü]'),
      (Match m) => '\u0626${m[0]!}');

  text = replaceViaTable(text, ctsGroup, uasGroup);

  text = text.replaceAll("'\u0626", '');

  return text;
}

String convert(String text, Map<String, String> replacements) {
  RegExp regex = RegExp(replacements.keys.join('|'));
  return text.replaceAllMapped(
      regex, (match) => replacements[match.group(0)] ?? '');
}

String convertULS2CTS(String text) {
  Map<String, String> replacements = {
    'ng': 'ñ',
    "n'g": 'ng',
    "'ng": 'ñ',
    'ch': 'ç',
    'zh': 'j',
    'sh': 'ş',
    'w': 'v',
    'j': 'c',
    "'gh": 'ğ',
    'gh': 'ğ'
  };
  return convert(text, replacements);
}

String convertUYS2CTS(String text) {
  Map<String, String> replacements = {
    "ng": 'ñ',
    'ə': 'e',
    'ⱬ': 'j',
    'j': 'c',
    'ⱪ': 'q',
    'q': 'ç',
    'ⱨ': 'h',
    'h': 'x',
    'x': 'ş',
    'ø': 'ö',
    'w': 'v',
    'e': 'é',
    'ƣ': 'ğ'
  };
  return convert(text, replacements);
}

String convertCTS2Language(String text, String language) {
  Map<String, String>? replacements = replacementsMaps[language];
  if (replacements == null) {
    throw Exception('Unsupported language: $language');
  }

  return convert(text, replacements);
}

String convertCTS2UCS(String text) {
  text = text.toLowerCase();
  text = text.replaceAll("ya", "я").replaceAll("y", "ю");
  text = replaceViaTable(text, ctsGroup, ucsGroup);
  return text;
}

String convertFunc(
    String text, Function convertToCTS, Function convertFromCTS) {
  return convertFromCTS(convertToCTS(text));
}

Map<String, Map<String, Function>> conversionMethods = {
  'UAS': {
    'CTS': (text) => convertUAS2CTS(text),
    'UCS': (text) => convertFunc(text, convertUAS2CTS, convertCTS2UCS),
    'ULS': (text) => convertFunc(
        text, convertUAS2CTS, (text) => convertCTS2Language(text, 'ULS')),
    'UYS': (text) => convertFunc(
        text, convertUAS2CTS, (text) => convertCTS2Language(text, 'UYS')),
    'UZBEK': (text) => convertFunc(
        text, convertUAS2CTS, (text) => convertCTS2Language(text, 'UZBEK')),
  },
  'ULS': {
    'CTS': (text) => convertULS2CTS(text),
    'UCS': (text) => convertFunc(text, convertULS2CTS, convertCTS2UCS),
    'UAS': (text) => convertFunc(text, convertULS2CTS, convertCTS2UAS),
    'UYS': (text) => convertFunc(
        text, convertULS2CTS, (text) => convertCTS2Language(text, 'UYS')),
  },
  'UCS': {
    'CTS': (text) => convertUCS2CTS(text),
    'UAS': (text) => convertFunc(text, convertUCS2CTS, convertCTS2UAS),
    'ULS': (text) => convertFunc(
        text, convertUCS2CTS, (text) => convertCTS2Language(text, 'ULS')),
    'UYS': (text) => convertFunc(
        text, convertUCS2CTS, (text) => convertCTS2Language(text, 'UYS')),
  },
  'UYS': {
    'CTS': (text) => convertUYS2CTS(text),
    'UAS': (text) => convertFunc(text, convertUYS2CTS, convertCTS2UAS),
    'ULS': (text) => convertFunc(
        text, convertUYS2CTS, (text) => convertCTS2Language(text, 'ULS')),
    'UCS': (text) => convertFunc(text, convertUYS2CTS, convertCTS2UCS),
  },
  'CTS': {
    'UAS': (text) => convertCTS2UAS(text),
    'ULS': (text) => convertCTS2Language(text, 'ULS'),
    'UCS': (text) => convertCTS2UCS(text),
    'UYS': (text) => convertCTS2Language(text, 'UYS'),
  },
};

const replacementsMaps = {
  'ULS': {
    'ng': "n'g",
    'sh': "s'h",
    'ch': "c'h",
    'zh': "z'h",
    'gh': "g'h",
    'nğ': "n'gh",
    'ñ': "ng",
    'j': 'zh',
    'c': 'j',
    'ç': 'ch',
    'ş': 'sh',
    'ğ': "gh",
    'v': 'w',
  },
  'UYS': {
    'ñ': "n'g",
    'e': 'ə',
    'j': 'ⱬ',
    'c': 'j',
    'q': 'ⱪ',
    'ç': 'q',
    'h': 'ⱨ',
    'x': 'h',
    'ş': 'x',
    'ö': 'ø',
    'v': 'w',
    'é': 'e',
    'ğ': 'ƣ'
  },
  'UZBEK': {
    'ñ': "ng",
    'e': 'a',
    'c': 'j',
    'ç': 'ch',
    'ş': 'sh',
    'ö': 'oʻ',
    'é': 'e',
    'ğ': 'gʻ'
  }
};

const uasGroup = [
  'ا',
  'ە',
  'ب',
  'پ',
  'ت',
  'ج',
  'چ',
  'خ',
  'د',
  'ر',
  'ز',
  'ژ',
  'س',
  'ش',
  'ف',
  'ڭ',
  'ل',
  'لا',
  'م',
  'ھ',
  'و',
  'ۇ',
  'ۆ',
  'ۈ',
  'ۋ',
  'ې',
  'ى',
  'ي',
  'ق',
  'ك',
  'گ',
  'ن',
  'غ',
  '؟',
  '،',
  '؛',
  '٭'
];
const ctsGroup = [
  'a',
  'e',
  'b',
  'p',
  't',
  'c',
  'ç',
  'x',
  'd',
  'r',
  'z',
  'j',
  's',
  'ş',
  'f',
  'ñ',
  'l',
  'la',
  'm',
  'h',
  'o',
  'u',
  'ö',
  'ü',
  'v',
  'é',
  'i',
  'y',
  'q',
  'k',
  'g',
  'n',
  'ğ',
  '?',
  ',',
  ';',
  '*'
];
const ucsGroup = [
  'а',
  'ә',
  'б',
  'п',
  'т',
  'җ',
  'ч',
  'х',
  'д',
  'р',
  'з',
  'ж',
  'с',
  'ш',
  'ф',
  'ң',
  'л',
  'ла',
  'м',
  'һ',
  'о',
  'у',
  'ө',
  'ү',
  'в',
  'е',
  'и',
  'й',
  'қ',
  'к',
  'г',
  'н',
  'ғ',
  '?',
  ',',
  ';',
  '*'
];
