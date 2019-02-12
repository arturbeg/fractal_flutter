import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './WhatsAppHome.dart';

void main() {
  runApp(LoginPage());
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoggedIn = false;
  var profileData;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Firestore _db = Firestore.instance;


  var facebookLogin = FacebookLogin();

  void onLoginStatusChanged(bool isLoggedIn, {profileData}) {
    setState(() {
      this.isLoggedIn = isLoggedIn;
      this.profileData = profileData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Facebook Login"),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.exit_to_app,
                color: Colors.white,
              ),
              onPressed: () => facebookLogin.isLoggedIn
                  .then((isLoggedIn) => isLoggedIn ? _logout() : {}),
            ),
          ],
        ),
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
              .where('id', isEqualTo: user.uid)
              .getDocuments();

            final List<DocumentSnapshot> documents = result.documents;

            if(documents.length == 0)  {
              // Update data to server if new user
              Firestore.instance
                .collection('users')
                .document(user.uid)
                .setData({
                  'name': user.displayName,
                  'id': user.uid
                });
            }  
          }

        } catch(e) {
          print(e);
        } 
        var graphResponse = await http.get(
            'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,picture.height(200)&access_token=${facebookLoginResult
                .accessToken.token}');

        var profile = json.decode(graphResponse.body);
        print(profile.toString());

        onLoginStatusChanged(true, profileData: profile);
        break;
    }
  }

  _displayUserData(profileData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 200.0,
          width: 200.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              fit: BoxFit.fill,
              image: NetworkImage(
                profileData['picture']['data']['url'],
              ),
            ),
          ),
        ),
        SizedBox(height: 28.0),
        Text(
          "Logged in as: ${profileData['name']}",
          style: TextStyle(
            fontSize: 20.0,
          ),
        ),
      ],
    );
  }

  _displayLoginButton() {
    return RaisedButton(
      child: Text("Login with Facebook"),
      onPressed: () => initiateFacebookLogin(),
    );
  }

  _displayHomePage() {
    // display the Tabular home page
   return WhatsAppHome();
  }

  _logout() async {
    await facebookLogin.logOut();
    _auth.signOut();
    onLoginStatusChanged(false);
    print("Logged out");
  }
}
