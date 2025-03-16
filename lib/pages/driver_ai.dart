import 'package:flutter/material.dart';

class DriverAIScreen extends StatefulWidget {
  const DriverAIScreen({super.key});

  @override
  State<DriverAIScreen> createState() => _DriverAIScreenState();
}

class _DriverAIScreenState extends State<DriverAIScreen> {
  bool _isPanelVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car, size: 100),
                      SizedBox(height: 20),
                      Text(
                        'Welcome to your DriverAI',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'How can I help today?',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildAttachmentButton(),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.send),
                        SizedBox(width: 8),
                        Icon(Icons.mic),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                      child: Text('AI Vehicle Overview'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isPanelVisible = !_isPanelVisible;
                });
              },
              child: Icon(Icons.history),
            ),
          ),
          if (_isPanelVisible)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isPanelVisible = false;
                });
              },
              child: Container(
                color: Colors.black,
              ),
            ),
          if (_isPanelVisible)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.75,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: ModalRoute.of(context)!.animation!,
                  curve: Curves.easeOut,
                )),
                child: Container(
                  color: Colors.blueGrey,
                  child: Center(
                    child: Text('Recent Panel Content'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.add),
      onSelected: (String result) {
        // Handle attachment selection
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'image',
          child: Text('Image'),
        ),
        const PopupMenuItem<String>(
          value: 'document',
          child: Text('Document'),
        ),
      ],
    );
  }
}

