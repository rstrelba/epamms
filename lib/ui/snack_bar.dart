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

class InfoUI extends StatelessWidget {
  final String text;
  const InfoUI({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          color: Colors.blue,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

/*
void showSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    action: SnackBarAction(
      label: 'Cancel',
      onPressed: () {
        // Action when pressing the "Cancel" button
      },
    ),
  );

  // Display SnackBar
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

void showErrSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    backgroundColor: Colors.red,

    content: Text(message),
    action: SnackBarAction(
      label: 'Cancel',
      onPressed: () {
        // Action when pressing the "Cancel" button
      },
    ),
  );

  // Display SnackBar
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
*/
