import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_network/pages/home.dart';
import 'package:social_network/pages/post_screen.dart';
import 'package:social_network/pages/profile.dart';
import 'package:social_network/widgets/header.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  getActtivityFeed() async {
    QuerySnapshot data = await feedsRef
        .document(currentUser.id)
        .collection('feedItems')
        .orderBy("timestamp", descending: true)
        .getDocuments();
    List<ActivityFeedItem> activityFeeds = [];
    data.documents.forEach((doc) {
      activityFeeds.add(ActivityFeedItem.fromDocument(doc));
    });
    return activityFeeds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: 'Activity Feed'),
      body: Container(
        child: FutureBuilder(
          builder: (context, snapshot) {
            return ListView(
              children: snapshot.data,
            );
          },
          future: getActtivityFeed(),
        ),
      ),
    );
  }
}

String changedText;

class ActivityFeedItem extends StatelessWidget {
  final String userId;
  final String type;
  final String username;
  final String mediaUrl;
  final String photoUrl;
  final Timestamp timestamp;
  final String postId;
  final String commentData;

  ActivityFeedItem(
      {this.mediaUrl,
      this.photoUrl,
      this.commentData,
      this.postId,
      this.timestamp,
      this.type,
      this.userId,
      this.username});

  factory ActivityFeedItem.fromDocument(doc) {
    return ActivityFeedItem(
      mediaUrl: doc["mediaUrl"],
      timestamp: doc["timestamp"],
      username: doc["username"],
      photoUrl: doc["photoUrl"],
      type: doc["type"],
      postId: doc["postId"],
      userId: doc["userId"],
      commentData: doc["commentData"],
    );
  }

  checkText() {
    if (type == "likes") {
      return changedText = "liked your post";
    } else if (type == "comment") {
      return changedText = "replied: $commentData";
    } else if (type.isEmpty) {
      return changedText = "Error : no type";
    }
  }

  @override
  Widget build(BuildContext context) {
    checkText();
    return Padding(
      padding: EdgeInsets.only(bottom: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(photoUrl),
        ),
        trailing: GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PostScreen(
                          postId: postId,
                          userId: userId,
                        )));
          },
          child: CachedNetworkImage(
            imageUrl: mediaUrl,
            height: 50,
            width: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: GestureDetector(
          onTap: () {
            showProfile(context, profileId: userId);
          },
          child: RichText(
            text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.black),
                children: [
                  TextSpan(
                      text: username,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: " $changedText")
                ]),
          ),
        ),
        subtitle: Text(timeago.format(timestamp.toDate())),
      ),
    );
  }
}
