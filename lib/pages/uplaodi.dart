import 'dart:io';

import 'package:authorized_app/pages/home.dart' as prefix0;
import 'package:authorized_app/pages/timeline.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import 'package:authorized_app/models/user.dart';
import 'package:authorized_app/pages/home.dart';

import 'package:uuid/uuid.dart';
final usersRef = Firestore.instance.collection('users');
class Uploadi extends StatefulWidget {
  final User currentUser;

  Uploadi({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Uploadi> {

  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  String postId = Uuid().v4();

  createPostInFirestore(
      {String location, String description}) {
    postsRef
        .document(currentUser.id)
        .collection("userPosts")
        .document(postId)
        .setData({
      "postId": postId,
      "ownerId": currentUser.id,
      "username": currentUser.username,

      "description": description,
      "location": location,
      "timestamp": timestamp,
      "likes": {},
    });
  }

  handleSubmit() {

    createPostInFirestore(description: captionController.text,location: locationController.text);
    captionController.clear();
    locationController.clear();

    setState(() {

      postId = Uuid().v4();
      /*Navigator.push(
          context,
          MaterialPageRoute(
          builder: (context) => Home(
      ),
      ));
*/Navigator.pop(context);
    });

  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Caption Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          FlatButton(
            onPressed: handleSubmit,
            child: Text(
              "Post",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          Padding(
            padding: EdgeInsets.all(15.0),
            child: TextField(
              controller: locationController,

              maxLines: null,

              decoration: InputDecoration(
                hintText: 'Post the topic of your problem here',

                border: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: captionController,

              maxLines: null,
              keyboardType:TextInputType.multiline,
              textInputAction:TextInputAction.newline,

              decoration: InputDecoration(
                  hintText: 'Write here',

                  border: InputBorder.none
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildUploadForm();
  }
}
