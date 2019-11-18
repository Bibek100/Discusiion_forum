import 'dart:async';
import 'package:authorized_app/pages/post_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
//import 'package:animator/animator.dart';
import 'package:authorized_app/pages/activity_feed.dart';
import 'package:authorized_app/pages/comments.dart';
import 'package:authorized_app/pages/home.dart';
import 'dart:core';

import 'package:authorized_app/widgets/custom_image.dart';
import 'package:authorized_app/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:authorized_app/models/user.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final Timestamp timestamp;
  final dynamic likes;

  Post({this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.timestamp
  });
   factory Post.fromDocument(DocumentSnapshot doc){
     return Post(
       postId: doc['postId'],
       ownerId: doc['ownerId'],
       username: doc['username'],
       location: doc['location'],
       description: doc['description'],
       timestamp: doc['timestamp'],
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
    timestamp:this.timestamp,
    mediaUrl: this.mediaUrl,
    likes: this.likes,
    likesCount:getLikesCount(likes),
  );
}

class _PostState extends State<Post> {
  final String currentUserId=currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final Timestamp timestamp;
  int likesCount;
  Map likes;
  bool isLiked;
  bool showHeart=false;
  int commentCount;

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
    this.timestamp,
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

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this post?"),
            children: <Widget>[
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    deletePost();
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  )),
              SimpleDialogOption(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
            ],
          );
        });
  }

  // Note: To delete post, ownerId and currentUserId must be equal, so they can be used interchangeably
  deletePost() async {
    // delete post itself
    postsRef
        .document(ownerId)
        .collection('userPosts')
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete uploaded image for thep ost
    storageRef.child("post_$postId.jpg").delete();
    // then delete all activity feed notifications
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .document(ownerId)
        .collection("feedItems")
        .where('postId', isEqualTo: postId)
        .getDocuments();
    activityFeedSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // then delete all comments
    QuerySnapshot commentsSnapshot = await commentRef
        .document(postId)
        .collection('comments')
        .getDocuments();
    commentsSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
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
  buildPostHeader(){
    return FutureBuilder(
        future:userRef.document(ownerId).get(),
        builder:(context,snapshot){
          if(!snapshot.hasData){
            return circularProgress();
          }
          User user=User.fromDocument(snapshot.data);
          bool isPostOwner=currentUserId==ownerId;
          return ListTile(

            leading: CircleAvatar(
              backgroundImage:CachedNetworkImageProvider(user.photoUrl) ,
              backgroundColor: Colors.grey,
            ),
            title:GestureDetector(
              //onTap: ()=>showProfile(context,profileId: user.id),
              child: Text(
                location,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                ),
              ),
            ) ,
            subtitle:Text(user.username),
            trailing: isPostOwner?IconButton(
              onPressed:()=>handleDeletePost(context),
              icon:Icon(Icons.more_vert),

            ):Text(" "),
          );
        }
    );

  }
  buildPostImage(){
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child:Stack(

        alignment: Alignment.center,
        children: <Widget>[
          Expanded(child: Text(description),),
          cachedNetworkImage(mediaUrl),
          /*showHeart?Animator(
            duration:Duration(milliseconds: 300),
            tween: Tween(begin: 0.8,end:1.4),
            curve: Curves.elasticOut,
            cycles: 0,
            builder: (anim)=>Transform.scale(
                scale: anim.value,
              child: Icon(Icons.favorite,
              size:80.0,
              color: Colors.red,),
            ),
          ):Text(""),*/
         showHeart?Icon(Icons.favorite,size:80.0,color: Colors.red,):Text(""),
        ],
    ),
    );

  }
  buildPostHead(){
    return FutureBuilder(
        future:userRef.document(ownerId).get(),
        builder:(context,snapshot) {
          if (!snapshot.hasData) {
            return Text("");
          }
          User user = User.fromDocument(snapshot.data);
          bool isPostOwner = currentUserId == ownerId;
          return Container(
            width: 500,
            height: 100,


            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              elevation: 4.0,
              color: Colors.white,

              child: ListTile(
                  leading:  CircleAvatar(
                    radius: 20.0,
                    backgroundColor: Colors.grey,
                    backgroundImage:
                    CachedNetworkImageProvider(user.photoUrl),
                  ),
                  title: Text(location,
                    style: TextStyle(fontSize: 14.0, color: Colors.green),),
                  subtitle: Text(timeago.format(timestamp.toDate())),
                  trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        isPostOwner?IconButton(
                          onPressed:()=>handleDeletePost(context),
                          icon:Icon(Icons.more_vert),

                        ):Text(" "),





                      ]
                  )
              ),

            ),
          );
        }
    );

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
                isLiked?Icons.favorite:Icons.favorite_border,

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
              child: Text(
                "$likesCount likes",
                style: TextStyle(color:Colors.black,
                fontWeight:FontWeight.bold,)
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                  "$likesCount comments",
                  style: TextStyle(color:Colors.black,
                    fontWeight:FontWeight.bold,)
              ),
            )
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
            Expanded(child: Text(description),)
          ],
        ),


      ],
    );
  }
  showPost2(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: postId,
          userId: ownerId,
        ),
      ),
    );

  }
  @override
  Widget build(BuildContext context) {
    isLiked=(likes[currentUserId] == true);
    return GestureDetector(
        onTap: ()=>showPost2(context),
        child: buildPostHead(),




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