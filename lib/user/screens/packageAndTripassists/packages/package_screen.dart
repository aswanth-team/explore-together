import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:explore_together/utils/loading.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package_details_screen.dart';



class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  PackagesScreenState createState() => PackagesScreenState();
}

class PackagesScreenState extends State<PackagesScreen> {
  TextEditingController searchController = TextEditingController();
  String _searchQuery = '';
  bool isSearchTriggered = false;
  bool isOffline = false;
  List<String> suggestions = [];
  List<QueryDocumentSnapshot> packages = [];
  bool isLoading = false;

  late StreamSubscription connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _fetchSuggestions();
    _fetchPackages();
  }

  @override
  void dispose() {
    connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (mounted) {
        setState(() {
          isOffline = connectivityResult == ConnectivityResult.none;
        });
      }

      connectivitySubscription =
          Connectivity().onConnectivityChanged.listen((connectivityResult) {
        if (mounted) {
          setState(() {
            isOffline = connectivityResult == ConnectivityResult.none;
          });
        }
      });
    } catch (e) {
      print('Error initializing connectivity: $e');
    }
  }

  Future<void> _fetchSuggestions() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('packages').get();

    final suggestionSet = <String>{};
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      suggestionSet.add(data['locationName'] ?? '');
      suggestionSet.addAll(List<String>.from(data['planToVisitPlaces'] ?? []));
    }

    setState(() {
      suggestions = suggestionSet.toList();
    });
  }

  Future<void> _fetchPackages() async {
    if (isOffline) return;

    setState(() {
      isLoading = true;
    });

    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('packages').get();
      setState(() {
        packages = querySnapshot.docs;
        packages.shuffle();
      });
    } catch (e) {
      print('Error fetching packages: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterPackages() {
    if (_searchQuery.isEmpty) {
      _fetchPackages();
      return;
    }

    setState(() {
      packages = packages.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final locationName = data['locationName'].toString().toLowerCase();
        final planToVisitPlaces = (data['planToVisitPlaces'] as List)
            .map((place) => place.toString().toLowerCase())
            .toList();

        return locationName.contains(_searchQuery.toLowerCase()) ||
            planToVisitPlaces
                .any((place) => place.contains(_searchQuery.toLowerCase()));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          enabled: !isOffline,
          controller: searchController,
          onChanged: isOffline
              ? null
              : (value) {
                  setState(() {
                    _searchQuery = value;
                    isSearchTriggered = false;
                  });
                },
          onSubmitted: isOffline
              ? null
              : (value) {
                  setState(() {
                    _searchQuery = value;
                    isSearchTriggered = true;
                  });
                },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: isOffline
                ? 'You are offline'
                : 'Search by location or places...',
            hintStyle: isOffline
                ? TextStyle(color: Colors.red[500], fontSize: 16)
                : TextStyle(color: Colors.grey[500], fontSize: 16),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[600],
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[600],
                    ),
                    onPressed: isOffline
                        ? null
                        : () {
                            setState(() {
                              searchController.clear();
                              _searchQuery = "";
                              isSearchTriggered = false;
                            });
                          },
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: LoadingAnimation())
              : RefreshIndicator(
                  onRefresh: isOffline ? () async {} : _fetchPackages,
                  child: packages.isEmpty
                      ? const Center(
                          child: Text(
                            'No packages available',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.99,
                          ),
                          itemCount: packages.length,
                          itemBuilder: (context, index) {
                            final package = packages[index];
                            final data = package.data() as Map<String, dynamic>;
                            final images = data['locationImages'] as List;
                            final locationName = data['locationName'];
                            final prize = data['prize'];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PackageDetailsScreen(
                                      documentId: package.id,
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Expanded(
                                      child: PageView.builder(
                                        itemCount: images.length,
                                        itemBuilder: (context, pageIndex) {
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                20.0), // Adjust radius as needed
                                            child: CachedNetworkImage(
                                              imageUrl: images[pageIndex],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                      child:
                                                          CircularProgressIndicator()),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            locationName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Prize: ₹$prize',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
          if (_searchQuery.isNotEmpty && !isSearchTriggered)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Material(
                elevation: 4,
                child: ListView.builder(
                  itemCount: suggestions.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    if (!suggestion
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase())) {
                      return const SizedBox.shrink();
                    }
                    return ListTile(
                      title: Text(suggestion),
                      trailing: const Icon(Icons.search),
                      onTap: () {
                        setState(() {
                          searchController.text = suggestion;
                          _searchQuery = suggestion;
                          isSearchTriggered = true;
                          _filterPackages();
                          FocusScope.of(context).unfocus();
                        });
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
