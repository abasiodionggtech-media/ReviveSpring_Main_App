class AppStrings {
  const AppStrings._();

  static String of(String language, String en, String fr) =>
      language == 'fr' ? fr : en;
}
