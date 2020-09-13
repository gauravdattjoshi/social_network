const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { user } = require('firebase-functions/lib/providers/auth');
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.onCreateFollower = functions.firestore.document(
    "/followers/{userId}/userFollowers/{followerId}"
).onCreate(
   async (snapshot, context)=> {
       console.log("Followers Created", snapshot.data())
        const userId = context.params.userId;
        const followerId=  context.params.followerId;
   
   const followerdUserPostsRef=    admin.firestore().collection("posts").doc(userId).collection("usersPosts");
   const timelinePostRef=    admin.firestore().collection("timeline").doc(followerId).collection("timelinePosts");
  const querySnapshot= await followerdUserPostsRef.get();
querySnapshot.forEach( doc => {
  const data=  doc.data();
  const postId = doc.id;
  if(doc.exists){
      timelinePostRef.doc(postId).set(data);
  }
    
})

}
);

exports.onDeleteFollower = functions.firestore.document(
    "/followers/{userId}/userFollowers/{followerId}"
).onDelete(
   async (snapshot, context)=> {
       console.log("Followers deleted", snapshot.id)
        const userId = context.params.userId;
        const followerId=  context.params.followerId;
   
   const timelinePostRef=    admin.firestore().collection("timeline").doc(followerId).collection("timelinePosts").where("ownerId","==",userId);
  const querySnapshot= await timelinePostRef.get();
querySnapshot.forEach( doc => {

  if(doc.exists){
     doc.ref.delete();
  }
    
})

}
);

exports.onCreatePost= functions.firestore.document(
  "/posts/{userId}/usersPosts/{postId}"
).onCreate(
  async(snapshot, context)=>{
    console.log("postcreated", snapshot.id)
    const userId = context.params.userId;
    const postId= context.params.postId;

    const postData= snapshot.data();


    const followersRef = admin.firestore().collection("followers").doc(userId).collection("userFollowers");
const querySnapshot =await followersRef.get();
querySnapshot .forEach(doc => {
  const followerId = doc.id;
 
  admin.firestore().collection("timeline").doc(followerId).collection("timelinePosts").doc(postId).set(postData);
 } );
  }
);


exports.onUpdatePost= functions.firestore.document(
  "/posts/{userId}/usersPosts/{postId}"
).onUpdate(
  async(change, context)=>{
    console.log("postUpdated", snapshot.id)
    const userId = context.params.userId;
    const postId= context.params.postId;

    const postData= change.after.data();


    const followersRef = admin.firestore().collection("followers").doc(userId).collection("userFollowers");
const querySnapshot =await followersRef.get();
querySnapshot .forEach(doc => {
  const followerId = doc.id;
 
 admin.firestore().collection("timeline").doc(followerId).collection("timelinePosts").doc(postId).get().then(doc=>{
   if(doc.exists){
     doc.ref.update(postData);
   }
 });

 } );
  }
);


exports.onDelete= functions.firestore.document(
  "/posts/{userId}/usersPosts/{postId}"
).onDelete(
  async(snapshot, context)=>{
    console.log("post deleted", snapshot.id)
    const userId = context.params.userId;
    const postId= context.params.postId;

  


    const followersRef = admin.firestore().collection("followers").doc(userId).collection("userFollowers");
const querySnapshot =await followersRef.get();
querySnapshot .forEach(doc => {
  const followerId = doc.id;
 
  admin.firestore().collection("timeline").doc(followerId).collection("timelinePosts").doc(postId).get().then(doc=> {
    if(doc.exists){
      doc.ref.delete();
    }
  });
 } );
  }
);