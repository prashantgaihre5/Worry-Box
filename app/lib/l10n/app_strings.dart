/// English and Nepali UI string translations.
///
/// All user-facing copy is centralized here so that the language
/// toggle can switch everything in one place.
/// Copy reference follows SPEC.md §14.
class AppStrings {
  // ── English ───────────────────────────────
  static const Map<String, dynamic> en = {
    'appTitle': 'Project Abhaya',
    'subtitle': 'Write it down. Put it away. Come back to it later.',
    'placeholder': "What's on your mind?",
    'submitButton': 'Put it away',
    'captureHelper': 'Opens at {time}',
    'lockedHeadline': 'Your thoughts are safe.', // fallback
    'lockedHeadlines': [
      'Your thoughts are safe.',
      'Stored away so you can focus on now.',
      'Let it rest until the time is right.',
      'Your worries are secure for now.',
      'Out of sight, out of mind.',
      'A safe place for heavy thoughts.',
      'Take a deep breath. We have got this.',
    ],
    'lockedCountdown': 'Opens in {time}',
    'lockedCount': '{count} worries put away',
    'lockedCountSingular': '1 worry put away',
    'lockedSubInput': 'Something else? Put it away too.',
    'revealHeadline': 'The box is open.',
    'revealSub': 'Read these back. Many will feel smaller now.',
    'releaseButton': 'Let go',
    'keepButton': 'Keep',
    'emptyReveal': 'All clear.',
    'newWorryButton': 'Write a new worry',
    'storageWarning': "Your worries won't be saved after you close this app.",
    'safetyLine':
        'Worry Box is a self-help tool, not a substitute for professional care.\nIf you are in crisis, contact your local emergency services or a crisis helpline.',
    'playAudio': 'Play calming audio',
    'stopAudio': 'Stop audio',
    'languageToggle': 'नेपाली',
    'devModeBadge': 'dev mode',
    'putAwayAgo': 'put away {time} ago',
    'justNow': 'put away just now',
    'analytics': 'Analytics',
    'analyticsSub': 'Your journey in numbers.',
    'totalCaptured': 'Total Captured',
    'totalLetGo': 'Total Let Go',
    'totalKept': 'Currently Kept',
  };

  // ── Nepali ────────────────────────────────
  static const Map<String, dynamic> ne = {
    'appTitle': 'प्रोजेक्ट अभय',
    'subtitle': 'लेख्नुहोस्। राख्नुहोस्। पछि फर्कनुहोस्।',
    'placeholder': 'तपाईंको मनमा के छ?',
    'submitButton': 'राखिदिनुहोस्',
    'captureHelper': '{time} मा खुल्छ',
    'lockedHeadline': 'तपाईंका विचारहरू सुरक्षित छन्।', // fallback
    'lockedHeadlines': [
      'तपाईंका विचारहरू सुरक्षित छन्।',
      'अहिलेको समयमा ध्यान केन्द्रित गर्न यसलाई टाढा राखिएको छ।',
      'सही समय नआएसम्म यसलाई आराम दिनुहोस्।',
      'तपाईंका चिन्ताहरू अहिलेको लागि सुरक्षित छन्।',
      'आँखाबाट टाढा, मनबाट टाढा।',
      'भारी विचारहरूको लागि एक सुरक्षित ठाउँ।',
      'लामो सास फेर्नुहोस्। हामी यो सम्हाल्न सक्छौं।',
    ],
    'lockedCountdown': '{time} मा खुल्छ',
    'lockedCount': '{count} चिन्ताहरू राखिएका छन्',
    'lockedCountSingular': '१ चिन्ता राखिएको छ',
    'lockedSubInput': 'अरू केही? त्यो पनि राख्नुहोस्।',
    'revealHeadline': 'बाकस खुलेको छ।',
    'revealSub': 'यी फेरि पढ्नुहोस्। धेरैजसो अहिले सानो लाग्नेछ।',
    'releaseButton': 'छोडिदिनुहोस्',
    'keepButton': 'राख्नुहोस्',
    'emptyReveal': 'सबै सफा।',
    'newWorryButton': 'नयाँ चिन्ता लेख्नुहोस्',
    'storageWarning': 'यो एप बन्द गरेपछि तपाईंका चिन्ताहरू सुरक्षित हुनेछैनन्।',
    'safetyLine':
        'चिन्ता बाकस एक स्व-सहायता उपकरण हो, व्यावसायिक हेरचाहको विकल्प होइन।\nसंकटमा हुनुहुन्छ भने, आफ्नो स्थानीय आपतकालीन सेवा वा क्राइसिस हेल्पलाइनमा सम्पर्क गर्नुहोस्।',
    'playAudio': 'शान्त संगीत बजाउनुहोस्',
    'stopAudio': 'संगीत बन्द गर्नुहोस्',
    'languageToggle': 'English',
    'devModeBadge': 'dev mode',
    'putAwayAgo': '{time} अघि राखिएको',
    'justNow': 'भर्खरै राखिएको',
    'analytics': 'विश्लेषण',
    'analyticsSub': 'अङ्कहरूमा तपाईंको यात्रा।',
    'totalCaptured': 'कुल लेखिएको',
    'totalLetGo': 'कुल हटाइएको',
    'totalKept': 'हाल राखिएको',
  };

  /// Retrieves a localized string by key.
  /// Falls back to English if the key is not found.
  static String get(String key, {String locale = 'en'}) {
    final map = locale == 'ne' ? ne : en;
    return (map[key] as String?) ?? en[key] as String? ?? key;
  }

  static String getHeadline(int index, {String locale = 'en'}) {
    final map = locale == 'ne' ? ne : en;
    final fallbackMap = en;
    final list = (map['lockedHeadlines'] as List<String>?) ?? (fallbackMap['lockedHeadlines'] as List<String>);
    return list[index % list.length];
  }

  /// Retrieves a localized string with placeholder replacement.
  /// Usage: AppStrings.format('captureHelper', {'time': '6:00 PM'}, locale: 'ne')
  static String format(String key, Map<String, String> params,
      {String locale = 'en'}) {
    var result = get(key, locale: locale);
    params.forEach((placeholder, value) {
      result = result.replaceAll('{$placeholder}', value);
    });
    return result;
  }
}
