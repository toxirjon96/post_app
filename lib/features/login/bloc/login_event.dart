part of 'login_bloc.dart';

sealed class LoginEvent {
  const LoginEvent._();
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({
    required this.username,
    required this.password,
  }) : super._();

  final String username;
  final String password;
}