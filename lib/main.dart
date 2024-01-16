import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:next_food/Bloc/States/swiper_states/swiper_states.dart';
import 'package:next_food/Bloc/swiper_bloc.dart';
import 'package:next_food/DAO/food_dao.dart';
import 'package:next_food/Data/data_manager.dart';
import 'package:next_food/Themes/theme_constants.dart';
import 'package:next_food/Themes/theme_manager.dart';
import 'package:next_food/Widgets/components/food_card.dart';
import 'package:next_food/Widgets/components/foods_swiper.dart';
import 'package:next_food/Widgets/components/logo.dart';
import 'package:permission_handler/permission_handler.dart';


import 'Widgets/pages/HomePage.dart';
import 'Widgets/pages/SignUpPage.dart';
import 'firebase_options.dart';


import 'package:firebase_core/firebase_core.dart';
import 'package:next_food/Service/auth_service.dart';

Future<bool> _requestLocationPermission() async {
  PermissionStatus permissionStatus = await Permission.location.request();
  return permissionStatus == PermissionStatus.granted;
}


void main() async {
  // All widgets need to be initialized before they can be used.

  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase.
  await Firebase.initializeApp();
  bool isLocationPermissionGranted = await _requestLocationPermission();

  if (isLocationPermissionGranted) {
    runApp(MyApp());
  } else {
    // Handle permission denied case
    // You can show a dialog or display a message to the user
    print('Location permission not granted.');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(

      body: HomePage(),

    ));
  }
}
