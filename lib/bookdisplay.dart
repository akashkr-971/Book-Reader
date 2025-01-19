// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
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
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _pageController = TextEditingController();
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _pageController.text = (_currentPage + 1).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.book[0]),
          backgroundColor: const Color.fromARGB(255, 176, 202, 248)),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.book[1],
            enableSwipe: true,
            autoSpacing: true,
            pageFling: true,
            onViewCreated: (controller) {
              _pdfViewController = controller;
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page!;
                _totalPages = total!;
                _pageController.text = (_currentPage + 1).toString();
              });
            },
          ),
          Positioned(
            bottom: 16.0,
            right: 155.0,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Page: ",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  Container(
                    width: 40.0, // Width of the text box
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: TextField(
                      controller: _pageController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        int? pageNumber = int.tryParse(value);
                        print('Page number: $pageNumber');
                        if (pageNumber != null &&
                            pageNumber > 0 &&
                            pageNumber <= _totalPages) {
                          setState(() {
                            _currentPage = pageNumber - 1;
                          });
                          Future.delayed(Duration(milliseconds: 200), () {
                            _pdfViewController?.setPage(_currentPage);
                          });
                          print('Current page: $_currentPage');
                        }
                      },
                    ),
                  ),
                  Text(
                    ' / $_totalPages',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 176, 202, 248),
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
            // _startTTS(); // Start reading aloud when the play button is clicked
          }
        },
      ),
    );
  }
}
