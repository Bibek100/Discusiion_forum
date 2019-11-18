import 'package:authorized_app/pages/home.dart' as prefix0;
import 'package:authorized_app/pages/uplaodi.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:authorized_app/models/user.dart';
import 'package:authorized_app/pages/home.dart';
import 'package:authorized_app/pages/search.dart';
import 'package:authorized_app/pages/upload.dart';
import 'package:authorized_app/widgets/header.dart';
import 'package:authorized_app/widgets/post.dart';
import 'package:authorized_app/widgets/progress.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image/image.dart' as Im;
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

final usersRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {

  final _formkey=GlobalKey<FormState>();
  List<Post> posts;
  List<String> followingList = [];
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  File file;
  bool isUploading = false;
  String postId = Uuid().v4();



  @override
  void initState() {
    super.initState();
    getTimeline();

  }
  handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.file = file;
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.gallery,);
    setState(() {
      this.file = file;
    });
  }

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text("Create Post"),
          children: <Widget>[
            SimpleDialogOption(
                child: Text("Photo with Camera"), onPressed: handleTakePhoto),
            SimpleDialogOption(
                child: Text("Image from Gallery"),
                onPressed: handleChooseFromGallery),
            SimpleDialogOption(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }
  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());

    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));
    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
    storageRef.child("post_$postId.jpg").putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore(

      {String mediaUrl, String location, String description}) {
    postsRef
        .document(widget.currentUser.id)
        .collection("userPosts")
        .document(postId)
        .setData({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": timestamp,
      "likes": {},
    });
  }

  handleSubmit() async {

  setState(() {
  isUploading = true;
  });

  await compressImage();
  String mediaUrl = await uploadImage(file);
  createPostInFirestore(
  mediaUrl: mediaUrl,
  location: locationController.text,
  description: captionController.text,
  );
  captionController.clear();
  locationController.clear();
  setState(() {
  file = null;
  isUploading = false;
  postId = Uuid().v4();
  });

  }



  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .document(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Post> posts =
    snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }



  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Text("empty");
    } else {
      return ListView(children: posts);
    }
  }
  Scaffold b(){
    return Scaffold(

      appBar: header(context, isAppTitle: true),
      body: RefreshIndicator(
          onRefresh: () => getTimeline(), child: buildTimeline()),

      /* floatingActionButton: FloatingActionButton(
        onPressed:(){ Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Upload(currentUser: currentUser,)),
        );},

        child: Icon(Icons.navigation),
        backgroundColor: Colors.green,
      ),*/
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.add_event,
        animatedIconTheme: IconThemeData(size: 22.0),
        // this is ignored if animatedIcon is non null
        // child: Icon(Icons.add),

        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () => print('OPENING DIAL'),
        onClose: () => print('DIAL CLOSED'),
        tooltip: 'Speed Dial',
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 8.0,
        shape: CircleBorder(),
        children: [
          SpeedDialChild(
              child: Icon(Icons.camera),
              backgroundColor: Colors.red,
              label: 'First',

              onTap: () =>selectImage(context),
          ),
          SpeedDialChild(
            child: Icon(Icons.brush),
            backgroundColor: Colors.blue,
            label: 'Second',

            onTap: () {Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Uploadi()));},
          ),

        ],
      ),
    );

  }
  getUserLocation() async {
    Position position =await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks=await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark=placemarks[0];
    String completeAddress =
        '${placemark.subThoroughfare} ${placemark.thoroughfare}, '
        '${placemark.subLocality} ${placemark.locality},'
        ' ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} '
        '${placemark.postalCode}, ${placemark.country}';
    print(completeAddress);
    String formatedAddress="${placemark.locality},${placemark.country}";
    locationController.text=formatedAddress;
  }
  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: clearImage),
        title: Text(
          "Caption Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
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
          isUploading ? linearProgress() : Text(""),
          Container(
            height: 220.0,
            width: MediaQuery
                .of(context)
                .size
                .width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(

                      fit: BoxFit.cover,
                      image: FileImage(file),
                    ),
                  ),

                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),

         /* ListTile(

            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: "Write a caption...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),*/
          Divider(),
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
          /*ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35.0,
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: "Where was this photo taken?",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),*/
          /*Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              label: Text(
                "Use Current Location",
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              color: Colors.blue,
              onPressed: getUserLocation,
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),*/
        ],
      ),
    );
  }
   @override
  Widget build(context) {
    return file==null?b() : buildUploadForm();
  }
}
