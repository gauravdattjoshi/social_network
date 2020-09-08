import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_network/pages/home.dart';
import 'package:social_network/widgets/header.dart';
import 'package:social_network/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String commentsPostUsername;
  final String commentsPostId;
  final String commentsMediaUrl;
  final String commentsOwnerId;

  Comments({
    this.commentsPostUsername,
    this.commentsPostId,
    this.commentsMediaUrl,
    this.commentsOwnerId,
  });
  @override
  CommentsState createState() => CommentsState(
        commentsMediaUrl: this.commentsMediaUrl,
        commentsOwnerId: this.commentsOwnerId,
        commentsPostId: this.commentsPostId,
        commentsPostUsername: this.commentsPostUsername,
      );
}

class CommentsState extends State<Comments> {
  final String commentsPostUsername;
  final String commentsPostId;
  final String commentsMediaUrl;
  final String commentsOwnerId;
  TextEditingController commentController = TextEditingController();

  CommentsState({
    this.commentsMediaUrl,
    this.commentsOwnerId,
    this.commentsPostId,
    this.commentsPostUsername,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: header(context, titleText: "Comments"),
        body: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder(
                stream: commentsRef
                    .document(commentsPostId)
                    .collection("comment")
                    .orderBy("timestamp", descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    circularProgress();
                  } else if (snapshot.hasData) {
                    List<Comment> comment = [];
                    snapshot.data.documents.forEach((doc) {
                      comment.add(Comment.fromDocument(doc));
                    });
                    return ListView(
                      children: comment,
                    );
                  }
                },
              ),
            ),
            Divider(),
            ListTile(
              title: TextFormField(
                controller: commentController,
                decoration: InputDecoration(
                    suffixIcon: OutlineButton(
                      onPressed: () async {
                        await commentsRef
                            .document(commentsPostId)
                            .collection("comment")
                            .add({
                          "avatarUrl": commentsMediaUrl,
                          "postId": commentsPostId,
                          "userId": commentsOwnerId,
                          "comment": commentController.text,
                          "timestamp": timestamp
                        });
                        commentController.clear();
                      },
                      child: Text(
                        "Post",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    labelText: "Add a Comment",
                    hintText: "Write comment"),
              ),
            )
          ],
        ));
  }
}

class Comment extends StatelessWidget {
  final String userId;
  final String avatarUrl;
  final String postId;
  final String comment;
  final Timestamp timestamp;
  Comment(
      {this.userId, this.avatarUrl, this.postId, this.comment, this.timestamp});

  factory Comment.fromDocument(doc) => Comment(
        avatarUrl: doc["avatarUrl"],
        postId: doc["postId"],
        comment: doc["comment"],
        timestamp: doc["timestamp"],
        userId: doc["userId"],
      );
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(comment),
      subtitle: Text(
        timeago.format(
          timestamp.toDate(),
        ),
      ),
      leading: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(currentUser.photoUrl),
      ),
    );
  }
}
