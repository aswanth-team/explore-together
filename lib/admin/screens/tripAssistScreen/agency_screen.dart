import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/loading.dart';
import 'edit_agencies_screen.dart';
import 'upload_agency_screen.dart';

class TravelAgencyPage extends StatefulWidget {
  const TravelAgencyPage({super.key});

  @override
  TravelAgencyPageState createState() => TravelAgencyPageState();
}

class TravelAgencyPageState extends State<TravelAgencyPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> filteredAgencies = [];
  List<Map<String, dynamic>> allAgencies = [];
  String selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _fetchAgencies(); // Initially, show all agencies
  }

  Future<void> _fetchAgencies() async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore.collection('agencies').get();
      final agenciesList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          allAgencies = agenciesList..shuffle(Random());
          filteredAgencies = allAgencies;
        });
      }
    } catch (e) {
      print("Error fetching agencies: $e");
    }
  }
  List<String> getCategories() {
    final categories = allAgencies.map((agency) => agency['category']).toSet();
    return ['All', ...categories];
  }
  void _filterAgencies(String query) {
    setState(() {
      filteredAgencies = allAgencies.where((agency) {
        final matchSearch =
            agency['agencyName'].toLowerCase().contains(query.toLowerCase());
        final matchCategory =
            selectedCategory == "All" || agency['category'] == selectedCategory;

        return matchSearch && matchCategory;
      }).toList();
    });
  }

  Future<void> _refreshData() async {
    await _fetchAgencies();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> categories = getCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Providers"),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) => _filterAgencies(query),
              decoration: InputDecoration(
                hintText: 'Search here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterAgencies(''); // Reset filter
                  },
                ),
              ),
            ),
          ),

          // Horizontal Scrollable Category Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = category == selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                      _filterAgencies(_searchController.text);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Filtered Results
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData, // Call the refresh method
              child: GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 4,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: filteredAgencies.length,
                itemBuilder: (context, index) {
                  final agency = filteredAgencies[index];
                  return GestureDetector(
                    onTap: () {
                      final url = Uri.parse(agency['agencyWeb']!);
                      if (url.scheme == 'http' || url.scheme == 'https') {
                        launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                          // ignore: body_might_complete_normally_catch_error
                        ).catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Could not open ${url.toString()}')),
                          );
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Invalid URL: ${url.toString()}')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.grey[100],
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CachedNetworkImage(
                            imageUrl: agency['agencyImage']!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => LoadingAnimation(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              agency['agencyName']!,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditAgencyPage(agency: agency),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('agencies')
                                  .doc(agency['id'])
                                  .delete();
                              _refreshData(); // Refresh after deletion
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return const UploadAgencyPage();
            },
          );
        },
        backgroundColor: Colors.blue,
        mini: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
