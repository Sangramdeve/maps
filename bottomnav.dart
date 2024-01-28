
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:elift/ui/createpost/ask_question.dart';
import 'package:elift/ui/createpost/create_post.dart';
import 'package:elift/ui/createpost/organize_event.dart';
import 'package:elift/maps_widgets/markers.dart';
import 'package:elift/uploderide.dart';
import 'package:elift/widgets/ride_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';
import 'maps_widgets/Directions_Service.dart';
import 'maps_widgets/places_service.dart';
import 'messages/components/appBar_build.dart';
import 'messages/components/body.dart';
import 'package:elift/ui/newsFeedPage/NewsFeed.dart';
import 'package:elift/models/ride.dart';
import 'package:elift/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

void main() {
  runApp(const MaterialApp(
    home: BottomNav(),
  ));
}

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedItem = 2;

  final List<Widget> _screens = [
    const ChatScreen(),
    const RideScreen(),
    const GooglemapScreen(),
    const SocialMediaScreen(),
    const SettingsScreen(),
  ];

  void _onTap(int index) {
    setState(() {
      _selectedItem = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedItem],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.blue.shade300,
        color: Colors.white,
        animationDuration: const Duration(milliseconds: 285),
        height: 60,
        items: const [
          Icon(Icons.chat),
          Icon(CupertinoIcons.search_circle_fill),
          Icon(Icons.map),
          Icon(Icons.home),
          Icon(Icons.settings),
        ],
        onTap: _onTap,
        index: _selectedItem,
      ),
    );
  }
}


class GooglemapScreen extends StatefulWidget {
  const GooglemapScreen({super.key});

  @override
  _GooglemapScreen createState() => _GooglemapScreen();
}

class _GooglemapScreen extends State<GooglemapScreen> {

  late GoogleMapController mapController;
  Position? currentLocation;
  String placeName = '';
  bool isMarkerAdded = false;
  LatLng? startLocation;
  LatLng? endLocation;
  final placesService = PlacesService();
  List<Prediction> _destinationSuggestions = [];
  List<Prediction> _pickupLocationSuggestions = [];
  final Set<Marker> _markers = {};
  bool isTextFieldVisible = true;
  bool isTextFieldVisible2 = false;
  bool isButtonVisible = false;
  Set<Polyline> _polylines = {};

  Future<void> _fetchDirections() async {
    DirectionsService directionsService = DirectionsService();

    await directionsService.fetchDirections(
      startLocation: startLocation!,
      endLocation: endLocation!,
      onPolylinesUpdated: (updatedPolylines) {
        setState(() {
          _polylines = updatedPolylines;
        });
        _fitRouteToBounds(updatedPolylines);
      },
    );
  }

  void _fitRouteToBounds(Set<Polyline> polylines) {
    if (polylines.isEmpty) {
      return;
    }

    LatLngBounds bounds = _calculateLatLngBounds(polylines);
    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }

  LatLngBounds _calculateLatLngBounds(Set<Polyline> polylines) {
    List<LatLng> points = [];
    for (Polyline polyline in polylines) {
      points.addAll(polyline.points);
    }
    return _createBoundsFromLatLngList(points);
  }

  LatLngBounds _createBoundsFromLatLngList(List<LatLng> latLngList) {
    double minLat = double.infinity;
    double minLng = double.infinity;
    double maxLat = -double.infinity;
    double maxLng = -double.infinity;

    for (LatLng latLng in latLngList) {
      minLat = math.min(minLat, latLng.latitude);
      minLng = math.min(minLng, latLng.longitude);
      maxLat = math.max(maxLat, latLng.latitude);
      maxLng = math.max(maxLng, latLng.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _setCustomMarker(String placeId) async {
    final details = await GoogleMapsPlaces(
      apiKey: 'Apikey',
    ).getDetailsByPlaceId(placeId);

    if (details.result.geometry != null) {
      final location = details.result.geometry!.location;
      double lat = location.lat;
      double lng = location.lng;
      LatLng destination = LatLng(lat, lng);
      startLocation = destination;

      BitmapDescriptor customIcon = await CustomMapMarker.getCustomMarkerIcon(
        Colors.red.shade400, // Fill color
        Colors.black, // Border color
        52.0, // Size of the marker
      );

      setState(() {
        isTextFieldVisible = false;
        _markers.add(
          Marker(
            markerId: MarkerId(placeId),
            position: destination,
            infoWindow: InfoWindow(
              snippet:  details.result.name,
              title: 'pick up location ',
            ),
            icon: customIcon, // Set the custom icon here
          ),
        );
      });

      _fetchDirections();
    }
  }

  Future<void> setCustomMarker(String placeId) async {
    final details = await GoogleMapsPlaces(
      apiKey: 'Apikey',
    ).getDetailsByPlaceId(placeId);

    if (details.result.geometry != null) {
      final location = details.result.geometry!.location;
      double lat = location.lat;
      double lng = location.lng;
      LatLng destination = LatLng(lat, lng);
      endLocation = destination;

      // Generate custom marker icon
      BitmapDescriptor customIcon = await CustomMapMarker.getCustomMarkerIcon(
        Colors.green, // Fill color
        Colors.black, // Border color
        52.0, // Size of the marker
      );

      setState(() {
        isTextFieldVisible = false;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId(placeId),
            position: destination,
            infoWindow: InfoWindow(
              snippet:  details.result.name,
              title:'Your destination ',
            ),
            icon: customIcon, // Set the custom icon here
          ),
        );
      });

      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(destination, 14.5),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    checkLocationPermission();
  }

  void checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) {
        return;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return;
      }
    }

    getUserLocation();
  }
  void getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      double lat = position.latitude;
      double lng = position.longitude;
      LatLng userLocation = LatLng(lat, lng);


      if (!isMarkerAdded) {
        _markers.add(Marker(
          markerId: MarkerId("userLocation"),
          position: userLocation,
          infoWindow: InfoWindow(title: "I am here"),
          icon: await CustomMapMarker.getCustomMarkerIcon(
            Colors.blue,
            Colors.black,
            52.0,
          ),
        ));
        isMarkerAdded = true;
      }

      // Ensure the widget is still mounted before calling setState
      if (mounted) {
        mapController.animateCamera(CameraUpdate.newLatLngZoom(userLocation, 14.5));

        setState(() {
          currentLocation = position;
         
        });
      }

      Geolocator.getPositionStream().listen((Position newPosition) {
        // Ensure the widget is still mounted before calling setState
        if (mounted) {
          setState(() {
            currentLocation = newPosition;
          });
        }
      });
    } catch (e) {
      // Ensure the widget is still mounted before showing the SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _processLocation() async {
    if (currentLocation != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          currentLocation!.latitude,
          currentLocation!.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          placeName = '${placemark.locality ?? ''}, '
              '${placemark.administrativeArea ?? ''}, ${placemark.country ?? ''}';
          debugPrint(placeName);
        } else {
          debugPrint('Unable to fetch place name');
        }
      } catch (e) {
        debugPrint('Error processing location: $e');
      }
    } else {
      debugPrint('User position is null');
    }
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builderContext) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.location_on,
                size: 50.0,
                color: Colors.blue,
              ),
              SizedBox(height: 16.0),
              Text(
                'Use current location as your Pick-up location',
                style: TextStyle(fontSize: 20.0),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  _processLocation();
                  isTextFieldVisible = false;
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blue,
                ),
                child: Text('Search Drop-off location with map'),
              ),
              SizedBox(height: 16.0),
            ],
          ),
        );
      },
    );
  }

  TextEditingController destinationController = TextEditingController();
  TextEditingController pickupLocationController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              setState(() {
                mapController = controller;
              });
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(28.6139, 77.2090),
              zoom: 1,
            ),
            markers: _markers,
            polylines: Set<Polyline>.from(_polylines),
          ),
          Positioned(
            top: 34,
            left: 0,
            right: 0,
            child: Visibility(
              visible: isTextFieldVisible,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: pickupLocationController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Enter pickup Location',
                    prefixIcon: Icon(Icons.search,size: 30.0,),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        pickupLocationController.clear();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(width: 0.8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) async {
                    if (value.length <= 4) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter at least 4 characters'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return; // Do not proceed with the API call
                    }
                    try {
                      final results = await placesService.getAutocompleteResults(value);
                      setState(() {
                        _pickupLocationSuggestions = results;
                      });
                    } catch (e) {
                      print('Error: $e');
                    }
                  },
                ),
              ),
            ),
          ),
          // Dropdown for destination suggestions
          if (_pickupLocationSuggestions.isNotEmpty)
            Positioned(
              top: 94,
              left: 0,
              right: 0,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    children: _pickupLocationSuggestions
                        .map(
                          (Prediction suggestion) => ListTile(
                        title: Text(
                          suggestion.structuredFormatting?.mainText ?? suggestion.description!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        subtitle:  Text(
                          suggestion.structuredFormatting?.secondaryText ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            pickupLocationController.text = suggestion.description!;
                            _pickupLocationSuggestions = []; // Clear suggestions after selection
                           isTextFieldVisible2 = true;

                          });
                          setCustomMarker(suggestion.placeId!);
                        },
                      ),
                    ).toList(),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 34,
            left: 0,
            right: 0,
            child: Visibility(
              visible: isTextFieldVisible2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: destinationController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search for a destination',
                    prefixIcon: Icon(Icons.search, size: 30.0),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        destinationController.clear();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(width: 0.8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) async {
                    if (value.length <= 4) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter at least 4 characters'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return; // Do not proceed with the API call
                    }
                    try {
                      final results = await placesService.getAutocompleteResults(value);
                      setState(() {
                        _destinationSuggestions = results;
                      });
                    } catch (e) {
                      print('Error: $e');
                    }
                  },
                ),
              ),
            ),
          ),
          if (_destinationSuggestions.isNotEmpty)
            Positioned(
              top: 94,
              left: 0,
              right: 0,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    children: _destinationSuggestions
                        .map(
                          (Prediction suggestion) => ListTile(
                        title: Text(
                          suggestion.structuredFormatting?.mainText ?? suggestion.description!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        subtitle:  Text(
                          suggestion.structuredFormatting?.secondaryText ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                            onTap: () {
                              setState(() {
                                destinationController.text = suggestion.description!;
                                _destinationSuggestions = []; // Clear suggestions after selection
                                isButtonVisible = true;
                              });
                              _setCustomMarker(suggestion.placeId!);
                            },
                          ),
                    ).toList(),
                  ),
                ),
              ),
            ),
          Positioned(
              bottom: 16.0,
              right: 8.0,
              left: 8.0,
              child: Visibility(
                visible: isButtonVisible,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>  Ride(
                        pickupLocation: pickupLocationController.text,
                        destination: destinationController.text,
                      )),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade200,
                    minimumSize: const Size(150, 45),
                  ),
                  child: const Text("Confirm location", style: TextStyle(fontSize: 17)),
                ),
              )
          ),
        ],
      ),
    );
  }

}

