import 'package:epamms/ii.dart';
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

Future<bool> showYesNoDialog(BuildContext context, String text) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title:
          Text('Warning'.ii(), style: Theme.of(context).textTheme.titleLarge),
      content: Text(text),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('No'.ii()),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Yes'.ii()),
        ),
      ],
    ),
  );
  return result ?? false;
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
