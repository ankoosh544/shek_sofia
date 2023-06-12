import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sk_login_sofia/login_page.dart';
import 'package:sk_login_sofia/utils/dependency_injection.dart';

void main() {
  setupDependencyInjection();
  runApp(const MyApp());
//  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

// void backgroundFetchHeadlessTask(HeadlessTask task) async {
//   FlutterBlue flutterBlue = FlutterBlue.instance;

//   // Start scanning for BLE devices in the background
//   flutterBlue.startScan(timeout: Duration(seconds: 4));

//   flutterBlue.scanResults.listen((scanResult) {
//     for (ScanResult result in scanResult) {
//       print(
//           'Background Scan Result: ${result.device.name} (${result.device.id})');
//       // Do something with the scanned devices in the background
//     }
//   });
// }

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('it'), // Italian
        Locale('es'), // Spanish
      ],
      locale: _locale,
      routes: {
        LoginPage.routeName: (context) => LoginPage(),
        // Add other route mappings here
      },
      initialRoute: LoginPage.routeName,
    );
  }
}
