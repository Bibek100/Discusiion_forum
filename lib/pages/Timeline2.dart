import 'package:authorized_app/widgets/header.dart';
import 'package:authorized_app/widgets/progress.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final userRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<dynamic> users = [];

  @override
  void initState() {
    //getUsers();
    deleteUser();
    super.initState();
  }

  createUser() {
    userRef.document("asadad").setData({
      "username": "Tom",
      "postCount": 0,
      "isAdmin": false
    });
  }

  updateUser() async {
    final doc = await userRef
        .document("HhvxcWz2hgn1OQp2U9MK").get();
    if (doc.exists) {
      doc.reference.updateData({
        "username": "Tim",
        "postCount": 1,
        "isAadmin": false
      });
    }
  }

  deleteUser() async {
    final DocumentSnapshot doc = await userRef
        .document("asadad").get();
    if (doc.exists) {
      doc.reference.delete();
    }
  }

  getUserById() async {
    final String id = "NYTuSujAR5JLPsmP7e3M";
    final DocumentSnapshot doc = await userRef.document(id).get();

    print(doc.data);
    print(doc.documentID);
    print(doc.exists);

  }

  getUsers() async {
    final QuerySnapshot snapshot =
    await userRef.getDocuments();

    setState(() {
      users = snapshot.documents;
    });
    snapshot.documents.forEach((DocumentSnapshot doc) {
      print(doc.data);
      print(doc.documentID);
      print(doc.exists);
    });


    @override
    Widget build(context) {
      return Scaffold(
        appBar: header(context, isAppTitle: true),
        body: StreamBuilder<QuerySnapshot>(
          stream: userRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return circularProgress();
            }
            final List<Text> children = snapshot.data.documents.map((doc) =>
                Text(doc['username'])).toList();
            return Container(
              child: ListView(
                children: children,

              ),
            );
          },

        ),

      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return null;
  }
}
