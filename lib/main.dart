import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  runApp(MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class Student {
  String fullName;
  LatLng location;

  Student(this.fullName, this.location);

  @override
  String toString() => '$fullName - Lat: ${location.latitude}, Lng: ${location.longitude}';
}

List<Student> students = [
  Student("test1", const LatLng(0, 0)),
  Student("test2", const LatLng(10.000002, 12.00001))
];

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Location _location = Location();
  Set<Marker> _markers = {};
  Map<Student, bool> selectedStudents = {};

  @override
  void initState() {
    super.initState();
    students.forEach((student) {
      selectedStudents[student] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Локатор'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              child: Text('Меню'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Начать развозку'),
              onTap: () {
                Navigator.pop(context); // Закрыть меню
                _showModalBottomSheet(context); // Открыть модальное окно с информацией о студентах
              },
            ),
            ListTile(
              title: Text('Элемент 2'),
              onTap: () {
                Navigator.pop(context); // Закрыть меню
              },
            ),
          ],
        ),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: LatLng(100, 100),
          zoom: 15,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          _locateMe();
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }

  void _showModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: navigatorKey.currentContext!,
        builder: (BuildContext context) {
          return Container(
            height: 400,
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Список студентов", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (BuildContext context, int index) {
                      return CheckboxListTile(
                        value: selectedStudents[students[index]],
                        title: Text(students[index].fullName),
                        subtitle: Text("Широта: ${students[index].location.latitude}, Долгота: ${students[index].location.longitude}"),
                        onChanged: (bool? value) {
                          setState(() {
                            selectedStudents[students[index]] = value!;
                          });
                        },
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: _handleStartRide,
                  child: Text("Начать"),
                )
              ],
            ),
          );
        }
    );
  }

  void _handleStartRide() {
    Navigator.pop(context); // Закрываем модальное окно
    _markers.clear(); // Очищаем старые маркеры

    List<Student> selected = selectedStudents.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    print("Selected students for the ride:");
    selected.forEach((student) {
      print(student);
      _markers.add(Marker(
        markerId: MarkerId(student.fullName),
        position: student.location,
        infoWindow: InfoWindow(title: student.fullName, snippet: 'Широта: ${student.location.latitude}, Долгота: ${student.location.longitude}'),
      ));
    });

    setState(() {}); // Обновляем UI с новыми маркерами
  }

  void _locateMe() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _location.getLocation().then((locationData) async {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(locationData.latitude!, locationData.longitude!),
            zoom: 15,
          ),
        ),
      );
    });
  }
}
