import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_state.dart';
import '../chat/chatscreen.dart';

class NewChat extends StatefulWidget {
  @override
  _NewChatState createState() => _NewChatState();
}

class _NewChatState extends State<NewChat> {

  final formKey = GlobalKey<FormState>();

  String _newChatName, _newChatAbout;

  void _submit() async {
    if(formKey.currentState.validate()) {
      formKey.currentState.save();
      print(_newChatName);
      print(_newChatAbout);

      final DocumentReference chatDocumentReference = await Firestore.instance.collection("chats").add(
        {
              "about": _newChatAbout,
              "avatarURL": "",
              
              "name": _newChatName,
              "owner": {
                'id': AuthState.currentUser.documentID,
                'name': AuthState.currentUser['name'],
                'avatarURL': AuthState.currentUser['avatarURL']
              },
              "timestamp": FieldValue.serverTimestamp(),
              "lastMessage": {
                'imageURL': "",
                'text': ""
              }
        }
      );

      final chatDocument = await chatDocumentReference.get();

      Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
          return new ChatScreen(chatDocument: chatDocument);
      }));

    }
  }
  
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("New Chat"),
        ),
        body: Card(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Name"
                    ),
                    validator: (input) {
                      return input.length < 1 ? "Provide a name" : null;
                    },
                    onSaved: (input) {
                      print(input);
                      _newChatName = input;
                    },
                  ),

                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "About"
                    ),

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
                        ),)
                    ],
                  )


                ],
              ),

            ),
          ),  
        )
    );}
}
