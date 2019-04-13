import 'package:flutter/material.dart';
import './chat/newChatPage.dart';
import './pages/chats.dart';
import './pages/profile.dart';
import './pages/explore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:core';
import './auth_state.dart';

class WhatsAppHome extends StatefulWidget {
  final DocumentSnapshot userDocument;

  WhatsAppHome({this.userDocument});
  @override
  State<StatefulWidget> createState() => new _WhatsAppHomeState();
}

class _WhatsAppHomeState extends State<WhatsAppHome>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;

  final _widgetOptions = [
    explore(),
    chats(),
    profile(userDocument: AuthState.currentUser)
  ];

  _onItemTapped(int index) {
    // //print("Tap tap");
    //print(index);

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = new GlobalKey<ScaffoldState>();
    // TODO: split this into StatelessWidgets one for searching, one for the initial home page
    return new Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home), title: Text('Explore')),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble), title: Text('Chats')),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), title: Text('Profile')),
        ],
        currentIndex: _selectedIndex,
        // fixedColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
      body: new Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // floatingActionButton: FloatingActionButton(
      //   elevation: 0.6,
      //   onPressed: () => startAction(),
      //   child: new Icon(Icons.message, color: Colors.white),
      //   backgroundColor: Theme.of(context).accentColor,
      // ),
    );
  }

  void startAction() {
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      return new NewChat();
    }));
  }
}
