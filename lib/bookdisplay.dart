// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class BookDisplay extends StatefulWidget {
  final List<String> book;

  const BookDisplay({super.key, required this.book});

  @override
  State<BookDisplay> createState() => _BookDisplayState();
}

class _BookDisplayState extends State<BookDisplay> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool isPlaying = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  late PDFDoc _pdfDocument;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    _pdfDocument = await PDFDoc.fromFile(File(widget.book[1]));
    setState(() {
      _totalPages = _pdfDocument.length;
    });
  }

  void _searchText(String query) async {
    setState(() {
      _searchQuery = query;
    });

    if (_searchQuery.isNotEmpty) {
      for (int page = 0; page < _totalPages; page++) {
        String pageText = await _getPageText(page);
        if (pageText.contains(_searchQuery)) {
          setState(() {
            _currentPage = page;
          });
          break;
        }
      }
    }
  }

  Future<String> _getPageText(int pageIndex) async {
    PDFPage page = _pdfDocument.pageAt(pageIndex);
    String text = await page.text;
    return text;
  }

  void _startTTS() async {
    // Start reading from the highlighted text (currently from the search query text)
    String pageText = await _getPageText(_currentPage);
    String textToRead = _searchQuery.isEmpty ? pageText : _searchQuery;
    await _flutterTts.speak(textToRead);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                onChanged: _searchText,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                ),
              )
            : Text(widget.book[0]),
        actions: [
          _isSearching
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                    });
                  },
                )
              : IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.book[1],
            enableSwipe: true,
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page!;
                _totalPages = total!;
              });
            },
          ),
          Positioned(
            bottom: 16.0,
            right: 160.0,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Page ${_currentPage + 1} / $_totalPages',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Speed'),
          BottomNavigationBarItem(
            icon: isPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
            label: isPlaying ? 'Stop' : 'Start',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            setState(() {
              isPlaying = !isPlaying;
            });
            _startTTS(); // Start reading aloud when the play button is clicked
          }
        },
      ),
    );
  }
}
