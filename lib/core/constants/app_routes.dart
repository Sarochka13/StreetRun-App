/// Пути роутов для go_router. Держим в одном месте, чтобы не было опечаток
/// в разных экранах при вызове context.go(...).
class AppRoutes {
  AppRoutes._();

  static const String onboardingLocation = '/onboarding/location';
  static const String onboardingTerms = '/onboarding/terms';

  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';

  static const String menu = '/menu';

  static const String modeSelection = '/run/mode';
  static const String runInProgress = '/run/active';
  static const String finish = '/run/finish';

  static const String friends = '/friends';
  static const String addFriend = '/friends/add';
  static const String friendRequests = '/friends/requests';
  static const String friendProfile = '/friends/profile'; // + /:uid

  static const String settings = '/settings';
  static const String profileEdit = '/settings/profile';
  static const String records = '/settings/records';
  static const String termsReadOnly = '/settings/terms';
}
