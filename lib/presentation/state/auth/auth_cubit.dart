import 'package:flutter/foundation.dart';

/// Auth state (logged in / out, user).
class AuthCubit extends ChangeNotifier {
  void checkAuth() {}
  void signIn(String email, String password) {}
  void register(String email, String password) {}
  void signOut() {}
}
