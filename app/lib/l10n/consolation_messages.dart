import 'dart:math';

/// Consolation messages displayed briefly after the user puts a worry away.
///
/// A random message is picked each time. The tone is calm, short,
/// and reassuring — never clinical, never cute (per SPEC.md §14).
class ConsolationMessages {
  static const List<String> _messagesEn = [
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

  static const List<String> _messagesNe = [
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

  static final _random = Random();

  /// Returns a random consolation message in the given locale.
  static String getRandom({String locale = 'en'}) {
    final messages = locale == 'ne' ? _messagesNe : _messagesEn;
    return messages[_random.nextInt(messages.length)];
  }
}
