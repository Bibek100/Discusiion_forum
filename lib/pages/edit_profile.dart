import 'package:authorized_app/pages/home.dart';
import 'package:authorized_app/widgets/progress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:authorized_app/models/user.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey=GlobalKey<ScaffoldState>();
  TextEditingController displayNameContoller = TextEditingController();
  TextEditingController bioContoller = TextEditingController();

  bool isloading = false;
  User user;
  bool _displayNameValid=true;
  bool _bioValid=true;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isloading = true;
    });
    DocumentSnapshot doc = await userRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameContoller.text = user.username;
    bioContoller.text = user.bio;
    setState(() {
      isloading = false;
    });
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text('Display Name', style: TextStyle(color: Colors.grey)),
        ),
        TextField(
          controller: displayNameContoller,
          decoration: InputDecoration(
            hintText: "Update DisplayName",
            errorText: _displayNameValid?null:"DisplayName too short",
          ),
        )
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text('Bio', style: TextStyle(color: Colors.grey)),
        ),
        TextField(
          controller: bioContoller,
          decoration: InputDecoration(
            hintText: "Update Bio",
            errorText: _bioValid?null:"bio too short",
          ),
        )
      ],
    );
  }
  updateProfileData(){
    setState(() {
      displayNameContoller.text.trim().length<3||
      displayNameContoller.text.isEmpty? _displayNameValid=false:
          _displayNameValid=true;
      bioContoller.text.trim().length>100||
          displayNameContoller.text.isEmpty?_bioValid=false:
      _bioValid=true;
    });
    if(_displayNameValid&&_bioValid){
      userRef.document(widget.currentUserId).updateData({
        "username" :displayNameContoller.text,
        "bio":bioContoller.text,
      });
      SnackBar snackBar=SnackBar(content: Text("Profile updated"),);
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }
  logout ()async
  {
   await googleSignIn.signOut();
   Navigator.push(context,MaterialPageRoute(builder:(context)=>Home() ));
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key:_scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.done,
              size: 30.0,
              color: Colors.green,
            ),
          ),
        ],
      ),
      body: isloading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                          child: CircleAvatar(
                            backgroundImage:
                                CachedNetworkImageProvider(user.photoUrl),
                          )),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            buildDisplayNameField(),
                            buildBioField(),
                          ],
                        ),
                      ),
                      RaisedButton(
                          onPressed: updateProfileData,
                          child: Text("Update Profile",
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ))),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: FlatButton.icon(
                            onPressed: logout,
                            icon: Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                            label: Text(
                              "logout",
                              style:
                                  TextStyle(color: Colors.red, fontSize: 20.0),
                            )),
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
