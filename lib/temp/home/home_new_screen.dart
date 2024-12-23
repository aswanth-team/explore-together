import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart';
import '../../utils/loading.dart';
import '../../user/screens/userDetailsScreen/others_user_profile.dart';
import '../../user/screens/userDetailsScreen/post&trip/post&trip/other_user_post_detail_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = "";
  List<String> suggestions = [];
  bool isSearchTriggered = false;
  bool isLoading = false;
  bool hasMorePosts = true;

  List<DocumentSnapshot> posts = [];
  Map<String, Map<String, dynamic>> users = {};

  DocumentSnapshot? _lastDocument;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    fetchSuggestions();
    _scrollController.addListener(_onScroll);
    _fetchInitialPosts();
  }

  Future<void> fetchSuggestions() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('post').get();

    final suggestionSet = <String>{};
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      suggestionSet.add(data['locationName']);
      suggestionSet.addAll(List<String>.from(data['visitedPlaces'] ?? []));
      suggestionSet.addAll(List<String>.from(data['planToVisitPlaces'] ?? []));
    }

    setState(() {
      suggestions = suggestionSet.toList();
    });
  }

  Future<void> _fetchInitialPosts() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch 10 random posts
      final randomQuery = await FirebaseFirestore.instance
          .collection('post')
          .orderBy(FieldPath.documentId)
          .limit(_pageSize)
          .get();

      if (randomQuery.docs.isEmpty) {
        setState(() {
          hasMorePosts = false;
          isLoading = false;
        });
        return;
      }

      // Store the last document for pagination
      _lastDocument = randomQuery.docs.last;

      // Fetch users for these posts
      await _fetchUsersForPosts(randomQuery.docs);

      setState(() {
        posts = randomQuery.docs;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching initial posts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchMorePosts() async {
    if (!hasMorePosts || isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      Query query;
      if (_searchQuery.isNotEmpty) {
        // Search-based query
        query = FirebaseFirestore.instance
            .collection('post')
            .where('locationName',
                isGreaterThan: _lastDocument?['locationName'])
            .limit(_pageSize);
      } else {
        // Random posts query
        query = FirebaseFirestore.instance
            .collection('post')
            .orderBy(FieldPath.documentId)
            .startAfterDocument(_lastDocument!)
            .limit(_pageSize);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          hasMorePosts = false;
          isLoading = false;
        });
        return;
      }

      // Update last document for next pagination
      _lastDocument = querySnapshot.docs.last;

      // Fetch users for new posts
      await _fetchUsersForPosts(querySnapshot.docs);

      setState(() {
        posts.addAll(querySnapshot.docs);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching more posts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUsersForPosts(List<DocumentSnapshot> newPosts) async {
    final userIds = newPosts.map((post) => post['userid']).toSet();

    if (userIds.isEmpty) return;

    final userSnapshots = await FirebaseFirestore.instance
        .collection('user')
        .where(FieldPath.documentId, whereIn: userIds.toList())
        .get();

    final newUsers = {
      for (var doc in userSnapshots.docs)
        doc.id: doc.data()
    };

    setState(() {
      users.addAll(newUsers);
    });
  }

  Future<void> _searchPosts() async {
    setState(() {
      isLoading = true;
      posts.clear();
      hasMorePosts = true;
      _lastDocument = null;
    });

    try {
      Query query =
          FirebaseFirestore.instance.collection('post').limit(_pageSize);

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          hasMorePosts = false;
          isLoading = false;
        });
        return;
      }

      // Filter posts based on search query
      final filteredPosts = querySnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final locationName =
            data['locationName']?.toString().toLowerCase() ?? "";
        final visitedPlaces = List<String>.from(data['visitedPlaces'] ?? [])
            .map((e) => e.toLowerCase())
            .toList();
        final planToVisitPlaces =
            List<String>.from(data['planToVisitPlaces'] ?? [])
                .map((e) => e.toLowerCase())
                .toList();

        final allSearchableFields = [
          locationName,
          ...visitedPlaces,
          ...planToVisitPlaces
        ];

        return allSearchableFields.any(
            (field) => field.similarityTo(_searchQuery.toLowerCase()) > 0.6);
      }).toList();

      if (filteredPosts.isEmpty) {
        setState(() {
          hasMorePosts = false;
          isLoading = false;
        });
        return;
      }

      _lastDocument = filteredPosts.last;

      // Fetch users for filtered posts
      await _fetchUsersForPosts(filteredPosts);

      setState(() {
        posts = filteredPosts;
        isLoading = false;
      });
    } catch (e) {
      print('Error searching posts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_searchQuery.isNotEmpty) {
        _searchPosts(); // Fetch more search results
      } else {
        _fetchMorePosts(); // Fetch more random posts
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              isSearchTriggered = false;
            });
          },
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
              isSearchTriggered = true;
              _searchPosts();
            });
          },
          decoration: InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = "";
                        isSearchTriggered = false;
                        _fetchInitialPosts();
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_searchQuery.isNotEmpty && !isSearchTriggered)
            Expanded(
              child: ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  if (!suggestion
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())) {
                    return SizedBox.shrink();
                  }
                  return ListTile(
                    title: Text(suggestion),
                    onTap: () {
                      setState(() {
                        _searchQuery = suggestion;
                        isSearchTriggered = true;
                        _searchPosts();
                      });
                    },
                  );
                },
              ),
            ),
          Expanded(
            child: posts.isEmpty && !isLoading
                ? Center(
                    child: Text(
                      'No posts available',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: posts.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == posts.length) {
                        return Center(child: LoadingAnimation());
                      }

                      var post = posts[index].data() as Map<String, dynamic>;
                      String postId = posts[index].id;
                      String userId = post['userid'];

                      if (!users.containsKey(userId)) return Container();

                      var user = users[userId]!;

                      if (user['isRemoved'] == true) return Container();

                      String locationName = post['locationName'];
                      String locationDescription = post['locationDescription'];
                      List locationImages = post['locationImages'];
                      bool tripCompleted = post['tripCompleted'];
                      String tripRating = post['tripRating'].toString();

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OtherUserPostDetailScreen(
                                  postId: postId,
                                  userId: userId,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OtherProfilePage(
                                        userId: userId,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(user['userimage']),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      user['username'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Image.network(locationImages[0]),
                              SizedBox(height: 10),
                              Text(
                                locationName,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(locationDescription),
                              SizedBox(height: 10),
                              if (tripCompleted)
                                Container(
                                  padding: EdgeInsets.all(5),
                                  color: Colors.green,
                                  child: Text(
                                    'Trip Completed',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              Text('Trip Rating: $tripRating'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
