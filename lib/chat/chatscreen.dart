// Version 1.1
import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import './messageslayout.dart';
import '../auth_state.dart';
import '../model/models.dart';



class ChatScreen extends StatefulWidget {
  
  final ChatModel chatDocument;
  ChatScreen({this.chatDocument});
  
  @override
  ChatScreenState createState() {
    return new ChatScreenState();
  }
}

class ChatScreenState extends State<ChatScreen> {

  
  final TextEditingController _textEditingController =
      new TextEditingController();
  bool _isComposingMessage = false;

  File imageFile;
  String imageURL;


  // reference to the database in here
  final Firestore _db = Firestore.instance;
  final reference = Firestore.instance.collection('messages');

  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();


  DocumentSnapshot currentUser;

  void initState() {
    super.initState();
    currentUser = AuthState.currentUser;
    print("THE CURRENT USER IS:");
    print(currentUser['name']);
    // focusNode.addListener(onFocusChange);
  }

  Future uploadFile() async {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
      StorageUploadTask uploadTask = reference.putFile(imageFile);
      StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
      storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageURL = downloadUrl;
      // setState(() {
      //   onSendMessage(imageURL, 1);
      // });
    }, onError: (err) {
      // setState(() {
      //   isLoading = false;
      // });
      // Fluttertoast.showToast(msg: 'This file is not an image');
      print("This file is not an image");
    });
  }

  // TODO: implemnt upload file to the firebase storage
  //   Future uploadFile() async {
  //   String fileName = DateTime.now().millisecondsSinceEpoch.toString();
  //   StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
  //   StorageUploadTask uploadTask = reference.putFile(imageFile);
  //   StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
  //   storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
  //     imageUrl = downloadUrl;
  //     setState(() {
  //       isLoading = false;
  //       onSendMessage(imageUrl, 1);
  //     });
  //   }, onError: (err) {
  //     setState(() {
  //       isLoading = false;
  //     });
  //     Fluttertoast.showToast(msg: 'This file is not an image');
  //   });
  // }
  // TODO: use to display timestamp in a nice way --> DateFormat 
  // Container(
  //                   child: Text(
  //                     DateFormat('dd MMM kk:mm')
  //                         .format(DateTime.fromMillisecondsSinceEpoch(int.parse(document['timestamp']))),
  //                     style: TextStyle(color: greyColor, fontSize: 12.0, fontStyle: FontStyle.italic),
  //                   ),
  //                   margin: EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0),

  // TODO: implement loading
  //   Widget buildLoading() {
  //   return Positioned(
  //     child: isLoading
  //         ? Container(
  //             child: Center(
  //               child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
  //             ),
  //             color: Colors.white.withOpacity(0.8),
  //           )
  //         : Container(),
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.chatDocument.name),
        ),
        body: new Container(
          child: new Column(
            children: <Widget>[
              new Flexible(
                child: MessagesList(chatDocument: widget.chatDocument,)
                
                
                ),
              new Divider(height: 1.0),
              new Container(
                decoration:
                    new BoxDecoration(color: Theme.of(context).cardColor),
                child: _buildTextComposer(),
              ),
              new Builder(builder: (BuildContext context) {
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
                      File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
                      int timestamp = new DateTime.now().millisecondsSinceEpoch;
                      StorageReference storageReference = FirebaseStorage
                          .instance
                          .ref()
                          .child("img_" + timestamp.toString() + ".jpg");
                      
                      StorageUploadTask uploadTask =
                          storageReference.putFile(imageFile);

                      StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete; 

                      storageTaskSnapshot.ref.getDownloadURL().then(
                        (downloadUrl) {
                          print(downloadUrl);
                          _sendMessage(
                            messageText: null, imageUrl: downloadUrl.toString()
                          );
                        }
                      );   

                    }),
              ),
              new Flexible(
                child: new TextField(
                  focusNode: focusNode,
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
    FocusScope.of(context).requestFocus(focusNode);
    setState(() {
      _isComposingMessage = false;
    });

    // await _ensureLoggedIn();
    _sendMessage(messageText: text, imageUrl: null);
  }

  void _sendMessage({String messageText, String imageUrl}) {
    
    var now = new DateTime.now().millisecondsSinceEpoch;
    now = now ~/ 1000;
    var firestoreTimestamp = Timestamp(now, 0);
    
    reference.document().setData({
      'chatId': widget.chatDocument.id,
      'imageURL': imageUrl,
      'text': messageText,
      'timestamp': firestoreTimestamp,
      'sender': {
        'avatarURL': currentUser['avatarURL'],
        'id': currentUser.documentID,
        'name': currentUser['name']
      },
      'subchatsCount': 0
    }
    );

    // analytics.logEvent(name: 'send_message');
  }


  // TODO: check this code out, might help with the Loading... issues
  // StreamBuilder<List<Content>> _getContentsList(BuildContext context) {
  //   final BlocProvider blocProvider = BlocProvider.of(context);
  //   int page = 1;
  //   return StreamBuilder<List<Content>>(
  //       stream: blocProvider.contentBloc.contents,
  //       initialData: [],
  //       builder: (context, snapshot) {
  //         if (snapshot.data.isNotEmpty) {
  //           return ListView.builder(itemBuilder: (context, index) {
  //             if (index < snapshot.data.length) {
  //               return ContentBox(content: snapshot.data.elementAt(index));
  //             } else if (index / 5 == page) {
  //               page++;
  //               blocProvider.contentBloc.index.add(index);
  //             }
  //           });
  //         } else {
  //           return Center(
  //             child: CircularProgressIndicator(),
  //           );
  //         }
  //       });
  // }



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
