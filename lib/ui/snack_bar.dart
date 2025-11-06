import 'package:flutter/material.dart';

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
