import 'package:flutter/material.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final Color teal = Colors.lightBlueAccent;
  final Color lightIndigo = const Color(0xFFA9BAFA);
  final Color lightPurple = const Color(0xFFB0F3E8);
  final Color darkColor = const Color(0xFF303F9F);

  final List<Map<String, dynamic>> popularTopics = [
    {'heading': 'Best routes for long trips', 'author': 'RoadWarrior', 'contributors': 35},
    {'heading': 'Tips for fuel efficiency', 'author': 'EcoDriver', 'contributors': 28},
    {'heading': 'Favorite road trip snacks', 'author': 'SnackMaster', 'contributors': 42},
    {'heading': 'Car maintenance hacks', 'author': 'MechanicPro', 'contributors': 31},
    {'heading': 'Music playlists for driving', 'author': 'MelodyRider', 'contributors': 39},
  ];

  final List<Map<String, dynamic>> recentTopics = [
    {'heading': 'New traffic laws discussion', 'author': 'LegalEagle', 'joined': 15},
    {'heading': 'Best dash cams 2023', 'author': 'TechGuru', 'joined': 23},
    {'heading': 'Eco-friendly car recommendations', 'author': 'GreenWheels', 'joined': 18},
    {'heading': 'Road trip planning tools', 'author': 'Wanderlust', 'joined': 27},
    {'heading': 'Dealing with road rage', 'author': 'ZenDriver', 'joined': 20},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightIndigo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchAndExplore(),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 20),
              _buildPopularTopics(),
              const SizedBox(height: 20),
              _buildRecentTopics(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage('https://example.com/profile_image.jpg'),
            ),
            const SizedBox(height: 4),
            const Text('Daniel', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            'SmartDriver Community',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndExplore() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search, color: teal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: teal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Explore'),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(Icons.add, 'Start a topic'),
        _buildActionButton(Icons.thumb_up, 'Liked'),
        _buildActionButton(Icons.topic, 'Topics'),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: darkColor, backgroundColor: lightPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildPopularTopics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Popular today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor)),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: popularTopics.length,
            itemBuilder: (context, index) {
              return _buildTopicCard(popularTopics[index]['heading'], popularTopics[index]['author'],
                  popularTopics[index]['contributors'], 'JOIN');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTopics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent topics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor)),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentTopics.length,
          itemBuilder: (context, index) {
            return _buildRecentTopicCard(
              recentTopics[index]['heading'],
              recentTopics[index]['author'],
              recentTopics[index]['joined'],
            );
          },
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('More'),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicCard(String title, String author, int count, String buttonText) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 10),
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(author, style: const TextStyle(color: Colors.grey)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: teal),
                      const SizedBox(width: 4),
                      Text('$count'),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: teal, side: BorderSide(color: teal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(buttonText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTopicCard(String title, String author, int joined) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(author),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group, color: teal),
            Text('$joined', style: TextStyle(color: teal)),
          ],
        ),
      ),
    );
  }
}
