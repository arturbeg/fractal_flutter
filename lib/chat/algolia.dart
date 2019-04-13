import 'package:algolia/algolia.dart';
import 'dart:async';

class AlgoliaApplication {
  // static
  final Algolia algolia = Algolia.init(
    applicationId: 'QIKU5RD9Q7',
    apiKey: '8096a2944438fd1c7cd0f7b771c85973',
  );

  static AlgoliaApplication instance = new AlgoliaApplication._();
  AlgoliaApplication._();
  
  performChatQuery(query) async {
    AlgoliaQuery searchResults = algolia.instance.index('chats_search').search(query);
    // Get Result/Objects
    AlgoliaQuerySnapshot snapshots = await searchResults.getObjects();
    
    // Checking if has [AlgoliaQuerySnapshot]
    //print('\n\n');
    //print('Hits count: ${snapshots.nbHits}');

    // I can make changes to the data at the async stage
    return snapshots;
  }



}

