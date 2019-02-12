// Version 1.0
import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import './chatmessagelistitem.dart';

class ChatScreen extends StatefulWidget {
  @override
  ChatScreenState createState() {
    return new ChatScreenState();
  }
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textEditingController =
      new TextEditingController();
  bool _isComposingMessage = false;

  // reference to the database in here
  final Firestore _db = Firestore.instance;
  final reference = Firestore.instance.collection('messages');

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Flutter Chat App"),
        ),
        body: new Container(
          child: new Column(
            children: <Widget>[
              new Flexible(
                  child: StreamBuilder<QuerySnapshot>(
                stream: Firestore.instance.collection('messages').snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError)
                    return new Text('Error: ${snapshot.error}');
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return new Text('Loading...');
                    default:
                      return new ChatMessageListItem();
                  }
                },
              )),
              new Divider(height: 1.0),
              new Container(
                decoration:
                    new BoxDecoration(color: Theme.of(context).cardColor),
                child: _buildTextComposer(),
              ),
              new Builder(builder: (BuildContext context) {
                var _scaffoldContext = context;
                return new Container(width: 0.0, height: 0.0);
              })
            ],
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? new BoxDecoration(
                  border: new Border(
                      top: new BorderSide(
                  color: Colors.grey[200],
                )))
              : null,
        ));
  }

  CupertinoButton getIOSSendButton() {
    return new CupertinoButton(
      child: new Text("Send"),
      onPressed: _isComposingMessage
          ? () => _textMessageSubmitted(_textEditingController.text)
          : null,
    );
  }

  IconButton getDefaultSendButton() {
    return new IconButton(
      icon: new Icon(Icons.send),
      onPressed: _isComposingMessage
          ? () => _textMessageSubmitted(_textEditingController.text)
          : null,
    );
  }

  Widget _buildTextComposer() {
    return new IconTheme(
        data: new IconThemeData(
          color: _isComposingMessage
              ? Theme.of(context).accentColor
              : Theme.of(context).disabledColor,
        ),
        child: new Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: new Row(
            children: <Widget>[
              new Container(
                margin: new EdgeInsets.symmetric(horizontal: 4.0),
                child: new IconButton(
                    icon: new Icon(
                      Icons.photo_camera,
                      color: Theme.of(context).accentColor,
                    ),
                    onPressed: () async {
                      // await _ensureLoggedIn();
                      File imageFile = await ImagePicker.pickImage();
                      int timestamp = new DateTime.now().millisecondsSinceEpoch;
                      StorageReference storageReference = FirebaseStorage
                          .instance
                          .ref()
                          .child("img_" + timestamp.toString() + ".jpg");
                      StorageUploadTask uploadTask =
                          storageReference.putFile(imageFile);
                      // Uri downloadUrl = (await uploadTask.future).downloadUrl;
                      // _sendMessage(
                      //     messageText: null, imageUrl: downloadUrl.toString());
                    }),
              ),
              new Flexible(
                child: new TextField(
                  controller: _textEditingController,
                  onChanged: (String messageText) {
                    setState(() {
                      _isComposingMessage = messageText.length > 0;
                    });
                  },
                  onSubmitted: _textMessageSubmitted,
                  decoration:
                      new InputDecoration.collapsed(hintText: "Send a message"),
                ),
              ),
              new Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Theme.of(context).platform == TargetPlatform.iOS
                    ? getIOSSendButton()
                    : getDefaultSendButton(),
              ),
            ],
          ),
        ));
  }

  Future<Null> _textMessageSubmitted(String text) async {
    _textEditingController.clear();

    setState(() {
      _isComposingMessage = false;
    });

    // await _ensureLoggedIn();
    _sendMessage(messageText: text, imageUrl: null);
  }

  void _sendMessage({String messageText, String imageUrl}) {
    
    // reference.push().set({
    //   'text': messageText,
    //   'email': googleSignIn.currentUser.email,
    //   'imageUrl': imageUrl,
    //   'senderName': googleSignIn.currentUser.displayName,
    //   'senderPhotoUrl': googleSignIn.currentUser.photoUrl,
    // });

    //  Firestore.instance
    //             .collection('users')
    //             .document(user.uid)
    //             .setData({
    //               'name': user.displayName,
    //               'id': user.uid
    //             });

    reference.document().setData({
      'text': messageText,
      'email': "arturbegyan98@gmail.com",
      'imageUrl': imageUrl,
      'senderName': "Artur",
      // 'senderPhotoUrl': googleSignIn.currentUser.photoUrl,  
    }
    );

    // analytics.logEvent(name: 'send_message');
  }

  // Future<Null> _ensureLoggedIn() async {
  //   GoogleSignInAccount signedInUser = googleSignIn.currentUser;
  //   if (signedInUser == null)
  //     signedInUser = await googleSignIn.signInSilently();
  //   if (signedInUser == null) {
  //     await googleSignIn.signIn();
  //     analytics.logLogin();
  //   }

  //   currentUserEmail = googleSignIn.currentUser.email;

  //   if (await auth.currentUser() == null) {
  //     GoogleSignInAuthentication credentials =
  //         await googleSignIn.currentUser.authentication;
  //     await auth.signInWithGoogle(
  //         idToken: credentials.idToken, accessToken: credentials.accessToken);
  //   }
  // }
}

// class ChatScreen extends StatefulWidget {
//   @override
//   ChatScreenState createState() {
//     return new ChatScreenState();
//   }
// }

// class ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _textEditingController =
//       new TextEditingController();
//   bool _isComposingMessage = false;

//   // reference to the database in here
//   final Firestore _db = Firestore.instance;

//   @override
//   Widget build(BuildContext context) {
//     return new Scaffold(
//         appBar: new AppBar(
//           title: new Text("Flutter Chat App"),
//           elevation:
//               Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
//         ),
//         body: new Container(
//           child: new Column(
//             children: <Widget>[
//               new Flexible(
//                   child: StreamBuilder<QuerySnapshot>(
//                 stream: Firestore.instance.collection('books').snapshots(),
//                 builder: (BuildContext context,
//                     AsyncSnapshot<QuerySnapshot> snapshot) {
//                   if (snapshot.hasError)
//                     return new Text('Error: ${snapshot.error}');
//                   switch (snapshot.connectionState) {
//                     case ConnectionState.waiting:
//                       return new Text('Loading...');
//                     default:
//                       return new ListView(
//                         children: snapshot.data.documents
//                             .map((DocumentSnapshot document) {
//                           return new ListTile(
//                             title: new Text(document['title']),
//                             subtitle: new Text(document['author']),
//                           );
//                         }).toList(),
//                       );
//                   }
//                 },
//               )),
//               new Divider(height: 1.0),
//               new Container(
//                 decoration:
//                     new BoxDecoration(color: Theme.of(context).cardColor),
//                 child: Text("Text Composer")//_buildTextComposer(),
//               ),
//               new Builder(builder: (BuildContext context) {
//                 _scaffoldContext = context;
//                 return new Container(width: 0.0, height: 0.0);
//               }),
//             ],
//           ),
//           decoration: Theme.of(context).platform == TargetPlatform.iOS
//               ? new BoxDecoration(
//                   border: new Border(
//                       top: new BorderSide(
//                   color: Colors.grey[200],
//                 )))
//               : null,
//         ));
//   }

//   CupertinoButton getIOSSendButton() {
//     return new CupertinoButton(
//       child: new Text("Send"),
//       onPressed: _isComposingMessage
//           ? () => _textMessageSubmitted(_textEditingController.text)
//           : null,
//     );
//   }

//   IconButton getDefaultSendButton() {
//     return new IconButton(
//       icon: new Icon(Icons.send),
//       onPressed: _isComposingMessage
//           ? () => _textMessageSubmitted(_textEditingController.text)
//           : null,
//     );
//   }

//   Widget _buildTextComposer() {
//     return new IconTheme(
//         data: new IconThemeData(
//           color: _isComposingMessage
//               ? Theme.of(context).accentColor
//               : Theme.of(context).disabledColor,
//         ),

//         child: new Container(
//           margin: const EdgeInsets.symmetric(horizontal: 8.0),
//           child: new Row(
//             children: <Widget>[
//               new Container(
//                 margin: new EdgeInsets.symmetric(horizontal: 4.0),
//                 child: new IconButton(
//                   icon: new Icon(
//                     Icons.photo_camera,
//                     color: Theme.of(context).accentColor,
//                   ),
//                   onPressed: () async {
//                     // work on this one
//                     await ensureLoggedIn();
//                     File imageFile = await ImagePicker.pickImage();
//                     int timestamp = new DateTime.now().millisecondsSinceEpoch;
//                       StorageReference storageReference = FirebaseStorage
//                           .instance
//                           .ref()
//                           .child("img_" + timestamp.toString() + ".jpg");
//                       StorageUploadTask uploadTask = storageReference.putFile(imageFile);

//                       // Uri downloadUrl = (await uploadTask.future).downloadUrl;
//                       // TODO: implement download url
//                       // _sendMessage()

//                   }),

//               ),
//               new Flexible(
//                 child: new TextField(
//                   controller: _textEditingController,
//                   onChanged: (String messageText) {
//                     setState(() {
//                       _isComposingMessage = messageText.length > 0;
//                     });
//                   },
//                   onSubmitted: _textMessageSubmitted,
//                   decoration:
//                     new InputDecoration.collapsed(hintText: "Send a message"),
//                 ),
//               ),

//               new Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 4.0),
//                 child:
//               )

// }

//                   }
