import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginState {
  final bool isAuthenticated;
  const LoginState({this.isAuthenticated = false});
}

class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier() : super(const LoginState());

  void authenticate() => state = const LoginState(isAuthenticated: true);
  void logout() => state = const LoginState(isAuthenticated: false);
}

final loginStateProvider =
    StateNotifierProvider<LoginNotifier, LoginState>((ref) => LoginNotifier());
