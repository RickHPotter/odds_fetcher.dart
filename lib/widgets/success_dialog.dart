import "package:flutter/material.dart" show AlertDialog, Navigator, Text, TextButton, showDialog;

void showSuccessDialog(context, String content) {
  showDialog(
    context: context,
    builder: (context) {
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
}
