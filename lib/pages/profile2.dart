import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:authorized_app/models/user.dart';
import 'package:authorized_app/pages/edit_profile.dart';
import 'package:authorized_app/pages/home.dart';
import 'package:authorized_app/widgets/header.dart';
import 'package:authorized_app/widgets/post.dart';
import 'package:authorized_app/widgets/post_tile.dart';
import 'package:authorized_app/widgets/progress.dart';

class Profile2 extends StatefulWidget {
  final String profileId;

  Profile2({this.profileId});

  @override
  _ProfileState2 createState() => _ProfileState2();
}

class _ProfileState2 extends State<Profile2> {
  final String currentUserId = currentUser?.id;
  String postOrientation = "grid";
  bool isFollowing = false;
  bool isLoading = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();

  }



  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }



  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset('assets/images/no_content.svg', height: 260.0),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                "No Posts",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
      return Column(
        children: posts,
      );

  }

  logout(){
    googleSignIn.signOut();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body: ListView(
        children: <Widget>[


      RaisedButton(
      child:Text("Logout") ,
      onPressed: logout,
    ),
          Column(
            children: posts,
          ),
        ],
      ),
    );
  }
}
