import 'dart:async';

import 'package:authorized_app/widgets/header.dart';
import 'package:flutter/material.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formkey=GlobalKey<FormState>();
  final _Scaffoldkey=GlobalKey<ScaffoldState>();
  String username;
  submit(){
    final form=_formkey.currentState;
    if(form.validate()) {
      form.save();
      SnackBar snackBar=SnackBar(content:Text("Welcome $username"));
      _Scaffoldkey.currentState.showSnackBar(snackBar);
      Timer(Duration(seconds:2),(){
        Navigator.pop(context, username);
      });

    }
  }
  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key:_Scaffoldkey,
      appBar: header(context,titleText: "Set up your Profile",removeBackButton: true),
      body:ListView(
        children: <Widget>[
          Container(
            child:Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 25.0),
                  child:Center(
                    child: Text("Create Username",style: TextStyle(fontSize: 25.0),),
                  )
                ),
                Padding(
                    padding: EdgeInsets.all(16.0),
                    child:Container(
                      child: Form(
                        key:_formkey,
                        autovalidate: true,
                        child:TextFormField(
                          validator:(val) {
                              if(val.trim().length<3 || val.isEmpty){
                                return "username is too short";
                              }else if(val.trim().length>12) {
                                return "username too long";
                              }else
                                {
                                  return null;
                                }
                            },
                          onSaved:(val)=>username=val,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Username",
                              labelStyle:TextStyle(fontSize: 25.0),
                            hintText: "Must be at least 3 characters"
                          ),
                        )
                      ),
                    )
                ),
                GestureDetector(
                  onTap:submit,
                  child:Container(
                    height:50.0,
                    width:350.0,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(7.0)
                    ),
                    child:Center(child:Text(
                      "Submit",
                      style:TextStyle(
                          color:Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold

                      ),
                    ),),
                  ),
                ),

              ],
            )

          ),
        ],
      )
    );
  }
}
