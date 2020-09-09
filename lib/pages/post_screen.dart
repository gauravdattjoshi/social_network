import 'package:flutter/material.dart';
import 'package:social_network/pages/home.dart';
import 'package:social_network/widgets/header.dart';
import 'package:social_network/widgets/post.dart';
import 'package:social_network/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;
  PostScreen({this.postId, this.userId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context)),
          title: Text(
            "Post",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.0,
            ),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).accentColor,
        ),
        body: FutureBuilder(
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return circularProgress();
            }

            Post post = Post.fromDocument(snapshot.data);
            return ListView(children: [
              Container(
                child: post,
              )
            ]);
          },
          future: postsRef
              .document(userId)
              .collection('usersPosts')
              .document(postId)
              .get(),
        ));
  }
}
