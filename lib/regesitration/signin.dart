import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../widget/signin_signup_fields.dart';
import 'bloc/login_bloc.dart';
import 'bloc/login_event.dart';
import 'bloc/login_state.dart';

class SignInPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _validateAndSubmit(BuildContext context) {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showSnackbar(context, 'Enter an email');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showSnackbar(context, 'Enter a valid email address');
      return;
    }
    if (password.isEmpty) {
      _showSnackbar(context, 'Enter a password');
      return;
    }

    context.read<AuthBloc>().add(SignInEvent(email, password));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
      if (state is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error)),
        );
      } else if (state is AuthSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
        Navigator.pushReplacementNamed(context, '/taxiHome');

      }
    },
    builder: (context, state) {
      if (state is AuthLoading) {
        return Center(child: CircularProgressIndicator());
      }


      return SafeArea(
          child: Column(
            children: [
              SizedBox(height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.15),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery
                        .of(context)
                        .size
                        .width * 0.05,
                    vertical: MediaQuery
                        .of(context)
                        .size
                        .height * 0.04,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is AuthError) {
                          _showSnackbar(context, state.error);
                        } else if (state is AuthSuccess) {
                          _showSnackbar(context, state.message);
                        }
                      },
                      builder: (context, state) {
                        return Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),),
                              SizedBox(height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.10),
                              Column(
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Email Address',
                                      style: Theme
                                          .of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ),
                                  SizedBox(height: MediaQuery
                                      .of(context)
                                      .size
                                      .height * 0.01),
                                  CustomTextField(
                                    controller: _emailController,
                                    hintText: 'Email',
                                    prefixIcon: Icons.email,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) => value!.isEmpty ? 'Enter an email' : null,
                                  ),
                                  SizedBox(height: MediaQuery
                                      .of(context)
                                      .size
                                      .height * 0.01),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Password',
                                      style: Theme
                                          .of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ),
                                  SizedBox(height: MediaQuery
                                      .of(context)
                                      .size
                                      .height * 0.01),
                                  CustomTextField(
                                    controller: _passwordController,
                                    hintText: 'Password',
                                    prefixIcon: Icons.lock,
                                    obscureText: true,
                                     validator: (value) =>
                                    value!.isEmpty ? 'Enter a password' : null,
                                  ),
                                ],
                              ),
                              SizedBox(height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.05),

                              SizedBox(height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.01),
                              state is AuthLoading
                                  ? Center(child: CircularProgressIndicator())
                                  : ElevatedButton(
                                onPressed: () => _validateAndSubmit(context),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.blue, // Set your desired button color here
                                  foregroundColor: Colors.white, // Set the text color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8), // Rounded corners
                                  ),
                                ),
                              ),

                              SizedBox(height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.02),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Don\'t have an account?',
                                      style: Theme
                                          .of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/signup');
                                      },
                                      child: const Text(
                                        'Create',
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          )
      );

    }),
    );
  }
}
