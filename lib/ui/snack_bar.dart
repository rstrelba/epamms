import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/tap_bounce_container.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

void showSnackBar(BuildContext context, String message) {
  showTopSnackBar(
    Overlay.of(context),
    snackBarPosition: SnackBarPosition.bottom,
    CustomSnackBar.success(
      message: message,
    ),
  );
}

void showErrSnackBar(BuildContext context, String message) {
  showTopSnackBar(
    Overlay.of(context),
    snackBarPosition: SnackBarPosition.bottom,
    CustomSnackBar.error(
      message: message,
    ),
  );
}

/*
void showSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    action: SnackBarAction(
      label: 'Отмена',
      onPressed: () {
        // Действие при нажатии на кнопку "Отмена"
      },
    ),
  );

  // Отображаем SnackBar
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

void showErrSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    backgroundColor: Colors.red,

    content: Text(message),
    action: SnackBarAction(
      label: 'Отмена',
      onPressed: () {
        // Действие при нажатии на кнопку "Отмена"
      },
    ),
  );

  // Отображаем SnackBar
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
*/
