import 'package:authorized_app/models/user.dart';
import 'package:authorized_app/pages/activity_feed.dart';
import 'package:authorized_app/pages/create_account.dart';
import 'package:authorized_app/pages/upload.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:authorized_app/pages/timeline.dart';
import 'package:authorized_app/pages/search.dart';
import 'package:authorized_app/pages/profile.dart';
import 'package:authorized_app/pages/profile2.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

User currentUser;
final activityFeedRef=Firestore.instance.collection('feed');
final followersRef=Firestore.instance.collection('followers');
final followingRef=Firestore.instance.collection('following');
final commentRef=Firestore.instance.collection('comments');
final userRef=Firestore.instance.collection('users');
final postsRef=Firestore.instance.collection('posts');
final timelineRef=Firestore.instance.collection('timeline');
final StorageReference storageRef= FirebaseStorage.instance.ref();
final googleSignIn=GoogleSignIn();
final DateTime timestamp=DateTime.now();
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {


  bool isAuth=false;
  PageController pageController;
  int pageIndex=0;
  @override
  void initState(){
    super.initState();
    pageController=PageController();
    //detects when user sign in
    googleSignIn.onCurrentUserChanged.listen((account){
      handleSignIn(account);
    },onError:(err) {
      print("error signon in:$err");
    });
    //Reautheniticated user when app is opened
    googleSignIn.signInSilently(suppressErrors:false)
    .then((account){
       handleSignIn(account);
    }).catchError((err){
      print('Error signing in: $err');
    });
  }
  handleSignIn(GoogleSignInAccount account){
    if(account!=null){
      print('User signed in!:$account');
      createUserInFirestore();
      setState(() {
        isAuth=true;
      });
    }else{
      setState(() {
        isAuth=false;
      });
    }

  }
  createUserInFirestore() async{
    //check if user exists in user collection in databae
    final GoogleSignInAccount user=googleSignIn.currentUser;
    DocumentSnapshot doc=await userRef.document(user.id).get();
    //if the user doesnt exists create acc
    if(!doc.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) =>
          CreateAccount()));


      //get usernma from creat acc and use it to make new users in users collection
      userRef.document(user.id).setData({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayname": user.displayName,
        "bio": "",
        "timestamp": timestamp,

      });
      doc=await userRef.document(user.id).get();
    }
    currentUser=User.fromDocument(doc);
    print(currentUser);
    print(currentUser.username);
  }
  @override
  void dispose(){
    pageController.dispose();
    super.dispose();
  }

  login(){
    googleSignIn.signIn();
  }
  logout(){
    googleSignIn.signOut();
  }
  onPageChanged(int pageIndex){
    setState(() {
      this.pageIndex=pageIndex;
    });
  }
  onTap(int pageIndex){
    pageController.animateToPage(
      pageIndex,
      duration:Duration(milliseconds: 250),
      curve:Curves.easeInCubic
    );

  }
  Scaffold buildAuthScreen(){
    return Scaffold(

      body: PageView(
        children: <Widget>[
         // Timeline(),
          Timeline(currentUser:currentUser),
          ActivityFeed(),
          /*Upload(currentUser:currentUser),
          Search(),*/
          Profile(profileId:currentUser?.id),
        ],
        controller:pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),

      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap:onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(icon:Icon(Icons.whatshot),),
          BottomNavigationBarItem(icon:Icon(Icons.notifications_active),),
//          BottomNavigationBarItem(icon:Icon(Icons.photo_camera,size:35.0),),
//          BottomNavigationBarItem(icon:Icon(Icons.search),),
          BottomNavigationBarItem(icon:Icon(Icons.account_circle),),
        ],

      ),
    );
    /*RaisedButton(
      child:Text("Logout") ,
      onPressed: logout,
    );*/
  }
  Scaffold buildUnAuthScreen(){
    return Scaffold(
      body:Container(
        decoration: BoxDecoration(
          gradient:LinearGradient(
              begin: Alignment.topRight,
              end:Alignment.bottomLeft,
              colors: [
               Theme.of(context).accentColor,
                Theme.of(context).primaryColor
              ]
          ),
        ),
        alignment: Alignment.center,
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Csforum",
              style: TextStyle(
                  fontFamily: "Signatra",
                  fontSize: 90.0,
                  color:Colors.white
              ),),

            GestureDetector(
              onTap: login,
              child:Container(
                width:260.0,
                height:60.0,
                decoration:BoxDecoration(
                  image:DecorationImage(
                      image:AssetImage('assets/images/google_signin_button.png'),
                      fit:BoxFit.cover
                  ),
                ),

              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return isAuth? buildAuthScreen():buildUnAuthScreen();
  }
}
