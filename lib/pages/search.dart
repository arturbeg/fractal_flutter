import 'package:flutter/material.dart';
import 'package:fractal/chat/algolia.dart';
import 'package:fractal/model/models.dart';
import 'package:fractal/view/chatItem.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _filter = new TextEditingController();
  String _searchText = "";
  List chatSearchResults = new List(); // chats we get from Algolia

  _SearchState() {
    _filter.addListener(() {
      if (_filter.text.isEmpty) {
        setState(() {
          _searchText = "";
          // filteredNames = names;
        });
      } else {
        setState(() {
          _searchText = _filter.text;
        });
      }
    });
  }

  Widget _buildSearchResults() {
    if (!(_searchText.isEmpty)) {
      Future<dynamic> snapshots =
          AlgoliaApplication.instance.performChatQuery(_searchText);
      return new FutureBuilder(
        future: snapshots,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            // perform caching as well
            case ConnectionState.none:
              return Text("No connection to search results");
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Center(child: LinearProgressIndicator());
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }
              if (snapshot.data != null && snapshot.data.nbHits == 0) {
                return Center(
                  child: Text("No results"),
                );
              } else {
                return ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: snapshot.data.nbHits,
                  itemBuilder: (BuildContext context, int index) {
                    var chatDocument = ChatModel();
                    chatDocument.setChatModelFromAlgoliaSnapshot(
                        snapshot.data.hits[index].data);
                    return new ChatItem(chatDocument: chatDocument);
                  },
                );
              }
          }
          print("Unreachable");
          return null; // unreachable
        },
      );
    } else {
      return Center(
        child: Text(""),
      );
    }
  }

  _buildSearchInput() {
    return new TextField(
      controller: _filter,
      decoration: new InputDecoration(
          prefixIcon: new Icon(Icons.search), hintText: 'Search...'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          _buildSearchInput(),
          GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                FocusScope.of(context).requestFocus(new FocusNode());
              },
              child: Container(height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width, child: _buildSearchResults()), ),
        ],
      ),
    );

    // return _buildSearchResults();
  }
}
