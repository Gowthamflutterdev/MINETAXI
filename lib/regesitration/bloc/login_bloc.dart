import 'package:flutter_bloc/flutter_bloc.dart';

import 'login_event.dart';
import 'login_repository.dart';
import 'login_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(AuthInitial()) {
    // Handle SignInEvent
    on<SignInEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final userId = await authRepository.signIn(event.email, event.password);
        emit(AuthSuccess('Sign-up successful!', event.email, userId));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    // Handle SignUpEvent
    on<SignUpEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final userId = await authRepository.signUp(event.email, event.password);
        emit(AuthSuccess('Sign-up successful!', event.email, userId));
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}
