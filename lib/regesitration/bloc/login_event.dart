import 'package:equatable/equatable.dart';

// Base class for authentication events
abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

// SignIn event
class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  SignInEvent(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

// SignUp event
class SignUpEvent extends AuthEvent {
  final String email;
  final String password;

  SignUpEvent(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}
