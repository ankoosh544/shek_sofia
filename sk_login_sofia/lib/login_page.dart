import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sk_login_sofia/command_page.dart';
import 'package:sk_login_sofia/interfaces/ICoreController.dart';
import 'package:sk_login_sofia/main.dart';
import 'package:sk_login_sofia/models/App.dart';

import 'interfaces/IAuthService.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
  static const String routeName = '/login'; // Add this line
}

class _LoginPageState extends State<LoginPage> {
  final authService = GetIt.I.get<IAuthService>();
  final coreController = GetIt.I.get<ICoreController>();

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool rememberPassword = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();

    initializeLanguage();
    checkGPS();
    refresh();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> initializeLanguage() async {
    // final SharedPreferences prefs = await SharedPreferences.getInstance();
    // final savedLanguage = prefs.getString('AppLanguage') ?? '';
    // final deviceLanguage = Localizations.localeOf(context).languageCode;

    // String selectedLanguage;

    // switch (savedLanguage) {
    //   case '':
    //     selectedLanguage = '';
    //     break;
    //   case 'English':
    //     selectedLanguage = '';
    //     break;
    //   case 'Italiano':
    //     selectedLanguage = 'it';
    //     break;
    //   default:
    //     selectedLanguage = '';
    //     break;
    // }

    // try {
    //   MyApp.setLocale(context, Locale(selectedLanguage));
    //   App.selectedLanguage = selectedLanguage;
    // } catch (e) {
    //   print('Error initializing language: $e');
    //   // Handle the error gracefully, such as falling back to a default language
    //   MyApp.setLocale(context, Locale(''));
    //   App.selectedLanguage = '';
    // }
  }

  Future<void> checkGPS() async {
    if (Platform.isAndroid) {
      final isGeolocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isGeolocationEnabled) {
        final permissionStatus = await Permission.locationWhenInUse.request();
        if (permissionStatus != PermissionStatus.granted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.info),
              content: Text(AppLocalizations.of(context)!.haveToActivateGPS),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> refresh() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('PasswordUtente');
    if (savedPassword != null && savedPassword.isNotEmpty) {
      passwordController.text = savedPassword;
      await loginUtente();
    }
  }

  Future<void> loginUtente() async {
  final currentContext = context; // Store the current context

  showDialog(
    context: currentContext,
    builder: (context) => Material(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    ),
  );

  final valid = await authService.loginAsync(usernameController.text, passwordController.text);

  setState(() {
    errorMessage = valid ? '' : AppLocalizations.of(currentContext)!.invalidCredential;
  });

  if (valid && rememberPassword) {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('PasswordUtente', passwordController.text);
  }

  passwordController.text = '';

  Navigator.pop(currentContext); // Close the loading dialog

  if (valid) {
    final user = await authService.detailsAsync();
    if (user != null) {
      coreController.loggerUser = user;
      // Navigator.pushNamed(currentContext, '/CommandPage');
      Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommandPage(),
      ),
    );
    } else {
      showDialog(
        context: currentContext,
        builder: (context) => AlertDialog(
          title: Text('Info'),
          content: Text('Failed to retrieve user details.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(currentContext);
              },
            ),
          ],
        ),
      );
    }
  } else {
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: Text('Info'),
        content: Text('Invalid username or password'),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.pop(currentContext);
            },
          ),
        ],
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.signIn),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.welcome,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.username,
              ),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.password,
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            CheckboxListTile(
              title: Text(AppLocalizations.of(context)!.memorizePassword),
              value: rememberPassword,
              onChanged: (value) {
                setState(() {
                  rememberPassword = value ?? false;
                });
              },
            ),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: loginUtente,
              child: Text(AppLocalizations.of(context)!.login),
            ),
          ],
        ),
      ),
    );
  }
}
