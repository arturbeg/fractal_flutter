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
import './model/message.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import './chat//chatscreen.dart';

// Widget getErrorWidget(BuildContext context, FlutterErrorDetails error) {
//   return Center(
//     child: Text(
//       "", // TODO: short term cheating Error Appeared
//       style: Theme.of(context).textTheme.title.copyWith(color: Colors.white),
//     ),
//   );
// }

void main() {
  runApp(LoginPage());
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoggedIn = false;
  bool showCircularProgress = false;
  // SharedPreferences prefs;
  DocumentSnapshot userDocument;
  String facebookProfilePicture;
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
  final List<Message> messages = [];

  Future<Null> _function() async {
    /*
    This Function will be called every single time
    when application is opened and it will check 
    if the value inside Shared Preference exist or not
    */

    // TODO: configure to store custom user data
    print("Executing prefs");
    SharedPreferences prefs;
    prefs = await SharedPreferences.getInstance();
    if (prefs.getString("id") != null) {
      // retreive the user document and pass it to the AuthState
      // after that declare logged in state...
      setState(() {
        showCircularProgress = true;
      });
      print("Got the user");
      Firestore.instance
          .collection('users')
          .document(prefs.getString("id"))
          .get()
          .then((userDocument) {
        // print("The user is here");
        print(userDocument['name']);
        // AuthState.instance.setUser(userDocument, "");
        // isLoggedIn = true;
        onLoginStatusChanged(true, userDocument: userDocument, profileUrl: "");
      });
    } else {
      onLoginStatusChanged(false);
    }
  }

  @override
  void initState() {
    super.initState();

    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {},
      onLaunch: (Map<String, dynamic> message) async {
        final data = message['data'];
        Firestore.instance
            .collection("chats")
            .document(data['chatId'])
            .get()
            .then((chatDocument) {
          print("Chat Id");
          print(chatDocument.documentID);
          var document = ChatModel();
          document.setChatModelFromDocumentSnapshot(chatDocument);

          Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
            var document = ChatModel();
            document.setChatModelFromDocumentSnapshot(chatDocument);
            return new ChatScreen(chatDocument: document);
          }));
        });
      },
      onResume: (Map<String, dynamic> message) async {
        final data = message['data'];
        print(data['chatId']);
        Firestore.instance
            .collection("chats")
            .document(data['chatId'])
            .get()
            .then((chatDocument) {
          print("Chat Id");
          print(chatDocument.documentID);
          var document = ChatModel();
          document.setChatModelFromDocumentSnapshot(chatDocument);

          Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
            var document = ChatModel();
            document.setChatModelFromDocumentSnapshot(chatDocument);
            return new ChatScreen(chatDocument: document);
          }));
        });
      },
    );

    this._function(); // check if user already logged in from the shared preferences
  }

  _LoginPageState() {
    // TODO: check if the user is logged in, in every case
    // TODO: once user is logged in
  }

  Widget _buildSearchResults() {
    if (!(_searchText.isEmpty)) {
      //print("Search Text contains stuff");

      Future<dynamic> snapshots =
          AlgoliaApplication.instance.performChatQuery(_searchText);
      //print(snapshots.runtimeType.toString());

      return FutureBuilder(
        future: snapshots,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return Text("Connection state is NONE");
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Text(""); // Awaiting Results
            case ConnectionState.done:
              //print("Connection is established");
              if (snapshot.hasError) {
                return Text("");
              }
              return ListView.builder(
                itemCount: snapshot.data.nbHits,
                itemBuilder: (BuildContext context, int index) {
                  // TODO: the issue is probably with the error of correcly
                  // converting python generated chats into Algolia snapshots
                  print(snapshot.data.nbHits);
                  if (snapshot.data.nbHits > 0) {
                    // print("Smth");
                    var chatDocument = ChatModel();
                    chatDocument.setChatModelFromAlgoliaSnapshot(
                        snapshot.data.hits[index].data);
                    return new ChatItem(
                      chatDocument: chatDocument,
                      heroTag: "searchResult",
                    );
                  } else {
                    return null;
                  }
                },
              );
          }
          //print("Unreachable");
          return null; // unreachable
        },
      );
    } else {
      //print("Search Text contains nothing");
      return Text(""); // Nothing to display
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
      //print("Log in!!!");
    }
  }

  void onLoginStatusChanged(bool isLoggedIn,
      {userDocument, String profileUrl}) async {
    setState(() {
      this.isLoggedIn = isLoggedIn;
      this.userDocument = userDocument;
      this.showCircularProgress = false;
    });

    if (isLoggedIn) {
      AuthState.instance.setUser(userDocument, profileUrl);

      // configure shared preferences here

      SharedPreferences prefs;
      prefs = await SharedPreferences.getInstance();
      // TODO: have custom user model!!!
      prefs.setString("id", userDocument.documentID);

      // later have all the fields necessary for user model stored locally
      // 'name': user.displayName,
      // 'about': "",
      // "email": user.email,
      // "lastSeen": Timestamp(user.metadata.lastSignInTimestamp, 0),
      // "facebookID": profile[
      //     'id'],
      // "timestamp": Timestamp(user.metadata.creationTimestamp, 0),
      // 'uid': user.uid,
      // "username": ""

      _filter.addListener(() {
        if (_filter.text.isEmpty) {
          setState(() {
            _searchText = "";
          });
        } else {
          setState(() {
            //print("Changing State");
            _searchText = _filter.text;
          });
        }
      });

      _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) {
          //print(message);
        },
        onLaunch: (Map<String, dynamic> message) {
          //print(message);
        },
        onResume: (Map<String, dynamic> message) {
          //print(message);
        },
      );
      _firebaseMessaging.getToken().then((token) {
        //print(token);
      });
    } else {
      AuthState.instance.setUser(null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    //   return getErrorWidget(context, errorDetails);
    // };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          title: _appBarTitle,
          actions: isLoggedIn
              ? <Widget>[
                  IconButton(
                    icon: Icon(
                      Icons.exit_to_app,
                      color: Colors.white,
                    ),
                    onPressed: () => facebookLogin.isLoggedIn
                        .then((isLoggedIn) => isLoggedIn ? _logout() : {}),
                  ),
                ]
              : null,
          // leading: isLoggedIn
          //     ? new IconButton(
          //         icon: _searchIcon,
          //         onPressed: _searchPressed,
          //       )
          //     : null,
        ),
        body: !_isSearching
            ? Container(
                child: isLoggedIn ? _displayHomePage() : _displayLoginButton(),
              )
            : _buildSearchResults(),
      ),
    );
  }

  void initiateFacebookLogin() async {
    var facebookLoginResult =
        await facebookLogin.logInWithReadPermissions(['email']);

    setState(() {
      this.showCircularProgress = true;
    });

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
          //print("signed in " + user.displayName);

          if (user != null) {
            final QuerySnapshot result = await Firestore.instance
                .collection('users')
                .where('uid', isEqualTo: user.uid)
                .getDocuments();

            final List<DocumentSnapshot> documents = result.documents;

            var graphResponse = await http.get(
                'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,picture.height(200)&access_token=${facebookLoginResult.accessToken.token}');

            var profile = json.decode(graphResponse.body);
            //print(profile.toString());
            //print("The Facebook profile is");

            // TODO: later on everything will be retreived based on the facebook id and not name, about, etc
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
                "facebookID": profile['id'],
                "timestamp": Timestamp(user.metadata.creationTimestamp, 0),
                'uid': user.uid,
                "username": ""
              });

              var userDocumentNew = await Firestore.instance
                  .collection('users')
                  .document(user.uid)
                  .get();

              onLoginStatusChanged(true,
                  userDocument: userDocumentNew,
                  profileUrl: profile['picture']['data']['url']);
            } else {
              var userDocumentNew = await Firestore.instance
                  .collection('users')
                  .document(user.uid)
                  .get();

              onLoginStatusChanged(true,
                  userDocument: userDocumentNew,
                  profileUrl: profile['picture']['data']['url']);
            }
            break;
          }
        } catch (e) {
          //print(e);
        }
    }
  }

  _displayLoginButton() {
    if (showCircularProgress) {
      return Center(child: CircularProgressIndicator());
    } else {
      return Center(
        child: RaisedButton(
          child: Text("Sign in with Facebook"),
          onPressed: () => initiateFacebookLogin(),
        ),
      );
    }
  }

  _displayHomePage() {
    return WhatsAppHome(userDocument: userDocument);
  }

  _logout() async {
    await facebookLogin.logOut();

    SharedPreferences prefs;
    prefs = await SharedPreferences.getInstance();
    prefs.clear();
    // prefs.commit(); --> is there anything that is used instead

    _auth.signOut();
    onLoginStatusChanged(false);


  }
}
