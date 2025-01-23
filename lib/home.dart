// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'bookdisplay.dart';
import 'package:path/path.dart' as p;
import 'db_helper.dart';
import 'package:url_launcher/url_launcher.dart';

List<List<String>> books = [];
List<List<String>> allbooks = [];
bool _isSearching = false;
final TextEditingController _searchController = TextEditingController();

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _reload() {
    setState(() {
      _currentIndex = 0;
      _pages[0] = Homescreen();
      _pages[1] = SearchBook();
      _pages[2] = Settingspage();
    });
    print('reload called');
  }

  Future<void> _loadBooks() async {
    List<Map<String, dynamic>> dbBooks = await DBHelper.getBooks();
    setState(() {
      books = dbBooks
          .map((book) => [book['name'] as String, book['path'] as String])
          .toList();
    });
    print('The books stored in db are : $books');
    allbooks = books;
    _reload();
  }

  Future<void> _addBook(bookName, path) async {
    await DBHelper.insertBook({
      'name': bookName,
      'path': path,
      'currentPage': 1,
    });
    _loadBooks();
  }

  void _toggleSearch() {
    allbooks = books;
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        books = allbooks;
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
          _addBook(fileName, file.path);
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

  final List<Widget> _pages = [
    const Homescreen(),
    const SearchBook(),
    const Settingspage()
  ];

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
                icon: Icon(Icons.search), label: 'Search Book'),
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
    if (books.isEmpty) {
      return Center(
        child: Text(
          'No books available\nUpload a book to continue!!',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
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
                          title: const Text('Book Operations'),
                          content: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 150),
                            child: Column(
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    String bookname = books[index][0];
                                    await DBHelper.deleteBook(bookname);
                                    setState(() {
                                      books.removeAt(index);
                                      allbooks.removeWhere(
                                          (book) => book[0] == bookname);
                                      _searchController.clear();
                                      _isSearching = !_isSearching;
                                      books = allbooks;
                                    });
                                    Navigator.pop(context);
                                    print('Deleted book: $bookname');
                                    setState(() {});
                                  },
                                  child: const Text('Delete Book'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close the dialog
                                    TextEditingController renameController =
                                        TextEditingController();
                                    renameController.text = books[index][0];
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Rename Book'),
                                          content: TextField(
                                            controller: renameController,
                                            decoration: const InputDecoration(
                                                hintText: 'Enter new name'),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () async {
                                                String newBookName =
                                                    renameController.text;
                                                String oldBookName =
                                                    books[index][0];
                                                final db =
                                                    await DBHelper.database;
                                                await db.update(
                                                  'books',
                                                  {'name': newBookName},
                                                  where: 'name = ?',
                                                  whereArgs: [oldBookName],
                                                );

                                                setState(() {
                                                  books[index][0] =
                                                      newBookName; // Update the name in books list
                                                  int allBooksIndex = allbooks
                                                      .indexWhere((book) =>
                                                          book[0] ==
                                                          oldBookName);
                                                  if (allBooksIndex != -1) {
                                                    allbooks[allBooksIndex][0] =
                                                        newBookName;
                                                  }
                                                  _searchController.clear();
                                                  books = allbooks;
                                                });

                                                Navigator.pop(context);
                                                setState(() {});
                                                print(
                                                    'Renamed book from $oldBookName to $newBookName');
                                              },
                                              child: const Text('Rename Book'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: const Text('Rename Book'),
                                ),
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

class SearchBook extends StatefulWidget {
  const SearchBook({super.key});

  @override
  State<SearchBook> createState() => _SearchBookState();
}

Future<void> _searchbook(String bookName) async {
  final Uri url =
      Uri.parse('https://www.google.com/search?query=$bookName:pdf');

  try {
    await launchUrl(url);
  } catch (e) {
    print('The error is : $e');
  }
}

class _SearchBookState extends State<SearchBook> {
  TextEditingController googlesearch = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: EdgeInsets.all(5),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(15),
            child: Text(
              "Enter the Book name to search for pdf on google...",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: googlesearch,
                  decoration: InputDecoration(
                      hintText: 'Enter book name',
                      prefixIcon: Icon(Icons.search)),
                ),
              ),
              TextButton(
                onPressed: () {
                  String bookName = googlesearch.text;
                  bookName = bookName.replaceAll(' ', '+');
                  _searchbook(bookName);
                },
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                        const Color.fromARGB(255, 97, 174, 236)),
                    foregroundColor: WidgetStateProperty.all(
                        const Color.fromARGB(255, 255, 255, 255))),
                child: const Text('Search Book'),
              )
            ],
          )
        ],
      ),
    ));
  }
}
