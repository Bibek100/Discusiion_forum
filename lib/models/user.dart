import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String photoUrl;
  final String displayname;
  final String bio;

   User({
    this.id,
     this.username,
     this.email,
     this.photoUrl,
     this.displayname,
     this.bio,
});
    factory User.fromDocument(DocumentSnapshot doc){
          return User(
            id:doc['id'],
            email: doc['email'],
            username: doc['username'],
            photoUrl: doc['photoUrl'],
            displayname: doc['displayname'],
            bio:doc['bio'],

          );
    }
}

