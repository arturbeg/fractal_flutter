import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fractal/chat_screen_provider.dart';
import 'package:fractal/providers/messaging_provider.dart';
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
import 'package:fractal/providers/anonimity_switch_provider.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chatDocument;

  ChatScreen({this.chatDocument});

  @override
  ChatScreenState createState() {
    return new ChatScreenState();
  }
}

class ChatScreenState extends State<ChatScreen> {

  _buildAppBarActions(
      ChatModel chatDocument, ChatScreenManager chatScreenProvider) {
    bool chatJoined = chatScreenProvider.getIsChatJoined(chatDocument.id);
    return <Widget>[
      IconButton(
        icon: chatJoined ? Icon(Icons.bookmark) : Icon(Icons.bookmark_border),
        onPressed: () {
          if (!chatJoined) {
            chatScreenProvider.joinChat(widget.chatDocument, context);
          } else {
            chatScreenProvider.leaveChat(widget.chatDocument.id, context);
          }
        },
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    ChatScreenManager chatScreenProvider =
        Provider.of<ChatScreenManager>(context);

    return Scaffold(
        appBar: new AppBar(
          title: new GestureDetector(
            onTap: () {
              Navigator.push(context, new MaterialPageRoute(builder: (context) {
                return new DetailPage(
                  chatDocument: widget.chatDocument,
                );
              }));
            },
            child: new Text(widget.chatDocument.name),
          ),
          actions: AuthState.currentUser != null
              ? _buildAppBarActions(widget.chatDocument, chatScreenProvider)
              : null,
        ),
        body: new Container(
          child: new Column(
            children: <Widget>[
              new Flexible(
                  child: MessagesList(
                chatDocument: widget.chatDocument,
              )),
              const Divider(height: 1.0),
              new Container(
                decoration:
                    new BoxDecoration(color: Theme.of(context).cardColor),
                child: AuthState.currentUser != null
                    ? new TextComposer(
                        chatDocument: widget.chatDocument,
                      )
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
}

class TextComposer extends StatefulWidget {
  final ChatModel chatDocument;

  TextComposer({this.chatDocument});

  @override
  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  CupertinoButton getIOSSendButton(MessagingManager messagingProvider) {
    return new CupertinoButton(
      child: new Text("Send"),
      onPressed: messagingProvider.isComposingMessage
          ? () => messagingProvider.textMessageSubmitted(messagingProvider.textEditingController.text)
          : null,
    );
  }

  IconButton getDefaultSendButton(MessagingManager messagingProvider) {
    return new IconButton(
      icon: new Icon(Icons.send),
      onPressed: messagingProvider.isComposingMessage
          ? () => messagingProvider.textMessageSubmitted(messagingProvider.textEditingController.text)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    AnonymitySwitch anonimitySwitchProvider = Provider.of<AnonymitySwitch>(context);

    return ChangeNotifierProvider(
        builder: (context) => MessagingManager(chatDocument: widget.chatDocument, context: context, anonimitySwitchProvider: anonimitySwitchProvider),
        child: Consumer<MessagingManager>(
          builder: (context, messagingProvider, child) {
            return new IconTheme(
                data: new IconThemeData(
                  color: messagingProvider.isComposingMessage
                      ? Theme.of(context).accentColor
                      : Theme.of(context).disabledColor,
                ),
                child: new Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: new Row(
                    children: <Widget>[
                      new Container(
                        margin: new EdgeInsets.symmetric(horizontal: 4.0),
                        child: messagingProvider.isUploadingPhoto
                            ? CircularProgressIndicator()
                            : IconButton(
                                icon: new Icon(
                                  Icons.insert_photo,
                                  color: Theme.of(context).accentColor,
                                  size: 32.0,
                                ),
                                onPressed: messagingProvider.uploadPhoto),
                      ),
                      new Flexible(
                        child: new TextField(
                          keyboardType: TextInputType.multiline,
                          // TODO: set limit to number of lines
                          maxLines: null,
                          focusNode: messagingProvider.focusNode,
                          controller: messagingProvider.textEditingController,
                          onChanged: messagingProvider.onChanged,
                          onSubmitted: messagingProvider.textMessageSubmitted,
                          decoration: new InputDecoration.collapsed(
                              hintText: "Send a message"),
                        ),
                      ),
                      new Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Theme.of(context).platform == TargetPlatform.iOS
                            ? getIOSSendButton(messagingProvider)
                            : getDefaultSendButton(messagingProvider),
                      ),
                    ],
                  ),
                ));
          },
        ));
  }
}