import 'dart:math';

/// Context-aware consolation messages.
///
/// Analyzes the user's worry text for keywords and returns
/// a relevant, personalized consolation message.
/// Falls back to a generic calming message if no keywords match.
class ConsolationMessages {
  static final _random = Random();

  /// Keyword → contextual messages mapping (English).
  static const Map<String, List<String>> _contextEn = {
    // Work & career
    'work|job|boss|office|deadline|meeting|colleague|fired|promotion|salary': [
      "Work will still be there. Give your mind a break.",
      "You can't solve it all in one shift. Rest now.",
      "Even the toughest days at work end. This one will too.",
      "Step away from work thoughts. They'll be clearer later.",
    ],
    // Exams & studies
    'exam|test|study|grade|fail|school|college|university|homework|assignment|marks': [
      "You've prepared more than you think. Let it rest.",
      "One exam doesn't define you. Breathe.",
      "Your brain works better after a break. Trust the process.",
      "Worrying won't add marks. Resting might.",
    ],
    // Money & finance
    'money|rent|bill|debt|loan|payment|expense|broke|afford|salary|financial': [
      "Financial worries feel heavy. You've acknowledged it — that's a step.",
      "Money problems are solvable. Not right now, but they are.",
      "You're not your bank balance. Let this thought rest.",
      "One bill at a time. You don't need to solve it all now.",
    ],
    // Relationships & family
    'relationship|partner|boyfriend|girlfriend|husband|wife|marriage|breakup|love|dating': [
      "Hearts need space to heal. Give yours some.",
      "Relationships are complex. You don't need the answer right now.",
      "What's meant for you won't pass you by. Rest easy.",
      "Love takes time. So does understanding. Both can wait.",
    ],
    'family|parent|mother|father|mom|dad|brother|sister|son|daughter|child': [
      "Family bonds are strong. This moment will pass.",
      "They care about you too. Give it time.",
      "You can't carry everyone's weight. Set it down for now.",
      "Home troubles feel big. They often look smaller with time.",
    ],
    // Health & body
    'health|sick|doctor|hospital|pain|disease|illness|medicine|symptom|surgery|anxiety|depression': [
      "Your health matters. So does your peace of mind right now.",
      "Worrying doesn't heal — resting does. Let it go for now.",
      "You're doing the right thing by paying attention. Now breathe.",
      "One step at a time. You don't need all the answers today.",
    ],
    // Future & uncertainty
    'future|tomorrow|plan|career|life|decision|choice|uncertain|scared|afraid|worry|anxious': [
      "The future isn't here yet. Right now, you're okay.",
      "Uncertainty is uncomfortable, not dangerous. You're safe right now.",
      "You don't need to figure out everything today.",
      "The best decisions come from a calm mind. Let it settle.",
    ],
    // Sleep & rest
    'sleep|insomnia|tired|exhausted|rest|night|nightmare|awake': [
      "Put this down. Your pillow is waiting.",
      "Thoughts feel louder at night. They'll be quieter tomorrow.",
      "Your mind deserves rest as much as your body does.",
      "Tomorrow is a fresh start. Let tonight be peaceful.",
    ],
    // Loneliness & social
    'lonely|alone|friend|social|nobody|isolated|left out|ignored': [
      "Feeling alone is temporary. You're not forgotten.",
      "Sometimes solitude is healing. Let it be.",
      "The right people will find you. Give it time.",
      "You reached out to this box. That takes courage.",
    ],
  };

  /// Keyword → contextual messages mapping (Nepali).
  static const Map<String, List<String>> _contextNe = {
    'work|job|boss|office|deadline|meeting|काम|कार्यालय': [
      "काम त रहिरहन्छ। अहिले आफ्नो मनलाई आराम दिनुहोस्।",
      "एकै दिनमा सबै समाधान हुँदैन। अहिले विश्राम गर्नुहोस्।",
      "कठिन दिनहरू पनि सकिन्छन्। यो पनि सकिन्छ।",
    ],
    'exam|test|study|grade|परीक्षा|पढाइ|नम्बर': [
      "तपाईंले सोचेभन्दा धेरै तयारी गर्नुभएको छ। आराम गर्नुहोस्।",
      "एउटा परीक्षाले तपाईंलाई परिभाषित गर्दैन।",
      "दिमागलाई आराम दिनुहोस् — यो राम्रो काम गर्नेछ।",
    ],
    'money|rent|bill|debt|पैसा|ऋण|बिल|तलब': [
      "आर्थिक चिन्ता गह्रौं हुन्छ। तपाईंले स्वीकार गर्नुभयो — त्यो पहिलो कदम हो।",
      "पैसाको समस्या समाधान हुन्छ। अहिले होइन, तर हुन्छ।",
      "एउटा एउटा गरेर हल गर्नुहोस्। अहिले सबै सोच्नु पर्दैन।",
    ],
    'relationship|partner|love|breakup|सम्बन्ध|माया|प्रेम': [
      "मनलाई निको हुन समय चाहिन्छ। आफ्नो मनलाई समय दिनुहोस्।",
      "सम्बन्ध जटिल हुन्छन्। अहिले जवाफ चाहिँदैन।",
      "मायाले समय लिन्छ। बुझ्नले पनि। दुवै पर्खन सक्छन्।",
    ],
    'family|parent|mother|father|परिवार|बुवा|आमा|दाइ|दिदी': [
      "परिवारको बन्धन बलियो हुन्छ। यो समय बित्नेछ।",
      "तिनीहरू पनि तपाईंको ख्याल गर्छन्। समय दिनुहोस्।",
      "सबैको भार तपाईंले बोक्नु पर्दैन। अहिले राख्नुहोस्।",
    ],
    'health|sick|doctor|pain|स्वास्थ्य|बिरामी|डाक्टर|दुखाइ|चिन्ता': [
      "तपाईंको स्वास्थ्य महत्त्वपूर्ण छ। अहिले मनको शान्ति पनि।",
      "चिन्ता गर्दैमा निको हुँदैन — आराम गर्दा हुन्छ।",
      "एक कदम एक कदम। आज सबै जवाफ चाहिँदैन।",
    ],
    'future|tomorrow|plan|career|भविष्य|भोलि|जीवन|डर': [
      "भविष्य अझै आएको छैन। अहिले तपाईं ठीक हुनुहुन्छ।",
      "अनिश्चितता असहज हुन्छ, खतरनाक होइन।",
      "आज सबै कुरा पत्ता लगाउनु पर्दैन।",
    ],
    'sleep|tired|exhausted|insomnia|निद्रा|थकान|रात': [
      "यो विचार राख्नुहोस्। तपाईंको सिरानी पर्खिरहेको छ।",
      "रातमा विचारहरू ठूला लाग्छन्। भोलि सानो हुन्छन्।",
      "भोलि नयाँ सुरुवात हो। आजको रात शान्त होस्।",
    ],
    'lonely|alone|friend|एक्लो|साथी|एकान्त': [
      "एक्लो महसुस गर्नु अस्थायी हो। तपाईं बिर्सिनुभएको छैन।",
      "कहिलेकाहीं एकान्त निको पार्छ।",
      "तपाईंले यो बाकसमा भन्नुभयो। त्यो हिम्मत हो।",
    ],
  };

  /// Generic fallback messages (English).
  static const List<String> _fallbackEn = [
    "That's safely put away.",
    "It's okay to feel this way.",
    "You've handled it for now.",
    "One less thing on your mind.",
    "You can come back to it later.",
    "It's safe in the box.",
    "Well done — let it rest.",
    "Breathe. It can wait.",
    "You don't have to solve it now.",
    "It's noted. Now it can rest.",
  ];

  /// Generic fallback messages (Nepali).
  static const List<String> _fallbackNe = [
    "त्यो सुरक्षित रूपमा राखिएको छ।",
    "यस्तो महसुस गर्नु ठीक छ।",
    "तपाईंले अहिलेलाई सम्हाल्नुभयो।",
    "मनमा एउटा कुरा कम भयो।",
    "तपाईं पछि फर्कन सक्नुहुन्छ।",
    "यो बाकसमा सुरक्षित छ।",
    "राम्रो गर्नुभयो — अब आराम गर्नुहोस्।",
    "सास फेर्नुहोस्। यो पर्खन सक्छ।",
    "अहिले समाधान गर्नुपर्दैन।",
    "नोट गरिएको छ। अब यसलाई आराम दिनुहोस्।",
  ];

  /// Returns a consolation message based on the worry text.
  ///
  /// Scans the text for keywords and returns a contextual message.
  /// Falls back to a generic message if no keywords match.
  static String getForWorry(String worryText, {String locale = 'en'}) {
    final lowerText = worryText.toLowerCase();
    final contextMap = locale == 'ne' ? _contextNe : _contextEn;

    for (final entry in contextMap.entries) {
      final keywords = entry.key.split('|');
      for (final keyword in keywords) {
        if (lowerText.contains(keyword.toLowerCase())) {
          final messages = entry.value;
          return messages[_random.nextInt(messages.length)];
        }
      }
    }

    // No keyword matched — return generic fallback
    final fallback = locale == 'ne' ? _fallbackNe : _fallbackEn;
    return fallback[_random.nextInt(fallback.length)];
  }

  /// Returns a random generic message (for non-text contexts).
  static String getRandom({String locale = 'en'}) {
    final fallback = locale == 'ne' ? _fallbackNe : _fallbackEn;
    return fallback[_random.nextInt(fallback.length)];
  }

  /// Returns a specific fallback message by index (for testing).
  static String getByIndex(int index, {String locale = 'en'}) {
    final fallback = locale == 'ne' ? _fallbackNe : _fallbackEn;
    return fallback[index % fallback.length];
  }

  /// Returns the total count of fallback messages for a locale.
  static int count({String locale = 'en'}) {
    return locale == 'ne' ? _fallbackNe.length : _fallbackEn.length;
  }
}
