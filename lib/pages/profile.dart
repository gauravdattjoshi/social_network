import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_network/models/user.dart';
import 'package:social_network/pages/edit_profile.dart';
import 'package:social_network/pages/home.dart';
import 'package:social_network/widgets/header.dart';
import 'package:social_network/widgets/post.dart';
import 'package:social_network/widgets/post_tile.dart';
import 'package:social_network/widgets/progress.dart';

import 'home.dart';
import 'home.dart';
import 'home.dart';

class Profile extends StatefulWidget {
  User user;

  final String profileId;
  Profile({this.user, this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  bool isLoading = false;
  String postOrientation = "grid";
  int postCount = 0;
  List<Post> posts = [];
  int followersCount = 0;
  int followingCount = 0;
  bool isFollow = false;
  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowersCount();
    getFollowingCount();
    checkFollowing();
  }

  getFollowersCount() async {
    await followerRef
        .document(widget.profileId)
        .collection("userFollowers")
        .getDocuments()
        .then((doc) {
      followersCount = doc.documents.length;
    });
  }

  checkFollowing() async {
    await followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get()
        .then((doc) {
      setState(() {
        isFollow = doc.exists;
      });
    });
  }

  getFollowingCount() async {
    await followingRef
        .document(currentUserId)
        .collection("userFollowing")
        .getDocuments()
        .then((doc) {
      followingCount = doc.documents.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    print(widget.profileId);
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('usersPosts')
        .orderBy("timestamp", descending: true)
        .getDocuments();
    print("$snapshot is data");
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      print(snapshot.documents.length);
      posts = snapshot.documents.map((doc) {
        return Post.fromDocument(doc);
      }).toList();
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(userdetails: widget.user)));
  }

  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 250.0,
          height: 27.0,
          child: Text(
            text,
            style: TextStyle(
              color: isFollow == true ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollow == true ? Colors.white54 : Colors.blue,
            border: Border.all(
              color: Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }

  buildProfileButton() {
    // viewing your own profile - should show edit profile button
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(text: "Edit Profile", function: editProfile);
    } else if (isFollow == false) {
      return buildButton(text: "Follow", function: handleFollow);
    } else if (isFollow == true) {
      return buildButton(text: "Unfollow", function: handleUnfollow);
    }
  }

  handleFollow() async {
    setState(() {
      isFollow = true;
    });
    await followerRef
        .document(widget.profileId)
        .collection("userFollowers")
        .document(currentUserId)
        .setData({});
    await followingRef
        .document(currentUserId)
        .collection("userFollowing")
        .document(widget.profileId)
        .setData({});
    await feedsRef
        .document(widget.profileId)
        .collection("feedItems")
        .document(currentUserId)
        .setData({
      "userId": currentUserId,
      "ownerId": widget.profileId,
      "photoUrl": currentUser.photoUrl,
      "type": "follow",
      "timestamp": timestamp,
      "username": currentUser.username
    });
  }

  handleUnfollow() async {
    setState(() {
      isFollow = false;
    });
    await followerRef
        .document(widget.profileId)
        .collection("userFollowers")
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    await followingRef
        .document(currentUserId)
        .collection("userFollowing")
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    await feedsRef
        .document(widget.profileId)
        .collection("feedItems")
        .document(currentUserId)
        .get()
        .then(
      ((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      }),
    );
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocuments(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: NetworkImage(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followersCount),
                            buildCountColumn("following", followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  user.bio,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (postOrientation == "list") {
      return posts.isEmpty
          ? buildNoPosts()
          : Column(
              children: posts,
            );
    } else if (posts.isEmpty) {
      return buildNoPosts();
    }
    List<GridTile> gridTile = [];
    posts.forEach((post) {
      gridTile.add(GridTile(
          child: PostTile(
        post: post,
        userId: post.ownerId,
        postId: post.postId,
      )));
    });
    return GridView.count(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 1.5,
      crossAxisSpacing: 1.5,
      children: gridTile,
    );
  }

  Container buildNoPosts() {
    return Container(
        child: Column(
      children: <Widget>[
        CachedNetworkImage(
          fit: BoxFit.cover,
          imageUrl:
              "https://pbs.twimg.com/profile_images/1059763814131003392/E8hJgr1b_400x400.jpg",
        ),
      ],
    ));
  }

  changePostState(String orientationName) {
    setState(() {
      postOrientation = orientationName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: currentUserId == widget.profileId
          ? header(context, titleText: "Profile")
          : header(context, titleText: "Profile", leading: true),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(
            height: 0.0,
          ),
          Container(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                  icon: Icon(
                    Icons.grid_on,
                    color: postOrientation == "grid"
                        ? Colors.deepPurple
                        : Colors.grey,
                  ),
                  onPressed: () => changePostState("grid")),
              IconButton(
                  icon: Icon(
                    Icons.list,
                    color: postOrientation == "list"
                        ? Colors.deepPurple
                        : Colors.grey,
                  ),
                  onPressed: () => changePostState("list")),
            ],
          )),
          Divider(),
          buildProfilePosts(),
        ],
      ),
    );
  }
}

showProfile(context, {String profileId}) {
  Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Profile(
            profileId: profileId,
          )));
}
