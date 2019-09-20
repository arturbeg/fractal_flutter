import 'package:flutter/material.dart';
import 'package:fractal/pages/search.dart';
import './chat/newChatPage.dart';
import './pages/chats.dart';
import './pages/profile.dart';
import './pages/subreddits.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:core';
import './auth_state.dart';
import './login.dart';

class WhatsAppHome extends StatefulWidget {
  final DocumentSnapshot userDocument;

  WhatsAppHome({this.userDocument});
  @override
  State<StatefulWidget> createState() => new _WhatsAppHomeState();
}

class _WhatsAppHomeState extends State<WhatsAppHome>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // depends on the loggedIn status

  final _widgetOptions = [SubredditsScreen(), Search(), chats(),  LoginPage()];

  _onItemTapped(int index) {
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
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home), title: Text('Explore')),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), title: Text('Search')),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble), title: Text('Saved')),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), title: Text('Profile')),
        ],
        currentIndex: _selectedIndex,
        // fixedColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }
}
