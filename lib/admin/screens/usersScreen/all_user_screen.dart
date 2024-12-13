import 'package:flutter/material.dart';

import '../../../data/removedusers.dart';
import '../../../data/users.dart';
import 'user_profile_screen.dart';

class UserSearchPage extends StatefulWidget {
  @override
  _UserSearchPageState createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  String query = "";
  String selectedCategory = "All";
  final List<String> categories = ["All", "Active", "Removed"];

  List<Map<String, dynamic>> getFilteredUsers() {
    List<Map<String, dynamic>> filteredUsers = [];

    if (selectedCategory == "All") {
      // Combine both active and removed users
      filteredUsers = [...users, ...removedusers];
    } else if (selectedCategory == "Active") {
      filteredUsers = users;
    } else if (selectedCategory == "Removed") {
      filteredUsers = removedusers;
    }

    // Apply query filter
    filteredUsers = filteredUsers
        .where((user) =>
            user['userName'].toLowerCase().startsWith(query.toLowerCase()))
        .toList();

    // Shuffle the user positions for the "All" category
    if (selectedCategory == "All") {
      filteredUsers.shuffle();
    }

    return filteredUsers;
  }

  void removeUser(String userName) {
    setState(() {
      // Find the user in the `users` list and move them to `removedusers`
      final user = users.firstWhere(
        (user) => user['userName'] == userName,
        orElse: () => {},
      );
      if (user.isNotEmpty) {
        users.remove(user);
        removedusers.add(user);
      }
    });
    print('User $userName is Removed');
  }

  void addUser(String userName) {
    setState(() {
      // Find the user in the `removedusers` list and move them to `users`
      final user = removedusers.firstWhere(
        (user) => user['userName'] == userName,
        orElse: () => {},
      );
      if (user.isNotEmpty) {
        removedusers.remove(user);
        users.add(user);
      }
    });
    print('User $userName is Added');
  }

  Color getCardColor(Map<String, dynamic> user) {
    if (removedusers.contains(user)) {
      return Colors.red.shade100; // Red color for removed users
    }
    return Colors.white; // Default color for active users
  }

  Color getShadowColor(Map<String, dynamic> user) {
    if (removedusers.contains(user)) {
      return Colors.red.shade300
          .withOpacity(0.5); // Shadow color for removed users
    }
    final gender = user['userGender']?.toLowerCase() ?? "";
    if (gender == "male") {
      return Colors.lightBlue.withOpacity(0.1); // Shadow color for males
    } else if (gender == "female") {
      return Colors.pinkAccent.shade100
          .withOpacity(0.1); // Shadow color for females
    } else {
      return Colors.yellow.shade600.withOpacity(0.1); // Shadow color for others
    }
  }

  Color getBorderColor(Map<String, dynamic> user) {
    final gender = user['userGender']?.toLowerCase() ?? "";
    if (gender == "male") {
      return Colors.lightBlue; // Border color for males
    } else if (gender == "female") {
      return Colors.pinkAccent.shade100; // Border color for females
    } else {
      return Colors.yellow.shade600; // Border color for others
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredUsers = getFilteredUsers();

    return Scaffold(
      appBar: AppBar(
        title: Text("Search Users"),
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
              decoration: InputDecoration(
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
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                        builder: (context) => UserProfilePage(
                          username: user['userName'],
                          isRemoved: removedusers
                              .contains(user), // Pass the status here
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    shadowColor: getShadowColor(user), // Shadow color
                    color: getCardColor(
                        user), // Card color (red for removed users)
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: getShadowColor(user), // Shadow effect
                            blurRadius: 4,
                            spreadRadius: 2,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: getBorderColor(
                                      user), // Border color based on gender
                                  width: 3.0,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundImage: AssetImage(user['userImage']),
                                radius: 30,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              user['userName'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!removedusers.contains(user))
                            ElevatedButton(
                                onPressed: () => removeUser(user['userName']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[100],
                                ),
                                child: Text(
                                  "-",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 16.0,
                                  ),
                                )),
                          if (removedusers.contains(user))
                            ElevatedButton(
                                onPressed: () => addUser(user['userName']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[100],
                                ),
                                child: Text(
                                  "+",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 16.0,
                                  ),
                                )),
                        ],
                      ),
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
