// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'bookdisplay.dart';
import 'package:path/path.dart' as p;

List<List<String>> books = [];
List<List<String>> allbooks = [];

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
        _searchController.clear();
        books = List.from(allbooks);
      }
    });
    _reload();
  }

  void _filterBooks() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        print('\n');
        print('Query is empty');
        books = allbooks;
      } else {
        books = books.where((book) {
          return book[0].toLowerCase().contains(query);
        }).toList();
      }
    });
    _reload();
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
      bool fileExists = books.any((book) => book[0] == fileName);
      bool filepathExists = books.any((book) => book[0] == file.path);
      if (!fileExists && !filepathExists) {
        setState(() {
          books.add([fileName, file.path]);
          allbooks.add([fileName, file.path]);
        });
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Already Uploaded'),
                content: const Text('Book already exists'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
        print('Book already exists');
      }
      _reload();
    } else {
      print('File not selected');
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
                onChanged: (query) => _filterBooks(),
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
  void _openPDF(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDisplay(book: books[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          title: const Text('Book Operations'),
                          content: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 150),
                            child: Column(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      String bookname = books[index][0];
                                      books.removeWhere(
                                          (book) => book[0] == bookname);
                                      allbooks.removeWhere(
                                          (book) => book[0] == bookname);
                                    });
                                    Navigator.pop(context);
                                    books = allbooks;
                                    print(books);
                                  },
                                  child: const Text('Delete Book'),
                                ),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      TextEditingController renameController =
                                          TextEditingController();
                                      renameController.text = books[index][0];
                                      print(
                                          'old book name in controller is: ${renameController.text}');
                                      showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Rename Book'),
                                              content: TextField(
                                                controller: renameController,
                                                decoration:
                                                    const InputDecoration(
                                                        hintText:
                                                            'Enter new name'),
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () {
                                                    String value =
                                                        renameController.text;
                                                    String oldBookName =
                                                        books[index][0];
                                                    print(
                                                        'Old book name: $oldBookName');
                                                    books[index][0] = value;
                                                    int allBooksIndex = allbooks
                                                        .indexWhere((book) =>
                                                            book[0] ==
                                                            oldBookName);
                                                    print(oldBookName);
                                                    print(allBooksIndex);
                                                    if (allBooksIndex != -1) {
                                                      allbooks[allBooksIndex]
                                                          [0] = value;
                                                    }
                                                    books = allbooks;
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
          onTap: () => _openPDF(index),
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
