/// Stable, offline identifiers. Unknown stored IDs fall back without losing data.
const highlightIllustrationLabels = <String, String>{
  'celebration': 'Celebration',
  'driving': 'Driving',
  'award': 'Award',
  'cooking': 'Cooking',
  'travel': 'Travel',
  'fitness': 'Fitness',
  'learning': 'Learning',
  'health': 'Health',
  'work': 'Work',
  'home': 'Home',
  'people': 'People',
  'creative': 'Creativity',
  'life': 'Sunrise',
};

// Ordered categories, whole words, case insensitive. No network or inference.
const _keywords = <String, Set<String>>{
  'driving': {'driving', 'drive', 'licence', 'license', 'car'},
  'award': {
    'certification',
    'certificate',
    'exam',
    'qualification',
    'graduation',
  },
  'cooking': {'cooking', 'cook', 'cooked', 'recipe', 'meal', 'baking'},
  'travel': {'travel', 'trip', 'flight', 'holiday', 'vacation'},
  'fitness': {'fitness', 'gym', 'strength', 'workout', 'marathon'},
};

String resolveHighlightIllustration({
  required String title,
  String? explicitIcon,
  String? areaIcon,
}) {
  if (highlightIllustrationLabels.containsKey(explicitIcon)) {
    return explicitIcon!;
  }
  final words = RegExp(r'[a-z]+')
      .allMatches(title.toLowerCase())
      .map((match) => match.group(0)!)
      .toSet();
  for (final category in _keywords.entries) {
    if (category.value.any(words.contains)) return category.key;
  }
  return highlightIllustrationLabels.containsKey(areaIcon)
      ? areaIcon!
      : 'celebration';
}
