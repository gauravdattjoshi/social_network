import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

cachedNetworkImage(mediaUrl) {
  return AspectRatio(
    aspectRatio: 1,
    child: CachedNetworkImage(
      imageUrl: mediaUrl,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) => Icon(
        Icons.error,
        color: Colors.red,
      ),
      placeholder: (context, url) => Padding(
          child: CircularProgressIndicator(), padding: EdgeInsets.all(20)),
    ),
  );
}
