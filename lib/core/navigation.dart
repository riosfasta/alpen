import 'package:flutter/material.dart';

void pushPage(BuildContext context, Widget page) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));

void replacePage(BuildContext context, Widget page) =>
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));

void showMessage(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

String friendlyError(Object error) => error is StateError
    ? error.message.toString()
    : 'Tidak dapat memproses permintaan. Periksa koneksi internet dan database.';
