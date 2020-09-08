class User {
  User({
    this.displayName,
    this.photoUrl,
    this.username,
    this.bio,
    this.email,
    this.id,
  });

  String displayName;
  String photoUrl;
  String username;
  String bio;
  String email;
  String id;

  factory User.fromDocuments(doc) => User(
        displayName: doc["displayName"],
        photoUrl: doc["photoUrl"],
        username: doc["username"],
        bio: doc["bio"],
        email: doc["email"],
        id: doc["id"],
      );
}
