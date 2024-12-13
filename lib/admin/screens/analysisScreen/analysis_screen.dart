import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../data/users.dart';
import '../../../data/removedusers.dart';

class AnalysisPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int totalActiveUsers = users.length;
    int totalRemovedUsers = removedusers.length;

    int totalUser = totalActiveUsers + totalRemovedUsers;
    int maleCount = users.where((user) => user['userGender'] == 'Male').length;
    int femaleCount =
        users.where((user) => user['userGender'] == 'Female').length;
    int otherCount =
        users.where((user) => user['userGender'] == 'Other').length;

    int totalPosts = users
        .map((user) => (user['userPosts'] as List).length)
        .reduce((a, b) => a + b);
    int completedPosts = users
        .map((user) => (user['userPosts'] as List)
            .where((post) => post['tripCompleted'] == true)
            .length)
        .reduce((a, b) => a + b);

    int incompletedPosts = totalPosts - completedPosts;

    return Scaffold(
      appBar: AppBar(
        title: Text("Analysis"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total Users Text
              Center(
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Centers content horizontally
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Centers content vertically
                  children: [
                    Column(
                      children: [
                        Text(
                          "$totalUser",
                          style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Total Users",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(
                        width: 50), // Adds space between left and right content
                    Column(
                      children: [
                        Text(
                          "$totalPosts",
                          style: TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Total Posts",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(
                color: Colors.grey,
                thickness: 1,
                height: 20,
              ),
              SizedBox(height: 30),

              _buildPieChartWithHeading(
                context,
                'Removed Users',
                [
                  PieChartSectionData(
                    value: totalRemovedUsers.toDouble(),
                    title: ' ',
                    color: const Color.fromARGB(255, 255, 0, 0),
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: totalActiveUsers.toDouble(),
                    color: const Color.fromARGB(255, 108, 192, 11),
                    title: ' ',
                    radius: 60,
                  ),
                ],
                [
                  "Active Users: $totalActiveUsers",
                  "Removed Users: $totalRemovedUsers"
                ],
              ),

              // Gender Distribution Pie Chart with Heading and Legend
              _buildPieChartWithHeading(
                context,
                'Gender Status',
                [
                  PieChartSectionData(
                    value: maleCount.toDouble(),
                    color: const Color.fromARGB(255, 0, 174, 255),
                    title: ' ',
                    radius: 80,
                  ),
                  PieChartSectionData(
                    value: femaleCount.toDouble(),
                    color: const Color.fromARGB(255, 255, 0, 170),
                    title: ' ',
                    radius: 80,
                  ),
                  PieChartSectionData(
                    value: otherCount.toDouble(),
                    color: const Color.fromARGB(218, 255, 238, 0),
                    title: ' ',
                    radius: 80,
                  ),
                ],
                [
                  "Male: $maleCount",
                  "Female: $femaleCount",
                  "Other: $otherCount"
                ],
              ),

              // Post Completion Pie Chart with Heading and Legend
              _buildPieChartWithHeading(
                context,
                'Post Completion Status',
                [
                  PieChartSectionData(
                    value: completedPosts.toDouble(),
                    color: const Color.fromARGB(255, 108, 192, 11),
                    title: ' ',
                    radius: 80,
                  ),
                  PieChartSectionData(
                    value: incompletedPosts.toDouble(),
                    title: ' ',
                    color: const Color.fromARGB(255, 211, 211, 211),
                    radius: 80,
                  ),
                ],
                [
                  "Completed: $completedPosts",
                  "Incompleted: $incompletedPosts"
                ],
              ),

              // Removed Users Pie Chart with Heading and Legend
            ],
          ),
        ),
      ),
    );
  }

  // Function to build pie chart with heading, legend, and HR line
  Widget _buildPieChartWithHeading(
    BuildContext context,
    String heading,
    List<PieChartSectionData> sections,
    List<String> legends,
  ) {
    return Column(
      children: [
        // Heading for the chart
        Text(
          heading,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),

        // Pie Chart
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 200, // You can control the size of the PieChart here
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 1,
                  centerSpaceRadius: 0,
                ),
              ),
            ),

            // Legend on the right side of the PieChart
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: legends
                  .map((legend) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Container(
                              width: 15,
                              height: 15,
                              color: _getLegendColor(legend), // Color mapping
                            ),
                            SizedBox(width: 5),
                            Text(legend),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),

        // HR Line separator
        Divider(
          color: Colors.grey,
          thickness: 1,
          height: 20,
        ),
      ],
    );
  }

  // Function to map legend text to its corresponding color
  Color _getLegendColor(String legend) {
    if (legend.contains('Male')) {
      return Colors.lightBlue;
    } else if (legend.contains('Female')) {
      return const Color.fromARGB(255, 255, 0, 170);
    } else if (legend.contains('Other')) {
      return const Color.fromARGB(218, 255, 238, 0);
    } else if (legend.contains('Completed')) {
      return const Color.fromARGB(255, 108, 192, 11); // Green for Completed
    } else if (legend.contains('Incompleted')) {
      return const Color.fromARGB(255, 211, 0, 0); // Red for Incompleted
    } else if (legend.contains('Removed')) {
      return const Color.fromARGB(255, 255, 0, 0);
    } else {
      return Colors.green; // Default color for unknown legends
    }
  }
}
