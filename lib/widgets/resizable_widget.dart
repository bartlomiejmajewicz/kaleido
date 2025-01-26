import 'package:flutter/material.dart';
import 'package:script_editor/models/settings_class.dart';



class ResizebleWidget extends StatefulWidget {
  const ResizebleWidget({super.key, required this.child});

  final Widget child;
  @override
  // ignore: library_private_types_in_public_api
  _ResizebleWidgetState createState() => _ResizebleWidgetState();
}

const resizeCornerDiameter = 40.0;

class _ResizebleWidgetState extends State<ResizebleWidget> {
  // double height = 200;
  // double width = 400;

  double top = 0;
  double left = 0;

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
          Positioned(
            top: top + SettingsClass.videoHeight - resizeCornerDiameter,
            left: left + SettingsClass.videoWidth - resizeCornerDiameter,
            child: ManipulatingCornerSquare(
              onDrag: (dx, dy) {
                var newHeight = SettingsClass.videoHeight + dy;
                var newWidth = SettingsClass.videoWidth + dx;
      
                setState(() {
                  SettingsClass.videoHeight = newHeight > 0 ? newHeight : 0;
                  SettingsClass.videoHeightNotifier.value = newHeight > 0 ? newHeight : 0;
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

class ManipulatingCornerSquare extends StatefulWidget {
  const ManipulatingCornerSquare({super.key, this.onDrag});

  final Function? onDrag;

  @override
  // ignore: library_private_types_in_public_api
  _ManipulatingCornerSquareState createState() => _ManipulatingCornerSquareState();
}

class _ManipulatingCornerSquareState extends State<ManipulatingCornerSquare> {
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