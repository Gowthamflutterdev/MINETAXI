import 'package:equatable/equatable.dart';

// Base class for authentication states
abstract class AuthState extends Equatable {
  @override
  List<Object> get props => [];
}

// Initial state
class AuthInitial extends AuthState {}

// Loading state
class AuthLoading extends AuthState {}

// Success state
class AuthSuccess extends AuthState {
  final String message;
  final String email;
  final String userId;

  AuthSuccess(this.message, this.email, this.userId);

  @override
  List<Object> get props => [message, email, userId];
}

// Error state
class AuthError extends AuthState {
  final String error;

  AuthError(this.error);

  @override
  List<Object> get props => [error];
}
