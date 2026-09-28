/// Validations de formulaire partagées par les écrans
class Validators {
  // Assez permissif pour les domaines récents (.africa, .agency…) ;
  // la vérification réelle se fait par l'email de confirmation.
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());

  /// Validateur prêt à l'emploi pour un TextFormField
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer votre email';
    }
    if (!isValidEmail(value)) return 'Email invalide';
    return null;
  }

  Validators._();
}
