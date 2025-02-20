import 'package:flutter/material.dart';

class RecordButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onPressed;

  const RecordButton({
    Key? key,
    required this.isRecording,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: isRecording ? Colors.red : Colors.blue,
      onPressed: onPressed,
      child: Icon(isRecording ? Icons.stop : Icons.videocam),
    );
  }
}