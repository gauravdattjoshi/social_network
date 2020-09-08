import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_network/models/user.dart';
import 'package:social_network/pages/home.dart';
import 'package:social_network/widgets/constant.dart';
import 'package:social_network/widgets/progress.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  TextEditingController locationController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  final _storage = FirebaseStorage.instance.ref();
  String postId = Uuid().v4();
  File _image;
  bool isUploadPost = false;
  @override
  Widget build(BuildContext context) {
    return _image == null ? buildSplashScreen() : buildUploadedForm();
  }

  compressImage() async {
    var tempDir = await getTemporaryDirectory();
    String path = tempDir.path;
    Im.Image imagedecode = Im.decodeImage(_image.readAsBytesSync());
    File compressedFile = File("$path/img_$postId.jpg")
      ..writeAsBytesSync(Im.encodeJpg(imagedecode, quality: 80));
    setState(() {
      _image = compressedFile;
    });
  }

  buildUploadedForm() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            }),
        title: Text("Create Post"),
        actions: <Widget>[
          Center(
            child: FlatButton(
              onPressed: isUploadPost ? null : () => handleSubmit(),
              child: Text(
                "Post",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploadPost ? Text("") : linearProgress(),
          AspectRatio(
            aspectRatio: 1 / 1,
            child: Container(
              margin: EdgeInsets.all(5),
              height: 250,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(image: FileImage(_image))),
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(widget.currentUser.photoUrl),
              ),
              title: TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                    hintText: "Give Caption",
                    enabledBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none),
              ),
            ),
          ),
          Divider(
            color: Colors.grey,
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: ListTile(
                leading: Icon(
                  Icons.pin_drop,
                  color: Colors.yellow.shade900,
                  size: 35,
                ),
                title: TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                      hintText: "Add Location",
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none),
                )),
          ),
          Container(
              alignment: Alignment.center,
              child: RaisedButton.icon(
                icon: Icon(
                  Icons.gps_fixed,
                  color: Colors.white,
                ),
                onPressed: () async {
                  final _geolocator = Geolocator();
                  final position = await _geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                      locationPermissionLevel:
                          GeolocationPermission.locationWhenInUse);
                  final List<Placemark> placemark =
                      await _geolocator.placemarkFromCoordinates(
                          position.latitude, position.longitude);
                  Placemark locationPlacemark = placemark[0];
                  String location =
                      "${locationPlacemark.locality}, ${locationPlacemark.country}";
                  locationController.text = location;
                  print(location);
                },
                label: Text(
                  "Use my Current Location",
                  style: knormalText,
                ),
                color: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ))
        ],
      ),
    );
  }

  ImagePicker picker = ImagePicker();
  getImage() async {
    Navigator.pop(context);
    final pickedFile = await picker.getImage(
        source: ImageSource.camera, maxHeight: 600, maxWidth: 600);

    setState(() {
      _image = File(pickedFile.path);
    });
  }

  getImagefromGallery() async {
    Navigator.pop(context);
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      _image = File(pickedFile.path);
    });
  }

  uploadImage(file) async {
    final uploadTask = _storage.child("post_$postId.jpg").putFile(file);
    final StorageTaskSnapshot uploadComplete = await uploadTask.onComplete;
    final downloadUrl = uploadComplete.ref.getDownloadURL();
    return downloadUrl;
  }

  createUserInFirestore(
      {String mediaurl, String description, String location}) async {
    await postsRef
        .document(widget.currentUser.id)
        .collection("usersPosts")
        .document(postId)
        .setData({
      "name": widget.currentUser.username,
      "ownerId": widget.currentUser.id,
      "postId": postId,
      "mediaUrl": mediaurl,
      "description": description,
      "location": location,
      "likes": {},
      "timestamp": timestamp,
    });
  }

  handleSubmit() async {
    setState(() {
      isUploadPost = true;
    });
    await compressImage();
    String imageUrl = await uploadImage(_image);
    await createUserInFirestore(
        mediaurl: imageUrl,
        location: locationController.text,
        description: _descriptionController.text);
    locationController.clear();
    _descriptionController.clear();
    setState(() {
      _image = null;
      isUploadPost = false;
    });
    postId = Uuid().v4();
  }

  showDialogbox(context) {
    return showDialog(
        context: context,
        builder: (context) => SimpleDialog(
              title: Text("Create Posts"),
              children: <Widget>[
                SimpleDialogOption(
                  child: Text("Open Camera"),
                  onPressed: getImage,
                ),
                SimpleDialogOption(
                  child: Text("Import from Gallery"),
                  onPressed: getImagefromGallery,
                ),
                SimpleDialogOption(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ));
  }

  Widget buildSplashScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage("images/upload.jpg"))),
          alignment: Alignment.center,
          child: FlatButton(
            onPressed: () {
              showDialogbox(context);
            },
            child: Text(
              " Upload",
              style: TextStyle(color: Colors.white),
            ),
            color: Colors.deepOrange,
          ),
        ),
      ),
    );
  }
}
