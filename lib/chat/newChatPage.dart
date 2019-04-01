import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_state.dart';
import '../chat/chatscreen.dart';
import '../model/models.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../chat/messageInfoPage.dart';

class NewChat extends StatefulWidget {
  final bool isSubchat;
  final DocumentSnapshot parentMessageSnapshot;

  // TODO: need the parentChatSnapshot
  NewChat({this.isSubchat = false, this.parentMessageSnapshot});

  @override
  _NewChatState createState() => _NewChatState();
}

class _NewChatState extends State<NewChat> {
  final formKey = GlobalKey<FormState>();

  String _newChatName, _newChatAbout, _newChatAvatarURL = "";

  bool avatarUploaded = false;

  void _submit() async {
    if (formKey.currentState.validate()) {
      formKey.currentState.save();
      print(_newChatName);
      print(_newChatAbout);

      if (widget.isSubchat) {
        // TODO: catch errors (like in the video with Javascript Promises)
        final reference = Firestore.instance.collection('chats');
        reference.document().setData({
          "about": _newChatAbout,
          "avatarURL": _newChatAvatarURL,
          "name": _newChatName,
          "owner": {
            'id': AuthState.currentUser.documentID,
            'name': AuthState.currentUser['name'],
            'facebookID': AuthState.currentUser['facebookID']
          },
          "timestamp": FieldValue.serverTimestamp(),
          "parentMessageId": widget.parentMessageSnapshot.documentID,
          "parentChat": {
            'id': widget.parentMessageSnapshot.data['chat']['id'],
            'name': widget.parentMessageSnapshot.data['chat']['name'],
            'avatarURL': widget.parentMessageSnapshot.data['chat']['avatarURL'],
          },
          "isSubchat": true,
          "lastMessageTimestamp": FieldValue.serverTimestamp()
        });

        Navigator.of(context)
            .pushReplacement(new MaterialPageRoute(builder: (context) {
          return new MessageInfoPage(
            messageSnapshot: widget.parentMessageSnapshot,
          );
        }));
      } else {
        final DocumentReference chatDocumentReference =
            await Firestore.instance.collection("chats").add({
          "about": _newChatAbout,
          "avatarURL": _newChatAvatarURL,
          "name": _newChatName,
          "owner": {
            'id': AuthState.currentUser.documentID,
            'name': AuthState.currentUser['name'],
            'facebookID': AuthState.currentUser['facebookID']
          },
          "timestamp": FieldValue.serverTimestamp(),
          "parentMessageId": "",
          "parentChat": {
            'id': "",
            'name': "",
            'avatarURL': "",
          },
          "isSubchat": false,
          "lastMessageTimestamp": FieldValue.serverTimestamp()
        });

        chatDocumentReference.get().then((chatDocument) {
          print("Got the newly created subchat");
          var document = ChatModel();
          document.setChatModelFromDocumentSnapshot(chatDocument);

          Navigator.of(context)
              .pushReplacement(new MaterialPageRoute(builder: (context) {
            var document = ChatModel();
            document.setChatModelFromDocumentSnapshot(chatDocument);
            return new ChatScreen(chatDocument: document);
          }));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: !widget.isSubchat
            ? AppBar(
                title: new Text("New Chat"),
              )
            : null,
        body: Card(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Form(
                key: formKey,
                child: new SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // TODO: upload chat picture in here

                      FlatButton(
                          onPressed: () async {
                            File imageFile = await ImagePicker.pickImage(
                                source: ImageSource.gallery);

                            int timestamp =
                                new DateTime.now().millisecondsSinceEpoch;

                            StorageReference storageReference = FirebaseStorage
                                .instance
                                .ref()
                                .child("chat_avatar_" +
                                    timestamp.toString() +
                                    ".jpg");

                            StorageUploadTask uploadTask =
                                storageReference.putFile(imageFile);

                            StorageTaskSnapshot storageTaskSnapshot =
                                await uploadTask.onComplete;

                            storageTaskSnapshot.ref
                                .getDownloadURL()
                                .then((downloadUrl) {
                              print(downloadUrl);

                              setState(() {
                                _newChatAvatarURL = downloadUrl;
                                avatarUploaded = true;
                              });
                            });
                          },
                          child: Container(
                            height: 200.0,
                            child: !avatarUploaded
                                ? new Image.network(
                                    'https://imageog.flaticon.com/icons/png/512/27/27825.png?size=1200x630f&pad=10,10,10,10&ext=png&bg=FFFFFFFF')
                                : Image.network(_newChatAvatarURL),
                          )),
                      Center(
                        child: Text("Upload Chat Avatar"),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: "Name"),
                        validator: (input) {
                          return input.length < 1 ? "Provide a name" : null;
                        },
                        onSaved: (input) {
                          print(input);
                          _newChatName = input;
                        },
                      ),

                      TextFormField(
                        decoration: InputDecoration(labelText: "About"),
                        onSaved: (input) {
                          _newChatAbout = input;
                        },
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: RaisedButton(
                              onPressed: _submit,
                              child: Text("Create Chat"),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                )),
          ),
        ));
  }
}
