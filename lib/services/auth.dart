import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Runbhumi/services/services.dart';
import 'package:Runbhumi/models/User.dart';
//

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

Future signInWithGoogle() async {
  await Firebase.initializeApp();
  //Initializing the Firebase auth Serivices
  final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount!.authentication;
  //Getting the device token of the device for FCM purposes
  final String token = await FirebaseMessagingServices().getTokenz();
  final AuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleSignInAuthentication.accessToken,
    idToken: googleSignInAuthentication.idToken,
  );

  final UserCredential authResult =
      await _auth.signInWithCredential(credential);
  final User user = authResult.user!;

  if (user != null) {
    print('User is not null');
    //The user has authenticated already
    var result = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!result.exists) {
      //Creating a documnet
      GetStorage().write("userId", user.uid);
      GetStorage().write("profileImage", user.photoURL!);
      GetStorage().write("name", user.displayName!);
      GetStorage().write("token", token);
      print('User Signed Up');
      String _username = generateusername(user.email!);
      //Writing to the backend and making a document for the user
      FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          UserProfile.newuser(user.uid, _username, user.displayName,
                  user.photoURL, user.email, token)
              .toJson());
    } else {
      //Document already exists
      print('I am Here');
      if (GetStorage().read('userId') != user.uid) {
        print('Reached');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'userDeviceToken': FieldValue.arrayUnion([token]),
        });
        GetStorage().write('userId', user.uid);
        GetStorage().write("name", user.displayName!);
        GetStorage().write("profileImage", user.photoURL!);
        GetStorage().write("token", token);
      }
    }
  }
}

Future<void> signOutGoogle() async {
  //Removing the device token, since the user is logging out
  print(GetStorage().read("token"));
  FirebaseFirestore.instance
      .collection('users')
      .doc(GetStorage().read("userId"))
      .update({
    'userDeviceToken': FieldValue.arrayRemove([GetStorage().read("token")]),
  }).then((_) async {
    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
  });
  print(GetStorage().read("token"));
  print(GetStorage().read("userId"));
  GetStorage().write('token', null as String);
  GetStorage().write('userId', null as String);
  print("User Signed Out");
}

// Future saveToSharedPreference(String uid, String username, String displayName,
//     String photoURL, String emailId) async {
//   await Constants.saveName(displayName);
//   await Constants.saveProfileImage(photoURL);
//   await Constants.saveUserEmail(emailId);
//   await Constants.saveUserId(uid);
//   await Constants.saveUserName(username);
// }
