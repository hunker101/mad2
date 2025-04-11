import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(GeoApi());
}

class GeoApi extends StatelessWidget {
  const GeoApi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GeoApiScreen(),
    );
  }
}

class GeoApiScreen extends StatefulWidget {
  const GeoApiScreen({super.key});

  @override
  State<GeoApiScreen> createState() => _GeoApiScreenState();
}

class _GeoApiScreenState extends State<GeoApiScreen> {
  late GoogleMapController mapController;

  List<LatLng> markerPositions = [];
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    gotoCurrentLocation();
  }

  void gotoLocation(LatLng position) {
    if (markerPositions.length >= 2) {
      markerPositions.clear();
      markers.clear();
      polylines.clear();
      setState(() {});
      return;
    }

    markerPositions.add(position);

    markers.clear();
    for (int i = 0; i < markerPositions.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId("marker_$i"),
          position: markerPositions[i],
          infoWindow: InfoWindow(title: i == 0 ? "Start" : "End"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed),
        ),
      );
    }

    if (markerPositions.length == 2) {
      polylines.add(
        Polyline(
          polylineId: PolylineId("route"),
          color: Colors.blue,
          width: 5,
          points: markerPositions,
        ),
      );
    }

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 12),
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GoogleMap(
          markers: markers,
          polylines: polylines,
          mapType: MapType.hybrid,
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,
          onMapCreated: (controller) {
            mapController = controller;
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(15.973778836401852, 120.5780839296901),
            zoom: 10,
          ),
          onTap: (position) {
            gotoLocation(position);
            print(
                'Latitude: ${position.latitude}, Longitude: ${position.longitude}');
          },
        ),
      ),
    );
  }

  Future<bool> checkLocationServicePermission() async {
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Location services are disabled. Please enable them in settings.'),
        ),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Location permission denied. Please allow location access.'),
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Location permission permanently denied. Please enable it from settings.'),
        ),
      );
      return false;
    }

    return true;
  }

  void gotoCurrentLocation() async {
    if (!await checkLocationServicePermission()) return;

    Position position = await Geolocator.getCurrentPosition();
    gotoLocation(
      LatLng(position.latitude, position.longitude),
    );
  }
}
