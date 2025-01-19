// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
  bool _isLoading = true;
  String _errorMessage = '';
  late PdfDocument _pdfDocument;
  String _currentPageText = '';
  double _speechRate = 1.0;

  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _pageController = TextEditingController();
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _pageController.text = (_currentPage + 1).toString();
    _initializePdf();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(_speechRate);

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    });
  }

  Future<void> _initializePdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final file = File(widget.book[1]);
      if (!await file.exists()) {
        throw Exception('PDF file not found at path: ${widget.book[1]}');
      }

      final bytes = await file.readAsBytes();
      _pdfDocument = PdfDocument(inputBytes: bytes);

      print('PDF loaded successfully with ${_pdfDocument.pages.count} pages');
      await _loadPageText(_currentPage);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing PDF: $e');
      setState(() {
        _errorMessage = 'Error loading PDF: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPageText(int pageNumber) async {
    try {
      if (pageNumber < 0 || pageNumber >= _pdfDocument.pages.count) {
        throw Exception('Invalid page number');
      }

      PdfTextExtractor extractor = PdfTextExtractor(_pdfDocument);
      String text = extractor.extractText(
        startPageIndex: pageNumber,
        endPageIndex: pageNumber,
      );

      setState(() {
        _currentPageText =
            text.isNotEmpty ? text : 'No text found on this page.';
      });
    } catch (e) {
      print('Error loading page text: $e');
      setState(() {
        _currentPageText = 'Error loading text: $e';
      });
    }
  }

  Future<void> _startTTS() async {
    try {
      if (_currentPageText.isEmpty) {
        await _loadPageText(_currentPage);
      }
      if (_currentPageText.startsWith('Error') ||
          _currentPageText.startsWith('No text found')) {
        await _flutterTts.speak("Cannot read this page. $_currentPageText");
      } else {
        await _flutterTts.speak(_currentPageText);
      }
    } catch (e) {
      print('TTS Error: $e');
      setState(() {
        isPlaying = false;
        _errorMessage = 'Text-to-speech error: $e';
      });
    }
  }

  void _changeSpeechRate(double newRate) async {
    await _flutterTts.setSpeechRate(newRate);
    setState(() {
      _speechRate = newRate;

      if (isPlaying) {
        _flutterTts.pause();
        _startTTS();
      }
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _pageController.dispose();
    _pdfDocument.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book[0]),
        backgroundColor: const Color.fromARGB(255, 176, 202, 248),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Stack(
                  children: [
                    PDFView(
                      filePath: widget.book[1],
                      enableSwipe: true,
                      autoSpacing: true,
                      pageFling: true,
                      onViewCreated: (controller) {
                        _pdfViewController = controller;
                      },
                      onPageChanged: (page, total) async {
                        if (mounted) {
                          setState(() {
                            _currentPage = page!;
                            _totalPages = total!;
                            _pageController.text =
                                (_currentPage + 1).toString();
                          });
                          await _loadPageText(_currentPage);
                        }
                      },
                      onError: (error) {
                        print('PDFView error: $error');
                        setState(() {
                          _errorMessage = 'Error displaying PDF: $error';
                        });
                      },
                    ),
                    Positioned(
                      bottom: 16.0,
                      right: 16.0,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Page: ",
                              style: TextStyle(color: Colors.white),
                            ),
                            Container(
                              width: 40.0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: TextField(
                                controller: _pageController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (value) async {
                                  int? pageNumber = int.tryParse(value);
                                  if (pageNumber != null &&
                                      pageNumber > 0 &&
                                      pageNumber <= _totalPages) {
                                    setState(() {
                                      _currentPage = pageNumber - 1;
                                    });
                                    await _pdfViewController
                                        ?.setPage(_currentPage);
                                    await _loadPageText(_currentPage);
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
          BottomNavigationBarItem(
            icon: const Icon(Icons.speed),
            label: _speechRate == 0.5
                ? '0.5x'
                : _speechRate == 1.0
                    ? '1x'
                    : _speechRate == 1.5
                        ? '1.5x'
                        : '2x',
          ),
          BottomNavigationBarItem(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            label: isPlaying ? 'Stop' : 'Start',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.voice_chat), label: 'Voice'),
        ],
        onTap: (index) async {
          if (index == 0) {
            if (_speechRate == 0.5) {
              _changeSpeechRate(1.0);
            } else if (_speechRate == 1.0) {
              _changeSpeechRate(1.5);
            } else if (_speechRate == 1.5) {
              _changeSpeechRate(2.0);
            } else {
              _changeSpeechRate(0.5);
            }
          } else if (index == 1) {
            setState(() {
              isPlaying = !isPlaying;
            });
            if (isPlaying) {
              await _startTTS();
            } else {
              await _flutterTts.pause();
            }
          }
        },
      ),
    );
  }
}
