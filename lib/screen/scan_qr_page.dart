import 'dart:async';
import 'dart:convert';

import '../database/db_helper.dart';
import '../model/settings.dart';
import '../screen/login_page.dart';
import '../utils/strings.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../utils/utils.dart';

class ScanQrPage extends StatefulWidget {
  @override
  _ScanQrPageState createState() => new _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  DbHelper dbHelper = DbHelper();
  Utils utils = Utils();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String _barcode = "";
  Settings settings;
  String _isAlreadyDoSettings = 'loading';

  Future scan() async {
    try {
      var barcode = await BarcodeScanner.scan();
      // Nilai Kode QR
      // Mengembalikkan Data JSON
      // Kami membutuhkan replaceAll karena Json dari web menggunakan tanda kutip tunggal ({' '}) bukan tanda kutip ganda ({" "})
      final newJsonData = barcode.replaceAll("'", '"');
      var data = jsonDecode(newJsonData);
      // Periksa Jenis Kode QR
      if (data['url'] != null && data['key'] != null) {
        // Decode Data JSON dari QR
        String getUrl = data['url'];
        String getKey = data['key'];

        // Set the url and key
        settings = Settings(url: getUrl, key: getKey);
        // Insert the settings
        insertSettings(settings);
      } else {
        utils.showAlertDialog(format_barcode_wrong, "Error", AlertType.error,
            _scaffoldKey, false);
      }
    } on PlatformException catch (e) {
      setState(() {
        _isAlreadyDoSettings = 'no';
      });
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        _barcode = barcode_permission_cam_close;
        utils.showAlertDialog(
            _barcode, "Warning", AlertType.warning, _scaffoldKey, false);
      } else {
        _barcode = '$barcode_unknown_error $e';
        utils.showAlertDialog(
            _barcode, "Error", AlertType.error, _scaffoldKey, false);
      }
    } catch (e) {
      _barcode = '$barcode_unknown_error : $e';
      print(_barcode);
    }
  }

  // Insert the URL and KEY
  insertSettings(Settings object) async {
    await dbHelper.newSettings(object);
    setState(() {
      _isAlreadyDoSettings = 'yes';
      goToLoginPage();
    });
  }

  getSettings() async {
    var checking = await dbHelper.countSettings();
    setState(() {
      checking > 0 ? _isAlreadyDoSettings = 'yes' : _isAlreadyDoSettings = 'no';
      goToLoginPage();
    });
  }

  // Init for the first time
  @override
  void initState() {
    super.initState();
    splashScreen();
  }

  // Show splash scree with time duration
  splashScreen() async {
    var duration = const Duration(seconds: 1);
    return Timer(duration, () {
      getSettings();
    });
  }

  // Got to main menu after scanning the QR or if user scanned the QR.
  goToLoginPage() {
    if (_isAlreadyDoSettings == 'yes') {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user already do settings
    if (_isAlreadyDoSettings == 'no') {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xff242559),
          key: _scaffoldKey,
          body: Container(
            margin: EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image(
                  image: AssetImage('images/logo.png'),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Text(
                  setting_welcome_title,
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 40.0,
                ),
                Text(
                  setting_desc,
                  style: TextStyle(fontSize: 12.0, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 10.0,
                ),
                RaisedButton(
                  child: Text(button_scan),
                  color: Color(0xffe11586),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  textColor: Colors.white,
                  onPressed: () => scan(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.blue,
      child: Center(
        child: Image(
          image: AssetImage('images/logo.png'),
        ),
      ),
    );
  }
}
