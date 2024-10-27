import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:script_editor/classes.dart';

const ballDiameter = 15.0;

class ManipulatingBallSmall extends StatefulWidget {
  ManipulatingBallSmall({Key? key, this.onDrag});

  final Function? onDrag;

  @override
  _ManipulatingBallSmallState createState() => _ManipulatingBallSmallState();
}

class _ManipulatingBallSmallState extends State<ManipulatingBallSmall> {
  // late double initX;
  // late double initY;

  _handleDrag(details) {
    setState(() {
      // initX = details.globalPosition.dx;
      // initY = details.globalPosition.dy;
    });
  }

  _handleUpdate(DragUpdateDetails details) {
    // var dx = details.globalPosition.dx - initX;
    // var dy = details.globalPosition.dy - initY;
    // initX = details.globalPosition.dx;
    // initY = details.globalPosition.dy;
    print(details.localPosition.dx);
    setState(() {
    });
    setState(() {
      
    });
    //widget.onDrag!(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handleDrag,
      onPanUpdate: _handleUpdate,
      onPanEnd: _handleDrag,
      child: Container(
        width: ballDiameter,
        height: ballDiameter,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ResizableGestureWidget extends StatefulWidget{
  final String title;

  const ResizableGestureWidget({
    Key? key,
    required this.title}) : super(key: key);

  @override
  State<ResizableGestureWidget> createState() => _ResizableGestureWidgetState();
}

class _ResizableGestureWidgetState extends State<ResizableGestureWidget> {


  bool _firstInit = true;
  late double boxWidth;

  @override
  Widget build(BuildContext context) {
    
    if (_firstInit) {
      boxWidth = 40;
      _firstInit = false;
    }
    double startPos=0;
    double startWidth = 40;
    return SizedBox(
      width: boxWidth,
      child: GestureDetector(
        onHorizontalDragStart:(DragStartDetails details) {
          startPos = details.localPosition.dx;
          startWidth = boxWidth;
        },

        onHorizontalDragUpdate: (details){
          setState(() {
            boxWidth = (startWidth+(details.localPosition.dx-startPos)>40) ? startWidth+(details.localPosition.dx-startPos) : 40;
          });
        },
        child: Text(
          widget.title,
          overflow: TextOverflow.ellipsis,),
      ),
    );
  }
}