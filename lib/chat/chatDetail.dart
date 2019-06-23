import 'dart:async';
import 'dart:io';
import '../view/chatItem.dart';

// import 'package:FlutterNews/localization/MyLocalizations.dart';
// import 'package:FlutterNews/util/date_util.dart';
// import 'package:FlutterNews/util/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:share/share.dart';

import 'package:flutter/material.dart';
import '../model/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

class DetailPage extends StatefulWidget {
  final ChatModel chatDocument;

  DetailPage({this.chatDocument});

  @override
  State<StatefulWidget> createState() => new _DetailPageState();
}

class _DetailPageState extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController = new TabController(vsync: this, initialIndex: 1, length: 2);
    print("THE URL IS");
    print(widget.chatDocument.url == "");
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.chatDocument.name),

          bottom: new TabBar(tabs: <Widget>[
            new Tab(text: "Subchats"),
            new Tab(text: "Info"),
          ], controller: _tabController),
          // actions: <Widget>[
          //   IconButton(
          //     icon: Icon(Icons.share),
          //     onPressed: () {
          //       shareNotice();
          //     },
          //     color: Colors.white,
          //   )
          // ],
        ),
        body: new TabBarView(
          controller: _tabController,
          children: <Widget>[
            _getSubchats(),
            new Container(
              margin: new EdgeInsets.all(10.0),
              child: new Material(
                elevation: 4.0,
                borderRadius: new BorderRadius.circular(6.0),
                child: new ListView(
                  children: <Widget>[
                    new Hero(
                        tag: widget.chatDocument.name,
                        child: _getImageNetwork()),
                    _getBody(
                        widget.chatDocument.name,
                        widget.chatDocument.about,
                        widget.chatDocument.url,
                        context),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  _getSubchats() {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('chats')
          .where('parentChat.id', isEqualTo: widget.chatDocument.id)
          .orderBy('lastMessageTimestamp', descending: true)
          .limit(80)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return new Text(''); // Not displaying Loading...
          default:
            return new ListView.builder(
              itemCount: snapshot.data.documents.length,
              itemBuilder: (BuildContext context, int index) {
                var chatDocument = ChatModel();
                chatDocument.setChatModelFromDocumentSnapshot(
                    snapshot.data.documents[index]);
                return new ChatItem(chatDocument: chatDocument);
              },
            );
        }
      },
    );
  }

  Widget _getImageNetwork() {
    return new Container(
        // height: 200.0,
        child: widget.chatDocument.avatarURL != ""
            ? Image.network(
                widget.chatDocument.avatarURL,
                fit: BoxFit.cover,
              )
            : null

        // new Image.asset(
        //     'assets/default-chat.png',
        //     fit: BoxFit.cover,
        );
  }

  Widget _getBody(tittle, description, link, context) { 
    print(widget.chatDocument.isSubchat);  
    return new Container(
      margin: new EdgeInsets.all(15.0),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.chatDocument.isSubchat
            ? <Widget>[
                _getTittle(tittle),
                _getDescription(description),
              ]
            : <Widget>[
                _getTittle(tittle),
                // _getDate(date,origin),
                _getDescription(description),
                _getAntLink(),
                _getLink(link, context),
                _getOriginalAntRedditLink(),
                _getRedditPostLink(context),
              ],
      ),
    );
  }

  Widget _getAntLink() {
    if (widget.chatDocument.url != "") {
      return new Container(
        margin: new EdgeInsets.only(top: 10.0),
        child: new Text(
          "Read more:",
          style: new TextStyle(
              fontWeight: FontWeight.bold, color: Colors.grey[600]),
        ),
      );
    } else {
      return new Text("");
    }
  }

  Widget _getOriginalAntRedditLink() {
    // if (widget.chatDocument.url != "") {
    return new Container(
      margin: new EdgeInsets.only(top: 10.0),
      child: new Text(
        "Original Reddit post:",
        style:
            new TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
      ),
    );
    // } else {
    //   return new Text("");
    // }
  }

  Widget _getLink(link, context) {
    if (widget.chatDocument.url != null) {
      if (widget.chatDocument.url != "") {
        return new GestureDetector(
          child: new Text(
            link,
            style: new TextStyle(color: Colors.blue),
          ),
          onTap: () {
            _launchURL(widget.chatDocument.url, context);
          },
        );
      }
    } else {
      return new Text("");
    }
  }

  Widget _getRedditPostLink(context) {
    if (widget.chatDocument.reddit.shortlink != null) {
      if (widget.chatDocument.url != "") {
        return new GestureDetector(
          child: new Text(
            widget.chatDocument.reddit.shortlink,
            style: new TextStyle(color: Colors.blue),
          ),
          onTap: () {
            _launchURL(widget.chatDocument.reddit.shortlink, context);
          },
        );
      }
    } else {
      return new Text("");
    }
  }

  _getTittle(tittle) {
    return new Text(
      tittle,
      style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
    );
  }

  // _getDate(date,origin) {

  //   return new Container(
  //     margin: new EdgeInsets.only(top: 4.0),
  //     child: new Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: <Widget>[
  //         new Text(new DateUtil().buildDate(date),
  //           style: new TextStyle(
  //               fontSize: 10.0,
  //               color: Colors.grey
  //           ),
  //         ),
  //         new Text(origin,
  //           style: new TextStyle(
  //               fontSize: 10.0,
  //               color: Colors.grey
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }

  _getDescription(description) {
    return new Container(
      margin: new EdgeInsets.only(top: 20.0),
      child: new Text(description),
    );
  }

  _launchURL(url, context) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

// Future shareNotice() async {
//   await Share.share("$_title:\n$_link");
// }

// void _showDialog(context) {
//   // flutter defined function
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       // return object of type Dialog
//       return AlertDialog(
//         content: new Text(strl.trans("text_copy")),
//         actions: <Widget>[
//           // usually buttons at the bottom of the dialog
//           new FlatButton(
//             child: new Text(strl.trans("text_fechar")),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//           ),
//         ],
//       );
//     },
//   );
// }
