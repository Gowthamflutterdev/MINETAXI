import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mymine/regesitration/bloc/login_bloc.dart';
import 'package:mymine/regesitration/bloc/login_repository.dart';
import 'package:mymine/regesitration/signin.dart';
import 'package:mymine/regesitration/signup.dart';

import 'dashboard/homepagetaxi.dart';
import 'screens/SearchPlaces.dart';
import 'screens/splashscreen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AuthRepository authRepository = AuthRepository();

    return MultiBlocProvider(
      providers: [
        // Pass the authRepository to AuthBloc constructor

        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authRepository),
        ),
      ],
      child: MaterialApp(
        title: '',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),  // Sign-In is the default page
          '/signin': (context) => SignInPage(),  // Sign-In is the default page
          '/signup': (context) => SignUpPage(),  // Route for Sign-Up page
          '/taxiHome': (context) => TaxiHome(),
          '/SearchPlaces': (context) => SearchPlaces(),

        },
      ),
    );
  }
}
