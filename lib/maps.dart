import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertweets/tweets.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter/material.dart';

class MapsScreen extends StatelessWidget {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: firebaseAuth.currentUser(),
        builder: (BuildContext context, AsyncSnapshot<FirebaseUser> asyncUser) {
          final title = asyncUser.connectionState == ConnectionState.done
              ? "Welcome, ${asyncUser.data.email}!"
              : "Welcome!";

          return Scaffold(
            appBar: AppBar(
              title: Text(title),
            ),
            body: MapView(),
          );
        });
  }
}

class MapView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MapViewState();
  }
}

class MapViewState extends State<MapView> {
  GoogleMapController mapController;

  final markers = Set<Marker>();

  Address currentAddress;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final map = GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: LatLng(38.899937, -77.0444101),
        zoom: 11.0,
      ),
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      markers: markers,
      onLongPress: (latLng) {
        handleGeocoding(context, latLng);
      },
    );

    final currentLocation = Material(
        elevation: 2.0,
        color: Colors.white,
        child: IconButton(
          onPressed: () {
            handleCurrentLocation(context);
          },
          icon: Icon(Icons.my_location),
        ));

    final confirmText = currentAddress != null
        ? currentAddress.addressLine
        : "Long-tap to choose a location!";
    final confirmColor = currentAddress != null ? Colors.green : Colors.red;
    final confirmIcon = currentAddress != null ? Icons.check : Icons.clear;
    final VoidCallback confirmOnClick = currentAddress != null
        ? () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TweetsScreen(currentAddress)));
          }
        : () {};

    // https://stackoverflow.com/a/59483324
    // Using RaisedButton.icon would work too and is much simpler, but doesn't give
    // me the spacing I want between the Icon and the Text, so doing a "custom" solution manually
    // using a Row + weighted spacing using Expanded
    final confirm = RaisedButton(
        onPressed: confirmOnClick,
        color: confirmColor,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Icon(confirmIcon, color: Colors.white),
            ),
            Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    confirmText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white),
                  ),
                ))
          ],
        ));

    return Stack(
      children: <Widget>[
        map,
        Align(
            alignment: Alignment.topLeft,
            child: Container(
                margin: EdgeInsets.fromLTRB(16.0, 16.0, 0.0, 0.0),
                child: currentLocation)),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
              margin: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
              child: SizedBox(width: double.infinity, child: confirm)),
        )
      ],
    );
  }

  void handleGeocoding(BuildContext context, LatLng latLng) {
    final coordinates = Coordinates(latLng.latitude, latLng.longitude);
    Geocoder.local
        .findAddressesFromCoordinates(coordinates)
        .then((List<Address> results) {
      if (results.isNotEmpty) {
        final first = results.first;
        setState(() {
          currentAddress = first;
          markers.clear();
          final markerId = MarkerId("Marker");
          markers.add(Marker(
            markerId: markerId,
            position: latLng,
            infoWindow: InfoWindow(title: first.addressLine),
            icon: BitmapDescriptor.defaultMarker,
          ));
        });
        mapController.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14.0));
      } else {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("No results found for location!"),
        ));
      }
    }).catchError((error) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Failed to geocode: $error"),
      ));
    });
  }

  void handleCurrentLocation(BuildContext context) {
    Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      handleGeocoding(context, LatLng(position.latitude, position.longitude));
    }).catchError((error) {
      print("Did not retrieve current location: $error");
    });
  }
}
