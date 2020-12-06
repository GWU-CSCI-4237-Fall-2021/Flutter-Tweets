import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'tweets.dart';

/// Our MapsScreen is comprised of two major pieces:
///   - The title bar
///   - The actual map with buttons
class MapsScreen extends StatelessWidget {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  /// Creates the UI.
  @override
  Widget build(BuildContext context) {
    final currentUser = firebaseAuth.currentUser;
    final title = "Welcome, ${currentUser.email}!";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: MapView(),
    );
  }
}

/// The MapView part of the screen needs to keep track of state and update accordingly.
class MapView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MapViewState();
  }
}

/// Displays the Map and functionality related to it -- marker display, geocoding, buttons.
class MapViewState extends State<MapView> {
  /// Allows us to manipulate the map (show markers, zoom, etc.).
  GoogleMapController mapController;

  /// Markers currently displayed on the map.
  final markers = Set<Marker>();

  /// The currently chosen (and geocoded) location on the map.
  Address currentAddress;

  /// Controls whether our progress indicator is shown.
  var loadingShown = false;

  /// Once the map has loaded, keep a reference to the controller.
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  /// Creates the UI, based on the current state.
  @override
  Widget build(BuildContext context) {
    final map = GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: LatLng(38.899937, -77.0444101),
        // Initial zoom to Washington D.C.
        zoom: 11.0,
      ),
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      markers: markers,
      // When the map is re-rendered, it displays the updated markers
      onLongPress: (latLng) {
        _handleGeocoding(context, latLng);
      },
    );

    final currentLocation = Material(
        elevation: 2.0,
        color: Colors.white,
        child: IconButton(
          onPressed: !loadingShown ? () {
            _handleCurrentLocation(context);
          } : null,
          icon: Icon(Icons.my_location),
        ));

    // Update our confirmation button based on whether a location has been chosen
    final confirmText = currentAddress != null
        ? currentAddress.addressLine
        : "Long-tap to choose a location!";
    final confirmIcon = currentAddress != null ? Icons.check : Icons.clear;
    final VoidCallback confirmOnClick = currentAddress != null && !loadingShown
        ? () {
            // If enabled, clicking goes to the Tweets screen and passes it the
            // current address as a parameter.
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TweetsScreen(currentAddress)));
          }
        : null;

    // https://stackoverflow.com/a/59483324
    // Using RaisedButton.icon would work too and is much simpler, but doesn't give
    // me the spacing I want between the Icon and the Text, so doing a "custom" solution manually
    // using a Row + weighted spacing using Expanded
    final confirm = RaisedButton(
        onPressed: confirmOnClick,
        color: Colors.green,
        disabledColor: Colors.red,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Using different weights ("flex") to manipulate how much visible space
            // is allocated to each element
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

    final progressBar = Visibility(
      visible: loadingShown,
      child: CircularProgressIndicator(),
    );

    // Stack is used to put widgets (two buttons) "on top" of the map
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
        ),
        Align(
          alignment: Alignment.center,
          child: progressBar
        )
      ],
    );
  }

  /// Reverse geocodes the [latlng] into an [Address] which will be displayed on the UI.
  void _handleGeocoding(BuildContext context, LatLng latLng) {
    setState(() {
      loadingShown = true;
    });

    final coordinates = Coordinates(latLng.latitude, latLng.longitude);
    Geocoder.local
        .findAddressesFromCoordinates(coordinates)
        .then((List<Address> results) {
      if (results.isNotEmpty) {
        final first = results.first;

        // Refresh the new UI with a new marker and address
        setState(() {
          loadingShown = false;
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
        setState(() {
          loadingShown = false;
        });
      }
    }).catchError((error) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Failed to geocode: $error"),
      ));
      setState(() {
        loadingShown = false;
      });
    });
  }

  /// Handles the location permission prompt and getting the last location.
  void _handleCurrentLocation(BuildContext context) {
    setState(() {
      loadingShown = true;
    });

    Geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      _handleGeocoding(context, LatLng(position.latitude, position.longitude));
    }).catchError((error) {
      print("Did not retrieve current location: $error");
      setState(() {
        loadingShown = false;
      });
    });
  }
}
