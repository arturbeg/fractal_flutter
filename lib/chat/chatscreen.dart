import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fractal/chat_screen_provider.dart';
import 'package:fractal/view/chatItem.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './messageslayout.dart';
import './chatDetail.dart';
import '../auth_state.dart';
import '../model/models.dart';
import '../login.dart';

class ChatScreen extends StatefulWidget {
  @override
  ChatScreenState createState() {
    return new ChatScreenState();
  }
}

class ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _textEditingController =
      new TextEditingController();
  bool _isComposingMessage = false;
  File imageFile;
  String imageURL;
  final reference = Firestore.instance.collection('messages');

  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  bool _isUploadingPhoto = false;

  // _onWillPop(BuildContext context, ChatModel chatDocument) {
  //   if (chatDocument.isSubchat) {
  //     Navigator.of(context).popUntil(ModalRoute.withName('/chat'));
  //   } else {
  //     Navigator.of(context).pop();
  //   }
  // }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageURL = downloadUrl;
    }, onError: (err) {});
  }

  _buildAppBarActions(
      ChatModel chatDocument, ChatScreenManager chatScreenProvider) {
    bool chatJoined = chatScreenProvider.getIsChatJoined(chatDocument.id);
    return <Widget>[
      IconButton(
        icon: chatJoined ? Icon(Icons.bookmark) : Icon(Icons.bookmark_border),
        onPressed: () {
          if (!chatJoined) {
            chatScreenProvider.joinChat(chatDocument, context);
          } else {
            chatScreenProvider.leaveChat(chatDocument.id, context);
          }
        },
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ChatScreenArguments args = ModalRoute.of(context).settings.arguments;

    ChatModel chatDocument = args.chatDocument;

    ChatScreenManager chatScreenProvider =
        Provider.of<ChatScreenManager>(context);
    
    // TODO: review later
    // TODO: make sure works fast
    // TODO: only have widget if it is a subchat
    // return WillPopScope(
    //   onWillPop: () async {
    //     if (chatDocument.isSubchat) {
    //       Navigator.of(context).popUntil(ModalRoute.withName('/chat'));
    //     } else {
    //       Navigator.of(context).pop();
    //     }
    //     return false;
    //   },
    return Scaffold(
        appBar: new AppBar(
          title: new GestureDetector(
            onTap: () {
              Navigator.push(context, new MaterialPageRoute(builder: (context) {
                return new DetailPage(
                  chatDocument: chatDocument,
                );
              }));
            },
            child: new Text(chatDocument.name),
          ),
          actions: AuthState.currentUser != null
              ? _buildAppBarActions(chatDocument, chatScreenProvider)
              : null,
        ),
        body: new Container(
          child: new Column(
            children: <Widget>[
              new Flexible(
                  child: MessagesList(
                chatDocument: chatDocument,
              )),
              new Divider(height: 1.0),
              new Container(
                decoration:
                    new BoxDecoration(color: Theme.of(context).cardColor),
                child: AuthState.currentUser != null
                    ? _buildTextComposer(chatDocument)
                    : _buildRequestToLogIn(),
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

  Widget _buildRequestToLogIn() {
    return new SizedBox(
      width: double.infinity,
      child: new FlatButton(
        child: Text('Log in to chat'),
        textColor: Colors.black,
        onPressed: () {
          Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
            return new LoginPage(redirectBack: true);
          }));
        },
      ),
    );
  }

  Widget _buildTextComposer(ChatModel chatDocument) {
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
                child: _isUploadingPhoto
                    ? CircularProgressIndicator()
                    : IconButton(
                        icon: new Icon(
                          Icons.insert_photo,
                          color: Theme.of(context).accentColor,
                          size: 32.0,
                        ),
                        onPressed: () async {
                          if (!_isUploadingPhoto) {
                            setState(() {
                              _isUploadingPhoto = true;
                            });
                            File imageFile = await ImagePicker.pickImage(
                                maxWidth: 500.0, // 640.0 is default vga
                                source: ImageSource.gallery);
                            if (imageFile == null) {
                              setState(() {
                                _isUploadingPhoto = false;
                              });
                            }
                            int timestamp =
                                new DateTime.now().millisecondsSinceEpoch;
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
                              _sendMessage(chatDocument,
                                  messageText: null,
                                  imageUrl: downloadUrl.toString());

                              setState(() {
                                _isUploadingPhoto = false;
                              });
                            });
                          }
                        }),
              ),
              new Flexible(
                child: new TextField(
                  keyboardType: TextInputType.multiline,
                  // TODO: set limit to number of lines
                  maxLines: null,
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
    ChatModel chatDocument = ModalRoute.of(context).settings.arguments;

    _textEditingController.clear();
    FocusScope.of(context).requestFocus(focusNode);
    setState(() {
      _isComposingMessage = false;
    });
    _sendMessage(chatDocument, messageText: text, imageUrl: null);
  }

  void _sendMessage(ChatModel chatDocument,
      {String messageText, String imageUrl}) {
    if (imageUrl == null && messageText.trim().length == 0) {
      //print("Not sending anything");
    } else {
      var now = new DateTime.now().millisecondsSinceEpoch;
      now = now ~/ 1000;
      var firestoreTimestamp = Timestamp(now, 0);

      reference.document().setData({
        'chat': {
          'id': chatDocument.id,
          'name': chatDocument.name,
          'avatarURL': chatDocument.avatarURL
        },
        'chatId': chatDocument.id,
        'imageURL': imageUrl,
        'text': messageText,
        'timestamp': firestoreTimestamp,
        'sender': {
          'facebookID': AuthState.currentUser['facebookID'],
          'id': AuthState.currentUser.documentID,
          'name': AuthState.currentUser['name']
        },
        'repliesCount':
            0 // 0 either means no chat created or no messages in the thread, so not displaying anythign
      });

      // send the cloud message notification

    }
  }
}
