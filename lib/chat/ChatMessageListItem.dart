import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';


class ChatMessageListItem extends StatelessWidget {
  
  // final DataSnapshot messageSnapshot;
  // final Animation animation;

  // ChatMessageListItem({this.animation});


  @override
  Widget build(BuildContext context) {
    return new Row(
      children: getReceivedMessageLayout(),
    );
    // return new SizeTransition(
    //   sizeFactor: 1.0// new CurvedAnimation(parent: animation, curve: Curves.decelerate),
    //   child: new Row(
    //     children: getReceivedMessageLayout(),
    //   )
    // );
  }



  List<Widget> getReceivedMessageLayout() {
    return <Widget>[
      new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: new CircleAvatar(
                backgroundImage:
                new NetworkImage("https://scontent-lht6-1.xx.fbcdn.net/v/t1.0-9/48412969_2015019108574498_3302275035338637312_n.jpg?_nc_cat=102&_nc_ht=scontent-lht6-1.xx&oh=3bffb47321f5d462cfa175f5feed39be&oe=5CDF49EB"),
          )),
        ],
      ),
      new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Text("Artur Begyan", style: new TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            new Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: new Text("Default message text")
            )        
          ],
        )
      )
    ];
  }
}