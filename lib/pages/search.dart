import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_network/models/user.dart';
import 'package:social_network/pages/home.dart';
import 'package:social_network/pages/profile.dart';
import 'package:social_network/widgets/constant.dart';
import 'package:social_network/widgets/progress.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  Future<QuerySnapshot> searchResultsFuture;
  void handleSubmit(String query) {
    Future<QuerySnapshot> snapshot = usersRef
        .where("username", isGreaterThanOrEqualTo: query)
        .getDocuments();

    setState(() {
      searchResultsFuture = snapshot;
    });
  }

  Widget buildSearchResult() {
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocuments(doc);
          searchResults.add(UserResult(user));
        });
        print(searchResults);
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: TextFormField(
          controller: controller,
          onFieldSubmitted: handleSubmit,
          decoration: InputDecoration(
            fillColor: Colors.grey.shade100,
            filled: true,
            hintText: "Search For User",
            prefixIcon: Icon(Icons.account_circle),
            suffixIcon: IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                controller.clear();
              },
            ),
          ),
        ),
      ),
      body: searchResultsFuture == null
          ? buildEmptySearch()
          : buildSearchResult(),
    );
  }

  Container buildEmptySearch() {
    return Container(
      child: Center(
        child: ListView(
          children: <Widget>[
            Image.network(
              "https://as2.ftcdn.net/jpg/03/10/05/65/500_F_310056540_9fOjPfae83kUV9by9tamhi15XlQQu6Yt.jpg",
              height: 300,
            ),
            Text(
              "Search Here",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}

TextEditingController controller = TextEditingController();

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepPurple.shade700,
      child: ListTile(
        onTap: () {
          showProfile(context, profileId: user.id);
        },
        title: Text(
          user.displayName,
          style: knormalText,
        ),
        subtitle: Text(
          user.username,
          style: knormalTextaa,
        ),
        leading: CircleAvatar(
          backgroundImage: NetworkImage("${user.photoUrl}"),
        ),
      ),
    );
  }
}
