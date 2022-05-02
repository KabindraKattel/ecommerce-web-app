import 'package:flutter/material.dart';

class ErrorMsgSnackBar {
  static SnackBar build({required String message}) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red[900],
      elevation: 1,
    );
  }

  static SnackBar buildInfiniteDuration({required String message}) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red[900],
      elevation: 1,
      duration: const Duration(days: 365),
    );
  }
}
