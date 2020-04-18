import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter/material.dart';

class MapsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MapsScreenState();
  }
}

class MapsScreenState extends State<MapsScreen> {
  Address currentAddress;

  // https://stackoverflow.com/a/50452277
  GlobalKey<ScaffoldState> scaffoldState = GlobalKey();

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
            key: scaffoldState,
            appBar: AppBar(
              title: Text(title),
            ),
            body: MapView(locationChosen),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                if (currentAddress == null) {
                  scaffoldState.currentState.showSnackBar(SnackBar(
                    content: Text("Long-tap to choose a location!"),
                  ));
                } else {}
              },
              child: currentAddress != null
                  ? Icon(Icons.check)
                  : Icon(Icons.clear),
              backgroundColor:
                  currentAddress != null ? Colors.green : Colors.red,
            ),
          );
        });
  }

  void locationChosen(Address address) {
    setState(() {
      currentAddress = address;
    });
  }
}

class MapView extends StatefulWidget {
  MapView(this.locationChosen);

  final Function(Address) locationChosen;

  @override
  State<StatefulWidget> createState() {
    return MapViewState(locationChosen);
  }
}

class MapViewState extends State<MapView> {
  GoogleMapController mapController;

  MapViewState(this.locationChosen);

  final Function(Address) locationChosen;

  final markers = Set<Marker>();

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
        final coordinates = Coordinates(latLng.latitude, latLng.longitude);
        Geocoder.local
            .findAddressesFromCoordinates(coordinates)
            .then((List<Address> results) {
          if (results.isNotEmpty) {
            final first = results.first;
            setState(() {
              markers.clear();
              final markerId = MarkerId("Marker");
              markers.add(Marker(
                markerId: markerId,
                position: latLng,
                infoWindow: InfoWindow(title: first.addressLine),
                icon: BitmapDescriptor.defaultMarker,
              ));
            });
            mapController
                .animateCamera(CameraUpdate.newLatLngZoom(latLng, 14.0));
            locationChosen(first);
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
      },
    );

    return map;
  }
}
