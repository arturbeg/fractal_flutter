import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './explore.dart';

class SubredditsScreen extends StatefulWidget {
  @override
  SubredditsScreenState createState() => new SubredditsScreenState();
}

class SubredditsScreenState extends State<SubredditsScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(body: _renderBody()),
    );
  }

  _renderBody() {
    return TopicsList();
  }
}

// With Card view
class TopicsList extends StatelessWidget {
  // final List<Topics> topics;
  final String defaultUrl =
      "https://b.thumbs.redditmedia.com/S6FTc5IJqEbgR3rTXD5boslU49bEYpLWOlh8-CMyjTY.png";

  const TopicsList({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: 1,
        itemBuilder: (context, index) {
          // var image = topics[index].iconImg.length > 0 ? topics[index].iconImg : defaultUrl;
          // var title = topics[index].displayName;
          // var desc = topics[index].publicDescription;
          final cardIcon = Container(
            padding: const EdgeInsets.all(16.0),
            margin: EdgeInsets.symmetric(vertical: 16.0),
            alignment: FractionalOffset.centerLeft,
            child: new Image.asset(
            'assets/reddit-logo.png',
            height: 64.0,
            width: 64.0
        //Image.network(defaultUrl, height: 64.0, width: 64.0),
          ));
          var cardText = Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // TODO: add JSON API in here
                  child: new Text("r/worldnews", style: headerTextStyle),
                  padding: EdgeInsets.only(bottom: 15.0),
                ),
                // TODO: add JSON API in here
                // Text(desc.length > 32 ? "${desc.substring(0, 32)}..." : desc)
                Text("A place for major news...")
              ],
            ),
          );
          return GestureDetector(
              child: Card(
                margin: EdgeInsets.all(5.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
                child: Row(
                  children: <Widget>[cardIcon, cardText],
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => explore()),
                );
              });
        });
  }
}

// TODO: Refactor into the styles folder
final baseTextStyle = const TextStyle(fontFamily: 'Poppins');

final headerTextStyle = baseTextStyle.copyWith(
  color: Colors.black,
  fontSize: 24.0,
  fontWeight: FontWeight.w600,
);
