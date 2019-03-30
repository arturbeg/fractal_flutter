import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './WhatsAppHome.dart';
import './auth_state.dart';
import './view/chatItem.dart';
import './model/models.dart';
import './chat/chatscreen.dart';
import './chat/algolia.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import './chat//chatscreen.dart';

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
  Icon _searchIcon = new Icon(Icons.search);
  String _searchText = "";
  List chatSearchResults = new List();
  bool _isSearching = false;  
  final TextEditingController _filter = new TextEditingController();
  Widget _appBarTitle = new Text('Fractal');

  var facebookLogin = FacebookLogin();

  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  @override
  void initState() {
    print("Initialising the app");
    super.initState();
  }     

  _LoginPageState() {
    // TODO: check if the user is logged in, in every case
    // TODO: once user is logged in
  
  }

  Widget _buildSearchResults() {
    if (!(_searchText.isEmpty)) {
      print("Search Text contains stuff");

      Future<dynamic> snapshots =
          AlgoliaApplication.instance.performChatQuery(_searchText);
      print(snapshots.runtimeType.toString());

      return FutureBuilder(
        future: snapshots,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return Text("Connection state is NONE");
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Text("Awaiting result...");
            case ConnectionState.done:
              print("Connection is established");
              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }
              return ListView.builder(
                itemCount: snapshot.data.nbHits,
                itemBuilder: (BuildContext context, int index) {
                  var chatDocument = ChatModel();
                  chatDocument.setChatModelFromAlgoliaSnapshot(
                      snapshot.data.hits[index].data);
                  return new ChatItem(
                    chatDocument: chatDocument,
                    heroTag: "searchResult",
                  );
                },
              );
          }
          print("Unreachable");
          return null; // unreachable
        },
      );
    } else {
      print("Search Text contains nothing");
      return Text("Nothing to display");
    }
    // return Text("Will work this shit");
  }

  void _searchPressed() {
    if (isLoggedIn) {
      setState(() {
        if (this._searchIcon.icon == Icons.search) {
          this._searchIcon = new Icon(Icons.close);
          this._isSearching = true;
          this._appBarTitle = new TextField(
            controller: _filter,
            decoration: new InputDecoration(
                prefixIcon: new Icon(Icons.search), hintText: 'Search...'),
          );
        } else {
          this._searchIcon = new Icon(Icons.search);
          this._appBarTitle = new Text('Fractal');
          this._isSearching = false;
          _filter.clear();
        }
      });
    } else {
      print("Log in!!!");
    }

  }

  void onLoginStatusChanged(bool isLoggedIn, {userDocument}) {
    setState(() {
      this.isLoggedIn = isLoggedIn;
      this.userDocument = userDocument;
    });

    if (isLoggedIn) {
      AuthState.instance.setUser(userDocument);
      _filter.addListener(() {
        if (_filter.text.isEmpty) {
          setState(() {
            _searchText = "";
            // filteredNames = names;
          });
        } else {
          setState(() {
            print("Changing State");
            _searchText = _filter.text;
          });
        }
      });

         _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) {
        print(message);
      },

      onLaunch: (Map<String, dynamic> message) {
        print(message);
      },

      onResume: (Map<String, dynamic> message) {
        print(message);

      }, 
    );
    _firebaseMessaging.getToken().then(
      (token) {
        print(token);
      }
    );

    } else {
      AuthState.instance.setUser(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          title: _appBarTitle,
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
          leading: new IconButton(
            icon: _searchIcon,
            onPressed: _searchPressed,
          ),
        ),
        body: !_isSearching
            ? Container(
                child: isLoggedIn ? _displayHomePage() : _displayLoginButton(),
              )
            : _buildSearchResults(),
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
          final FacebookAccessToken accessToken =
              facebookLoginResult.accessToken;
          AuthCredential credential = FacebookAuthProvider.getCredential(
              accessToken: accessToken.token);
          FirebaseUser user = await _auth.signInWithCredential(credential);
          print("signed in " + user.displayName);

          if (user != null) {
            final QuerySnapshot result = await Firestore.instance
                .collection('users')
                .where('uid', isEqualTo: user.uid)
                .getDocuments();

            final List<DocumentSnapshot> documents = result.documents;

            var graphResponse = await http.get(
                'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,picture.height(200)&access_token=${facebookLoginResult.accessToken.token}');

            var profile = json.decode(graphResponse.body);
            print(profile.toString());

            // TODO: check if works
            if (documents.length == 0) {
              // Update data to server if new user
              Firestore.instance
                  .collection('users')
                  .document(user.uid)
                  .setData({
                'name': user.displayName,
                'about': "",
                "email": user.email,
                "lastSeen": Timestamp(user.metadata.lastSignInTimestamp, 0),
                "avatarURL": profile['picture']['data']
                    ['url'], // might change to store on firebase storage
                "timestamp": Timestamp(user.metadata.creationTimestamp, 0),
                'uid': user.uid,
                "username": ""
              });

              var userDocumentNew = await Firestore.instance
                  .collection('users')
                  .document(user.uid)
                  .get();

              onLoginStatusChanged(true, userDocument: userDocumentNew);
            } else {
              var userDocumentNew = await Firestore.instance
                  .collection('users')
                  .document(user.uid)
                  .get();

              onLoginStatusChanged(true, userDocument: userDocumentNew);
            }

            break;
          }
        } catch (e) {
          print(e);
        }
    }
  }

  _displayLoginButton() {
    return Center(
      child: RaisedButton(
        child: Text("Login with Facebook"),
        onPressed: () => initiateFacebookLogin(),
      ),
    );
  }

  _displayHomePage() {
    return WhatsAppHome(userDocument: userDocument);
  }

  _logout() async {
    await facebookLogin.logOut();
    _auth.signOut();
    onLoginStatusChanged(false);
    print("Logged out");
  }
}
