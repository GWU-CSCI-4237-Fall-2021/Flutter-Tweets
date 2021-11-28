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
  final Future<FirebaseApp> _firebaseInit = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    /// Similar to Android, in Flutter initializing Firebase an async action...
    ///
    /// However, in Android it was something that was done for us, in Flutter *we* have to initiate
    /// the process and "wait" for Firebase to finish initializing (maybe show a loading
    /// screen in the meantime).
    ///
    /// So our UI has to have an "initial" state and then an "updated" state after the
    /// current user is retrieved.
    ///
    /// i.e. there's a little extra complexity here on Flutter, since an asynchronous action determines
    /// what we actually render on the screen from the root level.
    return FutureBuilder(
      future: _firebaseInit,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return MaterialApp(
              title: 'Flutter Tweets',
              home: Scaffold(
                  appBar: AppBar(title: Text('Flutter Tweets')),
                  body: Center(child: Text('Failed to initialize Firebase!'))));
        }

        // Once complete, show the login screen
        if (snapshot.connectionState == ConnectionState.done) {
          /// Wrap our application in one that uses Material Design
          /// (as opposed to iOS's Cupertino or a roll-your-own design)
          ///
          /// The first screen of the app will be the LoginScreen.
          return MaterialApp(
            title: 'Flutter Tweets',
            home: LoginScreen(),
          );
        }

        // Otherwise, show a loading spinner while waiting for initialization to complete
        return MaterialApp(
            title: 'Flutter Tweets',
            home: Scaffold(
                appBar: AppBar(title: Text('Flutter Tweets')),
                body: Center(child: CircularProgressIndicator())));
      },
    );
  }
}
