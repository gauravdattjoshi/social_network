import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:social_network/models/user.dart';
import 'package:social_network/pages/home.dart';
import 'package:social_network/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final User userdetails;
  EditProfile({this.userdetails});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displaynameController = TextEditingController();

  TextEditingController biocontroller = TextEditingController();
  User user;
  bool _displaynameValid = true;
  bool _bioValid = true;
  bool isLoading = false;
  bool isUpdated = false;
  @override
  void initState() {
    getUser();
    super.initState();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.document(widget.userdetails.id).get();
    user = User.fromDocuments(doc);
    biocontroller.text = user.bio;
    displaynameController.text = user.displayName;
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.grey,
            ),
            onPressed: () {
              Navigator.pop(context);
            }),
        centerTitle: true,
        title: Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.done,
              size: 30,
              color: isUpdated == false ? Colors.grey : Colors.green,
            ),
            onPressed: isUpdated == false
                ? null
                : () {
                    Navigator.pop(context);
                  },
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: InkWell(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(children: [
          Container(
            child: isLoading == true
                ? circularProgress()
                : Column(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.all(20),
                        alignment: Alignment.topCenter,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              NetworkImage(widget.userdetails.photoUrl),
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: TextField(
                          controller: displaynameController,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  displaynameController.clear();
                                },
                              ),
                              hintText: "add display name",
                              errorText: _displaynameValid == false
                                  ? "Display name too short"
                                  : null,
                              labelText: "Display Name"),
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: TextField(
                          controller: biocontroller,
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  biocontroller.clear();
                                },
                              ),
                              errorText:
                                  _bioValid == false ? "Bio is too long" : null,
                              hintText: "Add Bio ",
                              labelText: "Bio"),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        alignment: Alignment.center,
                        child: RaisedButton(
                          onPressed: () async {
                            setState(() {
                              displaynameController.text.trim().length < 3 ||
                                      displaynameController.text.isEmpty
                                  ? _displaynameValid = false
                                  : _displaynameValid = true;

                              biocontroller.text.trim().length > 100
                                  ? _bioValid = false
                                  : _bioValid = true;
                            });
                            if (_displaynameValid && _bioValid) {
                              await usersRef.document(user.id).updateData({
                                "displayName": displaynameController.text,
                                "bio": biocontroller.text
                              });
                              final snackbar = SnackBar(
                                content: Text("Profile Updated"),
                              );

                              setState(() {
                                isUpdated = true;
                              });

                              Timer(Duration(seconds: 2), () {
                                _scaffoldKey.currentState
                                    .showSnackBar(snackbar);
                              });
                            }
                          },
                          color: Colors.teal,
                          child: Text("Update Profile"),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        alignment: Alignment.center,
                        child: RaisedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await googleSignIn.signOut();
                          },
                          icon: Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                          color: Colors.white,
                          label: Text("Log out"),
                        ),
                      ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}
