import 'package:bus_just/router/router.dart';
import 'package:bus_just/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'University Bus System',
          theme: ThemeData(
    primaryColor: const Color.fromARGB(255, 18, 26, 181),
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(),
          ),
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: Routes.splash,
        );
  }




  MyApp({super.key});
}
