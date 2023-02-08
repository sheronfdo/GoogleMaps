import 'dart:async';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'order_tracking_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.

          ),
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  late GoogleMapController mapController;
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPIKey = "AIzaSyCOn-9T8norb1o28JaKp2CBYCk8LHKTAW4";

  Set<Marker> markers = Set(); //markers for google map
  Map<PolylineId, Polyline> polylines = {}; //pilylines to show directions
  LatLng startLocation = LatLng(7.00000, 80.00000);
  LatLng endLocation = LatLng(7.00000, 80.00000);
  String locationTitleFrom = "Search Location";
  String locationTitleTo = "Search Location";
  PointLatLng locationFrom = PointLatLng(0, 0);
  PointLatLng locationTo = PointLatLng(0, 0);
  double distance = 0.0;

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  addPolyLine(List<LatLng> polylineCoodinates) {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.redAccent,
      points: polylineCoodinates,
      width: 2,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  getDirections() async {
    List<LatLng> polylineCoodinates = [];
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleAPIKey,
      PointLatLng(startLocation.latitude, startLocation.longitude),
      PointLatLng(endLocation.latitude, endLocation.longitude),
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoodinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }

//polylinecoodinates is the list of langitute and latidtude.
    double totalDistance = 0;
    for (var i = 0; i < polylineCoodinates.length - 1; i++) {
      totalDistance += calculateDistance(
          polylineCoodinates[i].latitude,
          polylineCoodinates[i].longitude,
          polylineCoodinates[i + 1].latitude,
          polylineCoodinates[i + 1].longitude);
    }
    print(totalDistance);
    setState(() {
      distance = totalDistance;
    });

//add to the list of  poly line coordinates
    addPolyLine(polylineCoodinates);
  }

  //final LatLng _center = const LatLng(7.00000, 80.00000);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Maps Sample App'),
          backgroundColor: Colors.green[700],
        ),
        body: Stack(fit: StackFit.loose, children: [
          GoogleMap(
            mapType: MapType.normal,
            onMapCreated: (controller) {
              setState(() {
                mapController = controller;
              });
            }, // _onMapCreated
            initialCameraPosition: CameraPosition(
              target: startLocation,
              zoom: 11.0,
            ),
            zoomGesturesEnabled: true,
            markers: markers,
            polylines: Set<Polyline>.of(polylines.values),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      margin: EdgeInsets.only(
                        right: 16,
                        left: 16,
                      ),
                      child: Material(
                        child: InkWell(
                          onTap: () async {
                            double lat = 0;
                            double lang = 0;
                            final place = await PlacesAutocomplete.show(
                              context: context,
                              apiKey: googleAPIKey,
                              mode: Mode.overlay,
                              types: [],
                              strictbounds: false,
                              components: [],
                            );
                            if (place != null) {
                              setState(() {
                                locationTitleFrom =
                                    place.description.toString();
                              });

                              //from google_maps_webservice package
                              final plist = GoogleMapsPlaces(
                                apiKey: googleAPIKey,
                                apiHeaders:
                                    await GoogleApiHeaders().getHeaders(),
                              );
                              final String placeid = place.placeId ?? '0';
                              final detail =
                                  await plist.getDetailsByPlaceId(placeid);
                              final geometry = detail.result.geometry;
                              if (geometry != null) {
                                lat = geometry.location.lat;
                                lang = geometry.location.lng;
                              }
                              locationFrom = PointLatLng(lat, lang);

                              setState(() {
                                startLocation = LatLng(
                                  lat,
                                  lang,
                                );

                                markers.add(
                                  Marker(
                                    //add start location marker
                                    markerId:
                                        MarkerId(startLocation.toString()),
                                    position:
                                        startLocation, //position of marker
                                    infoWindow: InfoWindow(
                                      title: 'Starting Point',
                                      snippet: 'Start Marker',
                                    ),
                                    icon: BitmapDescriptor.defaultMarker,
                                  ),
                                );
                              });
                              getDirections();
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: ListTile(
                              title: Text(
                                locationTitleFrom,
                                style: TextStyle(fontSize: 18),
                              ),
                              trailing: Icon(Icons.search),
                              dense: true,
                            ),
                          ),
                        ),
                      ),
                    ),
//.......................................
                    SizedBox(
                      height: 12,
                    ),
                    Container(
                      height: 64,
                      margin: EdgeInsets.only(
                        right: 16,
                        left: 16,
                      ),
                      child: Material(
                        child: InkWell(
                          onTap: () async {
                            final List<LatLng> polylineCoodinates = [];
                            double lat = 0;
                            double lang = 0;
                            final place = await PlacesAutocomplete.show(
                              context: context,
                              apiKey: googleAPIKey,
                              mode: Mode.overlay,
                              types: [],
                              strictbounds: false,
                              components: [],
                            );
                            if (place != null) {
                              setState(() {
                                locationTitleTo = place.description.toString();
                              });

                              //from google_maps_webservice package
                              final plist = GoogleMapsPlaces(
                                apiKey: googleAPIKey,
                                apiHeaders:
                                    await GoogleApiHeaders().getHeaders(),
                              );
                              final String placeid = place.placeId ?? '0';
                              final detail =
                                  await plist.getDetailsByPlaceId(placeid);
                              final geometry = detail.result.geometry;
                              if (geometry != null) {
                                lat = geometry.location.lat;
                                lang = geometry.location.lng;
                              }
                              locationTo = PointLatLng(lat, lang);

                              setState(() {
                                endLocation = LatLng(
                                  lat,
                                  lang,
                                );

                                markers.add(
                                  Marker(
                                    //add start location marker
                                    markerId: MarkerId(endLocation.toString()),
                                    position: endLocation, //position of marker
                                    infoWindow: InfoWindow(
                                      title: 'Destination Point',
                                      snippet: 'Destination Marker',
                                    ),
                                    icon: BitmapDescriptor.defaultMarker,
                                  ),
                                );
                              });
                              getDirections();
                              final PolylineResult result = await polylinePoints
                                  .getRouteBetweenCoordinates(
                                googleAPIKey,
                                PointLatLng(locationFrom.latitude,
                                    locationFrom.longitude),
                                PointLatLng(
                                    locationTo.latitude, locationTo.longitude),
                              );
                              if (result.points.isNotEmpty) {
                                result.points.forEach((point) {
                                  polylineCoodinates.add(
                                      LatLng(point.latitude, point.longitude));
                                });
                              }

//polylinecoodinates is the list of langitute and latidtude.
                              double totalDistance = 0;
                              for (var i = 0;
                                  i < polylineCoodinates.length - 1;
                                  i++) {
                                totalDistance += calculateDistance(
                                    polylineCoodinates[i].latitude,
                                    polylineCoodinates[i].longitude,
                                    polylineCoodinates[i + 1].latitude,
                                    polylineCoodinates[i + 1].longitude);
                              }
                              print(totalDistance);
                              setState(() {
                                distance = totalDistance;
                              });
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: ListTile(
                              title: Text(
                                locationTitleTo,
                                style: TextStyle(fontSize: 18),
                              ),
                              trailing: Icon(Icons.search),
                              dense: true,
                            ),
                          ),
                        ),
                      ),
                    ),

                    //----------------------
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 20),
                child: Card(
                  child: Container(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Total Distance:${distance.toStringAsFixed(2)}KM",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ]),
      ),
    );
  }
}
