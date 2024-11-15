import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:script_editor/classes.dart';

void main() {
  MediaKit.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Text Overflow Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Demo(),
      ),
    );
  }
}

class Demo extends StatefulWidget {
  @override
  _DemoState createState() => _DemoState();
}

class _DemoState extends State<Demo> {
  late final player = Player();
  late final controller = VideoController(player);
  @override
  Widget build(BuildContext context) {
    //return ResizebleWidget(child: Video(controller: controller),);
    return ResizebleWidget(child: Text("test text"));
    
  }
}

class ResizebleWidget extends StatefulWidget {
  ResizebleWidget({required this.child});

  final Widget child;
  @override
  _ResizebleWidgetState createState() => _ResizebleWidgetState();
}

const resizeCornerDiameter = 30.0;

class _ResizebleWidgetState extends State<ResizebleWidget> {
  // double height = 200;
  // double width = 400;

  double top = 0;
  double left = 0;

  void onDrag(double dx, double dy) {
    var newHeight = SettingsClass.videoHeight + dy;
    var newWidth = SettingsClass.videoWidth + dx;

    setState(() {
      SettingsClass.videoHeight = newHeight > 0 ? newHeight : 50;
      SettingsClass.videoWidth = newWidth > 0 ? newWidth : 50;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SettingsClass.videoHeight,
      width: SettingsClass.videoWidth,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: top,
            left: left,
            child: Container(
              height: SettingsClass.videoHeight,
              width: SettingsClass.videoWidth,
              color: Colors.red[100],
              child: widget.child,
            ),
          ),
          // top left
          // top middle
          // top right
          // center right
          Positioned(
            top: top + SettingsClass.videoHeight - resizeCornerDiameter,
            left: left + SettingsClass.videoWidth - resizeCornerDiameter,
            child: ManipulatingBall(
              onDrag: (dx, dy) {
                var newHeight = SettingsClass.videoHeight + dy;
                var newWidth = SettingsClass.videoWidth + dx;
      
                setState(() {
                  SettingsClass.videoHeight = newHeight > 0 ? newHeight : 0;
                  SettingsClass.videoWidth = newWidth > 0 ? newWidth : 0;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ManipulatingBall extends StatefulWidget {
  ManipulatingBall({Key? key, this.onDrag});

  final Function? onDrag;

  @override
  _ManipulatingBallState createState() => _ManipulatingBallState();
}

class _ManipulatingBallState extends State<ManipulatingBall> {
  late double initX;
  late double initY;

  _handleDrag(details) {
    setState(() {
      initX = details.globalPosition.dx;
      initY = details.globalPosition.dy;
    });
  }

  _handleUpdate(DragUpdateDetails details) {
    var dx = details.globalPosition.dx - initX;
    var dy = details.globalPosition.dy - initY;
    initX = details.globalPosition.dx;
    initY = details.globalPosition.dy;
    widget.onDrag!(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handleDrag,
      onPanUpdate: _handleUpdate,
      child: Container(
        color: ColorScheme.fromSeed(seedColor: Colors.deepPurple).primary.withOpacity(0.75),
        width: resizeCornerDiameter,
        height: resizeCornerDiameter,
        child: Transform.rotate(angle: 3.14/2, child: const Icon(Icons.arrow_outward_sharp),),
      ),
    );
  }
}