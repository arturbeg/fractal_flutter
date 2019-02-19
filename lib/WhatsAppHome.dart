import 'package:flutter/material.dart';
import './view/camera_full.dart';
import './chat/newChatPage.dart';
import './view/new_call.dart';
import './pages/chats.dart';
import './pages/profile.dart';
import './pages/explore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './pages/search_results.dart';
import './chat/algolia.dart';
import 'dart:async';
import 'dart:core';
import './view/chatItem.dart';
import './model/models.dart';
import './chat/chatscreen.dart';

class WhatsAppHome extends StatefulWidget {
  final DocumentSnapshot userDocument;

  WhatsAppHome({this.userDocument});
  @override
  State<StatefulWidget> createState() => new _WhatsAppHomeState();
}

class _WhatsAppHomeState extends State<WhatsAppHome>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  _fab selectedfab;

  // Controls the Text Label we use as a search bar
  // final TextEditingController _filter = new TextEditingController();

  // bool _isSearching = false;

  // String _searchText = "";

  // List chatSearchResults = new List(); // chats we get from Algolia

  // Icon _searchIcon = new Icon(Icons.search);

  // Widget _appBarTitle = new Text('Fractal');

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(_handleTab);
    selectedfab = fablist[1];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTab() {
    setState(() {
      selectedfab = fablist[_tabController.index];
    });
  }

//   void _searchPressed() {
//   setState(() {
//     if (this._searchIcon.icon == Icons.search) {
//       this._searchIcon = new Icon(Icons.close);
//       this._appBarTitle = new TextField(
//         controller: _filter,
//         decoration: new InputDecoration(
//           prefixIcon: new Icon(Icons.search),
//           hintText: 'Search...'
//         ),
//       );
//     } else {
//       this._searchIcon = new Icon(Icons.search);
//       this._appBarTitle = new Text('Search Example');
//       filteredNames = names;
//       _filter.clear();
//     }
//   });
// }

  // void _searchPressed() {
  //   setState(() {
  //     if (this._searchIcon.icon == Icons.search) {
  //       this._searchIcon = new Icon(Icons.close);
  //       this._isSearching = true;
  //       this._appBarTitle = new TextField(
  //         controller: _filter,
  //         decoration: new InputDecoration(
  //             prefixIcon: new Icon(Icons.search), hintText: 'Search...'),
  //       );
  //     } else {
  //       this._searchIcon = new Icon(Icons.search);
  //       this._appBarTitle = new Text('Fractal');
  //       this._isSearching = false;
  //       _filter.clear();
  //     }
  //   });
  // }

  _WhatsAppHomeState() {
    // _filter.addListener(() {
    //   if (_filter.text.isEmpty) {
    //     setState(() {
    //       _searchText = "";
    //       // filteredNames = names;
    //     });
    //   } else {
    //     setState(() {
    //       _searchText = _filter.text;
    //     });
    //   }
    // });
  }

  // Widget _buildSearchResults() {
  //   if (!(_searchText.isEmpty)) {
  //     print("Search Text contains stuff");

  //     Future<dynamic> snapshots =
  //         AlgoliaApplication.instance.performChatQuery(_searchText);
  //     print(snapshots.runtimeType.toString());

  //     return FutureBuilder(
  //       future: snapshots,
  //       builder: (BuildContext context, AsyncSnapshot snapshot) {
  //         switch (snapshot.connectionState) {
  //           case ConnectionState.none:
  //             return Text("Connection state is NONE");
  //           case ConnectionState.active:
  //           case ConnectionState.waiting:
  //             return Text("Awaiting result...");
  //           case ConnectionState.done:
  //             print("Connection is established");
  //             if (snapshot.hasError) {
  //               return Text("Error: ${snapshot.error}");
  //             }
  //             return ListView.builder(
  //               itemCount: snapshot.data.nbHits,
  //               itemBuilder: (BuildContext context, int index) {
  //                 var chatDocument = ChatModel();
  //                 chatDocument.setChatModelFromAlgoliaSnapshot(
  //                     snapshot.data.hits[index].data);
  //                 return new GestureDetector(
  //                     onTap: () {
  //                       Navigator.push(context,
  //                           new MaterialPageRoute(builder: (context) {
  //                         print(chatDocument.id);
  //                         return new ChatScreen(chatDocument: chatDocument);
  //                       }));
  //                     },
  //                     child: ChatItem(
  //                       chatDocument: chatDocument,
  //                       heroTag: "searchResult",
  //                     ));
  //               },
  //             );
  //         }
  //         print("Unreachable");
  //         return null; // unreachable
  //       },
  //     );

  //     //       return StreamBuilder<QuerySnapshot>(
  //     //   stream: joinedChats,
  //     //   builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
  //     //     if (snapshot.hasError)
  //     //       return new Text('Error: ${snapshot.error}');
  //     //     switch (snapshot.connectionState) {
  //     //       case ConnectionState.waiting: return new Text('Loading...');
  //     //       default:
  //     //         return new ListView(
  //     //           children: snapshot.data.documents.map((DocumentSnapshot document) {

  //     //             return new ChatItem(chatDocument: document);
  //     //           }).toList(),
  //     //         );
  //     //     }
  //     //   },
  //     // )

  //     // return Text("Something in here");

  //     //       return ListView.builder(
  //     //   itemCount: names == null ? 0 : filteredNames.length,
  //     //   itemBuilder: (BuildContext context, int index) {
  //     //     return new ListTile(
  //     //       title: Text(filteredNames[index]['name']),
  //     //       onTap: () => print(filteredNames[index]['name']),
  //     //     );
  //     //   },
  //     // );

  //   } else {
  //     print("Search Text contains nothing");
  //     return Text("Nothing to display");
  //   }
  //   // return Text("Will work this shit");
  // }

  @override
  Widget build(BuildContext context) {
    final key = new GlobalKey<ScaffoldState>();
    // TODO: split this into StatelessWidgets one for searching, one for the initial home page
    return new Scaffold(
      // appBar: new AppBar(
      //   // TODO: add the signout button
      //   // title: _appBarTitle,
      //   // backgroundColor: Colors.black.withOpacity(0.7),
      //   // leading: new IconButton(
      //   //   icon: _searchIcon,
      //   //   onPressed: _searchPressed,
      //   // ),
      //   // elevation: 0.7,
      //   bottom: new TabBar(
      //           controller: _tabController,
      //           indicatorColor: Colors.white,
      //           tabs: <Widget>[
      //             new Tab(text: "EXPLORE"),
      //             new Tab(text: "CHATS"),
      //             new Tab(text: "PROFILE")
      //           ],
      //         )
      //       ,
      // ),
      body: new SafeArea(
          child: Column(
        children: <Widget>[
          new Material(
            color: Colors.blue,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: <Widget>[
                new Tab(text: "EXPLORE"),
                new Tab(text: "CHATS"),
                new Tab(text: "PROFILE")
              ],
            ),
          ),
          Expanded(
            child: new TabBarView(
              controller: _tabController,
              children: <Widget>[
                new explore(),
                new chats(),
                new profile(
                  userDocument: widget.userDocument,
                ),
                // new status(),
              ],
            ),
          )
        ],
      )),
      floatingActionButton: buildFloatingActionButton(selectedfab),
    );
  }

  Widget buildFloatingActionButton(_fab page) {
    if (!page.fabDefined) return null;
    return new FloatingActionButton(
      key: page.fabKey,
      backgroundColor: Theme.of(context).accentColor,
      child: new Icon(page.fabIcon.icon, color: Colors.white),
      onPressed: () => startAction(page),
      elevation: 0.6,
    );
  }

  void startAction(_fab page) {
    switch (page.label) {
      case "chats":
        Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
          // return new contacts();
          return new NewChat();
        }));
        break;
      // case "status":
      //   Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      //     print("clicled");
      //     return new camera_full();
      //   }));
      //   break;
      // case "calls":
      //   Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      //     print("clicled");
      //     return new new_call();
      //   }));
    }
  }
}

class _fab {
  _fab({this.label, this.icon});
  final IconData icon;
  final String label;
  Icon get fabIcon => new Icon(icon);
  bool get fabDefined => icon != null;
  Key get fabKey => new ValueKey<Icon>(fabIcon);
  //Key get fabKey => new ValueKey<Color>(fabColor);
}

List<_fab> fablist = [
  new _fab(icon: null),
  new _fab(
    label: "chats",
    icon: Icons.message,
  ),
  new _fab(icon: null),
  // new _fab(label: "status", icon: Icons.photo_camera),
  // new _fab(label: "calls", icon: Icons.add_call),
];
