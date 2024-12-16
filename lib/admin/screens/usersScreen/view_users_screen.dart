import 'package:flutter/material.dart';
import '../../../services/user/user_services.dart';
import '../../../utils/loading.dart';
import 'user_profile_view_screen.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  UserSearchPageState createState() => UserSearchPageState();
}

class UserSearchPageState extends State<UserSearchPage> {
  String query = "";
  String selectedCategory = "All";
  final List<String> categories = ["All", "Active", "Removed"];
  final UserService userService = UserService();

  Future<List<Map<String, dynamic>>> getFilteredUsers() async {
    final allUsers = await userService.fetchUsers();
    List<Map<String, dynamic>> filteredUsers = [];

    if (selectedCategory == "All") {
      filteredUsers = allUsers;
    } else if (selectedCategory == "Active") {
      filteredUsers = allUsers.where((user) => !user['isRemoved']).toList();
    } else if (selectedCategory == "Removed") {
      filteredUsers = allUsers.where((user) => user['isRemoved']).toList();
    }

    // Apply query filter
    if (query.isNotEmpty) {
      filteredUsers = filteredUsers
          .where((user) =>
              user['userName'].toLowerCase().startsWith(query.toLowerCase()))
          .toList();
    }

    return filteredUsers;
  }

  Future<void> updateUserStatus(String userId, bool isRemoved) async {
    userService.updateUserRemovalStatus(userId: userId, isRemoved: isRemoved);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Users"),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = category == selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search by username...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: getFilteredUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingAnimation());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                final filteredUsers = snapshot.data!;
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    childAspectRatio: 5,
                  ),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  OtherProfilePage(userId: user['userId'])),
                        );
                      },
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        shadowColor: user['isRemoved']
                            ? Colors.red.shade300.withOpacity(0.5)
                            : Colors.blue.shade100.withOpacity(0.5),
                        color: user['isRemoved']
                            ? Colors.red.shade100
                            : Colors.white,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: CircleAvatar(
                                backgroundImage:
                                    NetworkImage(user['userImage']),
                                radius: 30,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                user['userName'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => updateUserStatus(
                                user['userId'],
                                !user['isRemoved'],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: user['isRemoved']
                                    ? Colors.green[100]
                                    : Colors.red[100],
                              ),
                              child: Text(
                                user['isRemoved'] ? "+" : "-",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
