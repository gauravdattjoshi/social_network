import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_network/models/user.dart';
import 'package:social_network/pages/comments.dart';
import 'package:social_network/pages/home.dart';
import 'package:social_network/pages/profile.dart';
import 'package:social_network/widgets/custom_image.dart';
import 'package:social_network/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String name;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;
  final dynamic timestamp;

  Post(
      {this.postId,
      this.ownerId,
      this.name,
      this.location,
      this.description,
      this.mediaUrl,
      this.likes,
      this.timestamp});

  factory Post.fromDocument(DocumentSnapshot doc) {
    print(doc.data);
    return Post(
      postId: doc.data['postId'],
      ownerId: doc.data['ownerId'],
      name: doc.data['name'],
      location: doc.data['location'],
      description: doc.data['description'],
      mediaUrl: doc.data['mediaUrl'],
      likes: doc.data['likes'],
      timestamp: doc.data['timestamp'],
    );
  }

  int getLikeCount(likes) {
    // if no likes, return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // if the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        name: this.name,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likeCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> {
  bool isLiked;
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String name;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  bool showHeart = false;

  _PostState({
    this.postId,
    this.ownerId,
    this.name,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likeCount,
  });

  delete() async {
    postsRef
        .document(ownerId)
        .collection('usersPosts')
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    storageRef.child("post_$postId.jpg").delete();
    var activityFeedSnapshots = await feedsRef
        .document(ownerId)
        .collection("feedItems")
        .where("postId", isEqualTo: postId)
        .getDocuments();
    activityFeedSnapshots.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    var commentSnapshots =
        await commentsRef.document(postId).collection('comment').getDocuments();
    commentSnapshots.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocuments(snapshot.data);
        return ListTile(
          leading: GestureDetector(
            onTap: () {
              showProfile(context, profileId: ownerId);
            },
            child: CircleAvatar(
              backgroundImage: NetworkImage(user.photoUrl),
              backgroundColor: Colors.grey,
            ),
          ),
          title: GestureDetector(
            onTap: () => print('showing profile'),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: currentUser.id == ownerId
              ? IconButton(
                  onPressed: () => showDialog(
                      context: context,
                      child: SimpleDialog(
                        title: Text("Want to delete the post?"),
                        children: <Widget>[
                          SimpleDialogOption(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          SimpleDialogOption(
                            child: Text("Ok"),
                            onPressed: () {
                              Navigator.pop(context);
                              delete();
                            },
                          )
                        ],
                      )),
                  icon: Icon(Icons.more_vert),
                )
              : Text(""),
        );
      },
    );
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikes,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  cycles: 0,
                  curve: Curves.elasticInOut,
                  tween: Tween(begin: 1, end: 2),
                  builder: (context, animatorState, child) {
                    return Transform.scale(
                      scale: 2,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.redAccent.shade400,
                        size: 100,
                      ),
                    );
                  },
                )
              : Text("")
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            GestureDetector(
              onTap: handleLikes,
              child: isLiked
                  ? Animator(
                      duration: Duration(milliseconds: 300),
                      cycles: 0,
                      curve: Curves.fastLinearToSlowEaseIn,
                      tween: Tween(begin: 0, end: 1),
                      builder: (context, animatorState, child) {
                        return Transform.scale(
                          scale: 1,
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ),
                        );
                      },
                    )
                  : Icon(
                      Icons.favorite_border,
                      size: 28.0,
                      color: Colors.pink,
                    ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: () => showComments(context,
                  username: name,
                  mediaUrl: mediaUrl,
                  ownerId: ownerId,
                  postId: postId),
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
                "$likeCount likes",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$name ",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Text(description))
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter()
      ],
    );
  }

  showComments(
    BuildContext context, {
    String ownerId,
    String username,
    String postId,
    String mediaUrl,
  }) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => Comments(
              commentsMediaUrl: mediaUrl,
              commentsOwnerId: ownerId,
              commentsPostId: postId,
              commentsPostUsername: username,
            )));
  }

  handleLikes() async {
    bool isLiked = likes[currentUserId] == true;
    if (isLiked == true) {
      await postsRef
          .document(ownerId)
          .collection("usersPosts")
          .document(postId)
          .updateData({"likes.$currentUserId": false});
      feedsRef
          .document(ownerId)
          .collection("feedItems")
          .document(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (isLiked == false) {
      await postsRef
          .document(ownerId)
          .collection("usersPosts")
          .document(postId)
          .updateData({"likes.$currentUserId": true});
      bool notCurrentOwner = currentUserId != ownerId;

      if (notCurrentOwner) {
        feedsRef
            .document(ownerId)
            .collection("feedItems")
            .document(postId)
            .setData({
          "userId": ownerId,
          "mediaUrl": mediaUrl,
          "postId": postId,
          "username": currentUser.username,
          "photoUrl": currentUser.photoUrl,
          "timestamp": timestamp,
          "type": "likes"
        });
      }

      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 300), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }
}
