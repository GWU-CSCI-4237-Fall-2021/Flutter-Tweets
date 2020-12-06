import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';

/// Here's the entry point to our app
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  // Create the initialization Future outside of `build`:
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    /// Wrap our application in one that uses Material Design
    /// (as opposed to iOS's Cupertino or a roll-your-own design)
    ///
    /// The first screen of the app will be the LoginScreen.
    return FutureBuilder(
      // Initialize FlutterFire:
      future: _initialization,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return MaterialApp(
              title: 'Flutter Tweets',
              home: Scaffold(
                  appBar: AppBar(title: Text('Flutter Tweets')),
                  body: Center(child: Text('Failed to initialize Firebase!'))));
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            title: 'Flutter Tweets',
            home: LoginScreen(),
          );
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return MaterialApp(
            title: 'Flutter Tweets',
            home: Scaffold(
                appBar: AppBar(title: Text('Flutter Tweets')),
                body: Center(child: CircularProgressIndicator())));
      },
    );
  }
}