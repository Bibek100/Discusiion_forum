import 'dart:async';
import 'package:authorized_app/pages/post_screen.dart';

//import 'package:animator/animator.dart';
import 'package:authorized_app/pages/activity_feed.dart';
import 'package:authorized_app/pages/comments.dart';
import 'package:authorized_app/pages/home.dart';

import 'package:authorized_app/widgets/custom_image.dart';
import 'package:authorized_app/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:authorized_app/models/user.dart';
import 'package:timeago/timeago.dart' as timeago;

class Post2 extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post2({this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,


  });
  factory Post2.fromDocument(DocumentSnapshot doc){
    return Post2(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],

    );
  }
  int getLikesCount(likes){
    //if no likes no return
    if(likes==null){
      return 0;
    }
    int count=0;
    likes.values.forEach((val){
      if(val==true){
        count+=1;
      }

    });
    return count;
  }



  @override
  _PostState createState() => _PostState(
    postId: this.postId,
    ownerId: this.ownerId,
    username: this.username,
    location: this.location,
    description: this.description,
    mediaUrl: this.mediaUrl,
    likes: this.likes,
    likesCount:getLikesCount(likes),
  );
}

class _PostState extends State<Post2> {
  final String currentUserId=currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int commentCount;
  int likesCount;
  Map likes;
  bool isLiked;
  bool showHeart=false;
  bool list=false;

  @override
  void initState(){
    super.initState();
    buildComments();
  }


  @override


  _PostState({this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likesCount,

  });

  buildComments() async {
    QuerySnapshot snapshot = await commentRef
        .document(postId)
        .collection('comments').getDocuments();

    setState(() {
     commentCount = snapshot.documents.length;
    });
  }

  buildPostHeader(){
    return FutureBuilder(
        future:userRef.document(ownerId).get(),
        builder:(context,snapshot){
          if(!snapshot.hasData){
            return circularProgress();
          }
          User user=User.fromDocument(snapshot.data);
          return ListTile(

            leading: CircleAvatar(
              backgroundImage:CachedNetworkImageProvider(user.photoUrl) ,
              backgroundColor: Colors.grey,
            ),
            title:GestureDetector(
              onTap: ()=>showProfile(context,profileId: user.id),
              child: Text(
                location,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                ),
              ),
            ) ,
            subtitle:Text(user.username),
            trailing: IconButton(
              onPressed:()=>"deltering post" ,
              icon:Icon(Icons.more_vert),

            ),
          );
        }
    );

  }
  handleLikePost(){
    bool _isLiked=likes[currentUserId]==true;
    if(_isLiked){
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId':false});
      setState(() {
        likesCount -=1;
        isLiked=false;
        likes[currentUserId]=false;

      });
    }else if(!_isLiked){
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId':true});
      addLikeToActivityFeed();
      setState(() {
        likesCount +=1;
        isLiked=true;
        likes[currentUserId]=true;
        showHeart=true;
      });
      Timer(Duration(milliseconds: 500),(){
        setState(() {
          showHeart=false;
        });
      });
    }

  }
  addLikeToActivityFeed(){
    //add a notification to the postOwner's activirt feed only if comment made by other user(to avoid getting
    //  notification from own
    bool isNotPostOwner=currentUserId !=ownerId;
    if(isNotPostOwner){
      activityFeedRef.
      document(ownerId)
          .collection("feeditems")
          .document(postId)
          .setData({
        "type": "like",
        "username":currentUser.username,
        "userId":currentUser.id,
        "userProfileImg":currentUser.photoUrl,
        "postId":postId,
        "mediaUrl":mediaUrl,
        "timeStamp":timestamp,
      });}

  }

  removeLikeFromActivityFeed(){
    bool isNotPostOwner=currentUserId !=ownerId;
    if(isNotPostOwner){
      activityFeedRef.
      document(ownerId)
          .collection("feeditems")
          .document(postId)
          .get().then((doc){
        if(doc.exists){
          doc.reference.delete();
        }
      });
    }

  }


  buildPostImage(){
    return mediaUrl==null? Padding(
        padding: EdgeInsets.all(15.0),child: Text(description),):Container(

        child:Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(15.0),child: Text(description),),
        GestureDetector(
          onDoubleTap: handleLikePost,
          child:Stack(

            alignment: Alignment.center,
            children: <Widget>[

              cachedNetworkImage(mediaUrl),

              showHeart?Icon(Icons.star,size:80.0,color: Colors.red,):Text(""),
            ],
          ),
        ),

      ],
    ));


  }

  buildPostFooter(){
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0,left: 20.0),),
            GestureDetector(
              onTap:handleLikePost,
              child: Icon(
                isLiked?Icons.star:Icons.star_border,

                size: 28.0,
                color: Colors.pink,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0),),
            GestureDetector(
              onTap:()=>showComments(
                  context,
                  postId:postId,
                  ownerId:ownerId,
                  mediaUrl: mediaUrl
              ),
              child: Icon(
                Icons.chat,
                size: 28.0,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(

          children: <Widget>[
        Container(
        margin: EdgeInsets.only(left: 20.0),
            child:GestureDetector(
              onTap:()=>showComments(
                  context,
                  postId:postId,
                  ownerId:ownerId,
                  mediaUrl: mediaUrl
              ),
              child: Text(
                  "$commentCount comments",
                  style: TextStyle(color:Colors.black,
                    fontWeight:FontWeight.bold,)
              ),
            ),
        ),
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                  "$likesCount likes",
                  style: TextStyle(color:Colors.black,
                    fontWeight:FontWeight.bold,)
              ),
            ),
            /*Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                  "$commentCount comments",
                  style: TextStyle(color:Colors.black,
                    fontWeight:FontWeight.bold,)
              ),
            )*/
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                  "$username",
                  style: TextStyle(color:Colors.black,
                    fontWeight:FontWeight.bold,)
              ),
            ),
           /* Expanded(child: Text(description),)*/
          ],
        ),


      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    isLiked=(likes[currentUserId] == true);
    return GestureDetector(

      child:Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildPostHeader(),
          buildPostImage(),
          buildPostFooter(),

        ],

      ),
    );

  }


}

showComments(BuildContext context,{String postId,String ownerId,
  String mediaUrl}){
  Navigator.push(context,MaterialPageRoute(builder: (context){
    return Comments(
      postId: postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrl,

    );
  }));

}
