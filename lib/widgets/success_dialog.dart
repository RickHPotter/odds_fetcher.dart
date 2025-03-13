import "package:flutter/material.dart" show AlertDialog, FutureBuilder, Navigator, Text, TextButton, showDialog;

void showSuccessDialog(context, String content) {
  Duration dismissDuration = const Duration(seconds: 2);

  showDialog(
    context: context,
    builder: (context) {
      return FutureBuilder(
        future: Future.delayed(dismissDuration).then((value) => true),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Navigator.of(context).pop();
          }

          return AlertDialog(
            elevation: 2,
            title: Text("Sucesso!"),
            content: Text(content),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
}
