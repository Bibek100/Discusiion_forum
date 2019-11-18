import 'package:authorized_app/pages/post2.dart';
import 'package:flutter/material.dart';
import 'package:authorized_app/pages/home.dart';
import 'package:authorized_app/widgets/header.dart';
import 'package:authorized_app/widgets/post.dart';

import 'package:authorized_app/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;

  PostScreen({this.userId, this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postsRef
          .document(userId)
          .collection('userPosts')
          .document(postId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        Post2 post = Post2.fromDocument(snapshot.data);
        return Center(
          child: Scaffold(
            appBar: header(context, titleText: "Post"),
            body: ListView(
              children: <Widget>[
                Container(
                  child: post,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
