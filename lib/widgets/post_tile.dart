import 'package:flutter/material.dart';
import 'package:social_network/pages/post_screen.dart';
import 'package:social_network/widgets/custom_image.dart';
import 'package:social_network/widgets/post.dart';

class PostTile extends StatelessWidget {
  final Post post;
  final String userId;
  final String postId;
  PostTile({this.post, this.postId, this.userId});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PostScreen(
                      userId: userId,
                      postId: postId,
                    )));
      },
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}
