import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

class Tweet {
  Tweet({this.name, this.handle, this.content, this.iconUrl});

  final String name;
  final String handle;
  final String content;
  final String iconUrl;
}

class TwitterSecrets {
  TwitterSecrets({this.key, this.secret});

  final String key;
  final String secret;
}

class TweetsScreen extends StatelessWidget {
  TweetsScreen(this.address);

  final Address address;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            AppBar(title: Text('Flutter Tweets near ${address.addressLine}')),
        body: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: TweetsList(address)));
  }
}

class TweetsList extends StatefulWidget {
  TweetsList(this.address);

  final Address address;

  @override
  State<StatefulWidget> createState() {
    return TweetsListState(address);
  }
}

class TweetsListState extends State<TweetsList> {
  TweetsListState(this.address);

  final Address address;

  List<Tweet> tweets;

  String error;

  @override
  void initState() {
    super.initState();
    retrieveTweets(address).then((tweets) {
      setState(() {
        this.tweets = tweets;
      });
    }).catchError((error) {
      setState(() {
        this.error = error.toString();
      });
    });
  }

  Future<TwitterSecrets> retrieveTwitterSecrets() async {
    String secrets = await rootBundle.loadString('assets/secrets.json');
    Map<String, dynamic> secretsJson = jsonDecode(secrets);
    return TwitterSecrets(
        key: secretsJson['twitter_key'], secret: secretsJson['twitter_secret']);
  }

  Future<String> retrieveOAuthToken() async {
    TwitterSecrets secrets = await retrieveTwitterSecrets();
    String encodedKey = Uri.encodeFull(secrets.key);
    String encodedSecret = Uri.encodeFull(secrets.secret);
    String combinedEncoded = "$encodedKey:$encodedSecret";
    String combinedBase64 = base64.encode(utf8.encode(combinedEncoded));

    http.Response oAuthResponse = await http.post(
        "https://api.twitter.com/oauth2/token",
        headers: {"Authorization": "Basic $combinedBase64"},
        body: {"grant_type": "client_credentials"});

    if (responseIsSuccessful(oAuthResponse) && oAuthResponse.body.isNotEmpty) {
      print(oAuthResponse.body);
      Map<String, dynamic> oauthBodyJson = jsonDecode(oAuthResponse.body);
      return oauthBodyJson["access_token"];
    } else {
      return Future.error(
          "OAuth failed to return a token: ${oAuthResponse.statusCode} ${oAuthResponse.body}");
    }
  }

  Future<List<Tweet>> retrieveTweets(Address address) async {
    String token = await retrieveOAuthToken();

    String searchTerm = "flutter";
    double latitude = address.coordinates.latitude;
    double longitude = address.coordinates.longitude;
    String radius = "30mi";
    List<Tweet> tweets = List();

    http.Response searchTweetsResponse = await http.get(
        "https://api.twitter.com/1.1/search/tweets.json?q=$searchTerm&geocode=$latitude,$longitude,$radius",
        headers: {"Authorization": "Bearer $token"});

    if (responseIsSuccessful(searchTweetsResponse) &&
        searchTweetsResponse.body.isNotEmpty) {
      print(searchTweetsResponse.body);
      Map<String, dynamic> tweetsBodyJson =
          jsonDecode(searchTweetsResponse.body);
      List<dynamic> statuses = tweetsBodyJson["statuses"] as List;
      statuses.forEach((dynamic curr) {
        Map<String, dynamic> currJson = curr as Map<String, dynamic>;
        String content = currJson["text"];

        Map<String, dynamic> userJson = currJson["user"];
        String name = userJson["name"];
        String handle = userJson["screen_name"];
        String iconUrl = userJson["profile_image_url_https"];
        tweets.add(Tweet(
            name: name, handle: handle, iconUrl: iconUrl, content: content));
      });
    } else {
      return Future.error(
          "Search Tweets failed to return Tweets: ${searchTweetsResponse.statusCode} ${searchTweetsResponse.body}");
    }
    return tweets;
  }

  bool responseIsSuccessful(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  @override
  Widget build(BuildContext context) {
    if (tweets == null && error == null) {
      return Center(child: CircularProgressIndicator());
    } else if (error != null) {
      return Center(child: Text('Failed to retrieve Tweets! $error'));
    } else if (tweets.isEmpty) {
      return Center(child: Text('No Tweets found!'));
    } else {
      return ListView.builder(
          itemCount: tweets.length,
          itemBuilder: (context, i) {
            Tweet curr = tweets[i];
            return Card(
                margin: EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                            width: 75,
                            height: 75,
                            child: Image.network(curr.iconUrl)),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(curr.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              Text("@${curr.handle}"),
                              Container(
                                width: MediaQuery.of(context).size.width - 150,
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
