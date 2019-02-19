import 'package:flutter/material.dart';
import '../model/status_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class profile extends StatefulWidget {
  DocumentSnapshot userDocument;
  profile({this.userDocument});

  @override
  State<StatefulWidget> createState() => new _profileState();
}

class _profileState extends State<profile> {
  @override
  Widget build(BuildContext context) {
    return _displayUserData();
  }

  _displayUserData() {
    print("THE USER DOCUMENT IS RECEIVED");
    print(widget.userDocument);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 200.0,
            width: 200.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.fill,
                image: NetworkImage(
                    // TODO: have a default photo option in the app's assets
                    //widget.userDocument['photoURL'],
                    "https://platform-lookaside.fbsbx.com/platform/profilepic/?asid=2086732544736487&height=200&ext=1552668603&hash=AeStMhlsftogsw3o"),
              ),
            ),
          ),
          SizedBox(height: 28.0),
          Text(
            //"Logged in as: ${widget.userDocument['name']}",
            "Artur Begyan",
            style: TextStyle(
              fontSize: 20.0,
            ),
          ),
        ],
      ),
    );
  }
}
