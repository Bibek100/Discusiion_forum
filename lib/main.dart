import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:authorized_app/pages/home.dart';
import 'package:firebase_storage/firebase_storage.dart';
void main() {
  Firestore.instance.settings(timestampsInSnapshotsEnabled: true).then(
      (_){
         print("timestamp enabled in snapshots\n");

      },onError: (_){
    print("Error in timestammop\n");
  }
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterShare',
      theme:ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.teal,
      ),

      debugShowCheckedModeBanner: false,
      home:Home(),
    );
  }
}
