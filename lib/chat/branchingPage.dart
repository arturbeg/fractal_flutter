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
import './algolia.dart';
import '../view/chatItem.dart';
import '../chat/newChatPage.dart';

class BranchingPage extends StatefulWidget {
  final DocumentSnapshot messageSnapshot;

  BranchingPage({this.messageSnapshot});

  @override
  _BranchingPageState createState() => _BranchingPageState();
}

class _BranchingPageState extends State<BranchingPage> {
  String _searchText = "";
  final TextEditingController _filter = new TextEditingController();

  _BranchingPageState() {
    _filter.addListener(() {
      if (_filter.text.isEmpty) {
        setState(() {
          _searchText = "";
        });
      } else {
        setState(() {
          _searchText = _filter.text;
        });
      }
    });
  }

  Widget _buildSearchForm() {
    return new TextField(
      controller: _filter,
      decoration: new InputDecoration(
          prefixIcon: new Icon(Icons.search), hintText: 'Search...'),
    );
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
                  return new ChatItem(chatDocument: chatDocument, isSubchat: true, parentMessageSnapshot: widget.messageSnapshot,);
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
  }

  Widget _buildLinkExistingTabView() {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: Column(
        children: <Widget>[
          _buildSearchForm(),
          Expanded(
            child: SizedBox(
              height: 200.0,
              child: _buildSearchResults(),
            ),
          )
        ],
      ),
    );
  }



  Widget _buildLinkNewChatTabView() {
    return NewChat(isSubchat: true, parentMessageSnapshot: widget.messageSnapshot,);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: new AppBar(
              title: new Text("Link Message to"),
              bottom: TabBar(
                tabs: <Widget>[
                  Tab(
                    text: "New Chat",
                  ),
                  Tab(text: "Existing Chat")
                ],
              ),
            ),
            body: TabBarView(
              children: <Widget>[
                _buildLinkNewChatTabView(),
                _buildLinkExistingTabView(),
              ],
            )));
  }
}

// DefaultTabController(
//         length: 2,
//         child: Scaffold(
//           appBar: AppBar(
//             bottom: TabBar(
//               tabs: <Widget>[
//                 Tab(text: "Link to new Chat",),
//                 Tab(text: "Link to existing Chat")
//               ],
//             ),
//           ),
//         )

//       )
