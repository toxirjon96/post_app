import 'package:bloc/bloc.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(const LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  static const _validUsername = 'user1';
  static const _validPassword = 'User1!';

  Future<void> _onSubmitted(
      LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(const LoginLoading());
    // Simulate auth delay
    await Future.delayed(const Duration(milliseconds: 900));
    if (event.username.trim() == _validUsername &&
        event.password == _validPassword) {
      emit(const LoginSuccess());
    } else {
      emit(const LoginFailure(message: 'Invalid username or password'));
    }
  }
}