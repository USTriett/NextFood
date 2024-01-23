import 'package:floating_pullup_card/floating_pullup_card.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:next_food/Themes/theme_constants.dart';
import 'package:next_food/Widgets/components/color_button.dart';
import 'package:next_food/Widgets/components/icon_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key, required this.searchKey}) : super(key: key);

  final String searchKey;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String GOONG_API = "v7v3WMJG0pFbtgEnbgyk8hvOeB59VPfciZ0XIGBd";
  String PUBLIC_ACCESS_TOKEN =
      "pk.eyJ1IjoidHJ1Y3Z5IiwiYSI6ImNscm5sd2pzazE2NjUyaW1oYmZyaHpyeXEifQ.CE4Gkbh5qm5Wc5amUrv0Sw";

  // input for search
  late String searchKey = widget.searchKey;
  num? lat = 10.2;
  num? lng = 106.2;
  num? latDes;
  num? lngDes;
  int? limit = 20;
  double? radius = 10;

  // output from search
  List<dynamic> places = [];
  List<dynamic> details = [];

  // open list of places
  bool openList = true;
  int? selectedId;

  MapboxMap? mapboxMap;

  CircleAnnotationManager? _circleAnnotationManager;
  PolylinePoints polylinePoints = PolylinePoints();

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    // get current location
    getCurrentLocation();

    print("########################");
    print("lat: $lat");
    print("lng: $lng");
    print("########################");

    await searchPlaces();
    for (var i = 0; i < places.length; i++) {
      await getDetail(places[i]['place_id']);
    }
    await getDistances();

    setState(() {
      // sort by distance
      details.sort(
          (a, b) => a['distance']['value'].compareTo(b['distance']['value']));
    });

    initMarker();
  }

  void getCurrentLocation() async {
    // PermissionStatus permissionStatus = await Permission.location.request();
    // if (permissionStatus == PermissionStatus.granted) {
    //   geolocator.Position position =
    //       await geolocator.Geolocator.getCurrentPosition(
    //           desiredAccuracy: geolocator.LocationAccuracy.high);
    //   lat = position.latitude;
    //   lng = position.longitude;
    //   print("########################");
    //   print("lat: $lat");
    //   print("lng: $lng");
    //   print("########################");
    // } else {
    //   print("Permission denied");
    // }
    lat = 10.1;
    lng = 106.1;
  }

  Future<void> searchPlaces() async {
    try {
      final url = Uri.parse(
          'https://rsapi.goong.io/Place/AutoComplete?api_key=$GOONG_API&input=$searchKey&location=$lat,$lng&limit=$limit&radius=$radius');

      var response = await http.get(url);

      final jsonResponse = jsonDecode(response.body);
      places = jsonResponse['predictions'];
    } catch (e) {
      print('$e');
    }
  }

  Future<void> getDetail(String placesId) async {
    try {
      final url = Uri.parse(
          'https://rsapi.goong.io/Place/Detail?place_id=$placesId&api_key=$GOONG_API');

      var response = await http.get(url);

      final jsonResponse = jsonDecode(response.body);
      details.add(jsonResponse['result']);
    } catch (e) {
      print('$e');
    }
  }

  Future<void> getDistances() async {
    String vehicle = "car";
    String origins =
        "https://rsapi.goong.io/DistanceMatrix?&vehicle=$vehicle&api_key=$GOONG_API&origins=";
    // origins
    origins += "$lat,$lng";
    //destinations
    origins += "&destinations=";
    for (var i = 0; i < details.length; i++) {
      if (i != 0) {
        origins += "|";
      }
      origins +=
          "${details[i]['geometry']['location']['lat']},${details[i]['geometry']['location']['lng']}";
    }

    try {
      final url = Uri.parse(origins);

      var response = await http.get(url);
      var jsonResponse = jsonDecode(response.body)['rows'][0]['elements'];
      for (int i = 0; i < details.length; i++) {
        details[i]['distance'] = jsonResponse[i]['distance'];
        details[i]['duration'] = jsonResponse[i]['duration'];
      }
    } catch (e) {
      print('$e');
    }
  }

  void initMarker() {
    mapboxMap?.annotations.createCircleAnnotationManager().then((value) async {
      _circleAnnotationManager = value;
      for (var detail in details) {
        final id = detail['place_id'];
        final lng = detail['geometry']['location']['lng'];
        final lat = detail['geometry']['location']['lat'];

        final options = CircleAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)).toJson(),
          circleColor: Color.fromARGB(255, 255, 0, 0).value,
          circleRadius: 12.0,
        );

        await value.create(options);
      }

      await value.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(lng!, lat!)).toJson(),
          circleColor: Color.fromARGB(255, 13, 255, 0).value,
          circleRadius: 12.0,
        ),
      );
    });
  }

  void removeLayer() async {
    await mapboxMap?.style.removeStyleLayer("line_layer");
    await mapboxMap?.style.removeStyleSource("line");
  }

  void findPath() async {
    if (lat != null && lng != null && lngDes != null && latDes != null) {
      final url = Uri.parse(
          'https://rsapi.goong.io/Direction?origin=$lat,$lng&destination=$latDes,$lngDes&vehicle=car&api_key=$GOONG_API');

      // move the screen to the path
      mapboxMap?.setCamera(CameraOptions(
          center: Point(
                  coordinates:
                      Position((lng! + lngDes!) / 2, (lat! + latDes!) / 2))
              .toJson(),
          zoom: 7.0));
      mapboxMap?.flyTo(
          CameraOptions(
              anchor: ScreenCoordinate(x: 0, y: 0),
              zoom: 10,
              bearing: 0,
              pitch: 0),
          MapAnimationOptions(duration: 2000, startDelay: 0));

      var response = await http.get(url);
      final jsonResponse = jsonDecode(response.body);
      var route = jsonResponse['routes'][0]['overview_polyline']['points'];
      List<PointLatLng> result = polylinePoints.decodePolyline(route);
      List<List<double>> coordinates =
          result.map((point) => [point.longitude, point.latitude]).toList();

      String geojson = '''{
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "properties": {
            "name": "Crema to Council Crest"
          },
          "geometry": {
            "type": "LineString",
            "coordinates": $coordinates
          }
        }
      ]
    }''';

      await mapboxMap?.style
          .addSource(GeoJsonSource(id: "line", data: geojson));
      var lineLayerJson = """{
     "type":"line",
     "id":"line_layer",
     "source":"line",
     "paint":{
     "line-join":"round",
     "line-cap":"round",
     "line-color":"rgb(51, 51, 255)",
     "line-width":9.0
     }
     }""";

      await mapboxMap?.style.addPersistentStyleLayer(lineLayerJson, null);
    }
  }

  void openGoogleMapsDirections() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=$lat,$lng&destination=$latDes,$lngDes';
    if (!await launchUrl(Uri.parse(url))) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FloatingPullUpCardLayout(
      state: openList
          ? FloatingPullUpState.uncollapsed
          : FloatingPullUpState.collapsed,
      child: SizedBox(
        child: MapWidget(
          key: const ValueKey("mapWidget"),
          resourceOptions: ResourceOptions(accessToken: PUBLIC_ACCESS_TOKEN),
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(lng!, lat!)).toJson(),
            // zoom: 4.0,
          ),
          // styleUri: MapboxStyles.DARK,
          textureView: true,
          onMapCreated: _onMapCreated,
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
          ),
          colorButton(
            context,
            "Chọn",
            () async {
              if (latDes == null || lngDes == null) {
                SnackBar snackBar = SnackBar(
                  content: Text("Vui lòng chọn điểm đến trước khi xác nhận"),
                  backgroundColor: Colors.green,
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                return;
              }
              // pick this restaurant

              // add history

              // open google map intent with start and end location
              openGoogleMapsDirections();
            },
          ),
          SizedBox(
            height: 10,
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  margin: EdgeInsets.fromLTRB(10, 5, 10, 5),
                  width: MediaQuery.of(context).size.width - 40,
                  height: 100,
                  decoration: BoxDecoration(
                    color: selectedId == index
                        ? Color.fromARGB(99, 236, 139, 104)
                        : Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () async {
                          // see path to that restaurant
                          if (latDes !=
                                  details[index]['geometry']['location']
                                      ['lat'] ||
                              lngDes !=
                                  details[index]['geometry']['location']
                                      ['lng']) {
                            removeLayer();
                          }
                          setState(() {
                            latDes =
                                details[index]['geometry']['location']['lat'];
                            lngDes =
                                details[index]['geometry']['location']['lng'];
                            openList = false;
                            selectedId = index;
                          });

                          findPath();
                        },
                        child: Container(
                          width: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconText(
                                  icon: Icons.directions_car,
                                  content: details[index]['distance']['text']),
                              SizedBox(
                                height: 5,
                              ),
                              IconText(
                                  icon: Icons.timer,
                                  content: details[index]['duration']['text']),
                            ],
                          ),
                        ),
                      ),
                      VerticalDivider(
                        color: Colors.grey,
                        thickness: 1,
                        indent: 10,
                        endIndent: 10,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            // see location of that restaurant
                            if (latDes !=
                                    details[index]['geometry']['location']
                                        ['lat'] ||
                                lngDes !=
                                    details[index]['geometry']['location']
                                        ['lng']) {
                              removeLayer();
                            }
                            setState(() {
                              latDes =
                                  details[index]['geometry']['location']['lat'];
                              lngDes =
                                  details[index]['geometry']['location']['lng'];
                              openList = false;
                              selectedId = index;
                            });
                            mapboxMap?.setCamera(CameraOptions(
                                center: Point(
                                        coordinates: Position(
                                            details[index]['geometry']
                                                ['location']['lng'],
                                            details[index]['geometry']
                                                ['location']['lat']))
                                    .toJson(),
                                zoom: 12.0));
                            mapboxMap?.flyTo(
                                CameraOptions(
                                    anchor: ScreenCoordinate(x: 0, y: 0),
                                    zoom: 18,
                                    bearing: 0,
                                    pitch: 0),
                                MapAnimationOptions(
                                    duration: 2000, startDelay: 0));
                          },
                          child: Column(
                            // verticalDirection: VerticalDirection.down,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                details[index]['name'],
                                style: ThemeConstants.storeTitleStyle,
                                overflow: TextOverflow.clip,
                              ),
                              Text(
                                details[index]['formatted_address'],
                                textAlign: TextAlign.end,
                                style: ThemeConstants.storeSubtitleStyle,
                                overflow: TextOverflow.clip,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                );
              },
              itemCount: places.length,
              shrinkWrap: true,
            ),
          ),
        ],
      ),
    ));
  }
}