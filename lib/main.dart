import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'WebView.dart';

Future main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Permission.camera.request();
  await Permission.microphone.request();

  var cameraStatus = await Permission.camera.status;

  if (cameraStatus.isDenied) {
    if(Platform.isAndroid){
      //To-do: implement show request rationale
    }
    await Permission.camera.request();//if permissions are permenantley denied, then the request is skipped
    var cameraStatus = await Permission.camera.status;
    if(cameraStatus.isDenied){
      openAppSettings();
    }
  }

  var audioStatus = await Permission.microphone.status;
  if (audioStatus.isDenied) {
    if(Platform.isAndroid){
      //request rationale
    }
    await Permission.microphone.request();
    var cameraStatus = await Permission.microphone.status;
    if(cameraStatus.isDenied){
      openAppSettings();
    }

  }
  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  runApp(MaterialApp(home: HomeScreen()));
}


class HomeScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(),
        body: Center(
            child: TextButton(
                child: Text('Go to pose est'),
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context){
                    return PoseInAppWebView();
                  }));
                }
            )
        )
    );
  }
}