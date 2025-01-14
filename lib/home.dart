// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

final List<List<String>> books = [];
final List<List<String>> filteredBooks = [];

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController
            .clear(); // Clear the text field when the search is closed
      }
    });
  }

  void _reload() {
    setState(() {
      _currentIndex = 0;
      _pages[0] = Homescreen();
      _pages[1] = Settingspage();
    });
  }

  final List<Widget> _pages = [
    const Homescreen(),
    const Settingspage(),
  ];

  Future<void> _upload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = p.basenameWithoutExtension(result.files.single.name);
      setState(() {
        books.add([fileName, file.path]);
      });
      _reload();
    } else {
      print('No file selected');
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
              )
            : const Text('Book Reader'),
        centerTitle: true,
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
              onPressed: _toggleSearch,
              icon: Icon(_isSearching ? Icons.close : Icons.search)),
        ],
      ),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
          onPressed: _upload, tooltip: 'Upload', child: Icon(Icons.upload)),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: onTabTapped,
          selectedItemColor: const Color.fromARGB(
              255, 67, 31, 226), // Color for the selected tab
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ]),
    );
  }
}

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
  Widget build(BuildContext context) {
    void openPdf() {
      print('Opening PDF...');
      print(books);
    }

    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(books[index][0]), // Correct access for title
          subtitle:
              Text(books[index][1]), // Correct access for subtitle (author)
          leading: const Icon(Icons.book),
          trailing: IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                          title: const Text('Book Opertaions'),
                          content: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 150),
                            child: Column(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      books.removeAt(index);
                                    });
                                  },
                                  child: const Text('Delete Book'),
                                ),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Rename Book'),
                                              content: TextField(
                                                decoration:
                                                    const InputDecoration(
                                                        hintText:
                                                            'Enter new name'),
                                                onChanged: (value) {
                                                  books[index][0] = value;
                                                },
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    setState(() {});
                                                  },
                                                  child: Text('Rename Book'),
                                                ),
                                              ],
                                            );
                                          });
                                    },
                                    child: const Text('Rename Book')),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.blue),
                                    child: const Text('Cancel')),
                              ],
                            ),
                          ));
                    });
              },
              icon: const Icon(Icons.more_vert)),
          onTap: openPdf,
        );
      },
    );
  }
}

class Settingspage extends StatefulWidget {
  const Settingspage({super.key});

  @override
  State<Settingspage> createState() => _SettingspageState();
}

class _SettingspageState extends State<Settingspage> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings'),
    );
  }
}
