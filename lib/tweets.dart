import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocode/geocode.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

/// Data class representing a Tweet.
class Tweet {

  Tweet({
    required this.name,
    required this.handle,
    required this.content,
    required this.iconUrl
  });

  final String name;
  final String handle;
  final String content;
  final String iconUrl;
}

/// Data class to hold Twitter API keys.
class TwitterSecrets {

  TwitterSecrets({
    required this.key,
    required this.secret
  });

  final String key;
  final String secret;
}

/// Our MapsScreen is comprised of two major pieces:
///   - The title bar
///   - The actual list of [Tweet]s.
class TweetsScreen extends StatelessWidget {
  // Data passed from previous screen
  TweetsScreen({required this.address, required this.coordinates});

  final LatLng coordinates;

  final Address address;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(
          'Flutter Tweets near ${address.streetAddress}',
          overflow: TextOverflow.ellipsis,
        )),
        body: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: TweetsList(address, coordinates)));
  }
}

/// The TweetsList part of the screen handles making the Twitter API call (using
/// the current [address] and rendering the scrollable list of [Tweet]s.
class TweetsList extends StatefulWidget {
  TweetsList(this.address, this.coordinates);

  final Address address;

  final LatLng coordinates;

  @override
  State<StatefulWidget> createState() {
    return TweetsListState(address, coordinates);
  }
}

/// Handles making the Twitter API call (using the current [address] and
/// rendering the scrollable list of [Tweet]s (or an error text).
class TweetsListState extends State<TweetsList> {
  TweetsListState(this.address, this.coordinates);

  /// Location the user selected on the [MapsScreen].
  final Address address;

  final LatLng coordinates;

  /// Retrieved list of [Tweet]s.
  List<Tweet>? tweets;

  /// API error, if one occurred.
  String? error;

  /// Kick off the API call when initialized for the 1st time.
  @override
  void initState() {
    super.initState();
    _retrieveTweets(address).then((tweets) {
      // Refresh the UI with retrieved Tweets
      setState(() {
        this.tweets = tweets;
      });
    }).catchError((error) {
      // Refresh the UI with an error
      setState(() {
        this.error = error.toString();
      });
    });
  }

  /// Reads Twitter API keys from "assets/secrets.json" which would normally
  /// be in the .gitignore to avoid being checked into GitHub.
  /// https://medium.com/@sokrato/storing-your-secret-keys-in-flutter-c0b9af1c0f69
  Future<TwitterSecrets> _retrieveTwitterSecrets() async {
    String secrets = await rootBundle.loadString('assets/secrets.json');

    // JSON parsing can be done manually using a Map of String --> Anything (dynamic)
    Map<String, dynamic> secretsJson = jsonDecode(secrets);
    return TwitterSecrets(
        key: secretsJson['twitter_key'], secret: secretsJson['twitter_secret']);
  }

  /// Retrieve an application-only OAuth token from the Twitter API.
  Future<String> _retrieveOAuthToken() async {
    // Required encoded key + secrets, per Twitter's OAuth docs
    TwitterSecrets secrets = await _retrieveTwitterSecrets();
    String encodedKey = Uri.encodeFull(secrets.key);
    String encodedSecret = Uri.encodeFull(secrets.secret);
    String combinedEncoded = "$encodedKey:$encodedSecret";
    String combinedBase64 = base64.encode(utf8.encode(combinedEncoded));

    // Execute API call
    http.Response oAuthResponse = await http.post(
        Uri.parse("https://api.twitter.com/oauth2/token"),
        headers: {"Authorization": "Basic $combinedBase64"},
        body: {"grant_type": "client_credentials"});

    if (_responseIsSuccessful(oAuthResponse) && oAuthResponse.body.isNotEmpty) {
      print(oAuthResponse.body);

      // JSON parsing can be done manually using a Map of String --> Anything (dynamic)
      Map<String, dynamic> oauthBodyJson = jsonDecode(oAuthResponse.body);

      // The OAuth token
      return oauthBodyJson["access_token"];
    } else {
      return Future.error(
          "OAuth failed to return a token: ${oAuthResponse.statusCode} ${oAuthResponse.body}");
    }
  }

  /// Retrieve Tweets containing the word "flutter" around the current [address].
  Future<List<Tweet>> _retrieveTweets(Address address) async {
    String token = await _retrieveOAuthToken();

    // Request parameters
    String searchTerm = "flutter";
    double latitude = coordinates.latitude;
    double longitude = coordinates.longitude;
    String radius = "30mi";
    List<Tweet> tweets = List.empty(growable: true);

    http.Response searchTweetsResponse = await http.get(
        Uri.parse("https://api.twitter.com/1.1/search/tweets.json?q=$searchTerm&geocode=$latitude,$longitude,$radius"),
        headers: {"Authorization": "Bearer $token"});

    if (_responseIsSuccessful(searchTweetsResponse) && searchTweetsResponse.body.isNotEmpty) {
      print(searchTweetsResponse.body);

      // JSON parsing can be done manually using a Map of String --> Anything (dynamic)
      Map<String, dynamic> tweetsBodyJson =
          jsonDecode(searchTweetsResponse.body);

      // List<JSONObject> containing the Tweets
      List<dynamic> statuses = tweetsBodyJson["statuses"] as List;

      // Loop over each Tweet and pick out the relevant fields
      statuses.forEach((dynamic curr) {
        // Get the current Tweet JSON
        Map<String, dynamic> currJson = curr as Map<String, dynamic>;

        // Tweet content
        String content = currJson["text"];

        // User-specific fields - name, handle, profile image URL
        Map<String, dynamic> userJson = currJson["user"];
        String name = userJson["name"];
        String handle = userJson["screen_name"];
        String iconUrl = userJson["profile_image_url_https"];

        final tweet = Tweet(
            name: name,
            handle: handle,
            iconUrl: iconUrl,
            content: content
        );
        
        tweets.add(tweet);
      });
    } else {
      return Future.error(
          "Search Tweets failed to return Tweets: ${searchTweetsResponse.statusCode} ${searchTweetsResponse.body}");
    }
    return tweets;
  }

  /// Returns true if the response has a 2XX status code.
  bool _responseIsSuccessful(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Creates the UI, based on the current state (either with [Tweet]s or an error.
  @override
  Widget build(BuildContext context) {
    if (tweets == null && error == null) {
      return Center(child: CircularProgressIndicator());
    } else if (error != null) {
      return Center(child: Text('Failed to retrieve Tweets! $error'));
    } else if (tweets != null && tweets!.isEmpty) {
      return Center(child: Text('No Tweets found!'));
    } else {
      return ListView.builder(
          itemCount: tweets!.length,
          itemBuilder: (context, i) {
            Tweet curr = tweets![i];
            return Card(
                margin: EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                            width: 75,
                            height: 75,
                            child: Image.network(curr.iconUrl)),

                        // Could do better than fixed widths here to help with overflow
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                  width: MediaQuery.of(context).size.width - 125,
                                  child: Text(curr.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18))),
                              Text("@${curr.handle}"),
                              Container(
                                width: MediaQuery.of(context).size.width - 125,
                                margin: EdgeInsets.only(top: 8.0),
                                child: Text(curr.content),
                              )
                            ])
                      ],
                    )));
          });
    }
  }
}
