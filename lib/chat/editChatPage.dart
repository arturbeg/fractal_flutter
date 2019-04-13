// TODO: finish implementing the edit page
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

class EditChat extends StatefulWidget {
  final ChatModel chatDocument;

  EditChat({this.chatDocument});

  @override
  _EditChatState createState() => _EditChatState();
}

class _EditChatState extends State<EditChat> {
  final formKey = GlobalKey<FormState>();

  String _newChatName, _newChatAbout, _newChatAvatarURL = "";
  bool avatarUploaded = false;

  void _submit() async {
    if (formKey.currentState.validate()) {
      formKey.currentState.save();

      var updatedValues; // update later
      
      if (_newChatAvatarURL != "") {
        updatedValues = {
          'name': _newChatName,
          'about': _newChatAbout,
          'avatarURL': _newChatAvatarURL
        };
      } else {
        updatedValues = {
          'name': _newChatName,
          'about': _newChatAbout,
        };
      }

      Firestore.instance
          .collection('chats')
          .document(widget.chatDocument.id)
          .updateData(updatedValues)
          .then((value) {
        // update the internal document
        widget.chatDocument.name = _newChatName;
        widget.chatDocument.about = _newChatAbout;
        widget.chatDocument.avatarURL = _newChatAvatarURL;

        Navigator.of(context).pop(widget.chatDocument);
      }).catchError((e) {
        //print(e);
      });
    }
  }

  _buildPictureToDisplay() {
    if (avatarUploaded) {
      return Image.network(_newChatAvatarURL);
    } else {
      if (widget.chatDocument.avatarURL == "") {
        return Image.asset('assets/default-chat.png');
      } else {
        return Image.network(widget.chatDocument.avatarURL);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: AppBar(
          title: new Text("Edit Chat"),
        ),
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
                              //print(downloadUrl);
                              setState(() {
                                _newChatAvatarURL = downloadUrl;
                                avatarUploaded = true;
                              });
                            });
                          },
                          child: Container(
                              height: 200.0, child: _buildPictureToDisplay())),
                      Center(
                        child: Text("Upload Chat Avatar"),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: "Name"),
                        initialValue: widget.chatDocument.name,
                        validator: (input) {
                          return input.length < 1 ? "Provide a name" : null;
                        },
                        onSaved: (input) {
                          //print(input);
                          _newChatName = input;
                        },
                      ),

                      TextFormField(
                        decoration: InputDecoration(labelText: "About"),
                        initialValue: widget.chatDocument.about,
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
                              child: Text("Submit Changes"),
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
