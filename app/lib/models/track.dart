class Track {
  final String id;
  final String name;
  final String emoji;
  final String url;

  const Track({
    required this.id,
    required this.name,
    required this.emoji,
    required this.url,
  });

  static const List<Track> meditativeTracks = [
    Track(id: 't1', name: 'Gentle Rain + Felt Piano', emoji: '🌧️', url: 'audio/t1.wav'),
    Track(id: 't2', name: 'Ocean Waves + Ambient Pads', emoji: '🌊', url: 'audio/t2.wav'),
    Track(id: 't3', name: 'Forest Stream + Birds', emoji: '🌲', url: 'audio/t3.wav'),
    Track(id: 't4', name: 'Fireplace + Soft Wind', emoji: '🔥', url: 'audio/t4.wav'),
    Track(id: 't5', name: 'Minimal Piano (no rain)', emoji: '🎹', url: 'audio/t5.wav'),
    Track(id: 't6', name: 'Night Crickets + Breeze', emoji: '🌙', url: 'audio/t6.wav'),
    Track(id: 't7', name: 'Deep Ambient Drone', emoji: '☁️', url: 'audio/t7.wav'),
    Track(id: 't8', name: 'Brown Noise', emoji: '🤍', url: 'audio/t8.wav'),
    Track(id: 't9', name: 'Bamboo Flute + Water', emoji: '🌸', url: 'audio/t9.wav'),
    Track(id: 't10', name: 'White Noise for focus', emoji: '💤', url: 'audio/t10.wav'),
  ];
}
