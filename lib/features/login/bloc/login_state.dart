part of 'login_bloc.dart';

sealed class LoginState {
  const LoginState._();
}

final class LoginInitial extends LoginState {
  const LoginInitial() : super._();
}

final class LoginLoading extends LoginState {
  const LoginLoading() : super._();
}

final class LoginSuccess extends LoginState {
  const LoginSuccess() : super._();
}

final class LoginFailure extends LoginState {
  const LoginFailure({required this.message}) : super._();
  final String message;
}