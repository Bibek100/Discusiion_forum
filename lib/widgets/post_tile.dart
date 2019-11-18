import 'package:authorized_app/widgets/custom_image.dart';
import 'package:authorized_app/widgets/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:authorized_app/pages/post_screen.dart';
import 'package:authorized_app/widgets/custom_image.dart';
import 'package:authorized_app/widgets/post.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile(this.post);

  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: post.postId,
          userId: post.ownerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context),
      child: post.mediaUrl==null?Container(child:Column(
          children: <Widget>[
          Text(post.description)])):cachedNetworkImage(post.mediaUrl),
    );
  }
}
