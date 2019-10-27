import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';


class CommunityModel {
  final String id;
  final String name;
  final String about;
  final CommunityOwnerModel owner;
  final DateTime timestamp;
  final String avatarURL;

  CommunityModel({this.id, this.name, this.about, this.owner, this.timestamp, this.avatarURL});

}

class CommunityOwnerModel {
  final String facebookID;
  final String id;
  final String name;
  final bool isGoogle;
  final String googleProfileURL;
  
  CommunityOwnerModel({this.facebookID, this.id, this.name, this.isGoogle, this.googleProfileURL});

  getChatOwnerModelMap() {
    final map = {'facebookID': facebookID, 'id': id, 'name': name, 'isGoogle': isGoogle, 'googleProfileURL': googleProfileURL};

    return map;
  }
}