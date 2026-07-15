import 'package:google_fonts/google_fonts.dart';

/// A single selectable font option. `googleFontsName` must exactly match
/// the family name Google Fonts uses (and what `GoogleFonts.getFont` /
/// `GoogleFonts.getTextTheme` expect) so the same string can be sent to
/// the backend, stored locally, and used to fetch the font itself.
class AppFontOption {
  const AppFontOption({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id; // exact Google Fonts family name
  final String label; // shown in the picker
  final String description; // one-line style note shown under the label
}

/// The curated set of fonts users can choose from. Kept deliberately small
/// (rather than exposing all ~1,500 Google Fonts) so every option has been
/// checked for readability and fits the app's calm, devotional tone.
const List<AppFontOption> availableFonts = [
  AppFontOption(id: 'Inter', label: 'Inter', description: 'Clean & modern (default)'),
  AppFontOption(id: 'Poppins', label: 'Poppins', description: 'Friendly & geometric'),
  AppFontOption(id: 'Nunito', label: 'Nunito', description: 'Soft & rounded'),
  AppFontOption(id: 'Merriweather', label: 'Merriweather', description: 'Classic serif, book-like'),
  AppFontOption(id: 'Lora', label: 'Lora', description: 'Warm serif, easy reading'),
  AppFontOption(id: 'Playfair Display', label: 'Playfair Display', description: 'Elegant, editorial'),
  AppFontOption(id: 'Quicksand', label: 'Quicksand', description: 'Light & airy'),
  AppFontOption(id: 'Source Sans 3', label: 'Source Sans', description: 'Neutral & professional'),
  AppFontOption(id: 'Crimson Text', label: 'Crimson Text', description: 'Traditional, literary'),
  AppFontOption(id: 'Comfortaa', label: 'Comfortaa', description: 'Rounded & gentle'),
];

const List<double> availableFontScales = [0.85, 0.9, 1.0, 1.1, 1.2, 1.3];

bool isKnownFont(String family) => availableFonts.any((f) => f.id == family);

/// Builds a full TextTheme in the requested Google Font, gracefully
/// falling back to Inter if an unrecognized family name ever shows up
/// (e.g. an older cached preference that predates a catalogue change).
TextTheme buildAppTextTheme(String fontFamily, TextTheme base) {
  final family = isKnownFont(fontFamily) ? fontFamily : 'Inter';
  return GoogleFonts.getTextTheme(family, base);
}
