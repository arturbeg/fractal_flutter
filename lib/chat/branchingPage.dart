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

  Widget _buildLinkNewChatTabView() {
    return NewChat(
      isSubchat: true,
      parentMessageSnapshot: widget.messageSnapshot,
      
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: new AppBar(
              title: new Text("Create a Subchat")
            ),
            body: _buildLinkNewChatTabView()));
  }
}