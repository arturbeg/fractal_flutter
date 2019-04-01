// Version 1.1
import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import './messageslayout.dart';
import './aboutChat.dart';
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
  bool chatJoined = false;

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

    _isChatJoined().then((isJoined) {
      setState(() {
        chatJoined = isJoined;
      });
    });
  }

  Future<bool> _isChatJoined() async {
    final QuerySnapshot result = await Firestore.instance
        .collection('joinedChats')
        .where('chatId', isEqualTo: widget.chatDocument.id)
        .where('user.id', isEqualTo: AuthState.currentUser.documentID)
        .getDocuments();

    final List<DocumentSnapshot> documents = result.documents;

    return documents.length > 0 ? true : false;
  }

  // check later if all is correct
  Future<bool> _leaveChat() async {
    final QuerySnapshot result = await Firestore.instance
        .collection('joinedChats')
        .where('chatId', isEqualTo: widget.chatDocument.id)
        .where('user.id', isEqualTo: AuthState.currentUser.documentID)
        .getDocuments()
        .then((snapshot) {
      for (DocumentSnapshot ds in snapshot.documents) {
        ds.reference.delete();
      }
    });

    // TODO: check if the deletion works, catch error, etc...
    setState(() {
      chatJoined = false;
    });
  }

  _joinChat() {
    final reference = Firestore.instance.collection('joinedChats');
    reference.document().setData({
      "about": widget.chatDocument.about,
      "avatarURL": widget.chatDocument.avatarURL,
      "chatId": widget.chatDocument.id,
      "chatTimestamp": widget.chatDocument.getFirebaseTimestamp(),
      "name": widget.chatDocument.name,
      "owner": widget.chatDocument.owner.getChatOwnerModelMap(),
      "timestamp": FieldValue.serverTimestamp(),
      "user": {
        "id": AuthState.currentUser.documentID,
        "facebookID": AuthState.currentUser.data['facebookID'],
        "name": AuthState.currentUser.data['name']
      },
      "parentMessageId": widget.chatDocument.parentMessageId,
      "parentChat": widget.chatDocument.parentChat.getParentChatModelMap(),
      "isSubchat": widget.chatDocument.isSubchat,
      "lastMessageTimestamp": FieldValue.serverTimestamp()
    });

    // TODO: check if the action was actually successful, otherwise there would be duplicated
    setState(() {
      chatJoined = true;
    });
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

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new GestureDetector(
            onTap: () {
              Navigator.push(context, new MaterialPageRoute(builder: (context) {
                return new ChatView(widget.chatDocument);
              }));
            },
            child: new Text(widget.chatDocument.name),
          ),
          actions: <Widget>[
            IconButton(
              icon: chatJoined
                  ? Icon(Icons.bookmark)
                  : Icon(Icons.bookmark_border),
              onPressed: () {
                print("Button pressed");
                if (!chatJoined) {
                  _joinChat();
                } else {
                  _leaveChat();
                }
              },
            ),
          ],
        ),
        body: new Container(
          child: new Column(
            children: <Widget>[
              new Flexible(
                  child: MessagesList(
                chatDocument: widget.chatDocument,
              )),
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
                      File imageFile = await ImagePicker.pickImage(
                          source: ImageSource.gallery);
                      int timestamp = new DateTime.now().millisecondsSinceEpoch;
                      StorageReference storageReference = FirebaseStorage
                          .instance
                          .ref()
                          .child("img_" + timestamp.toString() + ".jpg");

                      StorageUploadTask uploadTask =
                          storageReference.putFile(imageFile);

                      StorageTaskSnapshot storageTaskSnapshot =
                          await uploadTask.onComplete;

                      storageTaskSnapshot.ref
                          .getDownloadURL()
                          .then((downloadUrl) {
                        print(downloadUrl);
                        _sendMessage(
                            messageText: null,
                            imageUrl: downloadUrl.toString());
                      });
                    }),
              ),
              new Flexible(
                child: new TextField(
                  focusNode: focusNode,
                  controller: _textEditingController,
                  onChanged: (String messageText) {
                    setState(() {
                      messageText = messageText.trim();
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
    if (imageUrl == null && messageText.trim().length == 0) {
      print("Not sending anything");
    } else {
      var now = new DateTime.now().millisecondsSinceEpoch;
      now = now ~/ 1000;
      var firestoreTimestamp = Timestamp(now, 0);

      reference.document().setData({
        'chat': {
          'id': widget.chatDocument.id,
          'name': widget.chatDocument.name,
          'avatarURL': widget.chatDocument.avatarURL
        },
        'chatId': widget.chatDocument.id,
        'imageURL': imageUrl,
        'text': messageText,
        'timestamp': firestoreTimestamp,
        'sender': {
          'facebookID': currentUser['facebookID'],
          'id': currentUser.documentID,
          'name': currentUser['name']
        },
        'subchatsCount': 0
      });
    }
  }
}
