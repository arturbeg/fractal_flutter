// All the text composer logic in here
// Notify the listeners

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:fractal/auth_state.dart';
import 'package:fractal/model/models.dart';
import 'package:fractal/providers/anonimity_switch_provider.dart';
import 'package:image_picker/image_picker.dart';

class MessagingManager extends ChangeNotifier {
  final AnonymitySwitch anonimitySwitchProvider;
  final BuildContext context;
  final ChatModel chatDocument;

  MessagingManager(
      {this.anonimitySwitchProvider, this.context, this.chatDocument});

  bool _isComposingMessage = false;
  get isComposingMessage => _isComposingMessage;
  bool _isUploadingPhoto = false;
  get isUploadingPhoto => _isUploadingPhoto;
  final TextEditingController _textEditingController =
      new TextEditingController();
  get textEditingController => _textEditingController;
  final FocusNode _focusNode = new FocusNode();
  get focusNode => _focusNode;

  File _imageFile;

  String _imageURL;
  final _reference = Firestore.instance.collection('messages');

  onChanged(String messageText) {
    messageText = messageText.trim();
    _isComposingMessage = messageText.length > 0;
    notifyListeners();
  }

  void uploadPhoto() async {
    if (!_isUploadingPhoto) {
      _isUploadingPhoto = true;
      notifyListeners();

      File imageFile = await ImagePicker.pickImage(
          maxWidth: 500.0, // 640.0 is default vga
          source: ImageSource.gallery);

      if (imageFile == null) {
        _isUploadingPhoto = false;
        notifyListeners();
      }
      int timestamp = new DateTime.now().millisecondsSinceEpoch;
      StorageReference storageReference = FirebaseStorage.instance
          .ref()
          .child("img_" + timestamp.toString() + ".jpg");

      StorageUploadTask uploadTask = storageReference.putFile(imageFile);

      StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;

      storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
        _sendMessage(messageText: null, imageURL: downloadUrl.toString());

        _isUploadingPhoto = false;
        notifyListeners();
      });
    }
  }

  void textMessageSubmitted(String text) async {
    _textEditingController.clear();
    FocusScope.of(context).requestFocus(_focusNode);
    _isComposingMessage = false;
    notifyListeners();
    _sendMessage(messageText: text, imageURL: null);
  }

  void _sendMessage({String messageText, String imageURL}) {
    if (imageURL == null && messageText.trim().length == 0) {
      //print("Not sending anything");
    } else {
      var now = new DateTime.now().millisecondsSinceEpoch;
      now = now ~/ 1000;
      var firestoreTimestamp = Timestamp(now, 0);

      _reference.document().setData({
        'chat': {
          'id': chatDocument.id,
          'name': chatDocument.name,
          'avatarURL': chatDocument.avatarURL
        },
        'chatId': chatDocument.id,
        'imageURL': imageURL,
        'text': messageText,
        'timestamp': firestoreTimestamp,
        'sender': {
          // TODO: if anonymous don't keep other data about the sender
          'facebookID': AuthState.currentUser['facebookID'],
          'isGoogle': AuthState.currentUser['isGoogle'],
          'googleProfileURL': AuthState.currentUser['googleProfileURL'],
          'id': AuthState.currentUser.documentID,
          'name': AuthState.currentUser['name'],
          'isAnonymous': anonimitySwitchProvider.isAnonymous,
          'anonymousName': anonimitySwitchProvider.anonymousName
        },
        'repliesCount':
            0 // 0 either means no chat created or no messages in the thread, so not displaying anythign
      });

      // send the cloud message notification
    }

    Future uploadFile() async {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      StorageReference reference =
          FirebaseStorage.instance.ref().child(fileName);
      StorageUploadTask uploadTask = reference.putFile(_imageFile);
      StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
      storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
        _imageURL = downloadUrl;
      }, onError: (err) {});
    }
  }
}