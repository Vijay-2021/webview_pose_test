import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class PoseInAppWebView extends StatefulWidget {
  @override
  _PoseInAppWebViewState createState() => new _PoseInAppWebViewState();
}

class _PoseInAppWebViewState extends State<PoseInAppWebView> {

  final GlobalKey webViewKey = GlobalKey();
  var value = true;
  // This function is triggered when the floating button is pressed
  // You can trigger it by using other events
  Size _getSize(GlobalKey key) {
    Size widgetSize = key.currentContext!.size!;
    if(widgetSize == null) return Size(0,0);
    return widgetSize;
  }

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true, //allows for playing of video in apple webview
      ));

  late PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Pose With InAppWebView")),
      body: SafeArea(

          child: Column(
              children: <Widget>[
                value
                    ? TextButton(
                        child: Text("Go to Test Page"),
                        onPressed:() async{
                          setState(() {
                            value = !value;
                          });
                          var url = Uri.parse("https://vijay-2021.github.io/staticPoseSandbox.html");
                          webViewController?.loadUrl(urlRequest: URLRequest(url: url));
                        }
                    ) : TextButton(
                        child: Text("Go back to Pose Est"),
                        onPressed:() async{
                          setState(() {
                            value = !value;
                          });
                          var url = Uri.parse("https://tps-webview-demo.web.app/");
                          webViewController?.loadUrl(urlRequest: URLRequest(url: url));
                        }
                ),

                  TextButton(
                    child: Text("Resize Window"),
                    onPressed: (){
                      //resizeWebViewVideo(context,webViewKey);
                      webViewController?.evaluateJavascript(source: """
                        window.dispatchEvent(
                          new CustomEvent("changeSkeleton", {
                            detail : {skeleton_type : "lumbar"}
                          }));
                      """,contentWorld: ContentWorld.PAGE);
                    }
                  ),
                Expanded(
                  child:
                  Center(child:InAppWebView(
                    key: webViewKey,
                    initialUrlRequest: URLRequest(url:Uri.parse("https://vijay-2021.github.io/combined.html")),
                    initialOptions: options,
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                      webViewController?.clearCache();
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        this.url = url.toString();
                      });
                    },
                    androidOnPermissionRequest: (controller, origin, resources) async { //implements WebChromeClient
                      return PermissionRequestResponse(
                          resources: resources,
                          action: PermissionRequestResponseAction.GRANT);
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      var uri = navigationAction.request.url!;

                      if (![ "http", "https", "file", "chrome",
                        "data", "javascript", "about"].contains(uri.scheme)) {
                        if (await canLaunch(url)) {
                          // Launch the App
                          await launch(
                            url,
                          );
                          // and cancel the request
                          return NavigationActionPolicy.CANCEL;
                        }
                      }

                      return NavigationActionPolicy.ALLOW;
                    },
                    onLoadStop: (controller, url) async {
                      pullToRefreshController.endRefreshing();
                      setState(() {
                        this.url = url.toString();
                      });
                      //resizeWebViewVideo(context,webViewKey);//once we have loaded in resize camera, this is not the right spot for this, need to figure out how to listen for when the video has loaded in so we can resize it using aspect ratio
                    },
                    onLoadError: (controller, url, code, message) {
                      pullToRefreshController.endRefreshing();
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        pullToRefreshController.endRefreshing();
                      }
                      setState(() {
                        this.progress = progress / 100;
                      });
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {
                      setState(() {
                        this.url = url.toString();
                      });
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      print(consoleMessage.toString());
                      if(consoleMessage.toString().contains("Message: ")){
                        if(consoleMessage.toString().contains("resize video")){
                          //resizeWebViewVideo(context, webViewKey);
                          //resizeCanvas();

                        }
                      }
                    },
                  )),
                ),

              ])),
    );
  }

  /**
   * Get the width of the camera(videoWidth should be the intrinsic width)
   */
  Future cameraWidth() async{
    var width = webViewController?.evaluateJavascript(source: "document.getElementsByTagName('video')[0].videoWidth;",contentWorld: ContentWorld.PAGE); //use PAGE ContentWorld to run javascript "normally", e.g using page will make source just a normal javascript function return
    return width;
  }

  /**
   * Get the height of the camera(videoHeight should be the intrinsic height)
   */
  Future cameraHeight() async{
    var height = await webViewController?.evaluateJavascript(source: "document.getElementsByTagName('video')[0].videoHeight;", contentWorld: ContentWorld.PAGE);
    return height;
  }


  Future<double> cameraAspectRatio() async{
    var height = await cameraHeight();
    var width = await cameraWidth();
    return width/height;
  }

  /**
   * Resizes the Videostream to fill the WebView if AspectRatio does not exist(likely becasue the video element
   * hasn't been loaded in yet even though the page has finished loading. If the AspectRatio exists, then set the
   * width to fill the WebView and scale the Height based on the Width and the Aspect Ratio
   */
  void resizeWebViewVideo(BuildContext context, GlobalKey key) async{
    Size widgetWH = getWidgetWH(context, key);
    if(widgetWH.width == 0 && widgetWH.height ==0) return;//this is definitely not the most efficient way to make this chain of functions null safe, I'll change it later
    var tempWidth = (widgetWH.width *(1/.9)).toInt();
    var width = widgetWH.width.toString();//set the width to the width of the widget
    var aspectRatio = await cameraAspectRatio();
    var height = widgetWH.height.toString();

    if(!aspectRatio.isNaN) {
      var aspectRatioInverse = (1 / aspectRatio);
      height = (widgetWH.width * aspectRatio).toString();
    }

    webViewController?.callAsyncJavaScript(functionBody: "var windowWidth = "+width+"; var windowHeight = "+height+"; var video = document.getElementsByTagName('video')[0]; video.height = windowHeight; video.width=windowWidth; video.style.textAlign = 'center';");
    webViewController?.callAsyncJavaScript(functionBody: "var windowWidth = "+width+"; var windowHeight = "+height+"; var canvas = document.getElementsByTagName('canvas')[0]; canvas.height = windowHeight; canvas.width=windowWidth; canvas.style.textAlign = 'center';");
  }

  void resizeCanvas(){
    webViewController?.callAsyncJavaScript(functionBody:
    "var canvas = document.getElementsByTagName('canvas')[0];"+
    "const width = canvas.clientWidth;" +
    "const height = canvas.clientHeight;"+
    "if (canvas.width !== width || canvas.height !== height) {"+
      "canvas.width = width;"+
      "canvas.height = height;"+
    "}");

  }

  Size getWidgetWH(BuildContext context, GlobalKey key){
    Size widgetSize = _getSize(key);
    if(widgetSize.width == 0 && widgetSize.height == 0) return Size(0,0);

    var contextWidth = widgetSize.width;// * MediaQuery.of(context).devicePixelRatio;
    var contextHeight = widgetSize.height;// * MediaQuery.of(context).devicePixelRatio;
    //print("Width: " + contextWidth.toString() + " Height: " + contextHeight.toString());
    return Size(contextWidth, contextHeight);

  }
}