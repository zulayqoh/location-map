import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  TextEditingController _pickUpController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();

  Completer<GoogleMapController> _controller = Completer();

  Set<Marker> _markers = Set<Marker>();
  Set<Polygon> _polygons = Set<Polygon>();
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polygonLatLngs = <LatLng>[];

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _setMarker(LatLng(37.42796133580664, -122.085749655962));
  }

  void _setMarker(LatLng point) {
    setState(() {
      _markers.add(
        Marker(markerId: MarkerId('marker'), position: point),
      );
    });
  }

  void _setPolygon() {

    _polygons = {
      Polygon(
          polygonId: PolygonId('polygonIdVal'),
          points: polygonLatLngs,
          strokeWidth: 2,
          fillColor: Colors.transparent),
    };
  }

  void _setPolyline(List<PointLatLng> points) {

    _polylines.add(
      Polyline(
          polylineId: PolylineId('polylineIdVal'),
          width: 2,
          color: Colors.blue,
          points: points
              .map(
                (point) => LatLng(point.latitude, point.longitude),
          )
              .toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LOCATION MAP'),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _pickUpController,
                      // textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Pick up',
                      ),
                    ),
                    TextFormField(
                      controller: _destinationController,
                      // textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Destination',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  var direction = await LocationService().getDirections(
                      _pickUpController.text, _destinationController.text);
                  _goToPlace(
                      direction['start_location']['lat'],
                      direction['start_location']['lng'],
                      direction['bounds_ne'],
                      direction['bounds_sw']);
                  _setPolyline(
                    direction['polyline_decoded'],
                  );
                },
                icon: Icon(Icons.search),
              ),
            ],
          ),
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              markers: _markers,
              polygons: _polygons,
              polylines: _polylines,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onTap: (point) {
                setState(() {
                  polygonLatLngs.add(point);
                  _setPolygon();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToPlace(double lat, double lng, Map<String, dynamic> boundsNe,
      Map<String, dynamic> boundsSw) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 12),
      ),
    );
    controller.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(
        southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
        northeast: LatLng(boundsNe['lat'], boundsNe['lng']),
        ), 25),);

        _setMarker(
        LatLng(lat, lng),);
    }
}
