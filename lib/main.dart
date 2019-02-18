import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './WhatsAppHome.dart';
import './auth_state.dart';


void main() {
  runApp(LoginPage());
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoggedIn = false;
  DocumentSnapshot userDocument;
  // var profileData;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Firestore _db = Firestore.instance;


  var facebookLogin = FacebookLogin();

  void onLoginStatusChanged(bool isLoggedIn, {userDocument}) {
    setState(() {
      this.isLoggedIn = isLoggedIn;
      this.userDocument = userDocument;
    });

    if(isLoggedIn) {
      AuthState.instance.setUser(userDocument);
    } else {
      AuthState.instance.setUser(null);
    }

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        // appBar: AppBar(
        //   title: Text("Facebook Login"),
        //   actions: <Widget>[
        //     IconButton(
        //       icon: Icon(
        //         Icons.exit_to_app,
        //         color: Colors.white,
        //       ),
        //       onPressed: () => facebookLogin.isLoggedIn
        //           .then((isLoggedIn) => isLoggedIn ? _logout() : {}),
        //     ),
        //   ],
        // ),
        body: Container(
          child: Center(
            child: isLoggedIn
                ? _displayHomePage()
                : _displayLoginButton(),
          ),
        ),
      ),
    );
  }

  //   static Future<String> signInWithFacebok(String accessToken) async {
    
  //   final FacebookAccessToken accessToken = result.accessToken;

  //   FirebaseUser user = await FirebaseAuth.instance
  //       .signInWithCredential(token: accessToken);
  //   return user.uid;
  // }

  void initiateFacebookLogin() async {
    var facebookLoginResult =
        await facebookLogin.logInWithReadPermissions(['email']);
    

    switch (facebookLoginResult.status) {
      case FacebookLoginStatus.error:
        onLoginStatusChanged(false);
        break;
      case FacebookLoginStatus.cancelledByUser:
        onLoginStatusChanged(false);
        break;
      case FacebookLoginStatus.loggedIn:
        
        try {

          final FacebookAccessToken accessToken = facebookLoginResult.accessToken;
          AuthCredential credential = FacebookAuthProvider.getCredential(accessToken:   accessToken.token);
          FirebaseUser user = await _auth.signInWithCredential(credential);
          print("signed in " + user.displayName);

          if(user != null) {
            final QuerySnapshot result = await Firestore.instance.collection('users')
              .where('uid', isEqualTo: user.uid)
              .getDocuments();

            final List<DocumentSnapshot> documents = result.documents;

            var graphResponse = await http.get(
            'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,picture.height(200)&access_token=${facebookLoginResult
                .accessToken.token}');

            var profile = json.decode(graphResponse.body);
            print(profile.toString());

            
            // TODO: check if works
            if(documents.length == 0)  {
              // Update data to server if new user
              Firestore.instance
                .collection('users')
                .document(user.uid)
                .setData({
                  'name': user.displayName,
                  'about': "",
                  "email": user.email,
                  "lastSeen": Timestamp(user.metadata.lastSignInTimestamp,0),
                  "avatarURL": profile['picture']['data']['url'], // might change to store on firebase storage
                  "timestamp": Timestamp(user.metadata.creationTimestamp,0),
                  'uid': user.uid,
                  "username": ""
                });

                var userDocumentNew = await Firestore.instance.collection('users').document(user.uid).get();

                onLoginStatusChanged(true, userDocument: userDocumentNew);

            } else {
              var userDocumentNew = await Firestore.instance.collection('users').document(user.uid).get();

              onLoginStatusChanged(true, userDocument: userDocumentNew);
            }

            

            break; 
          }

        } catch(e) {
          print(e);
        } 
        
    }
  }

  _displayLoginButton() {
    return RaisedButton(
      child: Text("Login with Facebook"),
      onPressed: () => initiateFacebookLogin(),
    );
  }

  _displayHomePage() {
    // TODO: provide profile data to the Home Page
   return WhatsAppHome(userDocument: userDocument);
  }

  _logout() async {
    await facebookLogin.logOut();
    _auth.signOut();
    onLoginStatusChanged(false);
    print("Logged out");
  }
}
