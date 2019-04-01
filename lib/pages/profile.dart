import 'package:flutter/material.dart';
import '../model/status_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_state.dart';

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
              color: Colors.white,
              image: DecorationImage(
                fit: BoxFit.fill,
                image: NetworkImage(AuthState.facebookGraphProfileUrl), 
                //TODO: have a default photo option in the app's assets
                //AssetImage('assets/default-avatar.png')
              ),
            ),
          ),
          SizedBox(height: 28.0),
          Text(
            AuthState.currentUser['name'],
            style: TextStyle(
              fontSize: 20.0,
            ),
          ),
        ],
      ),
    );
  }
}
