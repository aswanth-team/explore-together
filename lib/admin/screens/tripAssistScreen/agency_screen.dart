import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/agencies.dart';
import 'agency_upload_screen.dart';

void main() {
  runApp(const MaterialApp(
    home: TravelAgencyPage(),
  ));
}

class TravelAgencyPage extends StatefulWidget {
  const TravelAgencyPage({super.key});

  @override
  _TravelAgencyPageState createState() => _TravelAgencyPageState();
}

class _TravelAgencyPageState extends State<TravelAgencyPage> {
  TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> filteredAgencies = [];
  String selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    filteredAgencies = agencies; // Initially, show all agencies
  }

  // Extract unique categories dynamically from the agencies list
  List<String> getCategories() {
    final categories = agencies.map((agency) => agency['category']).toSet();
    return ['All', ...categories]; // Add 'All' as the default option
  }

  // Update filtered agencies based on search and category
  void _filterAgencies(String query) {
    setState(() {
      filteredAgencies = agencies.where((agency) {
        final matchSearch =
            agency['agencyName']!.toLowerCase().contains(query.toLowerCase());
        final matchCategory =
            selectedCategory == "All" || agency['category'] == selectedCategory;

        return matchSearch && matchCategory;
      }).toList();
    });
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      filteredAgencies = agencies; // Reset to original agencies data
    });
  }

  // Function to delete agency
  void _deleteAgency(String agencyId) {
    setState(() {
      filteredAgencies.removeWhere((agency) => agency['agencyId'] == agencyId);
    });
    print("Agency with ID $agencyId deleted.");
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
                        // Launch in an external browser
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
                          Image.asset(
                            agency['agencyImage']!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
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
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteAgency(
                                  agency['agencyId']!); // Call delete function
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UploadAgencyPage()),
          );

          if (result != null) {
            // Handle the result (new agency added)
            setState(() {
              agencies.add(result); // Add the new agency to the list
              filteredAgencies = agencies; // Update filtered agencies
            });
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Upload Agency',
      ),
    );
  }
}
